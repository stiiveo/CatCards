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
    
    internal var delegate: NetworkManagerDelegate?
    private var dataIndex: Int = 0
    private let imageProcesser = ImageProcessor()
    
    internal func performRequest(numberOfRequests: Int) {
        guard numberOfRequests > 0 else {
            debugPrint("Error: Number of network request equals 0 or less.")
            return
        }
        for _ in 1...numberOfRequests {
            // Create URL object
            guard let url = URL(string: K.API.urlString) else {
                debugPrint("Error initiating an URL object from API's HTTP address string.")
                return
            }
            
            // Pass in HTTP request header
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
                    debugPrint("Server-side error response is received from API's server. (HTTP status code: \(status)")
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
            // The returned json data is wrapped in an array
            let decodedData = try jsonDecoder.decode([JSONModel].self, from: data) // Decoded data type: [JSONModel]
            let jsonData = decodedData[0] // [JSONModel] -> JSONModel
            guard let imageURL = URL(string: jsonData.url) else {
                debugPrint("Error creating image URL object from decoded json data.")
                return
            }
            let id = jsonData.id
            let image = imageFromURL(url: imageURL)
            guard let processedImage = imageProcesser.processImage(image) else {
                // Call another fetch request if the processed image is not valid
                performRequest(numberOfRequests: 1)
                return
            }
            
            let newData = CatData(id: id, image: processedImage)
            // Transfer newly fetched data to the delegate
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
            debugPrint("Error initializing image data from image URL object. Error: \(error)")
        }
        return K.Image.defaultImage // Return default image if any error occured.
    }
}
