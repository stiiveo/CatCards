//
//  FavoriteDataManager.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/8/14.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class FavoriteDataManager {
    
//    static var favoriteArray = [Favorite]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let fileManager = FileManager.default

    func saveData(image: UIImage, dataID: String) {
        let newData = Favorite(context: context)
        newData.id = dataID
        newData.date = Date()
        saveContext()
        saveImage(image: image)
    }
    
    func saveImage(image: UIImage) {
        
    }
    
    func saveContext() {
        do {
            try self.context.save()
        } catch {
            print("Error saving Favorite object to container: \(error)")
        }
    }
   
}
