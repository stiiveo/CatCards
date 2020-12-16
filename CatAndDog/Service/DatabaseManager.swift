//
//  DatabaseManager.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/8/14.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit
import CoreData

protocol DatabaseManagerDelegate {
    func savedImagesMaxReached()
}

class DatabaseManager {
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private let fileManager = FileManager.default
    private let imageFolderName = K.Image.FolderName.fullImage
    private let thumbFolderName = K.Image.FolderName.thumbnail
    internal let imageProcess = ImageProcess()
    private var favoriteArray: [Favorite]!
    static var imageFileURLs = [FilePath]()
    internal var delegate: DatabaseManagerDelegate?
    
    struct FilePath {
        let image: URL
        let thumbnail: URL
    }
    
    //MARK: - Data Loading
    
    // Load thumbnail images from local folder
    internal func getImageFileURLs() {
        DatabaseManager.imageFileURLs.removeAll() // Clean all image file URLs in memory buffer first
        
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageFolderURL = url.appendingPathComponent(imageFolderName, isDirectory: true)
        let thumbnailFolderURL = url.appendingPathComponent(thumbFolderName, isDirectory: true)
        
        // Load image file path to cache
        let fileList = listOfSavedFileNames() // Get list of image file IDs from local database
        for fileName in fileList {
            let fileExtension = K.API.imageType
            let imageURL = imageFolderURL.appendingPathComponent(fileName + "." + fileExtension)
            let thumbnailURL = thumbnailFolderURL.appendingPathComponent(fileName + "." + fileExtension)
            let newFilePath = FilePath(image: imageURL, thumbnail: thumbnailURL)
            
            DatabaseManager.imageFileURLs.append(newFilePath)
        }
        
        // TEST USE
        print("Local Document Directory Path: \(url.path)")
    }
    
    //MARK: - Data Saving
    
    internal func saveData(_ data: CatData) {
        guard favoriteArray.count < K.Data.maxSavedImages else {
            delegate?.savedImagesMaxReached() // Notify the error to the delegate.
            
            return
        }
        
        // Save data to local database
        let newData = Favorite(context: context)
        newData.id = data.id
        newData.date = Date()
        saveContext()
        
        // Update favorite list
        favoriteArray.append(newData)
        
        // Save image to local file system with ID as the file name
        saveImageToLocalSystem(image: data.image, fileName: data.id)
    }
    
    /// Save downloaded image and downsampled image to user's local disk.
    ///
    ///  * Image is compressed to JPG file.
    ///  * Thumbnail image is made by downsampling the image data and converting to JPG file.
    /// - Parameters:
    ///   - image: Image to be processed and saved.
    ///   - fileName: The name used to be saved in local file system, both image and thumbnail image.
    private func saveImageToLocalSystem(image: UIImage, fileName: String) {
        // Compress image to JPG data and save it in local disk
        guard let compressedJPG = image.jpegData(compressionQuality: 0.7) else {
            debugPrint("Unable to convert UIImage to JPG data."); return }
        writeFileTo(folder: imageFolderName, withData: compressedJPG, withName: "\(fileName).jpg")
        
        // Downsample the downloaded image
        guard let imageData = image.pngData() else {
            debugPrint("Unable to convert UIImage object to PNG data."); return }
        let downsampledImage = imageProcess.downsample(dataAt: imageData)
        
        // Convert downsampled image to JPG data and save it to local disk
        guard let JpegData = downsampledImage.jpegData(compressionQuality: 0.7) else {
            debugPrint("Error: Unable to convert downsampled image data to JPG data."); return }
        writeFileTo(folder: thumbFolderName, withData: JpegData, withName: "\(fileName).jpg")
        
        // Refresh image file url cache
        getImageFileURLs()
    }
    
    // Write data into application's document folder
    private func writeFileTo(folder folderName: String, withData data: Data, withName fileName: String) {
        let url = try? fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        if let fileURL = url?.appendingPathComponent(folderName, isDirectory: true).appendingPathComponent(fileName) {
            do {
                try data.write(to: fileURL) // Write data to assigned URL
            } catch {
                debugPrint("Error writing data into document directory: \(error)")
            }
        }
    }
    
    //MARK: - Data Deletion
    
    // Delete data matching the ID in database and file system
    internal func deleteData(id: String) {
        
        // Delete data in database (CoreData)
        let fetchRequest: NSFetchRequest<Favorite> = Favorite.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id MATCHES %@", id) // Fetch data with the matched ID value
        do {
            let fetchResult = try context.fetch(fetchRequest)
            for object in fetchResult {
                context.delete(object) // Delete every object from the fetched result
            }
            saveContext()
        } catch {
            debugPrint("Error fetching result from container: \(error)")
        }
        
        // Delete image file in local file system
        let fileName = "\(id).jpg"
        let imageURL = folderURL(name: imageFolderName).appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: imageURL.path) {
            do {
                try fileManager.removeItem(at: imageURL)
            } catch {
                debugPrint("Error removing image from file system: \(error)")
            }
        }
        
        // Delete thumbnail file in local file system
        let thumbnailURL = folderURL(name: thumbFolderName).appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: thumbnailURL.path) {
            do {
                try fileManager.removeItem(at: thumbnailURL)
            } catch {
                debugPrint("Error removing thumbnail image from file system: \(error)")
            }
        }
        
        // Refresh the image file URL cache
        getImageFileURLs()
        
        // Remove the cached favorite item matching the id
        for item in favoriteArray {
            if item.id == id {
                favoriteArray.removeAll{$0 == item} // Remove all elements that satisfy the predicate
            }
        }
    }
    
    //MARK: - Creation of Directory / sub-Directory
    
    // Create image and thumbnail folder in application document directory
    internal func createDirectory() {
        
        // Create image folder
        let imageURL = folderURL(name: imageFolderName)
        if !fileManager.fileExists(atPath: imageURL.path) {
            do {
                try fileManager.createDirectory(at: imageURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("Failed to create image folder within app's document folder.\n Make sure file path \(imageURL.path) is correct.")
            }
        }
        
        // Create thumbnail image folder
        let thumbnailURL = folderURL(name: thumbFolderName)
        if !fileManager.fileExists(atPath: thumbnailURL.path) {
            do {
                try fileManager.createDirectory(at: thumbnailURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("Failed to create thumbnail image folder within app's document folder.\n Make sure file path \(thumbnailURL.path) is correct.")
            }
        }
    }
    
    private func folderURL(name: String) -> URL {
        let documentURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentURL.appendingPathComponent(name, isDirectory: true)
    }
    
    //MARK: - CoreData and File Manager Tools
    
    internal func isDataSaved(data: CatData) -> Bool {
        let url = folderURL(name: imageFolderName)
        let newDataId = data.id
        let newFileURL = url.appendingPathComponent("\(newDataId).jpg")
        return fileManager.fileExists(atPath: newFileURL.path)
    }
    
    internal func listOfSavedFileNames() -> [String] {
        let fetchRequest: NSFetchRequest<Favorite> = Favorite.fetchRequest()
        
        // Sort data by making the last saved data at first
        let sort = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sort]
        
        var fileNameList = [String]()
        do {
            favoriteArray = try context.fetch(fetchRequest)
            for item in favoriteArray {
                if let id = item.id {
                    fileNameList.append(id)
                }
            }
            return fileNameList
        } catch {
            debugPrint("Error fetching Favorite entity from container: \(error)")
        }
        return []
    }
    
    private func saveContext() {
        do {
            try self.context.save()
        } catch {
            debugPrint("Error saving Favorite object to container: \(error)")
        }
    }
   
}
