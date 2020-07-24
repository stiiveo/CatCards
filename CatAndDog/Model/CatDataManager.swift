//
//  CatDataManager.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import Foundation

protocol CatDataManagerDelegate {
    func dataDidFetch(url: String)
}

struct CatDataManager {
    
    let catUrl = "https://api.thecatapi.com/v1/images/search"
    var delegate: CatDataManagerDelegate?
    
    func performRequest() {
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: URL(string: catUrl)!) { (data, response, error) in
            if error != nil {
                print(error.debugDescription)
                return
            } else {
                if let safeData = data {
                    let processedData = self.bracketsRemover(data: safeData)
                    self.parseJSON(data: processedData)
                }
            }
        }
        task.resume()
    }
    
    private func bracketsRemover(data: Data) -> Data {
        
        // convert Data to String
        let dataToString = String(data: data, encoding: .utf8)!
        
        // convert String to Array
        var stringToArray = Array(dataToString)
        
        // remove the first and last element ('[' & ']') of the array
        stringToArray.removeFirst()
        stringToArray.removeLast()
        
        // convert Array to String
        var arrayToString: String = ""
        for character in stringToArray {
            arrayToString.append(character)
        }
        
        // convert String to Data
        let stringToData = arrayToString.data(using: .utf8)!
        
        return stringToData
    }
    
    func parseJSON(data: Data) {
        let jsonDecoder = JSONDecoder()
        do {
            let decodedData = try jsonDecoder.decode(CatData.self, from: data)
            delegate?.dataDidFetch(url: decodedData.url)
            
//            print(decodedData)
//            let catUrl = decodedData.data[0].url
//            print(catUrl)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
}
