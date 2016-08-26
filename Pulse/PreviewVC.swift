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
    private var _loadingIndicator : LoadingIndicatorView?
    private var aPlayer = AVPlayer()
    
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
        
        backgroundColor = UIColor.blackColor()
        let avPlayerLayer = AVPlayerLayer(player: aPlayer)
        layer.addSublayer(avPlayerLayer)
        avPlayerLayer.frame = bounds
        avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func loadQuestion() {
        if currentQuestion.hasAnswers() {
            setupAnswer(currentQuestion.qAnswers!.first!)
        }
    }
    
    func itemStatusReady() {
        switch aPlayer.status {
        case AVPlayerStatus.ReadyToPlay:
            removeLoadingIndicator()
            aPlayer.play()
            break
        default: break
        }
    }
    
    private func setupAnswer(answerID : String) {
        Database.getAnswerURL(answerID, completion: {(URL, error) in
            if (error != nil) {
                print(error.debugDescription)
            } else {
                let aPlayerItem = PreviewPlayerItem(URL: URL!)
                aPlayerItem.delegate = self
                self.aPlayer.replaceCurrentItemWithPlayerItem(aPlayerItem)
            }
        })
    }
    
    func addLoadingIndicator() {
        let _loadingIndicatorFrame = CGRectMake(bounds.midX - (IconSizes.Medium.rawValue / 2), bounds.midY - (IconSizes.Medium.rawValue / 2), IconSizes.Medium.rawValue, IconSizes.Medium.rawValue)
        _loadingIndicator = LoadingIndicatorView(frame: _loadingIndicatorFrame, color: UIColor.whiteColor())
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
    
    init(URL: NSURL) {
        super.init(asset: AVAsset(URL: URL) , automaticallyLoadedAssetKeys:[])
        self.addMyObservers()
    }
    
    deinit {
        self.removeMyObservers()
    }
    
    func addMyObservers() {
        self.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    func removeMyObservers() {
        self.removeObserver(self, forKeyPath: "status", context: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "status" {
            self.delegate?.itemStatusReady()
        }
    }
    
}
