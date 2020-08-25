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
    
    var favoriteArray = [Favorite]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let fileManager = FileManager.default
    let folderName = FileManager.SearchPathDirectory.documentDirectory
    let subFolderName = "Cat_Pictures"
    static var imageArray = [UIImage]()

    func loadImages() {
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageFolderURL = url.appendingPathComponent(subFolderName, isDirectory: true)
        
        let fileList = listOfFileNames() // Get list of image files from local database
        for file in fileList {
            let fileURL = imageFolderURL.appendingPathComponent("\(file).jpg") // Create URL for each image file
            do {
                let data = try Data(contentsOf: fileURL)
                guard let image = UIImage(data: data) else { return }
                DatabaseManager.imageArray.append(image)
            } catch {
                print("Error generating data from file system: \(error)")
            }
        }
    }
    
    func listOfFileNames() -> [String] {
        let request: NSFetchRequest<Favorite> = Favorite.fetchRequest()
        
        // Sort properties by the attribute 'date' in ascending order
        let sort = NSSortDescriptor(key: "date", ascending: true)
        request.sortDescriptors = [sort]
        
        var fileNameList = [String]()
        do {
            favoriteArray = try context.fetch(request)
            for data in favoriteArray {
                if let id = data.id {
                    fileNameList.append(id)
                }
            }
            return fileNameList
        } catch {
            print("Error fetching Favorite entity from container: \(error)")
        }
        return []
    }
    
    func saveData(_ data: CatData) {
        // Save new image to array used for collection view
        DatabaseManager.imageArray.append(data.image)
        
        // Save data to local database
        let newData = Favorite(context: context)
        newData.id = data.id
        newData.date = Date()
        saveContext()
        
        // Save image to local file system with ID as the file name
        saveImage(data.image, data.id)
    }
    
    func saveImage(_ image: UIImage, _ fileName: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        createFileToURL(withData: imageData, withName: "\(fileName).jpg")
    }
    
    // Save image to 'cat_pictures' in application's document folder
    func createFileToURL(withData data: Data, withName fileName: String) {
        let url = try? fileManager.url(
            for: folderName,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        if let fileURL = url?.appendingPathComponent(subFolderName, isDirectory: true).appendingPathComponent(fileName) {
            do {
                try data.write(to: fileURL) // Write data to assigned URL
            } catch {
                print("error: \(error)")
            }
        }
    }
    
    // Create new directory in application document directory
    func createDirectory() {
        let urls = fileManager.urls(for: folderName, in: .userDomainMask)
        guard let documentURL = urls.first else { return }
        let folderURL = documentURL.appendingPathComponent(subFolderName, isDirectory: true)
        
        guard !fileManager.fileExists(atPath: folderURL.path) else { return } // Determine if the folder already exists
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating new directory: \(error)")
        }
    }
    
    func saveContext() {
        do {
            try self.context.save()
        } catch {
            print("Error saving Favorite object to container: \(error)")
        }
    }
   
}
