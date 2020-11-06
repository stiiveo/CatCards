//
//  DatabaseManager.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/8/14.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit
import CoreData

class DatabaseManager {
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private let fileManager = FileManager.default
    private let documentDirectory = FileManager.SearchPathDirectory.documentDirectory
    private let imageFolderName = "Cat_Pictures"
    private let thumbFolderName = "Thumbnails"
    let imageProcess = ImageProcess()
    var favoriteArray = [Favorite]()
    static var thumbImages = [UIImage]()
    static var fullImages = [UIImage]()
    
    //MARK: - Data Loading
    
    // Load thumbnail images from local folder
    internal func loadThumbnailImages() {
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageFolderURL = url.appendingPathComponent(thumbFolderName, isDirectory: true)
        let fileList = listOfFileNames() // Get list of image files from local database
        for fileName in fileList {
            let fileURL = imageFolderURL.appendingPathComponent("\(fileName).jpg") // Create URL for each image file
            do {
                let data = try Data(contentsOf: fileURL)
                guard let image = UIImage(data: data) else { return }
                DatabaseManager.thumbImages.append(image)
            } catch {
                print("Error loading data from file system to memory buffer: \(error)")
            }
        }
    }
    
    internal func loadFullImages() {
        
    }
    
    //MARK: - Data Saving
    
    internal func saveData(_ data: CatData) {
        // Save data's image to array
        DatabaseManager.thumbImages.append(data.image)
        
        // Save data to local database
        let newData = Favorite(context: context)
        newData.id = data.id
        newData.date = Date()
        saveContext()
        
        // Update favorite list
        favoriteArray.append(newData)
        
        // Save image to local file system with ID as the file name
        saveImageToLocalSystem(data.image, data.id)
    }
    
    private func saveImageToLocalSystem(_ image: UIImage, _ fileName: String) {
        // Save full scale image
        guard let compressedJPG = image.jpegData(compressionQuality: 0.5) else { return }
        writeFileTo(folder: imageFolderName, withData: compressedJPG, withName: "\(fileName).jpg")
        
        // Save downsampled image
        let downsampledData = imageProcess.downsample(dataAt: compressedJPG)
        guard let compressedThumbnail = downsampledData.jpegData(compressionQuality: 0.5) else { return }
        writeFileTo(folder: thumbFolderName, withData: compressedThumbnail, withName: "\(fileName).jpg")
    }
    
    // Write data into application's document folder
    private func writeFileTo(folder folderName: String, withData data: Data, withName fileName: String) {
        let url = try? fileManager.url(
            for: documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        if let fileURL = url?.appendingPathComponent(folderName, isDirectory: true).appendingPathComponent(fileName) {
            do {
                try data.write(to: fileURL) // Write data to assigned URL
            } catch {
                print("Error writing data into document directory: \(error)")
            }
        }
    }
    
    //MARK: - Data Deletion
    
    // Delete specific data in database and file system
    internal func deleteData(id: String) {
        
        // Delete data from database
        let fetchRequest: NSFetchRequest<Favorite> = Favorite.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id MATCHES %@", id) // Fetch data with the matched ID value
        do {
            let fetchResult = try context.fetch(fetchRequest)
            for object in fetchResult {
                context.delete(object) // Delete every object from the fetched result
            }
            saveContext()
        } catch {
            print("Error fetching result from container: \(error)")
        }
        
        // Delete image and thumbnail files from local directory
        let fileName = "\(id).jpg"
        let imageURL = folderURL(name: imageFolderName).appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: imageURL.path) {
            do {
                try fileManager.removeItem(at: imageURL)
            } catch {
                print("Error removing image from file system: \(error)")
            }
        }
        let thumbnailURL = folderURL(name: thumbFolderName).appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: thumbnailURL.path) {
            do {
                try fileManager.removeItem(at: thumbnailURL)
            } catch {
                print("Error removing thumbnail image from file system: \(error)")
            }
        }
        
        // Update image url array
        DatabaseManager.thumbImages.removeAll()
        loadThumbnailImages()
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
        let documentURL = fileManager.urls(for: documentDirectory, in: .userDomainMask).first!
        return documentURL.appendingPathComponent(name, isDirectory: true)
    }
    
    //MARK: - Support
    
    internal func isDataSaved(data: CatData) -> Bool {
        let url = folderURL(name: imageFolderName)
        let newDataId = data.id
        let newFileURL = url.appendingPathComponent("\(newDataId).jpg")
        return fileManager.fileExists(atPath: newFileURL.path)
    }
    
    internal func listOfFileNames() -> [String] {
        let fetchRequest: NSFetchRequest<Favorite> = Favorite.fetchRequest()
        
        // Sort properties by the attribute 'date' in ascending order
        let sort = NSSortDescriptor(key: "date", ascending: true)
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
            print("Error fetching Favorite entity from container: \(error)")
        }
        return []
    }
    
    private func saveContext() {
        do {
            try self.context.save()
        } catch {
            print("Error saving Favorite object to container: \(error)")
        }
    }
   
}
