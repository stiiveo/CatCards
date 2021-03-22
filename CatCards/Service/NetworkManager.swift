//
//  NetworkManager.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

protocol NetworkManagerDelegate {
    func dataDidFetch(data: CatData, dataIndex: Int)
    func networkErrorDidOccur()
}

class NetworkManager {
    
    var delegate: NetworkManagerDelegate?
    private var dataIndex: Int = 0
    
    func performRequest(numberOfRequests: Int) {
        // Make sure the number of requests is not negative.
        let validatedNumber = numberOfRequests > 0 ? numberOfRequests : 1
        for _ in 1...validatedNumber {
            guard let url = URL(string: K.API.urlString) else { return }
            var request = URLRequest(url: url)
            request.addValue(Secrets.API.key, forHTTPHeaderField: Secrets.API.header)
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                // Transport error occured
                if let error = error {
                    self.delegate?.networkErrorDidOccur() // Alert the main VC that an error occured in the data retrieving process.
                    debugPrint("Error sending URLSession request to the server or getting response from the server. Error: \(error)")
                    return
                }
                
                // Server-side error occured
                let response = response as! HTTPURLResponse
                let status = response.statusCode
                guard (200...299).contains(status) else {
                    debugPrint("Server-side error response is received from API's server. (HTTP status code: \(status))")
                    return
                }
                
                // Data is retrieved successfully
                if let fetchedData = data {
                    self.parseJSON(data: fetchedData)
                }
            }.resume() // Start the newly-initialized task
        }
    }
    
    private func parseJSON(data: Data) {
        let jsonDecoder = JSONDecoder()
        do {
            let decodedData = try jsonDecoder.decode([JSONModel].self, from: data) // Decoded data type: [JSONModel]
            guard !decodedData.isEmpty else {
                debugPrint("Decoded JSON data is invalid.")
                return
            }
            
            let jsonData = decodedData[0] // Type [JSONModel] -> JSONModel
            guard let imageURL = URL(string: jsonData.url) else { return }
            let image = imageFromURL(url: imageURL)
            let screenSize = UIScreen.main.nativeBounds.size
            let id = jsonData.id
            
            guard let filteredImage = image.filterOutGrumpyCatImage(),
                  let downsizedImage = filteredImage.downsizeTo(screenSize) else {
                // Fetch another image if the image is not valid.
                performRequest(numberOfRequests: 1)
                return
            }
            
            let newData = CatData(id: id, image: downsizedImage)
            // Pass newly established data to the delegate
            delegate?.dataDidFetch(data: newData, dataIndex: dataIndex)
            
            dataIndex += 1
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    private func imageFromURL(url: URL) -> UIImage {
        do {
            let imageData = try Data(contentsOf: url)
            if let image = UIImage(data: imageData) {
                return image
            }
        } catch {
            debugPrint("Failed to initialize new image data from fetched URL object. Error: \(error)")
        }
        return K.Image.defaultImage // Return default image if any error occured.
    }
}

extension UIImage {
    /// Filter out any image matching the grumpy cat image's size
    func filterOutGrumpyCatImage() -> UIImage? {
        guard self.size != K.Image.grumpyCatImageSize else {
            return nil
        }
        return self
    }
    
    /// Resize the image to be within the designated bounds. Original input image will be returned if its size is within the designated bounds.
    func downsizeTo(_ bounds: CGSize) -> UIImage? {
        let imageSize = self.size
        
        // Return the original image if its height or width is not bigger than the designated bounds.
        guard imageSize.height > bounds.height || imageSize.width > bounds.width else {
            return self
        }
        
        // The new image size's width and height is limited to the device's native resolution
        let widthDiff = imageSize.width / bounds.width
        let heightDiff = imageSize.height / bounds.height
        let newImageSize = CGSize(
            width: imageSize.width / max(widthDiff, heightDiff),
            height: imageSize.height / max(widthDiff, heightDiff)
        )
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newImageSize.width, height: newImageSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newImageSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
