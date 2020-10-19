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
    
    let catUrl = "https://api.thecatapi.com/v1/images/search"
    var delegate: NetworkManagerDelegate?
    var serializedData: [Int: CatData] = [:]
    var dataIndex: Int = 0
    
    func performRequest(imageDownloadNumber: Int) {
        for _ in 0..<imageDownloadNumber {
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
                        let processedData = self.removeBrecketsInJSON(data: safeData)
                        self.parseJSON(data: processedData)
                    }
                }
            }
            task.resume()
        }
    }
    
    private func removeBrecketsInJSON(data: Data) -> Data {
        let dataToString = String(data: data, encoding: .utf8)! // convert Data to String
        var stringToArray = Array(dataToString) // convert String to Array
        
        // remove the first and last element ('[' & ']') of the array
        stringToArray.removeFirst()
        stringToArray.removeLast()
        
        // convert Array to String
        var arrayToString: String = ""
        for character in stringToArray {
            arrayToString.append(character)
        }
        let stringToData = arrayToString.data(using: .utf8)! // convert String to Data
        return stringToData
    }
    
    private func parseJSON(data: Data) {
        let jsonDecoder = JSONDecoder()
        do {
            let decodedData = try jsonDecoder.decode(JSONModel.self, from: data)
            guard let imageURL = URL(string: decodedData.url) else {
                print("Error creating URL object from fetched url.")
                return
            }
            let newImage = imageFromURL(url: imageURL)
            let newID = decodedData.id
            
            // Construct new CatData object and append to catDataArray
            let newData = CatData(imageURL: imageURL, id: newID, image: newImage)
            dataIndex += 1
            serializedData[dataIndex] = newData
            
            // Remove the first saved data in the array if numbers of data exceed threshold
            if serializedData.count > K.Data.maxDataNumberStored {
                serializedData[dataIndex - K.Data.maxDataNumberStored] = nil
            }
            // Execute code at MainViewController
            delegate?.dataDidFetch()
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
