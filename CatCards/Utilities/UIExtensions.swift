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
    
    /// Resize the image so the size is within the provided size.
    /// The original image is returned if its size is within the target size.
    func resize(within targetSize: CGSize) -> UIImage {
        let ratio = size.width / size.height
        let targetRatio = targetSize.width / targetSize.height
        var scale: CGFloat
        
        scale = ratio > targetRatio ?
            targetSize.width / size.width : targetSize.height / size.height
        if scale >= 1 { return self }

        let scaledSize = CGSize(width: size.width * scale,
                                height: size.height * scale)

        // Render the image in the scaled size.
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let resizedImage = renderer.image { context in
            draw(in: CGRect(origin: .zero, size: scaledSize))
        }
        return resizedImage
    }
    
    /// The provided image is returned if process of data initialization or downsizing failed.
    /// - Parameter size: Size the image to be downsized to.
    /// - Returns: The downsized image.
    func downsampled(toSize size: CGSize) -> UIImage {
        guard let imageData = self.jpegData(compressionQuality: K.Data.jpegDataCompressionQuality) else {
            debugPrint("Unable to create jpeg data for downsampling operation.")
            return self
        }
        
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOptions)!
        let scale = UIScreen.main.scale
        let maxPixelSize = size.applying(CGAffineTransform(scaleX: scale, y: scale))
        
        let options: [CFString : Any] =
            [kCGImageSourceCreateThumbnailFromImageAlways: true,
             kCGImageSourceShouldCacheImmediately: true,
             kCGImageSourceCreateThumbnailWithTransform: true,
             kCGImageSourceThumbnailMaxPixelSize: max(maxPixelSize.width, maxPixelSize.height)]
        
        if let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) {
            return UIImage(cgImage: downsampledImage)
        } else {
            debugPrint("Failed to downsample image.")
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

extension UIView {
    struct AutoLayoutOffset {
        let leading: CGFloat
        let trailing: CGFloat
        let top: CGFloat
        let bottom: CGFloat
    }
    
    func addView(_ view: UIView, to superview: UIView, withOffset offset: AutoLayoutOffset) {
        view.translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: offset.leading),
            view.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: offset.trailing * -1),
            view.topAnchor.constraint(equalTo: superview.topAnchor, constant: offset.top),
            view.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: offset.bottom * -1)
        ])
    }
    
    var width: CGFloat { frame.width }
    var height: CGFloat { frame.height }
    var left: CGFloat {
        get { frame.origin.x }
        set { frame.origin.x = newValue }
    }
    var top: CGFloat {
        get { frame.origin.y }
        set { frame.origin.y = newValue }
    }
}

extension UIViewController {
    func presentSimpleAlert(withTitle title: String?, message: String?, actionTitle: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actionTitle, style: .default)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}
