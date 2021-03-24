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
    
    /// Fetch new data and send it to the delegate of this class.
    /// - Parameter numberOfRequests: Number of data the delegate needs to receive.
    func performRequest(numberOfRequests: Int) {
        // Make sure the number of requests is not negative.
        let validatedNumber = numberOfRequests > 0 ? numberOfRequests : 1
        
        guard let url = URL(string: K.API.urlString) else { return }
        for _ in 0..<validatedNumber {
            fetchDataViaURL(url: url)
        }
    }
    
    /// Fetch the JSON data from the URL object and decode the data.
    /// - Parameter url: The URL object used to fetch the data from.
    private func fetchDataViaURL(url: URL) {
        var request = URLRequest(url: url)
        // Add header and API key to the request.
        request.addValue(Secrets.API.key, forHTTPHeaderField: Secrets.API.header)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Transport error occured
            if let error = error {
                // Make the delegate awared that an error occured in the data retrieving process.
                self.delegate?.networkErrorDidOccur()
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
    
    /// Decode JSON data, initialize image object, filter out and downsize the image if conditions are met, initialize a CatData object from the processed image and pass the object to the delegate.
    /// - Parameter data: JSON data to be decoded.
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
            
            // Filter out any image with the size as same as the "Grumpy Cat" image which is returned constantly from the Cat API.
            // Downsize the image if its width or height exceeds the native size(with the screen scale considered) of the device's screen in order to limit memory usage by the imageView.
            guard let filteredImage = image.filterOutGrumpyCatImage(),
                  let downsizedImage = filteredImage.downsizeTo(screenSize) else {
                // Fetch another image if the image is not valid.
                performRequest(numberOfRequests: 1)
                return
            }
            
            let id = jsonData.id
            let newData = CatData(id: id, image: downsizedImage)
            
            // Pass the newly established data to the delegate
            delegate?.dataDidFetch(data: newData, dataIndex: dataIndex)
            
            dataIndex += 1
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    /// Initialize and return an image object with the data initialized from an URL object.
    ///
    /// If the provided URL object is invalid or the initialization of the image object failed, a default image object provided with the bundle will be returned.
    /// - Parameter url: The URL object from which the data will be retrieved from.
    /// - Returns: The image object initialized by using the data retrieved from the provided URL object.
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
