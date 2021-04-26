//
//  APIManager.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

enum APIError {
    case server
}

protocol APIManagerDelegate {
    func dataDidFetch(data: CatData, dataIndex: Int)
    func APIErrorDidOccur(error: APIError)
}

final class APIManager {
    
    var delegate: APIManagerDelegate?
    static let shared = APIManager()
    var dataIndex: Int = 0
    private let urlString = K.API.urlString
    
    /// Fetch the data from the URL object and decode the data.
    /// - Parameter url: The URL object used to fetch the data from.
    func fetchData() {
        // Retry API request if URL init failed.
        guard let url = URL(string: urlString) else {
            debugPrint("Failed to initialize an valid URL object using the provided url string: \(urlString).")
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            // Transport error occured
            if let error = error {
                // Make the delegate awared that an error occured in the data retrieving process.
                self.delegate?.APIErrorDidOccur(error: .server)
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
                self.sendProcessedDataToDelegate(usingData: fetchedData)
            } else {
                self.fetchData()
                debugPrint("Fetched data is invalid.")
            }
        }.resume() // Start the newly-initialized task
    }
    
    private func sendProcessedDataToDelegate(usingData data: Data) {
        if let parsedData = parsedJSONData(from: data),
           let catData = dataCreateFrom(parsedData: parsedData) {
            delegate?.dataDidFetch(data: catData, dataIndex: self.dataIndex)
            dataIndex += 1
        } else {
            self.fetchData()
            debugPrint("Parsed data is invalid.")
        }
    }
    
    /// Return parsed JSON data.
    /// - Parameter data: The raw JSON data which is usually downloaded from an API service.
    /// - Returns: Parsed JSON data.
    private func parsedJSONData(from data: Data) -> JSONModel? {
        let jsonDecoder = JSONDecoder()
        do {
            let decodedData = try jsonDecoder.decode([JSONModel].self, from: data) // Decoded data type: [JSONModel]
            guard !decodedData.isEmpty else {
                debugPrint("Decoded JSON data is invalid.")
                return nil
            }
            
            let jsonData = decodedData[0] // Type [JSONModel] -> JSONModel
            return jsonData
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    /// Init and return a CatData object from the parsed data.
    ///
    /// An invalid value could be returned if an image object could not be initiated from the provided data.
    /// - Parameter parsedData: A parsed data.
    /// - Returns: A CatData object created using the provided parsed data.
    private func dataCreateFrom(parsedData: JSONModel) -> CatData? {
        guard let imageURL = URL(string: parsedData.url) else { return nil }
        
        let image = imageFromURL(url: imageURL)
        let screenSize = UIScreen.main.nativeBounds.size
        
        if let filteredImage = image.filteredBySpecifiedSize {
            let downsizedImage = filteredImage.scaledToAspectFit(size: screenSize)
            return CatData(id: parsedData.id, image: downsizedImage)
        } else {
            return nil
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

