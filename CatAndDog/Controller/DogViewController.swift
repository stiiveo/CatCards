//
//  DogViewController.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class DogViewController: UIViewController, DogDataManagerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var refreshBtn: UIButton!
    
    var dogDataManager = DogDataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // this View Controller is the delegate of the protocol DogDataManagerDelegate inside DogDataManager
        dogDataManager.delegate = self
        
        // user will see the first random pic without having to press refresh button
        startFetchImage()
    }

    @IBAction func refreshBtnPressed(_ sender: UIButton) {
        startFetchImage()
    }
    
    func startFetchImage() {
        dogDataManager.performDogRequest()
        indicator.startAnimating()
        
        // disable refresh button while image is being downloaded
        refreshBtn.isEnabled = false
        refreshBtn.tintColor = UIColor.systemGray
    }
    
    func stopFetchImage() {
        indicator.stopAnimating()
        
        // re-enable refresh button
        refreshBtn.isEnabled = true
        refreshBtn.tintColor = UIColor.systemBlue
    }
    
    // this method will be executed once JSON data in DataManager is parsed successfully
    func dataDidFetch(url: String) {
        if let dataUrl = URL(string: url) {
            do {
                let imageData = try Data(contentsOf: dataUrl)
                DispatchQueue.main.async {
                    // present downloaded picture on the imageView
                    self.imageView.image = UIImage(data: imageData)
                    self.stopFetchImage()
                }
                
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    @IBAction func PanView(_ sender: UIPanGestureRecognizer) {
        print("test")
    }
    
}

