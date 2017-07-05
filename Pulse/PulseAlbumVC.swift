//
//  PulseAlbumVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/27/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import Photos

public struct ImageMetadata {
    public let mediaType: PHAssetMediaType
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let location: CLLocation?
    public let duration: TimeInterval
}

class PulseAlbumVC: PulseVC, XMSegmentedControlDelegate {
    /** PUBLIC SETTER VARS **/
    public weak var delegate: InputItemDelegate!
    public var shouldAllowVideo = true
    public var captureSize : AssetSize! = .fullScreen
    
    /** VIEW VARS **/
    fileprivate var controlsView : UIView!
    fileprivate var titleLabel : UILabel!
    fileprivate var cancelButton = PulseButton(size: .xSmall, type: .close, isRound: true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    fileprivate var cameraButton = PulseButton(size: .xSmall, type: .camera, isRound: true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    fileprivate var scopeBar : XMSegmentedControl!
    fileprivate var albumView : PulseAlbumView!
    
    fileprivate var selectedMetadata : ImageMetadata?
    
    fileprivate var hasGalleryPermission: Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    fileprivate var cleanupComplete = false
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            delegate = nil
            cleanupComplete = true

            if albumView != nil {
                albumView.performCleanup()
                albumView.delegate = nil
                albumView = nil
            }
            if scopeBar != nil {
                scopeBar.delegate = nil
                scopeBar = nil
            }
        }
    }
    
    deinit {
        performCleanup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            setupLayout()
            setupScope()
            setupAlbum()
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //view.alpha = 1.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func handleCancel(_ sender: UIButton) {
        delegate?.dismissInput()
    }
    
    func handleSwitchInput() {
        delegate?.switchInput(currentInput: .album)
    }
    
    func xmSegmentedControl(_ xmSegmentedControl: XMSegmentedControl, selectedSegment: Int) {
        if selectedSegment == 0 {
            albumView.currentMode = .albumImage
        } else {
            albumView.currentMode = .albumVideo
        }
    }
}

//setup layout
extension PulseAlbumVC {
    fileprivate func setupLayout() {
        let buttonHeight = IconSizes.xSmall.rawValue
        let headerHeight = IconSizes.medium.rawValue * 1.2
        
        controlsView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: headerHeight))
        titleLabel = UILabel(frame: CGRect(x: Spacing.m.rawValue + buttonHeight, y: 0,
                                           width: view.bounds.width - (Spacing.m.rawValue + buttonHeight) * 2, height: headerHeight))
        cancelButton.frame = CGRect(x: Spacing.s.rawValue, y: headerHeight / 2 - buttonHeight / 2,
                                   width: buttonHeight, height: buttonHeight)
        cameraButton.frame = CGRect(x: controlsView.frame.width - buttonHeight - Spacing.s.rawValue, y: headerHeight / 2 - buttonHeight / 2,
                                    width: buttonHeight, height: buttonHeight)
        
        view.addSubview(controlsView)
        controlsView.backgroundColor = UIColor.white
        controlsView.addShadow()
        
        controlsView.addSubview(cancelButton)
        controlsView.addSubview(cameraButton)
        controlsView.addSubview(titleLabel)
        
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(handleSwitchInput), for: .touchUpInside)
        
        titleLabel.setFont(FontSizes.headline.rawValue, weight: UIFontWeightHeavy, color: .black, alignment: .center)
        titleLabel.text = "Camera Roll"
    }
    
    fileprivate func setupScope() {
        if shouldAllowVideo {
            let scopeFrame = CGRect(x: 0, y: controlsView.frame.height, width: view.bounds.width, height: scopeBarHeight)
            let segmentTitles : [String] = ["Images", "Videos"]
            let segmentIcons : [UIImage] = [UIImage(named: "photo")!, UIImage(named:"video")!]
            
            scopeBar = XMSegmentedControl(frame: scopeFrame, segmentContent: (segmentTitles, segmentIcons) , selectedItemHighlightStyle: .bottomEdge)
            
            scopeBar.delegate = self
            scopeBar.addBottomBorder(color: .pulseGrey)
            
            scopeBar.backgroundColor = .white
            scopeBar.highlightColor = .pulseBlue
            scopeBar.highlightTint = .black
            scopeBar.tint = .gray
            
            view.addSubview(scopeBar)
        }
    }
    
    fileprivate func setupAlbum() {
        let startY = shouldAllowVideo ? controlsView.frame.height + scopeBarHeight : controlsView.frame.height
        albumView = PulseAlbumView(frame: CGRect(x: 0, y: startY, width: view.frame.width, height: view.frame.height - startY))
        view.addSubview(albumView)
        albumView.layoutIfNeeded()
        
        albumView.delegate = self
    }
}

extension PulseAlbumVC: VideoTrimmerDelegate, ImageTrimmerDelegate {
    func dismissedTrimmer() {
        view.alpha = 1.0

        guard let nav = self.navigationController else {
            dismiss(animated: true, completion: nil)
            return
        }
        nav.popViewController(animated: false)
    }
    
    func exportedAsset(url: URL?) {
        guard let nav = self.navigationController else {
            delegate?.capturedItem(url: url, image: nil, location: selectedMetadata?.location, assetType: .albumVideo)
            return
        }
        
        nav.popViewController(animated: false)
        delegate?.capturedItem(url: url, image: nil, location: selectedMetadata?.location, assetType: .albumVideo)
    }
    
    func capturedItem(image: UIImage?) {
        let resizedImage = image?.resizeImage(newWidth: fullImageWidth) ?? image
        
        guard let nav = self.navigationController else {
            delegate?.capturedItem(url: nil, image: resizedImage, location: selectedMetadata?.location, assetType: .albumImage)
            return
        }
        
        nav.popViewController(animated: false)
        delegate?.capturedItem(url: nil, image: resizedImage, location: selectedMetadata?.location, assetType: .albumImage)
    }
}

extension PulseAlbumVC: AlbumViewDelegate {
    
    public func selectedImage(image : UIImage?, metaData: ImageMetadata?) {
        if captureSize == .fullScreen {
            delegate?.capturedItem(url: nil, image: image, location: metaData?.location, assetType: self.albumView.currentMode)
        } else {
            guard let image = image else {
                GlobalFunctions.showAlertBlock("Invalid Selection",
                                               erMessage: "Sorry! There was an error fetching the image. Please try again or select another image")
                return
            }
            
            let imageCropperVC = ImageCropperVC()
            imageCropperVC.selectedImage = image
            imageCropperVC.captureSize = captureSize
            imageCropperVC.delegate = self
            imageCropperVC.transitioningDelegate = self
            
            guard let nav = self.navigationController else {
                view.alpha = 0.0
                present(imageCropperVC, animated: false, completion: nil)
                return
            }
            
            nav.pushViewController(imageCropperVC, animated: false)
        }
    }
    
    public func selectedVideo(video: PHAsset?, metaData: ImageMetadata?) {
        guard let asset = video else {
            GlobalFunctions.showAlertBlock("Invalid Selection", erMessage: "Sorry! There was an error fetching the video. Please try again or select another video")
            return
        }
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .mediumQualityFormat
        
        let imageManager = PHImageManager()
        
        guard asset.duration <= PulseDatabase.maxVideoLength else {
            DispatchQueue.global(qos: .default).async(execute: {
                imageManager.requestAVAsset(forVideo: asset, options: options, resultHandler: { asset, _ , info in
                    guard let asset = asset else { return }
                    
                    let videoTrimmer = VideoTrimmerVC()
                    videoTrimmer.asset = asset
                    videoTrimmer.delegate = self
                    self.selectedMetadata = metaData
                    
                    guard let nav = self.navigationController else {
                        DispatchQueue.main.async {
                            self.present(videoTrimmer, animated: false, completion: nil)
                        }
                        return
                    }
                    
                    DispatchQueue.main.async {
                        nav.pushViewController(videoTrimmer, animated: false)
                    }
                })
            })
            return
        }
        
        imageManager.requestPlayerItem(forVideo: asset, options: options, resultHandler: { playerItem, info in
            if let avAsset = playerItem?.asset as? AVURLAsset {
                DispatchQueue.main.async {
                    self.delegate?.capturedItem(url: avAsset.url, image: nil, location: metaData?.location, assetType: self.albumView.currentMode)
                }
            } else {
                imageManager.requestExportSession(forVideo: asset, options: options, exportPreset: AVAssetExportPresetMediumQuality,
                                                  resultHandler: {session, info in
                    
                    guard let session = session else {
                        return
                    }
                    
                    session.outputURL = GlobalFunctions.tempFileURL()
                    session.outputFileType = AVFileTypeMPEG4
                    
                    session.exportAsynchronously(completionHandler: {
                        switch session.status {
                        case AVAssetExportSessionStatus.failed, AVAssetExportSessionStatus.cancelled:
                            break
                        case AVAssetExportSessionStatus.completed:
                            self.delegate?.capturedItem(url: session.outputURL, image: nil, location: metaData?.location, assetType: self.albumView.currentMode)
                            break
                        case AVAssetExportSessionStatus.exporting:
                            break
                        case AVAssetExportSessionStatus.unknown:
                            break
                        case AVAssetExportSessionStatus.waiting:
                            break
                        }
                    })
                })
            }
        })
    }
    
    // MARK: FSAlbumViewDelegate
    public func albumViewCameraRollUnauthorized() {
        
        let alert = UIAlertController(title: "Access Requested",
                                      message: "We need access to your photo album so you can select images and videos",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "settings", style: .default) { (action) -> Void in
            
            if let url = URL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: { _ in })
            }
        })
        
        alert.addAction(UIAlertAction(title: "cancel", style: .cancel) { (action) -> Void in
            
        })
        
        self.present(alert, animated: true, completion: nil)
        
    }
}
