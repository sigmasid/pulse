//
//  PreviewVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import AVFoundation

class Preview: UIView, PreviewPlayerItemDelegate {
    static var aPlayer = AVPlayer() //shared instance

    fileprivate var _loadingIndicator : LoadingIndicatorView?
    fileprivate var imageView : UIImageView!
    fileprivate var isImageViewShown = false
    
    fileprivate var isTapForMoreShown = false
    fileprivate var tapForMore = UILabel()
    
    //delegate vars
    var delegate : previewDelegate!
    var showTapForMore = false
    var currentItem : Item! {
        didSet {
            addItem(item: currentItem)
            addLoadingIndicator()
        }
    }
    //end delegate vars
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.black
        let avPlayerLayer = AVPlayerLayer(player: Preview.aPlayer)
        layer.addSublayer(avPlayerLayer)
        avPlayerLayer.frame = bounds
        avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        removeClip()
    }
    
    func removeClip() {
        Preview.aPlayer.pause()
        Preview.aPlayer.replaceCurrentItem(with: nil)
    }
    
    func itemStatusReady() {
        switch Preview.aPlayer.status {
        case AVPlayerStatus.readyToPlay:
            removeLoadingIndicator()
            Preview.aPlayer.play()
            break
        default: break
        }
    }
    
    //adds the first clip to the answers
    fileprivate func addItem(item : Item) {
        removeClip()
        
        guard let answerType = item.contentType, let itemURL = item.contentURL else {
            GlobalFunctions.showErrorBlock("error getting video", erMessage: "Sorry there was an error! Please try again")
            return
        }
        
        if answerType == .recordedVideo || answerType == .albumVideo {
            
            let aPlayerItem = PreviewPlayerItem(url: itemURL)
            self.removeImageView()
            aPlayerItem.delegate = self
            Preview.aPlayer.replaceCurrentItem(with: aPlayerItem)
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.showPreviewEndedOverlay),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: Preview.aPlayer.currentItem)

        } else if answerType == .recordedImage || answerType == .albumImage {
            DispatchQueue.main.async {
                let _userImageData = try? Data(contentsOf: itemURL)
                DispatchQueue.main.async(execute: {
                    if let data = _userImageData, let image = UIImage(data: data) {
                        self.showImageView(image)
                        self.removeLoadingIndicator()
                    }
                })
            }
        }
    }
    
    fileprivate func showImageView(_ image : UIImage) {
        if isImageViewShown {
            imageView.image = image
        } else {
            imageView = UIImageView(frame: bounds)
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            insertSubview(imageView, at: 1)
            isImageViewShown = true
        }
    }
    
    func showPreviewEndedOverlay() {
        if showTapForMore {
            if delegate != nil {
                delegate.watchedFullPreview = true
            }
            tapForMore = UILabel(frame: bounds)
            tapForMore.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            tapForMore.text = "See More"
            tapForMore.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .center)
            
            addSubview(tapForMore)
            NotificationCenter.default.removeObserver(self)
            
            isTapForMoreShown = true
        }
    }
    
    fileprivate func removeImageView() {
        if isImageViewShown {
            imageView.image = nil
            imageView.removeFromSuperview()
            isImageViewShown = false
        }
    }

    func addLoadingIndicator() {
        if isTapForMoreShown {
            tapForMore.removeFromSuperview()
        }
        
        let _loadingIndicatorFrame = CGRect(x: bounds.midX - (IconSizes.medium.rawValue / 2), y: bounds.midY - (IconSizes.medium.rawValue / 2), width: IconSizes.medium.rawValue, height: IconSizes.medium.rawValue)
        _loadingIndicator = LoadingIndicatorView(frame: _loadingIndicatorFrame, color: UIColor.white)
        addSubview(_loadingIndicator!)
    }
    
    func removeLoadingIndicator() {
        _loadingIndicator!.removeFromSuperview()
    }
}

protocol PreviewPlayerItemDelegate {
    func itemStatusReady()
}

class PreviewPlayerItem: AVPlayerItem {
    
    var delegate : PreviewPlayerItemDelegate?
    
    init(url URL: URL) {
        super.init(asset: AVAsset(url: URL) , automaticallyLoadedAssetKeys:[])
        self.addMyObservers()
    }
    
    deinit {
        self.removeMyObservers()
    }
    
    func addMyObservers() {
        self.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    func removeMyObservers() {
        self.removeObserver(self, forKeyPath: "status", context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            self.delegate?.itemStatusReady()
        }
    }
    
}
