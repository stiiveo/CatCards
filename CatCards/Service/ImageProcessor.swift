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
    let screenSize = UIScreen.main.nativeBounds.size
    
    /// Resize the image so its size is within the bounds of the device's native resolution
    func resizeImage(_ image: UIImage) -> UIImage? {
        let imageSize = image.size
        
        // Filter any image matching the grumpy cat image's size
        if imageSize == K.Image.grumpyCatImageSize {
            return nil
        }
        
        // Continue the resizing process if image's height and width is bigger than the resizing threshold, return original image otherwise.
        guard imageSize.height > screenSize.height || imageSize.width > screenSize.width else { return image
        }
        
        // The new image size's width and height is limited to the device's native resolution
        let widthDiff = imageSize.width / screenSize.width
        let heightDiff = imageSize.height / screenSize.height
        let newImageSize = CGSize(width: imageSize.width / max(widthDiff, heightDiff),
                                  height: imageSize.height / max(widthDiff, heightDiff))
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newImageSize.width, height: newImageSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newImageSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    func downsample(dataAt data: Data) -> UIImage {
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
