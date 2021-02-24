//
//  ImageProcessor.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/11/6.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit
import ImageIO

class ImageProcessor {
    
    let screenScale = UIScreen.main.scale
    var cellSize = CGSize()
    let screenSize = UIScreen.main.bounds.size
    
    internal func processImage(_ image: UIImage) -> UIImage? {
        let imageSize = image.size
        let maxSize = K.Image.maxImageSize
        
        // Filter any image matching the grumpy cat image's size
        if imageSize == K.Image.grumpyCatImageSize {
            return nil
        }
        
        // Continue the resizing process if image's height and width is bigger than the resizing threshold, return original image otherwise.
        guard imageSize.height > maxSize.height && imageSize.width > maxSize.width else { return image
        }
        
        let widthDiff  = maxSize.width  / imageSize.width
        let heightDiff = maxSize.height / imageSize.height
        
        // Figure out image's orientation and use that to form a target rectangle
        var newSize: CGSize
        if widthDiff > heightDiff {
            newSize = CGSize(width: imageSize.width * heightDiff, height: imageSize.height * heightDiff)
        } else {
            newSize = CGSize(width: imageSize.width * widthDiff,  height: imageSize.height * widthDiff)
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
        
        let maxDimensionInPixels = max(cellSize.width, cellSize.height) * screenScale
        let downsampleOptions =
            [kCGImageSourceCreateThumbnailFromImageAlways: true,
             kCGImageSourceShouldCacheImmediately: true,
             kCGImageSourceCreateThumbnailWithTransform: true,
             kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
        
        if let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) {
            return UIImage(cgImage: downsampledImage)
        } else {
            debugPrint("Error: Unable to downsample image source to thumbnail image data.")
            return UIImage(data: data)!
        }
        
    }
    
}
