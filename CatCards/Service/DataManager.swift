//
//  DataManager.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/8/14.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit
import CoreData

protocol DataManagerDelegate: AnyObject {
    func savedImagesMaxReached()
}

final class DataManager {
    
    static let shared = DataManager()
    
    // MARK: - Properties
    
    unowned var delegate: DataManagerDelegate?
    
    private var context: NSManagedObjectContext? {
        if let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
            return context
        }
        fatalError("Failed to get valid reference to application's AppDelegate.swift.")
    }
    
    private let fileManager = FileManager.default
    private var favoriteArray = [Favorite]()
    
    private let previewImageFolderName = K.File.FolderName.activityPreview
    private let imageFolderName = K.File.FolderName.fullImage
    private let thumbFolderName = K.File.FolderName.thumbnail
    private let cacheFolderName = K.File.FolderName.cacheImage
    private let jpegCompression = K.Data.jpegDataCompressionQuality
    private let imageExtension = K.File.imageFileExtension
    
    enum ImageFolder: String {
        case fullImage, thumbnail, cacheImage, activityPreview
    }
    
    private func folderName(folder: ImageFolder) -> String {
        switch folder {
        case .fullImage: return imageFolderName
        case .thumbnail: return thumbFolderName
        case .cacheImage: return cacheFolderName
        case .activityPreview: return previewImageFolderName
        }
    }
    
    enum ImageFileType: String {
        case jpg = "jpg"
    }
    
    struct ImageFileURL {
        let image: URL
        let thumbnail: URL
    }
    
    var imageFileURLs: [ImageFileURL] {
        return savedImageFilesURLs()
    }
    
    // MARK: - Init
    
    private init() {
        createFoldersNeeded()
    }
    
    // MARK: - Data Loading
    
    private func savedImageFilesURLs() -> [ImageFileURL] {
        let rootUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageFolderURL = rootUrl.appendingPathComponent(imageFolderName, isDirectory: true)
        let thumbnailFolderURL = rootUrl.appendingPathComponent(thumbFolderName, isDirectory: true)
        
        var imageFilesURLs: [ImageFileURL] = []
        savedFilesList().forEach {
            let imageURL = imageFolderURL.appendingPathComponent($0).appendingPathExtension(imageExtension)
            let thumbnailURL = thumbnailFolderURL.appendingPathComponent($0).appendingPathExtension(imageExtension)
            let filePath = ImageFileURL(image: imageURL, thumbnail: thumbnailURL)
            imageFilesURLs.append(filePath)
        }
        
        return imageFilesURLs
    }
    
    // MARK: - Data Saving
    
    internal func saveData(_ data: CatData, completion: K.CompletionHandler) {
        guard favoriteArray.count < K.Data.maxSavedImages else {
            // Maximum number of saved images is reached.
            delegate?.savedImagesMaxReached()
            completion(false)
            return
        }
        
        // Save data to local database.
        let newData = Favorite(context: context!)
        newData.id = data.id
        newData.date = Date()
        saveContext()
        
        // Update favorite list.
        favoriteArray.append(newData)
        
        // Save image to local file system with ID as the file name.
        saveImageFile(image: data.image, withFileName: data.id)
        completion(true)
    }
    
    /// Save downloaded image and downsampled image to user's local disk.
    ///
    ///  * Image is compressed to JPG file.
    ///  * Thumbnail image is made by downsampling the image data and converting to JPG file.
    /// - Parameters:
    ///   - image: Image to be processed and saved.
    ///   - fileName: The name used to be saved in local file system, both image and thumbnail image.
    private func saveImageFile(image: UIImage, withFileName fileName: String) {
        // Compress image to JPG data and save it in local disk
        guard let jpegData = image.jpegData(compressionQuality: jpegCompression) else {
            debugPrint("Unable to convert UIImage to JPG data."); return }
        writeData(jpegData, to: .fullImage, withName: fileName, fileType: .jpg)
        
        // Downsample the image to be used as the thumbnail image
        let downsampledImage = image.downsampled(toSize: K.Image.thumbnailSize)
        
        // Convert downsampled image to JPG data and save it to local disk
        guard let jpegData = downsampledImage.jpegData(compressionQuality: jpegCompression) else {
            debugPrint("Error: Unable to convert downsampled image data to JPG data.")
            return
        }
        
        writeData(jpegData, to: .thumbnail, withName: fileName, fileType: .jpg)
    }
    
    // Write data into app's document folder.
    private func writeData(
        _ data: Data,
        to folder: ImageFolder,
        withName fileName: String,
        fileType: ImageFileType
    ) {
        let url = try? fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let folderName = folderName(folder: folder)
        if let fileURL = url?
            .appendingPathComponent(folderName, isDirectory: true)
            .appendingPathComponent(fileName)
            .appendingPathExtension(fileType.rawValue) {
            do {
                try data.write(to: fileURL) // Write data to assigned URL
            } catch {
                debugPrint("Error writing data into document directory: \(error)")
            }
        }
    }
    
    // MARK: - Data Deletion
    
    // Delete data matching the ID in database and file system
    internal func deleteData(id: String) {
        // Delete data in database (CoreData)
        let fetchRequest: NSFetchRequest<Favorite> = Favorite.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id MATCHES %@", id) // Fetch data with the matched ID value
        do {
            let fetchResult = try context!.fetch(fetchRequest)
            for object in fetchResult {
                context!.delete(object) // Delete every object from the fetched result
            }
            saveContext()
        } catch {
            debugPrint("Error fetching result from container: \(error)")
        }
        
        // Remove full and thumbnail image files from local file system
        removeImageFile(fileName: id, fileType: .jpg, fromFolder: .fullImage, directory: .documentDirectory)
        removeImageFile(fileName: id, fileType: .jpg, fromFolder: .thumbnail, directory: .documentDirectory)
        
        // Remove the cached favorite item matching the id
        for item in favoriteArray where item.id == id {
            favoriteArray.removeAll(where: { $0 == item })
        }
    }
    
    internal func removeImageFile(fileName: String, fileType: ImageFileType, fromFolder folder: ImageFolder, directory: FileManager.SearchPathDirectory) {
        let url = getFolderURL(folderName: folderName(folder: folder), at: directory)
            .appendingPathComponent(fileName)
            .appendingPathExtension(fileType.rawValue)
        
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                debugPrint("Failed to remove file `\(fileName)` from the file system:\n\(error)")
            }
        }
    }
    
    // MARK: - Directories Creation
    
    private func createFolder(name: String, at directory: FileManager.SearchPathDirectory) {
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
        let directoryURL = fileManager.urls(for: directory, in: .userDomainMask).first!
        return directoryURL.appendingPathComponent(folderName, isDirectory: true)
    }
    
    private func createFoldersNeeded() {
        createFolder(name: imageFolderName, at: .documentDirectory)
        createFolder(name: thumbFolderName, at: .documentDirectory)
        createFolder(name: cacheFolderName, at: .cachesDirectory)
        createFolder(name: previewImageFolderName, at: .cachesDirectory)
    }
    
    // MARK: - Saved Data Availability & Listing
    
    /// Determine if the provided data already exists in local folder.
    /// - Parameter data: Data to be determined.
    /// - Returns: Boolean value on whether the provided data exists in the device's image folder.
    internal func isDataSaved(data: CatData) -> Bool {
        let url = getFolderURL(folderName: imageFolderName, at: .documentDirectory)
        let dataId = data.id
        let newFileURL = url.appendingPathComponent(dataId + imageExtension)
        return fileManager.fileExists(atPath: newFileURL.path)
    }
    
    /// Get all the names of files saved in the database.
    /// - Returns: An array containing string values of all file's names saved in the database.
    internal func savedFilesList() -> [String] {
        let fetchRequest: NSFetchRequest<Favorite> = Favorite.fetchRequest()
        
        // Sort data by making the last saved data at first
        let sort = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sort]
        
        var fileNameList = [String]()
        do {
            favoriteArray = try context!.fetch(fetchRequest)
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
            try self.context!.save()
        } catch {
            debugPrint("Failed to commit changes to context's parent store: \(error)")
        }
    }
   
}
