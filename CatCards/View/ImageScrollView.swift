//
//  ImageScrollView.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/10/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class ImageScrollView: UIScrollView {

    private var imageView: UIImageView!
    private lazy var zoomingTap: UITapGestureRecognizer = {
        let zoomingTap = UITapGestureRecognizer(target: self, action: #selector(handleZoomingTap))
        zoomingTap.numberOfTapsRequired = 2
        return zoomingTap
    }()
    
    //MARK: - Overriding Methods
    
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        centerImage()
    }
    
    //MARK: - ScrollView & ImageView Configuration
    
    func set(image: UIImage) {
        imageView?.removeFromSuperview()
        imageView = nil
        
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        self.addSubview(imageView)
        
        configurateFor(imageSize: image.size)
    }

    private func configurateFor(imageSize: CGSize) {
        self.contentSize = imageSize
        
        setZoomScale()
        self.zoomScale = self.minimumZoomScale
        
        imageView.addGestureRecognizer(zoomingTap)
        imageView.isUserInteractionEnabled = true
    }
    
    func setZoomScale() {
        let scrollViewSize = self.bounds.size
        
        let xScale = scrollViewSize.width / imageView.frame.width
        let yScale = scrollViewSize.height / imageView.frame.height
        let minScale = min(xScale, yScale)
        
        self.minimumZoomScale = minScale
        self.maximumZoomScale = 3
    }
    
    private func centerImage() {
        let boundsSize = self.bounds.size
        var frameToCenter = imageView.frame
        
        // Define image frame's origin position based on its relative size to the scroll view's bound
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        imageView.frame = frameToCenter
    }
    
    //MARK: - Image zooming
    
    @objc func handleZoomingTap(sender: UITapGestureRecognizer) {
        let location = sender.location(in: sender.view)
        self.zoom(point: location, animated: true)
    }
    
    private func zoom(point: CGPoint, animated: Bool) {
        let currentScale = self.zoomScale
        let minScale = self.minimumZoomScale
        var toScale: CGFloat?
        
        let scrollViewSize = self.bounds.size
        let imageViewSize = imageView.bounds.size
        
        // Define zooming behavior
        let scrollViewRatio = scrollViewSize.width / scrollViewSize.height
        let imageViewRatio = imageViewSize.width / imageViewSize.height
        
        if abs(scrollViewRatio - imageViewRatio) >= 0.25 {
            // Scale image to precisely fill the entire scroll view
            toScale = max(scrollViewSize.width / imageViewSize.width, scrollViewSize.height / imageViewSize.height)
        } else {
            toScale = self.minimumZoomScale + 0.5
        }
         
        let finalScale = (currentScale == minScale) ? toScale! : minScale // Scale image if it's not scaled by the user yet
        let zoomRect = self.zoomRect(scale: finalScale, center: point)
        self.zoom(to: zoomRect, animated: animated)
    }
    
    private func zoomRect(scale: CGFloat, center: CGPoint) -> CGRect {
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
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
    
}

