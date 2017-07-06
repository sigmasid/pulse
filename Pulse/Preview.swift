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
    public weak var delegate : PreviewDelegate!
    var showTapForMore = false
    var currentItem : Item! {
        didSet {
            if currentItem != nil {
                addItem(item: currentItem)
                addLoadingIndicator()
            }
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
        delegate = nil
        currentItem = nil
        
        if imageView != nil {
            imageView.image = nil
            imageView = nil
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func removeClip() {
        Preview.aPlayer.pause()
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
            GlobalFunctions.showAlertBlock("error getting video", erMessage: "Sorry there was an error! Please try again")
            return
        }
        
        if answerType == .recordedVideo || answerType == .albumVideo {
            
            removeImageView()

            let aPlayerItem = PreviewPlayerItem(url: itemURL)
            Preview.aPlayer.replaceCurrentItem(with: aPlayerItem)
            aPlayerItem.delegate = self
            
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

class PreviewPlayerItem: AVPlayerItem {
    
    weak var delegate : PreviewPlayerItemDelegate?
    var isObserving = false
    
    init(url URL: URL) {
        super.init(asset: AVAsset(url: URL) , automaticallyLoadedAssetKeys:[])
        addMyObservers()
    }
    
    deinit {
        removeMyObservers()
    }
    
    func addMyObservers() {
        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        isObserving = true
    }
    
    func removeMyObservers() {
        if isObserving {
            removeObserver(self, forKeyPath: "status", context: nil)
            isObserving = false
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            switch Preview.aPlayer.status {
            case AVPlayerStatus.readyToPlay:
                delegate?.itemStatusReady()
                removeMyObservers()
                break
            default: break
            }
        }
    }
    
}
