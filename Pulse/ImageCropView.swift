//
//  PulseImageCropView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/26/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

final class ImageCropView: UIScrollView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    public var isCropImage : Bool = true
    private var imageView = UIImageView()
    private var imageSize: CGSize?
    
    private var initialContentOffsetX : CGFloat = 0
    private var initialContentOffsetY : CGFloat = 0
    
    var cropArea:CGRect{
        get{
            let fullScreen = frame.height > frame.width
            let factor = fullScreen ? image.size.height / frame.height : image.size.width / frame.width
            let scale = 1 / zoomScale
            
            let x = contentOffset.x * scale * factor
            let y = contentOffset.y * scale * factor
            let width = frame.size.width * scale * factor
            let height = fullScreen ? frame.size.height * scale * factor : frame.size.width * scale * factor
                        
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }
    
    public var image: UIImage! = nil {
        
        didSet {
            if image != nil {
                
                zoomScale = 1.0
                
                if !imageView.isDescendant(of: self) {
                    imageView.alpha = 1.0
                    addSubview(imageView)
                }
                
            } else {
                
                imageView.image = nil
                return
            }
            
            if !isCropImage {
                // Disable scroll view and set image to fit in view
                imageView.frame = frame
                imageView.contentMode = .scaleAspectFit
                isUserInteractionEnabled = false
                
                imageView.image = image
                return
            }
            
            let imageSize = self.imageSize ?? image.size
            
            let ratioW = frame.width / imageSize.width // 400 / 1000 => 0.4
            let ratioH = frame.height / imageSize.height // 300 / 500 => 0.6
            
            if ratioH > ratioW {
                imageView.frame = CGRect(
                    origin: CGPoint.zero,
                    size: CGSize(width: imageSize.width  * ratioH, height: frame.height)
                )
            } else {
                imageView.frame = CGRect(
                    origin: CGPoint.zero,
                    size: CGSize(width: frame.width, height: imageSize.height  * ratioW)
                )
            }
            
            contentOffset = CGPoint(
                x: imageView.center.x - center.x,
                y: imageView.center.y - center.y
            )
            
            initialContentOffsetX = contentOffset.x
            initialContentOffsetY = contentOffset.y
            
            contentSize = CGSize(width: imageView.frame.width + 1, height: imageView.frame.height + 1)
            
            imageView.contentMode = .scaleAspectFill
            self.maximumZoomScale = min(2.0, max(image.size.width / (UIScreen.main.bounds.width * 2), 1.0))
            
            imageView.image = image
            imageView.layoutIfNeeded()
            
            zoomScale = 1.0
        }
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        self.clipsToBounds   = true
        self.imageView.alpha = 0.0
        
        imageView.frame = CGRect(origin: CGPoint.zero, size: CGSize.zero)
        
        self.maximumZoomScale = 2.0
        self.minimumZoomScale = 1.0
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator   = false
        self.bouncesZoom = true
        self.bounces = true
        self.scrollsToTop = false
        
        self.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
    
    
    func changeScrollable(_ isScrollable: Bool) {
        
        self.isScrollEnabled = isScrollable
    }
    
    // MARK: UIScrollViewDelegate Protocol
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return imageView
        
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        let boundsSize = scrollView.bounds.size
        var contentsFrame = imageView.frame
        
        if contentsFrame.size.width < boundsSize.width {
            
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
            
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
            
        } else {
            
            contentsFrame.origin.y = 0.0
        }
        
        imageView.frame = contentsFrame
        
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        
        self.contentSize = CGSize(width: imageView.frame.width + 1, height: imageView.frame.height + 1)
    }
    
    public func getCroppedImage() -> UIImage? {
        
        guard let imageData = image?.fixOrientation() else {
            return image
        }
        
        guard let croppedCGImage = imageData.cropping(to: cropArea) else {
            return image
        }
        
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: zoomScale, orientation: image.imageOrientation == .upMirrored ? .upMirrored : .up)
        
        zoomScale = 1.0
        
        return croppedImage
    }

}
