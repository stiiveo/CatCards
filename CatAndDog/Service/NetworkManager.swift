//
//  NetworkManager.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

protocol NetworkManagerDelegate {
    func dataDidFetch()
    func errorDidOccur()
}

class NetworkManager {
    
    internal var delegate: NetworkManagerDelegate?
    internal var serializedData: [Int: CatData] = [:]
    private var dataIndex: Int = 0
    private let imageProcesser = ImageProcess()
    
    internal func performRequest(numberOfRequests: Int) {
        guard numberOfRequests > 0 else { debugPrint("Error: Number of network request equals 0 or less."); return }
        for _ in 1...numberOfRequests {
            // Create URL object using API's HTTP address string
            guard let url = URL(string: K.API.urlString) else {
                debugPrint("Error creating URL object from API's HTTP address")
                return
            }
            
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                // Error occured during process of network data fetching
                if error != nil {
                    self.delegate?.errorDidOccur()
                    debugPrint("Error fetching data with url.")
                    return
                }
                // Data is required successfully
                else {
                    if let fetchedData = data {
                        self.parseJSON(data: fetchedData)
                    }
                }
            }
            task.resume() // Start the newly-initialized task
        }
    }
    
    private func parseJSON(data: Data) {
        let jsonDecoder = JSONDecoder()
        do {
            // The raw string data of returned JSON is enclosed within a pair of square brackets
            let decodedData = try jsonDecoder.decode([JSONModel].self, from: data) // Decoded data type: [JSONModel]
            let jsonData = decodedData[0] // [JSONModel] -> JSONModel
            guard let imageURL = URL(string: jsonData.url) else {
                debugPrint("Error creating URL object from fetched url.")
                return
            }
            let newImage = imageFromURL(url: imageURL)
            let resizedImage = imageProcesser.resizeImage(newImage) // Resize image if its size is bigger than set threshold
            let newID = jsonData.id
            
            // Construct new CatData object and append to catDataArray
            let newData = CatData(id: newID, image: resizedImage)
            
            dataIndex += 1
            serializedData[dataIndex] = newData // Save newly-initialized data to memory buffer
            
            // Remove the first saved data in the array if numbers of data exceed threshold
            if serializedData.count > K.Data.maxOfCachedData {
                serializedData[dataIndex - K.Data.maxOfCachedData] = nil
            }
            delegate?.dataDidFetch() // Execute code at MainViewController
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    private func imageFromURL(url: URL) -> UIImage {
        do {
            let imageData = try Data(contentsOf: url)
            guard let image = UIImage(data: imageData) else {
                debugPrint("Error converting imageData into UIImage object.")
                return UIImage(named: "default")!
            }
            return image
        } catch {
            debugPrint("Error creating image data from url: \(error)")
        }
        return UIImage(named: "default")!
    }
}
