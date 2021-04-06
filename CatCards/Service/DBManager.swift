//
//  DBManager.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/8/14.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit
import CoreData

protocol DBManagerDelegate {
    func savedImagesMaxReached()
}

final class DBManager {
    
    static let shared = DBManager()
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private let fileManager = FileManager.default
    private let imageFolderName = K.File.FolderName.fullImage
    private let thumbFolderName = K.File.FolderName.thumbnail
    private let cacheFolderName = K.File.FolderName.cacheImage
    private let previewImageFolderName = K.File.FolderName.activityPreview
    private var favoriteArray: [Favorite]!
    var imageFileURLs = [FilePath]()
    var delegate: DBManagerDelegate?
    private let jpegCompression = K.Data.jpegDataCompressionQuality
    private let fileExtension = K.File.fileExtension
    
    struct FilePath {
        let image: URL
        let thumbnail: URL
    }
    
    init() {
        createFoldersNeeded()
    }
    
    //MARK: - Data Loading
    
    // Load thumbnail images from local folder
    func getSavedImageFileURLs() {
        imageFileURLs.removeAll() // Clean all image file URLs in memory buffer first
        
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageFolderURL = url.appendingPathComponent(imageFolderName, isDirectory: true)
        let thumbnailFolderURL = url.appendingPathComponent(thumbFolderName, isDirectory: true)
        
        // Load image file path to cache
        let fileList = listOfSavedFileNames() // Get list of image file IDs from local database
        for fileName in fileList {
            let imageURL = imageFolderURL.appendingPathComponent(fileName + fileExtension)
            let thumbnailURL = thumbnailFolderURL.appendingPathComponent(fileName + fileExtension)
            let newFilePath = FilePath(image: imageURL, thumbnail: thumbnailURL)
            
            imageFileURLs.append(newFilePath)
        }
    }
    
    //MARK: - Data Saving
    
    func saveData(_ data: CatData, completion: K.CompletionHandler) {
        guard favoriteArray.count < K.Data.maxSavedImages else {
            delegate?.savedImagesMaxReached()
            completion(false)
            return
        }
        
        // Save data to local database.
        let newData = Favorite(context: context)
        newData.id = data.id
        newData.date = Date()
        saveContext()
        
        // Update favorite list.
        favoriteArray.append(newData)
        
        // Save image to local file system with ID as the file name.
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
        
        // Downsample the image to be used as the thumbnail image
        let downsampledImage = image.downsampleToSize(K.Image.thumbnailSize)
        
        // Convert downsampled image to JPG data and save it to local disk
        guard let jpegData = downsampledImage.jpegData(compressionQuality: jpegCompression) else {
            debugPrint("Error: Unable to convert downsampled image data to JPG data.")
            return
        }
        
        writeFileTo(folder: thumbFolderName, withData: jpegData, withName: fileName + fileExtension)
        
        // Refresh image file url cache
        getSavedImageFileURLs()
    }
    
    // Write data into app's document folder.
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
        removeFile(fromDirectory: .documentDirectory, inFolder: imageFolderName, fileName: id)
        removeFile(fromDirectory: .documentDirectory, inFolder: thumbFolderName, fileName: id)
        
        // Refresh the image file URL cache
        getSavedImageFileURLs()
        
        // Remove the cached favorite item matching the id
        for item in favoriteArray {
            if item.id == id {
                favoriteArray.removeAll{$0 == item} // Remove all elements that satisfy the predicate
            }
        }
    }
    
    func removeFile(fromDirectory directory: FileManager.SearchPathDirectory, inFolder folderName: String, fileName: String) {
        let url = getFolderURL(folderName: folderName, at: directory).appendingPathComponent(fileName + fileExtension)
        
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                debugPrint("Failed to remove file `\(fileName)` from the file system:\n\(error)")
            }
        }
    }
    
    //MARK: - Directories Creation
    
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
        let directoryURL = fileManager.urls(for: directory, in: .userDomainMask).first!
        return directoryURL.appendingPathComponent(folderName, isDirectory: true)
    }
    
    func createFoldersNeeded() {
        createDirectory(withName: imageFolderName, at: .documentDirectory)
        createDirectory(withName: thumbFolderName, at: .documentDirectory)
        createDirectory(withName: cacheFolderName, at: .cachesDirectory)
        createDirectory(withName: previewImageFolderName, at: .cachesDirectory)
    }
    
    //MARK: - Data Detection & Listing
    
    /// Determine if the provided data already exists in local folder.
    /// - Parameter data: Data to be determined.
    /// - Returns: Boolean value on whether the provided data exists in the device's image folder.
    func isDataSaved(data: CatData) -> Bool {
        let url = getFolderURL(folderName: imageFolderName, at: .documentDirectory)
        let dataId = data.id
        let newFileURL = url.appendingPathComponent(dataId + fileExtension)
        return fileManager.fileExists(atPath: newFileURL.path)
    }
    
    /// Get all the names of files saved in the database.
    /// - Returns: An array containing string values of all file's names saved in the database.
    func listOfSavedFileNames() -> [String] {
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

//MARK: - Picture Downsampling

private extension UIImage {
    /// Downsize the image to be used as the collection VC's cell image.
    ///
    /// The non–processed image could be returned if data initialization or downsizing process went wrong.
    /// - Parameter size: Size the image to be downsized to.
    /// - Returns: The downsized image.
    func downsampleToSize(_ size: CGSize) -> UIImage {
        guard let imageData = self.pngData() else {
            debugPrint("Unable to convert UIImage object to PNG data.")
            return self
        }
        
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOptions)!
        let screenScale = UIScreen.main.scale
        
        let maxDimensionInPixels = max(size.width, size.height) * screenScale
        let downsampleOptions =
            [kCGImageSourceCreateThumbnailFromImageAlways: true,
             kCGImageSourceShouldCacheImmediately: true,
             kCGImageSourceCreateThumbnailWithTransform: true,
             kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
        
        if let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) {
            return UIImage(cgImage: downsampledImage)
        } else {
            debugPrint("Error: Unable to downsample image source to thumbnail image data.")
            return self
        }
        
    }
}
