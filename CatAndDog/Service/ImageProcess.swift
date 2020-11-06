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
    
    let screenSize = UIScreen.main.bounds.size
    var cellSize = CGSize()
    var scale = CGFloat()
    
    internal func resizeImage(_ image: UIImage) -> UIImage {
        let imageSize = image.size
        let maxSize = CGSize(width: screenSize.width * 1.5, height: screenSize.height * 1.5)
        
        // Return original image if its height or width is smaller than threshold
        guard imageSize.height > maxSize.height && imageSize.width > maxSize.width else { return image }
        
        let widthRatio  = maxSize.width  / imageSize.width
        let heightRatio = maxSize.height / imageSize.height
        
        // Figure out image's orientation and use that to form new rectangle
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: imageSize.width * heightRatio, height: imageSize.height * heightRatio)
        } else {
            newSize = CGSize(width: imageSize.width * widthRatio,  height: imageSize.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    internal func downsample(dataAt data: Data) -> UIImage {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions)!
        
        let maxDimensionInPixels = max(cellSize.width, cellSize.height) * scale
        let downsampleOptions =
            [kCGImageSourceCreateThumbnailFromImageAlways: true,
             kCGImageSourceShouldCacheImmediately: true,
             kCGImageSourceCreateThumbnailWithTransform: true,
             kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
        
        let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions)!
        return UIImage(cgImage: downsampledImage)
    }
    
}
