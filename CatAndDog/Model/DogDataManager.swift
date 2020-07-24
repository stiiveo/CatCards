//
//  DogDataManager.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/23.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import Foundation

protocol DogDataManagerDelegate {
    func dataDidFetch(url: String)
}

struct DogDataManager {
    
    let dogUrl = "https://dog.ceo/api/breeds/image/random"
    var delegate: DogDataManagerDelegate?
    
    func performRequest() {
        let url = URL(string: dogUrl)
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: url!) { (data, response, error) in
            if error != nil {
                debugPrint(error.debugDescription)
                return
            } else {
                if let safeData = data {
                    self.parseJSON(data: safeData)
                }
            }
        }
        task.resume()
    }
    
    func parseJSON(data: Data) {
        let jsonDecoder = JSONDecoder()
        do {
            let decodedData = try jsonDecoder.decode(DogData.self, from: data)
            // extract url data from received JSON data
            let url = decodedData.message
            // send url to the delegate of protocol DogDataManagerDelegate
            self.delegate?.dataDidFetch(url: url)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
}
