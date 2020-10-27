//
//  ImageScrollView.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/10/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class ImageScrollView: UIScrollView {

    var imageZoomView: UIImageView!
    lazy var zoomingTap: UITapGestureRecognizer = {
        let zoomingTap = UITapGestureRecognizer(target: self, action: #selector(handleZoomingTap))
        zoomingTap.numberOfTapsRequired = 2
        return zoomingTap
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.delegate = self
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.decelerationRate = UIScrollView.DecelerationRate.fast
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(image: UIImage) {
        imageZoomView?.removeFromSuperview()
        imageZoomView = nil
        
        imageZoomView = UIImageView(image: image)
        self.addSubview(imageZoomView)
        
        configurateFor(imageSize: image.size)
    }

    func configurateFor(imageSize: CGSize) {
        self.contentSize = imageSize
        
        setCurrentMaxAndMinZoomScale()
        self.zoomScale = self.minimumZoomScale
        
        self.imageZoomView.addGestureRecognizer(self.zoomingTap)
        self.imageZoomView.isUserInteractionEnabled = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.centerImage()
    }
    
    func setCurrentMaxAndMinZoomScale() {
        let scrollViewSize = self.bounds.size
        let imageViewSize = imageZoomView.bounds.size
        
        let xScale = scrollViewSize.width / imageViewSize.width
        let yScale = scrollViewSize.height / imageViewSize.height
        let minScale = min(xScale, yScale)
        
        self.minimumZoomScale = minScale
        self.maximumZoomScale = 2.0
    }
    
    func centerImage() {
        let boundsSize = self.bounds.size
        var frameToCenter = imageZoomView.frame
        
        // define image frame's origin position based on its relative size to the scroll view's bound
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        imageZoomView.frame = frameToCenter
    }
    
    // tap gesture definition
    @objc func handleZoomingTap(sender: UITapGestureRecognizer) {
        let location = sender.location(in: sender.view)
        self.zoom(point: location, animated: true)
    }
    
    func zoom(point: CGPoint, animated: Bool) {
        let currentScale = self.zoomScale
        let minScale = self.minimumZoomScale
        var toScale: CGFloat?
        
        let scrollViewSize = self.bounds.size
        let imageViewSize = imageZoomView.bounds.size
        
        // Define zooming behavior
        let scrollViewRatio = scrollViewSize.width / scrollViewSize.height
        let imageViewRatio = imageViewSize.width / imageViewSize.height
        
        if abs(scrollViewRatio - imageViewRatio) >= 0.25 {
            // Scale image to precisely fill the entire scroll view
            toScale = max(scrollViewSize.width / imageViewSize.width, scrollViewSize.height / imageViewSize.height)
        } else {
            toScale = self.minimumZoomScale + 1.0
        }
         
        let finalScale = (currentScale == minScale) ? toScale! : minScale // Scale image if it's not scaled by the user yet
        let zoomRect = self.zoomRect(scale: finalScale, center: point)
        self.zoom(to: zoomRect, animated: animated)
    }
    
    func zoomRect(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        let bounds = self.bounds
        
        zoomRect.size.width = bounds.size.width / scale
        zoomRect.size.height = bounds.size.height / scale
        
        zoomRect.origin.x = center.x - (zoomRect.size.width / 2)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2)
        return zoomRect
    }
    
}

//MARK: - UIScrollViewDelegate

extension ImageScrollView: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageZoomView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.centerImage()
    }
    
}

