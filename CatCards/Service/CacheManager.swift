//
//  CacheManager.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/3/31.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import UIKit
import CoreData

class CacheManager {
    
    static let shared = CacheManager()
    var cachedData: [CatData] = []
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private let fileManager = FileManager.default
    private var cacheFolderURL: URL {
        let cacheDirectoryURL = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let folderURL = cacheDirectoryURL.appendingPathComponent(K.Image.FolderName.cacheImage, isDirectory: true)
        return folderURL
    }
    private let jpegCompression = K.Image.jpegCompressionQuality
    private let fileExtension = "." + K.API.imageType
    
    //MARK: - Clear Cache
    
    /// Remove cached data matching the specified id name.
    /// - Parameter dataID: ID of the data to be removed.
    func clearCache(dataID: String) {
        let fetchRequest: NSFetchRequest<Cache> = Cache.fetchRequest()
        do {
            let fetchResult = try context.fetch(fetchRequest)
            // Delete specified attributes in the Cache entity
            for object in fetchResult {
                if object.name == dataID {
                    context.delete(object)
                    removeCacheFile(fileName: object.name!)
                }
            }
            saveContext()
        } catch {
            debugPrint("Error fetching result from container: \(error)")
        }
    }
    
    /// Remove cache file from local file system with specified file name.
    /// - Parameter fileName: Name of file to be removed from local cache folder.
    private func removeCacheFile(fileName: String) {
        let fileURL = cacheFolderURL.appendingPathComponent(fileName + fileExtension)
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                debugPrint("Failed to remove file `\(fileName)` from the cache folder:\n\(error.localizedDescription)")
            }
        }
    }
    
    //MARK: - Load Cache
    
    /// Return the cached data stored in app's cache directory.
    /// - Returns: Cached data stored in app's cache directory.
    func getCachedData() -> [CatData] {
        print("CacheFolderURL:", cacheFolderURL)
        
        let fetchRequest: NSFetchRequest<Cache> = Cache.fetchRequest()
        let sort = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        do {
            let dataArray = try context.fetch(fetchRequest)
            for data in dataArray {
                if let fileName = data.name {
                    loadCachedImageFile(fileName)
                }
            }
        } catch {
            debugPrint("Error fetching Favorite entity from container: \(error)")
        }
        
        return cachedData
    }
    
    /// Retrieve the stored image file matching the specified file name.
    /// - Parameter fileName: Name of the image file to be retrieved.
    private func loadCachedImageFile(_ fileName: String) {
        let imageURL = cacheFolderURL.appendingPathComponent(fileName + fileExtension)
        if let image = UIImage(contentsOfFile: imageURL.path) {
            let data = CatData(id: fileName, image: image)
            cachedData.append(data)
        }
    }
    
    //MARK: - Save Cache
    
    /// Cache the provided data to local cache directory.
    ///
    /// Note: To reduce disk I/O, only the data not cached yet will be processed and cached.
    /// - Parameter dataToCache: Data to be cached into the cache directory.
    func cache(_ dataToCache: [CatData]) {
        let idOfCachedData: [String] = cachedData.map { data in
            data.id
        }
        
        for data in dataToCache {
            if !idOfCachedData.contains(data.id) {
                let cache = Cache(context: context)
                cache.name = data.id
                cache.date = Date()
                saveContext()
                saveImageToLocal(withData: data)
            }
        }
    }
    
    /// Cache the provided data into cache directory.
    /// - Parameter data: Data to be cached.
    private func saveImageToLocal(withData data: CatData) {
        let image = data.image
        guard let imageData = image.jpegData(compressionQuality: jpegCompression) else {
            debugPrint("Failed to compress UIImage to JPEG data.")
            return
        }
        
        let fileName = data.id + fileExtension
        let fileURL = cacheFolderURL.appendingPathComponent(fileName)
        do {
            try imageData.write(to: fileURL)
        } catch {
            debugPrint("Failed to write data into cache directory: \(error.localizedDescription)")
        }
    }
    
    private func saveContext() {
        do {
            try self.context.save()
        } catch {
            debugPrint("Error saving Favorite object to container: \(error.localizedDescription)")
        }
    }
}
