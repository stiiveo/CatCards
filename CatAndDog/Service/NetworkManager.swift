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
    
    private let catUrl = "https://api.thecatapi.com/v1/images/search"
    internal var delegate: NetworkManagerDelegate?
    internal var serializedData: [Int: CatData] = [:]
    private var dataIndex: Int = 0
    
    internal func performRequest(numberOfRequests: Int) {
        for _ in 0..<numberOfRequests {
            let session = URLSession(configuration: .default)
            guard let url = URL(string: catUrl) else {
                print("Error creating URL object from API's HTTP address")
                return
            }
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.errorDidOccur()
                    print("Error fetching data with url.")
                    return
                } else {
                    if let safeData = data {
                        self.parseJSON(data: safeData)
                    }
                }
            }
            task.resume()
        }
    }
    
    private func parseJSON(data: Data) {
        let jsonDecoder = JSONDecoder()
        do {
            // The raw string data of returned JSON is enclosed within a pair of square brackets
            let decodedData = try jsonDecoder.decode([JSONModel].self, from: data) // Decoded data type: [JSONModel]
            let jsonData = decodedData[0] // [JSONModel] -> JSONModel
            guard let imageURL = URL(string: jsonData.url) else {
                print("Error creating URL object from fetched url.")
                return
            }
            let newImage = imageFromURL(url: imageURL)
            let newID = jsonData.id
            
            // Construct new CatData object and append to catDataArray
            let newData = CatData(imageURL: imageURL, id: newID, image: newImage)
            dataIndex += 1
            serializedData[dataIndex] = newData
            
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
                print("Error converting imageData into UIImage object.")
                return UIImage(named: "default")!
            }
            return image
        } catch {
            print("Error creating image data from url: \(error)")
        }
        return UIImage(named: "default")!
    }
}
