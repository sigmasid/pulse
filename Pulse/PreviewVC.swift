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
    fileprivate var _loadingIndicator : LoadingIndicatorView?
    fileprivate var aPlayer = AVPlayer()
    
    var currentQuestion : Question! {
        didSet {
            loadQuestion()
            addLoadingIndicator()
        }
    }
    
    var currentAnswerID : String! {
        didSet {
            setupAnswer(currentAnswerID)
            addLoadingIndicator()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.black
        let avPlayerLayer = AVPlayerLayer(player: aPlayer)
        layer.addSublayer(avPlayerLayer)
        avPlayerLayer.frame = bounds
        avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func loadQuestion() {
        if currentQuestion.hasAnswers() {
            setupAnswer(currentQuestion.qAnswers!.first!)
        }
    }
    
    func itemStatusReady() {
        switch aPlayer.status {
        case AVPlayerStatus.readyToPlay:
            removeLoadingIndicator()
            aPlayer.play()
            break
        default: break
        }
    }
    
    fileprivate func setupAnswer(_ answerID : String) {
        Database.getAnswerURL(answerID, completion: {(URL, error) in
            if (error != nil) {
                print(error.debugDescription)
            } else {
                let aPlayerItem = PreviewPlayerItem(url: URL!)
                aPlayerItem.delegate = self
                self.aPlayer.replaceCurrentItem(with: aPlayerItem)
            }
        })
    }
    
    func addLoadingIndicator() {
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
