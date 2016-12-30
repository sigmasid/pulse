//
//  PreviewVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewVC: UIView, PreviewPlayerItemDelegate {
    static var aPlayer = AVPlayer() //shared instance

    fileprivate var _loadingIndicator : LoadingIndicatorView?
    fileprivate var imageView : UIImageView!
    fileprivate var isImageViewShown = false
    
    fileprivate var isTapForMoreShown = false
    fileprivate var tapForMore = UILabel()
    
    //delegate vars
    var delegate : previewDelegate!
    var showTapForMore = false
    var currentQuestion : Question!
    var currentAnswer : Answer! {
        didSet {
            addAnswer(answer: currentAnswer)
            addLoadingIndicator()
        }
    }
    //end delegate vars
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.black
        let avPlayerLayer = AVPlayerLayer(player: PreviewVC.aPlayer)
        layer.addSublayer(avPlayerLayer)
        avPlayerLayer.frame = bounds
        avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func removeClip() {
        PreviewVC.aPlayer.pause()
        PreviewVC.aPlayer.replaceCurrentItem(with: nil)
    }
    
    func itemStatusReady() {
        switch PreviewVC.aPlayer.status {
        case AVPlayerStatus.readyToPlay:
            removeLoadingIndicator()
            PreviewVC.aPlayer.play()
            break
        default: break
        }
    }
    
    //adds the first clip to the answers
    fileprivate func addAnswer(answer : Answer) {
        Database.getAnswer(answer.aID, completion: { (answer, error) in
            
            guard let answerType = answer.aType else {
                GlobalFunctions.showErrorBlock("error getting video", erMessage: "Sorry there was an error! Please try the next answer")
                return
            }
            
            if answerType == .recordedVideo || answerType == .albumVideo {
                Database.getAnswerURL(qID: answer.qID, fileID: answer.aID, completion: { (URL, error) in
                    if (error != nil) {
                        GlobalFunctions.showErrorBlock("error getting video", erMessage: "Sorry there was an error! Please try the next answer")
                    } else {
                        let aPlayerItem = PreviewPlayerItem(url: URL!)
                        self.removeImageView()
                        aPlayerItem.delegate = self
                        PreviewVC.aPlayer.replaceCurrentItem(with: aPlayerItem)
                        
                        NotificationCenter.default.addObserver(self, selector: #selector(self.showPreviewEndedOverlay),
                                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: PreviewVC.aPlayer.currentItem)

                    }
                })
            } else if answerType == .recordedImage || answerType == .albumImage {
                Database.getAnswerImage(qID: answer.qID, fileID: answer.aID, maxImgSize: maxImgSize, completion: {(data, error) in
                    if error != nil {
                        GlobalFunctions.showErrorBlock("error getting video", erMessage: "Sorry there was an error! Please try the next answer")
                    } else {
                        if let _image = GlobalFunctions.createImageFromData(data!) {
                            self.showImageView(_image)
                            self.removeLoadingIndicator()
                        } else {
                            GlobalFunctions.showErrorBlock("error getting video", erMessage: "Sorry there was an error! Please try the next answer")
                        }
                    }
                })
            }
        })
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
