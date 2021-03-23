//
//  CatImageUrl.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import Foundation

struct JSONModel: Decodable {
    let id: String // Unique ID string assigned to the object.
    let url: String // HTTP address of the image.
}
