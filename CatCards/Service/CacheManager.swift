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
    private var imageFolderURL: URL {
        let cacheDirectoryURL = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let folderURL = cacheDirectoryURL.appendingPathComponent(K.Image.FolderName.cacheImage, isDirectory: true)
        return folderURL
    }
    private let jpegCompression = K.Image.jpegCompressionQuality
    private let fileExtension = K.Image.fileExtension
    
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
        let fileURL = imageFolderURL.appendingPathComponent(fileName + fileExtension)
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
        print("imageFolderURL:", imageFolderURL)
        
        let fetchRequest: NSFetchRequest<Cache> = Cache.fetchRequest()
        let sort = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        do {
            let dataArray = try context.fetch(fetchRequest)
            for data in dataArray {
                if let dataKey = data.name {
                    loadCachedImageFile(dataKey + fileExtension)
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
        let imageURL = imageFolderURL.appendingPathComponent(fileName)
        if let image = UIImage(contentsOfFile: imageURL.path) {
            let data = CatData(id: fileName, image: image)
            cachedData.append(data)
        }
    }
    
    //MARK: - Save Cache
    
    /// Cache the CatData's id string value and the date it is saved.
    /// The image data will also be saved into the cache image folder.
    ///
    /// Note: To reduce disk I/O, only the data not cached yet will be processed and cached.
    /// - Parameter dataToCache: Data to be cached into the cache directory.
    func cacheData(_ dataToCache: [CatData]) {
        let idOfCachedData: [String] = cachedData.map { data in
            data.id
        }
        
        for data in dataToCache {
            if !idOfCachedData.contains(data.id) {
                let cache = Cache(context: context)
                cache.name = data.id
                cache.date = Date()
                saveContext()
                
                let fileName = data.id + fileExtension
                cacheImage(data.image, withFileName: fileName)
            }
        }
    }
    
    /// Cache the image data into the cache image folder.
    /// - Parameter image: Image data to be cached.
    /// - Parameter fileName: File name with which the image file to be created.
    func cacheImage(_ image: UIImage, withFileName fileName: String) {
        guard let imageData = image.jpegData(compressionQuality: jpegCompression) else {
            debugPrint("Failed to compress UIImage to JPEG data.")
            return
        }
        
        let fileURL = imageFolderURL.appendingPathComponent(fileName)
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
    
    //MARK: - Support
    
    /// Return the URL of the image file saved in cache image folder.
    /// - Parameter fileName: The file name of the image file.
    /// - Throws: An error could be thrown if the file with provided file name does not exist.
    /// - Returns: The URL of the image file saved in cache image folder.
    func urlOfImageFile(fileName: String) throws -> URL {
        let fileURL = imageFolderURL.appendingPathComponent(fileName)
        let fileExists = fileManager.fileExists(atPath: fileURL.relativePath)
        
        guard fileExists else {
            throw CacheError.fileNotFound
        }
        return fileURL
    }
}

enum CacheError: Error {
    case fileNotFound
}
