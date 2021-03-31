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
    var cacheData: [CatData] = []
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private let fileManager = FileManager.default
    private var cacheFolderURL: URL {
        let cacheDirectoryURL = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return cacheDirectoryURL.appendingPathComponent(K.Image.FolderName.cacheImage, isDirectory: true)
    }
    private let jpegCompression = K.Image.jpegCompressionQuality
    private let fileExtension = "." + K.API.imageType
    
    //MARK: - Clear Cache
    func delete() {
        // Local database
        let fetchRequest: NSFetchRequest<Cache> = Cache.fetchRequest()
        do {
            let fetchResult = try context.fetch(fetchRequest)
            // Delete all attributes in the Cache entity
            for object in fetchResult {
                context.delete(object)
                // Remove cache file from local file system
                removeCacheFile(fileName: object.name!)
            }
            saveContext()
        } catch {
            debugPrint("Error fetching result from container: \(error)")
        }
    }
    
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
    func readData() {
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
    }
    
    private func loadImageFromLocal(withFileList fileList: [String]) {
        for fileName in fileList {
            let imageURL = cacheFolderURL.appendingPathComponent(fileName + fileExtension)
            if let image = UIImage(contentsOfFile: imageURL.path) {
                let data = CatData(id: fileName, image: image)
                cacheData.append(data)
            }
        }
    }
    
    //MARK: - Save Cache
    func save(_ dataToSave: [CatData]) {
        cacheData = dataToSave
        
        // Local database
        for data in cacheData {
            let cache = Cache(context: context)
            cache.name = data.id
            cache.date = Date()
            saveContext()
        }
        
        // Local file system
        saveImageToLocal()
    }
    
    private func saveImageToLocal() {
        for data in cacheData {
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
    }
    
    private func saveContext() {
        do {
            try self.context.save()
        } catch {
            debugPrint("Error saving Favorite object to container: \(error.localizedDescription)")
        }
    }
}
