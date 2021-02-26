//
//  DatabaseManager.swift
//  CatCards
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
    private let cacheFolderName = K.Image.FolderName.cacheImage
    let imageProcess = ImageProcessor()
    private var favoriteArray: [Favorite]!
    static var imageFileURLs = [FilePath]()
    var delegate: DatabaseManagerDelegate?
    private let jpegCompression = K.Image.jpegCompressionQuality
    private let fileExtension = "." + K.API.imageType
    
    struct FilePath {
        let image: URL
        let thumbnail: URL
    }
    
    //MARK: - Data Loading
    
    // Load thumbnail images from local folder
    internal func getSavedImageFileURLs() {
        DatabaseManager.imageFileURLs.removeAll() // Clean all image file URLs in memory buffer first
        
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageFolderURL = url.appendingPathComponent(imageFolderName, isDirectory: true)
        let thumbnailFolderURL = url.appendingPathComponent(thumbFolderName, isDirectory: true)
        
        // Load image file path to cache
        let fileList = listOfSavedFileNames() // Get list of image file IDs from local database
        for fileName in fileList {
            let imageURL = imageFolderURL.appendingPathComponent(fileName + fileExtension)
            let thumbnailURL = thumbnailFolderURL.appendingPathComponent(fileName + fileExtension)
            let newFilePath = FilePath(image: imageURL, thumbnail: thumbnailURL)
            
            DatabaseManager.imageFileURLs.append(newFilePath)
        }
    }
    
    //MARK: - Data Saving
    
    internal func saveData(_ data: CatData, completion: K.CompletionHandler) {
        guard favoriteArray.count < K.Data.maxSavedImages else {
            delegate?.savedImagesMaxReached() // Notify the error to the delegate.
            completion(false)
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
        completion(true)
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
        guard let compressedJPG = image.jpegData(compressionQuality: jpegCompression) else {
            debugPrint("Unable to convert UIImage to JPG data."); return }
        writeFileTo(folder: imageFolderName, withData: compressedJPG, withName: fileName + fileExtension)
        
        // Downsample the downloaded image
        guard let imageData = image.pngData() else {
            debugPrint("Unable to convert UIImage object to PNG data."); return }
        let downsampledImage = imageProcess.downsample(dataAt: imageData)
        
        // Convert downsampled image to JPG data and save it to local disk
        guard let jpegData = downsampledImage.jpegData(compressionQuality: jpegCompression) else {
            debugPrint("Error: Unable to convert downsampled image data to JPG data."); return }
        writeFileTo(folder: thumbFolderName, withData: jpegData, withName: fileName + fileExtension)
        
        // Refresh image file url cache
        getSavedImageFileURLs()
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
        
        // Remove full and thumbnail image file from local file system
        removeFile(atDirectory: .documentDirectory, withinFolder: imageFolderName, fileName: id)
        removeFile(atDirectory: .documentDirectory, withinFolder: thumbFolderName, fileName: id)
        
        // Refresh the image file URL cache
        getSavedImageFileURLs()
        
        // Remove the cached favorite item matching the id
        for item in favoriteArray {
            if item.id == id {
                favoriteArray.removeAll{$0 == item} // Remove all elements that satisfy the predicate
            }
        }
    }
    
    func removeFile(atDirectory directory: FileManager.SearchPathDirectory, withinFolder folderName: String, fileName: String) {
        let url = getFolderURL(folderName: folderName, at: directory).appendingPathComponent(fileName + fileExtension)
        
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                debugPrint("Failed to remove file `\(fileName)` from the file system:\n\(error)")
            }
        }
    }
    
    //MARK: - Cache Creation & Removal
    
    /// Get an image's temporary URL object for share sheet's preview usage
    func getImageTempURL(catData: CatData) -> URL? {
        // Convert image to jpeg file and write it to cache directory folder
        guard let imageData = catData.image.jpegData(compressionQuality: jpegCompression) else { return nil }
        
        let cacheURL = try? fileManager.url(for: .cachesDirectory,
                                       in: .userDomainMask,
                                       appropriateFor: nil,
                                       create: true)
        let fileName = catData.id + fileExtension
        
        if let fileURL = cacheURL?.appendingPathComponent(cacheFolderName, isDirectory: true).appendingPathComponent(fileName) {
            do {
                try imageData.write(to: fileURL)
                // Return file's url
                return fileURL
            } catch {
                debugPrint("Error writing data into cache directory: \(error)")
            }
        } 
        return nil
    }
    
    //MARK: - Creation of Directory / sub-Directory
    
    private func createDirectory(withName name: String, at directory: FileManager.SearchPathDirectory) {
        let url = getFolderURL(folderName: name, at: directory)
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("Failed to create folder `\(name)`.\n Please make sure this file path `\(url.path)` is correct.")
            }
        }
    }
    
    private func getFolderURL(folderName: String, at directory: FileManager.SearchPathDirectory) -> URL {
        let documentURL = fileManager.urls(for: directory, in: .userDomainMask).first!
        return documentURL.appendingPathComponent(folderName, isDirectory: true)
    }
    
    func createNecessaryFolders() {
        createDirectory(withName: imageFolderName, at: .documentDirectory)
        createDirectory(withName: thumbFolderName, at: .documentDirectory)
        createDirectory(withName: cacheFolderName, at: .cachesDirectory)
    }
    
    //MARK: - CoreData and File Manager Tools
    
    internal func isDataSaved(data: CatData) -> Bool {
        let url = getFolderURL(folderName: imageFolderName, at: .documentDirectory)
        let dataId = data.id
        let newFileURL = url.appendingPathComponent(dataId + fileExtension)
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
