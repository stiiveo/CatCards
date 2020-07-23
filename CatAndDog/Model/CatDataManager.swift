//
//  CatDataManager.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import Foundation

struct CatDataManager {
    
    let catUrl = "https://api.thecatapi.com/v1/images/search"
    
    func performRequest() {
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: URL(string: catUrl)!) { (data, response, error) in
            if error != nil {
                print(error.debugDescription)
                return
            } else {
                if let safeData = data {
                    
                    // test
                    if let dataToString = String(data: safeData, encoding: .utf8) {
                        print(dataToString)
                    }
                    self.parseJSON(data: safeData)
                }
            }
        }
        task.resume()
    }
    
    func parseJSON(data: Data) {
        let jsonDecoder = JSONDecoder()
        do {
            let decodedData = try jsonDecoder.decode(CatData.self, from: data)
            print(decodedData.url)
        } catch {
            
        }
    }
    
}
