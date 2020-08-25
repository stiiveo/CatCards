//
//  FavoriteDataManager.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/8/14.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit
import CoreData

class FavoriteDataManager {
    
    var favoriteArray = [Favorite]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let fileManager = FileManager.default
    let folderName = FileManager.SearchPathDirectory.documentDirectory
    let subFolderName = "Cat_Pictures"
    static var imageArray = [UIImage]()

    func loadImages() {
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageFolderURL = url.appendingPathComponent(subFolderName, isDirectory: true)
        do {
            let imagesURLs = try fileManager.contentsOfDirectory(at: imageFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for imageURL in imagesURLs {
                let imageData = try Data(contentsOf: imageURL)
                if let image = UIImage(data: imageData) {
                    FavoriteDataManager.imageArray.append(image)
                }
            }
        } catch {
            print("Error getting URLs of the images in file system: \(error)")
        }
        
    }
    
//    func loadData() {
//        let request: NSFetchRequest<Favorite> = Favorite.fetchRequest()
//        do {
//            favoriteArray = try context.fetch(request)
//        } catch {
//            print("Error fetching Favorite entity from container: \(error)")
//        }
//    }
    
    func saveData(_ data: CatData) {
        // Save new image to array used for collection view
        FavoriteDataManager.imageArray.append(data.image)
        
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
        createDirectory(withFolderName: subFolderName)
        if let fileURL = url?.appendingPathComponent(subFolderName, isDirectory: true).appendingPathComponent(fileName) {
            do {
                try data.write(to: fileURL) // Write data to assigned URL
            } catch {
                print("error: \(error)")
            }
        }
    }
    
    // Create new directory in application document directory
    func createDirectory(withFolderName dest: String) {
        let urls = fileManager.urls(for: folderName, in: .userDomainMask)
        if let documentURL = urls.last {
            do {
                let newURL = documentURL.appendingPathComponent(dest, isDirectory: true)
                try fileManager.createDirectory(at: newURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating new directory: \(error)")
            }
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
