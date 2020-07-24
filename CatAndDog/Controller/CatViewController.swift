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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        catDataManager.delegate = self
        startFetchImage()
    }

    @IBAction func refreshBtnPressed(_ sender: UIButton) {
        startFetchImage()
    }
    
    private func startFetchImage() {
        refreshButton.isEnabled = false
        refreshButton.tintColor = UIColor.systemGray
        indicator.startAnimating()
        catDataManager.performRequest()
    }
    
    func dataDidFetch(url: String) {
        do {
            let imageData = try Data(contentsOf: URL(string: url)!)
            if let image = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    self.imageView.image = image
                    self.indicator.stopAnimating()
                    self.refreshButton.isEnabled = true
                    self.refreshButton.tintColor = UIColor.systemBlue
                }
                
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        
    }
    
}

