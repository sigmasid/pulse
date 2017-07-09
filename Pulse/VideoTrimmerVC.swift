//
//  VideoTrimmerVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/27/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

class VideoTrimmerVC: UIViewController {
    
    public var asset : AVAsset?
    public weak var delegate : VideoTrimmerDelegate?
    
    fileprivate var playerView: UIView!
    fileprivate var trimmerView: TrimmerView!
    fileprivate var controlsView: UIView!
    
    fileprivate var playButton = PulseButton(size: .xSmall, type: .play, isRound: true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    fileprivate var chooseButton = PulseButton(size: .xSmall, type: .check, isRound: true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    fileprivate var cancelButton = PulseButton(size: .xSmall, type: .close, isRound: true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    
    fileprivate var editingTip = PaddingLabel()
    fileprivate var durationLabel = PaddingLabel()
    
    fileprivate var player: AVPlayer?
    fileprivate var playbackTimeCheckerTimer: Timer?
    fileprivate var trimmerPositionChangedTimer: Timer?
    fileprivate var progressBar = UIProgressView()
    
    private var isLoaded = false
    private var assetLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            view.backgroundColor = .white
            
            setupLayout()
            addControls()
            
            isLoaded = true
        }
    }
    
    deinit {
        asset = nil
        player = nil
    
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let asset = asset, !assetLoaded {
            loadAsset(asset)
            assetLoaded = true
        }
    }
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    internal func play(_ sender: Any) {
        
        guard let player = player else { return }
        
        if !player.isPlaying {
            player.play()
            playButton.setImage(UIImage(named: "pause"), for: .normal)
            startPlaybackTimeChecker()
        } else {
            player.pause()
            playButton.setImage(UIImage(named: "play"), for: .normal)
            stopPlaybackTimeChecker()
        }
    }
    
    private func loadAsset(_ asset: AVAsset) {
        trimmerView.maxDuration = MAX_VIDEO_LENGTH
        trimmerView.asset = asset
        trimmerView.delegate = self
        addVideoPlayer(with: asset, playerView: playerView)
    }
    
    internal func exportAsset() {
        guard let asset = asset, let startTime = trimmerView.startTime, let endTime = trimmerView.endTime else {
            return
        }
        
        player?.pause()
        chooseButton.isEnabled = false
        let range: CMTimeRange = CMTimeRangeMake(startTime, endTime - startTime)
        
        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            // Error handling code here
            return
        }
        
        addUploadProgressBar()
        
        export.outputURL = GlobalFunctions.tempFileURL()
        export.outputFileType = AVFileTypeMPEG4
        export.shouldOptimizeForNetworkUse = true
        export.timeRange = range
        
        export.exportAsynchronously {[weak self] in
            guard let `self` = self else { return }
            
            switch export.status {
            case .exporting:
                self.updateProgressBar(export.progress)
                
            case .completed:
                DispatchQueue.main.async {
                    self.chooseButton.isEnabled = true
                    self.delegate?.exportedAsset(url: export.outputURL)
                }
                break
                
            case .cancelled, .failed:
                DispatchQueue.main.async {
                    self.chooseButton.isEnabled = true
                    GlobalFunctions.showAlertBlock("Error Exporting Video", erMessage: "Sorry there was an error. Please try again or select another video")
                }
                break
                
            default:
                fatalError("Shouldn't be called")
            }
        }
    }
    
    func itemDidFinishPlaying(_ notification: Notification) {
        if let startTime = trimmerView.startTime {
            player?.seek(to: startTime)
        }
    }
    
    fileprivate func startPlaybackTimeChecker() {
        
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(VideoTrimmerVC.onPlaybackTimeChecker), userInfo: nil, repeats: true)
    }
    
    fileprivate func stopPlaybackTimeChecker() {
        
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }
    
    internal func onPlaybackTimeChecker() {
        
        guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime, let player = player else {
            return
        }
        
        let playBackTime = player.currentTime()
        trimmerView.seek(to: playBackTime)
        
        if playBackTime >= endTime {
            player.seek(to: startTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            trimmerView.seek(to: startTime)
        }
    }
    
    internal func handleCancel() {
        delegate?.dismissedTrimmer()
    }
    
    func updateProgressBar(_ percentComplete : Float) {
        DispatchQueue.main.async {
            self.progressBar.setProgress(percentComplete, animated: true)
        }
    }
}

extension VideoTrimmerVC: TrimmerViewDelegate {
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        player?.seek(to: playerTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        player?.play()
        playButton.setImage(UIImage(named: "pause"), for: .normal)
        startPlaybackTimeChecker()
    }
    
    func didChangePositionBar(_ playerTime: CMTime) {
        stopPlaybackTimeChecker()
        player?.pause()
        playButton.setImage(UIImage(named: "play"), for: .normal)
        player?.seek(to: playerTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
        durationLabel.text = "edited:\n\(duration.rounded()) sec"
    }
}

//setup layout
extension VideoTrimmerVC {
    fileprivate func setupLayout() {
        let headerHeight = IconSizes.medium.rawValue * 1.2
        
        controlsView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: headerHeight))
        playerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        trimmerView = TrimmerView(frame: CGRect(x: 0, y: view.bounds.height - IconSizes.large.rawValue, width: view.bounds.width, height: IconSizes.large.rawValue))
        durationLabel = PaddingLabel(frame: CGRect(x: view.bounds.width * 0.8, y: view.bounds.height - trimmerView.frame.height - IconSizes.medium.rawValue,
                                             width: view.bounds.width * 0.2, height: IconSizes.medium.rawValue))
        editingTip = PaddingLabel(frame: CGRect(x: 0, y: view.bounds.height - trimmerView.frame.height - IconSizes.medium.rawValue,
                                              width: view.bounds.width * 0.8, height: IconSizes.medium.rawValue))
        
        view.addSubview(playerView)
        view.addSubview(controlsView)
        view.addSubview(trimmerView)
        view.addSubview(durationLabel)
        view.addSubview(editingTip)
        
        trimmerView.handleColor = UIColor.white
        trimmerView.mainColor = UIColor.darkGray
        
        editingTip.text = "edited for 20sec max duration. drag clip to select starting point or drag handles to edit length further."
        editingTip.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        editingTip.setFont(FontSizes.caption.rawValue, weight: UIFontWeightBold, color: .white, alignment: .left)
        
        durationLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightBold, color: .white, alignment: .center)
        durationLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        durationLabel.text = "edited:\n\(MAX_VIDEO_LENGTH.rounded()) sec"
    }
    
    fileprivate func addControls() {
        let buttonHeight = IconSizes.xSmall.rawValue
        
        controlsView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        controlsView.addSubview(cancelButton)
        controlsView.addSubview(playButton)
        controlsView.addSubview(chooseButton)
        
        chooseButton.translatesAutoresizingMaskIntoConstraints = false
        chooseButton.centerYAnchor.constraint(equalTo: controlsView.centerYAnchor).isActive = true
        chooseButton.trailingAnchor.constraint(equalTo: controlsView.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        chooseButton.widthAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        chooseButton.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.centerYAnchor.constraint(equalTo: controlsView.centerYAnchor).isActive = true
        playButton.centerXAnchor.constraint(equalTo: controlsView.centerXAnchor).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.centerYAnchor.constraint(equalTo: controlsView.centerYAnchor).isActive = true
        cancelButton.leadingAnchor.constraint(equalTo: controlsView.leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        cancelButton.widthAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        
        cancelButton.removeShadow()
        chooseButton.removeShadow()
        playButton.removeShadow()
        
        playButton.addTarget(self, action: #selector(play), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        chooseButton.addTarget(self, action: #selector(exportAsset), for: .touchUpInside)
    }
    
    fileprivate func addVideoPlayer(with asset: AVAsset, playerView: UIView) {
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(VideoTrimmerVC.itemDidFinishPlaying(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        let layer: AVPlayerLayer = AVPlayerLayer(player: player)
        layer.backgroundColor = UIColor.white.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: playerView.frame.width, height: playerView.frame.height)
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill
        playerView.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        playerView.layer.insertSublayer(layer, at: 0)
    }
    
    fileprivate func addUploadProgressBar() {
        progressBar.progressTintColor = UIColor.white
        progressBar.trackTintColor = UIColor.black.withAlphaComponent(0.7)
        progressBar.progressViewStyle = .bar
        
        view.addSubview(progressBar)
        
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        
        progressBar.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        progressBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        progressBar.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue * 1.2).isActive = true
        progressBar.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    }
}

extension AVPlayer {
    
    var isPlaying: Bool {
        return self.rate != 0 && self.error == nil
    }
}


