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
        return cacheDirectoryURL.appendingPathComponent(K.Image.FolderName.cacheImage, isDirectory: true)
    }
    private let jpegCompression = K.Image.jpegCompressionQuality
    private let fileExtension = "." + K.API.imageType
    
    //MARK: - Clear Cache
    func clearCache(dataID: String) {
        // Local database
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
    func getCacheData() -> [CatData] {
        // Local database
        let fetchRequest: NSFetchRequest<Cache> = Cache.fetchRequest()
        let sort = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        // Get all the saved file names
        var fileList: [String] = []
        do {
            let dataArray = try context.fetch(fetchRequest)
            for data in dataArray {
                if let id = data.name {
                    fileList.append(id)
                }
            }
        } catch {
            debugPrint("Error fetching Favorite entity from container: \(error)")
        }
        
        // Local images using the file list
        loadImageFromLocal(withFileList: fileList)
        return cachedData
    }
    
    private func loadImageFromLocal(withFileList fileList: [String]) {
        for fileName in fileList {
            let imageURL = cacheFolderURL.appendingPathComponent(fileName + fileExtension)
            if let image = UIImage(contentsOfFile: imageURL.path) {
                let data = CatData(id: fileName, image: image)
                cachedData.append(data)
            }
        }
    }
    
    //MARK: - Save Cache
    func cache(_ dataToCache: [CatData]) {
        // Filter out data that's already cached.
        var filteredData: [CatData] = []
        let idOfCachedData: [String] = cachedData.map { data in
            data.id
        }
        
        let eDTC = dataToCache.enumerated()
        for (index, data) in eDTC {
            if !idOfCachedData.contains(data.id) {
                filteredData.append(dataToCache[index])
            }
        }
        
        // Local database
        for data in filteredData {
            let cache = Cache(context: context)
            cache.name = data.id
            cache.date = Date()
            saveContext()
        }
        
        // Local file system
        saveImageToLocal(withData: filteredData)
    }
    
    private func saveImageToLocal(withData data: [CatData]) {
        for d in data {
            let image = d.image
            guard let imageData = image.jpegData(compressionQuality: jpegCompression) else {
                debugPrint("Failed to compress UIImage to JPEG data.")
                return
            }
            
            let fileName = d.id + fileExtension
            let fileURL = cacheFolderURL.appendingPathComponent(fileName)
            do {
                try imageData.write(to: fileURL)
            } catch {
                debugPrint("Failed to write data into cache directory: \(error.localizedDescription)")
            }
            
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
