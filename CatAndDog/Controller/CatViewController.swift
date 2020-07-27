//
//  CatViewController.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class CatViewController: UIViewController, CatDataManagerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var refreshButton: UIButton!

    var catDataManager = CatDataManager()
    var arrayIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        catDataManager.delegate = self
        
        // download 5 new images into imageArray
        startFetchImage(initialRequest: true)
    }
    
    private func startFetchImage(initialRequest: Bool) {
        // first time loading image data
        if initialRequest {
            refreshButton.isEnabled = false
            refreshButton.tintColor = UIColor.systemGray
            indicator.startAnimating()
            catDataManager.performRequest(numberOfRequest: 5)
        } else {
            catDataManager.performRequest(numberOfRequest: 1)
            
        }
        
    }

    @IBAction func refreshBtnPressed(_ sender: UIButton) {
        startFetchImage(initialRequest: false)
        
        // make sure there's new image in imageArray ready to be loaded
        if catDataManager.catImages.imageArray.count > 1 {
            arrayIndex += 1
            imageView.image = catDataManager.catImages.imageArray[arrayIndex]
            catDataManager.catImages.imageArray.removeFirst()
            arrayIndex = 0
        }
        
    }

    func dataDidFetch() {
        // update image and UI components
        let imageArray = catDataManager.catImages.imageArray
        DispatchQueue.main.async {
            
            // update image
            guard let firstDownloadedImage = imageArray.first else { print("Fail to get image"); return }
            self.imageView.image = firstDownloadedImage
            
            // update UI components
            self.indicator.stopAnimating()
            self.refreshButton.isEnabled = true
            self.refreshButton.tintColor = UIColor.systemBlue
        }
    }
    
}

