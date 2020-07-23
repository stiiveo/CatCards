//
//  SecondViewController.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class DogViewController: UIViewController, DogDataManagerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var refreshBtn: UIButton!
    
    var dogDataManager = DogDataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dogDataManager.delegate = self
        startFetchImage()
    }

    @IBAction func refreshBtnPressed(_ sender: UIButton) {
        startFetchImage()
    }
    
    func startFetchImage() {
        activityIndicator.startAnimating()
        dogDataManager.performRequest()
        refreshBtn.isEnabled = false
        refreshBtn.tintColor = UIColor.systemGray
    }
    
    func stopFetchImage() {
        activityIndicator.stopAnimating()
        refreshBtn.isEnabled = true
        refreshBtn.tintColor = UIColor.systemBlue
    }
    
    func dataDidFetched(url: String) {
        if let dataUrl = URL(string: url) {
            do {
                let imageData = try Data(contentsOf: dataUrl)
                DispatchQueue.main.async {
                    self.imageView.image = UIImage(data: imageData)
                    self.stopFetchImage()
                }
                
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
    
}

