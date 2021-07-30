//
//  CacheManager.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/3/31.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import UIKit
import CoreData

final class CacheManager {
    static let shared = CacheManager()
    private var context: NSManagedObjectContext!
    private let fileManager = FileManager.default
    private var cacheImagesFolderUrl: URL!
    private let imageFileExtension = K.File.imageFileExtension
    
    private init?() {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else {
            return nil
        }
        self.context = context
        
        do {
            let cacheRootUrl = try fileManager.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            self.cacheImagesFolderUrl = cacheRootUrl.appendingPathComponent(K.File.FolderName.cacheImage, isDirectory: true)
        } catch {
            debugPrint("Failed to locate nor create standard system Caches directory: \(error)")
            return nil
        }
    }
    
    // MARK: - Clear Cache
    
    /// Remove cached data matching the specified id name.
    /// - Parameter dataName: Name attribute of the data to be removed.
    /// - Throws: One of the cache errors could be thrown.
    func clearCache(dataId dataName: String) throws {
        let fetchRequest: NSFetchRequest<Cache> = Cache.fetchRequest()
        var fetchResult: [Cache] = []
        do {
            fetchResult = try context.fetch(fetchRequest)
        } catch {
            debugPrint("Error fetching result from container: \(error)")
        }
        // Remove specified attributes in the Cache entity
        for cacheObject in fetchResult {
            if cacheObject.name == dataName {
                context?.delete(cacheObject)
                if cacheObject.isDeleted {
                    if let fileId = cacheObject.name {
                        // Remove cached file matching the specified file name.
                        try removeCacheFile(fileName: fileId, fileType: imageFileExtension)
                    }
                } else {
                    debugPrint("Unknown error: The specified attribute '\(dataName)' cannot be removed from Cache database.")
                }
            }
        }
        try saveContext()
    }
    
    /// Remove cache file from local file system with specified file name.
    /// - Parameter fileName: Name of file to be removed from local cache folder.
    /// - Throws: An error could be thrown if the specified file cannot be found in the cache directory.
    private func removeCacheFile(fileName: String, fileType: String) throws {
        guard let fileURL =
                cacheImagesFolderUrl?
                .appendingPathComponent(fileName)
                .appendingPathExtension(fileType) else {
            debugPrint("Failed to remove cache file \(fileName) since the valid url of cache images folder cannot be obtained.")
            return
        }
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        } else {
            throw CacheError.fileNotFound(fileName: fileName)
        }
    }
    
    // MARK: - Load Cache
    
    /// Return the cached data stored in app's cache directory.
    /// - Returns: Cached data stored in app's cache directory.
    func fetchCachedData() -> [CatData] {
        // Fetch the collection of cached objects sorted by the date each item was saved with in ascending order.
        let fetchRequest: NSFetchRequest<Cache> = Cache.fetchRequest()
        let sort = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sort]
        var objects: [Cache] = []
        do {
            objects = try context.fetch(fetchRequest)
        } catch {
            debugPrint("Failed to fetch cached objects from persistent container: \(error)")
        }
        
        // Get the image file from the cache images folder.
        var cachedData: [CatData] = []
        for object in objects {
            let dataKey = object.name!
            if let imageUrl = urlOfImageFile(fileName: dataKey, fileExtension: imageFileExtension) {
                guard let image = UIImage(contentsOfFile: imageUrl.path) else {
                    debugPrint("Failed to initialize an image object with the contents of file located at \(imageUrl.path)")
                    continue
                }
                let data = CatData(id: dataKey, image: image)
                cachedData.append(data)
            }
        }
        
        return cachedData
    }
    
    // MARK: - Save Cache
    
    /// Cache the data's id string value and the date it is saved.
    /// The image data is also saved into the cache image folder with CatData's id as its file name.
    ///
    /// Note: To reduce disk I/O, only the data not cached yet will be processed and cached.
    /// - Parameter dataToCache: Data to be cached into the cache directory.
    /// - Throws: This attempt could fail and return one or more cases of CacheError.
    func cacheData(_ dataToCache: [CatData]) throws {
        let cachedData = self.fetchCachedData()
        let cachedDataIdList: [String] = cachedData.map { $0.id }
        for data in dataToCache {
            if !cachedDataIdList.contains(data.id) {
                let cacheItem = Cache(context: context)
                cacheItem.name = data.id
                cacheItem.date = Date()
                do {
                    try saveContext()
                } catch {
                    throw CacheError.failedToCommitChangesToPersistentContainer
                }
                
                let fileName = data.id
                try cacheImage(data.image, fileName: fileName, extensionName: imageFileExtension)
            }
        }
    }
    
    /// Convert the specified image into a jpeg format data and save it in the cache images folder.
    /// - Parameter image: Image data to be saved.
    /// - Parameter fileName: File name with which the image file to be saved.
    /// - Throws: This attempt could fail and return one or more cases of CacheError.
    func cacheImage(_ image: UIImage, fileName: String, extensionName: String) throws {
        guard let imageData = image.jpegData(compressionQuality: K.Data.jpegDataCompressionQuality) else {
            throw CacheError.failedToConvertImageToJpegData(image: image)
        }
        
        if let fileURL = cacheImagesFolderUrl?.appendingPathComponent(fileName).appendingPathExtension(extensionName) {
            do {
                try imageData.write(to: fileURL)
            } catch {
                throw CacheError.failedToWriteImageFile(url: fileURL)
            }
        } else {
            print("Unable to create valid file URL.")
        }
    }
    
    /// Attempts to commit unsaved changes to cache objects to the persistent container.
    /// - Throws: This attempt could fail and return one of the cases of CacheError.
    private func saveContext() throws {
        guard self.context.hasChanges else { return }
        do {
            try self.context?.save()
        } catch {
            throw CacheError.failedToCommitChangesToPersistentContainer
        }
    }
    
    // MARK: - Support
    
    /// Return the URL of the image file saved in cache image folder.
    /// - Parameter fileName: The file name of the image file.
    /// - Throws: An error could be thrown if the file with provided file name does not exist.
    /// - Returns: The URL of the image file saved in cache image folder.
    func urlOfImageFile(fileName: String, fileExtension: String) -> URL? {
        return cacheImagesFolderUrl?.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
    }
}

enum CacheError: Error {
    case failedToCommitChangesToPersistentContainer
    case failedToConvertImageToJpegData(image: UIImage)
    case failedToWriteImageFile(url: URL)
    case fileNotFound(fileName: String)
}
