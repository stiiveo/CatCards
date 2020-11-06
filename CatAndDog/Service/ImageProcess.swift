//
//  ImageProcess.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/11/6.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit
import ImageIO

class ImageProcess {
    
    var size = CGSize()
    var scale = CGFloat()
    
    internal func downsample(dataAt data: Data) -> UIImage {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
//        let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions)!
        let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions)!
        
        let maxDimensionInPixels = max(size.width, size.height) * scale
        let downsampleOptions =
            [kCGImageSourceCreateThumbnailFromImageAlways: true,
             kCGImageSourceShouldCacheImmediately: true,
             kCGImageSourceCreateThumbnailWithTransform: true,
             kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
        
        let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions)!
        return UIImage(cgImage: downsampledImage)
    }
    
}
