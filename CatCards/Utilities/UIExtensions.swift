//
//  UIExtensions.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/4/26.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import UIKit

extension UIImage {
    /// Filter out any image matching the specified size.
    /// The returned value could be nil if the provided image's size matches any size of the filter list.
    var filteredBySpecifiedSize: UIImage? {
        for filter in K.Image.imageSizeFilterList {
            if self.size == filter {
                return nil
            }
        }
        return self
    }
    
    /// Resize the image to be within the designated bounds.
    /// Provided image is returned if its size is within the specified size.
    func scaledToAspectFit(size: CGSize) -> UIImage {
        let imageSize = self.size
        let imageAspectRatio = imageSize.width / imageSize.height
        let canvasAspectRatio = size.width / size.height
        
        var resizeVector: CGFloat
        
        if imageAspectRatio > canvasAspectRatio {
            resizeVector = size.width / imageSize.width
        } else {
            resizeVector = size.height / imageSize.height
        }
        
        if resizeVector >= 1 {
            return self
        }
        
        let scaledSize = CGSize(width: imageSize.width * resizeVector, height: imageSize.height * resizeVector)
        
        // Re–draw the image with calculated scaled size.
        UIGraphicsBeginImageContextWithOptions(scaledSize, false, 0)
        draw(in: CGRect(origin: .zero, size: scaledSize))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    /// The provided image is returned if process of data initialization or downsizing failed.
    /// - Parameter size: Size the image to be downsized to.
    /// - Returns: The downsized image.
    func downsampled(toSize size: CGSize) -> UIImage {
        guard let imageData = self.pngData() else {
            debugPrint("Unable to convert UIImage object to PNG data.")
            return self
        }
        
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOptions)!
        let screenScale = UIScreen.main.scale
        
        let maxDimensionInPixels = max(size.width, size.height) * screenScale
        let downsampleOptions =
            [kCGImageSourceCreateThumbnailFromImageAlways: true,
             kCGImageSourceShouldCacheImmediately: true,
             kCGImageSourceCreateThumbnailWithTransform: true,
             kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
        
        if let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) {
            return UIImage(cgImage: downsampledImage)
        } else {
            debugPrint("Error: Unable to downsample image source to thumbnail image data.")
            return self
        }
        
    }
    
}

extension UIColor {
    /// Initialize an UIImage object with specified size and color.
    ///
    /// Demo code: *let image0 = UIColor.orange.image(CGSize(width: 128, height: 128)); let image1 = UIColor.yellow.image()*
    /// - Parameter size: *Optional*: Default size is CGSize(width: 1, height: 1)
    /// - Returns: Returns UIImage object with specified size and color.
    func image(size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
