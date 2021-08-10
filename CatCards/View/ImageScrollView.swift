//
//  ImageScrollView.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/10/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

final class ImageScrollView: UIScrollView {
    
    // MARK: - Properties

    private var imageView = UIImageView()
    private lazy var zoomingTap: UITapGestureRecognizer = {
        let zoomingTap = UITapGestureRecognizer(target: self, action: #selector(handleZoomingTap))
        zoomingTap.numberOfTapsRequired = 2
        return zoomingTap
    }()
    
    //MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Set up scroll view.
        delegate = self
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        decelerationRate = .fast
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        centerImage()
    }
    
    //MARK: - ScrollView & ImageView Configuration
    
    func updateImage(_ image: UIImage) {
        imageView.removeFromSuperview() // Remove default image.
        imageView = UIImageView(image: image)
//        imageView.image = image
//        imageView.frame.size = image.size
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(zoomingTap)
        self.addSubview(imageView)
        self.contentSize = image.size
        
        setUpZoomScale()
        self.zoomScale = self.minimumZoomScale
    }
    
    private func setUpZoomScale() {
        let xScale = bounds.width / imageView.width
        let yScale = bounds.height / imageView.height
        let minScale = min(xScale, yScale)
        
        self.minimumZoomScale = minScale
        self.maximumZoomScale = 3
    }
    
    private func centerImage() {
        // Position the imageView to the center of the scrollView.
        imageView.left = imageView.width <= self.width ? (self.width - imageView.width) / 2 : 0
        imageView.top = imageView.height <= self.height ? (self.height - imageView.height) / 2 : 0
    }
    
    //MARK: - Image zooming
    
    /// Handler of user's tapping gestures on the imageView.
    /// - Parameter sender: The UITapGestureRecognizer attached to the imageView.
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

