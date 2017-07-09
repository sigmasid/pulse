//
//  CameraVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseDatabase

class CameraVC: PulseVC, UIGestureRecognizerDelegate, CameraManagerProtocol {
    /** PUBLIC SETTERS **/
    public var screenTitle : String? //set by delegate
    public var captureSize : AssetSize! = .fullScreen {
        didSet {
            if cameraLayer != nil {
                cameraLayer.frame = getCameraFrame()
            }
        }
    }
    public weak var delegate : InputItemDelegate?
    public var cameraMode : CameraOutputMode = .videoWithMic {
        didSet {
            camera.cameraOutputMode = cameraMode
            if longTap != nil {
                longTap.isEnabled = cameraMode == .stillImage ? false : true
            }
        }
    }
    public var showTextInput = false
    /** END SETTERS **/
    
    fileprivate var camera = CameraManager()
    fileprivate var cameraOverlay : CameraOverlayView!
    fileprivate var loadingOverlay : LoadingView!
    fileprivate var cameraLayer : UIView!
    
    /* duration set in milliseconds */
    fileprivate let videoDuration : Double = MAX_VIDEO_LENGTH * 10
    fileprivate var countdownTimer : CALayer!
    
    /** GESTURE RECOGNIZERS **/
    fileprivate var tap : UITapGestureRecognizer!
    fileprivate var longTap : UILongPressGestureRecognizer!
    
    fileprivate var cleanupComplete = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }
    
    deinit {
        performCleanup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !isLoaded {
            camera.maxRecordingDelegate = self
            
            cameraOverlay = CameraOverlayView(frame: view.bounds, showTextInput: showTextInput)
            cameraLayer = UIView(frame: getCameraFrame())
            view.addSubview(cameraLayer)
            //cameraLayer.isMultipleTouchEnabled = true
            
            setupLoading()
            setupCamera()
            setupCameraOverlay()
            
            isLoaded = true
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    private func getCameraFrame() -> CGRect {
        switch captureSize! {
        case .fullScreen:
            return view.bounds
        case .square:
            return CGRect(x: 0, y: SCOPE_HEIGHT, width: min(view.bounds.width, view.bounds.height), height: min(view.bounds.width, view.bounds.height))
        }
    }
    
    //Camera is in video mode - so will take a 0.3 second image
    fileprivate func takeImage() {
        camera.startRecordingVideo()
    }
    
    //Camera is in still image mode
    fileprivate func takeStillImage() {
        camera.capturePictureWithCompletion({[weak self] (image, error) in
            guard let `self` = self else { return }
            
            if let image = image {
                self.sendImage(image: image)
            } else {
                self.delegate?.capturedItem(item: nil, location: nil, assetType: .recordedImage)
            }
        })
    }
    
    fileprivate func sendImage(image: UIImage) {
        if captureSize == .fullScreen {
            guard let croppedImage = image.resizeImage(newWidth: FULL_IMAGE_WIDTH) else {
                delegate?.capturedItem(item: image, location: self.camera.location, assetType: .recordedImage)
                return
            }
            delegate?.capturedItem(item: croppedImage, location: self.camera.location, assetType: .recordedImage)
        } else {
            guard let croppedImage = image.getSquareImage(newWidth: FULL_IMAGE_WIDTH) else {
                delegate?.capturedItem(item: image.resizeImage(newWidth: FULL_IMAGE_WIDTH),
                                            location: self.camera.location, assetType: .recordedImage)
                return
            }
            delegate?.capturedItem(item: croppedImage, location: self.camera.location, assetType: .recordedImage)
        }
    }
    
    fileprivate func startVideoCapture() {
        cameraOverlay.countdownTimer(videoDuration / 10) //convert to seconds
        camera.startRecordingVideo()
    }
    
    fileprivate func stopVideoCapture() {
        cameraOverlay.stopCountdown()
        camera.stopRecordingVideo({[weak self] (videoURL, image, error) -> Void in
            guard let `self` = self else {
                return
            }
            
            if let errorOccured = error {
                self.camera.showErrorBlock("Error occurred", errorOccured.localizedDescription)
            } else {
                if let image = image {
                    self.sendImage(image: image)
                } else if videoURL != nil {
                    self.delegate?.capturedItem(item: videoURL, location: self.camera.location, assetType: .recordedVideo)
                } else {
                    self.delegate?.capturedItem(item: nil, location: nil, assetType: .recordedImage)
                }
            }
        })
    }
    
    func didReachMaxRecording(_ fileURL : URL?, image: UIImage?, error : NSError?) {
        if let image = image {
            //it's an image
            camera.cameraVideoDuration = videoDuration //reset the duration

            if let errorOccured = error {
                camera.showErrorBlock("Error occurred", errorOccured.localizedDescription)
            } else {
                sendImage(image: image)
            }
        } else {
            //it's a video
            cameraOverlay.stopCountdown()
            
            if let errorOccured = error {
                camera.showErrorBlock("Error occurred", errorOccured.localizedDescription)
            } else {
                delegate?.capturedItem(item: fileURL, location: self.camera.location, assetType: .recordedVideo)
            }
        }
    }
    
    public func toggleLoading(show: Bool, message: String?) {
        view.addSubview(loadingOverlay)
        loadingOverlay.isHidden = show ? false : true
        loadingOverlay.addIcon(.medium, _iconColor: .white, _iconBackgroundColor: .black)
        loadingOverlay?.addMessage(message, _color: .white)
    }

    
    public func cycleFlash(_ oldButton : UIButton) {
        let newFlashMode = camera.changeFlashMode()
        
        switch newFlashMode {
        case .off: cameraOverlay._flashMode =  .off
        case .on: cameraOverlay._flashMode = .on
        case .auto: cameraOverlay._flashMode = .auto
        }
    }
    
    public func flipCamera() {
        if camera.cameraDevice == .front {
            camera.cameraDevice = .back
        } else {
            camera.cameraDevice = .front
        }
    }
    
    fileprivate func setupLoading() {
        loadingOverlay = LoadingView(frame: view.bounds, backgroundColor : UIColor.black)
        view.addSubview(loadingOverlay)
    }
    
    fileprivate func setupCamera() {
        camera.showAccessPermissionPopupAutomatically = true
        camera.shouldRespondToOrientationChanges = false
        camera.cameraDevice = .front
        camera.cameraVideoDuration = videoDuration

        let _ = camera.addPreviewLayerToView(cameraLayer, newCameraOutputMode: cameraMode, completition: {() in
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2, animations: { self.loadingOverlay.alpha = 0.0 } ,
                    completion: {(value: Bool) in
                        self.loadingOverlay.removeFromSuperview()
                        self.loadingOverlay.alpha = 1.0
                })
                self.tap.isEnabled = true //enables tap when camera is ready
                
                if self.cameraMode != .stillImage {
                    self.longTap.isEnabled = true
                }
            }
        })
        
        camera.showErrorBlock = { [weak self] (erTitle: String, erMessage: String) -> Void in
            guard let `self` = self else {
                return
            }
            
            let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (alertAction) -> Void in  }))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    fileprivate func setupCameraOverlay() {
        view.addSubview(cameraOverlay)
        cameraOverlay.updateTitle(screenTitle)
        
        switch camera.flashMode {
        case .off: cameraOverlay._flashMode =  .off
        case .on: cameraOverlay._flashMode = .on
        case .auto: cameraOverlay._flashMode = .auto
        }
        
        tap = UITapGestureRecognizer(target: self, action: #selector(respondToShutterTap))
        cameraOverlay.getButton(.shutter).addGestureRecognizer(tap)
        tap.isEnabled = false
        
        if cameraMode != .stillImage {
            longTap = UILongPressGestureRecognizer(target: self, action: #selector(respondToShutterLongTap))
            longTap.minimumPressDuration = 0.3
            cameraOverlay.getButton(.shutter).addGestureRecognizer(longTap)
            longTap.isEnabled = false
        }
        
        cameraOverlay.getButton(.close).addTarget(self, action: #selector(dismissCamera), for: UIControlEvents.touchUpInside)
        cameraOverlay.getButton(.flip).addTarget(self, action: #selector(flipCamera), for: UIControlEvents.touchUpInside)
        cameraOverlay.getButton(.flash).addTarget(self, action: #selector(cycleFlash), for: UIControlEvents.touchUpInside)
        cameraOverlay.getButton(.album).addTarget(self, action: #selector(showAlbumPicker), for: UIControlEvents.touchUpInside)
        cameraOverlay.getButton(.text).addTarget(self, action: #selector(showNotecard), for: UIControlEvents.touchUpInside)
    }
    
    func updateOverlayTitle(title: String) {
        cameraOverlay.updateTitle(title)
    }
    
    internal func respondToShutterTap() {
        if cameraMode == .stillImage {
            takeStillImage()
        } else {
            camera.cameraVideoDuration = 0.1
            takeImage()
        }
    }
    
    internal func respondToShutterLongTap(_ longPress : UILongPressGestureRecognizer) {
        if longPress.state == .began {
            startVideoCapture()
            let shutterButton = cameraOverlay.getButton(.shutter)
            let xForm = CGAffineTransform.identity.scaledBy(x: 1.3, y: 1.3)
            UIView.animate(withDuration: 0.5, animations: { shutterButton.transform = xForm; self.cameraOverlay.countdownTimer.transform = xForm; shutterButton.alpha = 1 } , completion: {_ in })
            
        } else if longPress.state == .ended {
            stopVideoCapture()
            
            let shutterButton = cameraOverlay.getButton(.shutter)
            let xForm = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
            UIView.animate(withDuration: 0.5, animations: { shutterButton.transform = xForm; self.cameraOverlay.countdownTimer.transform = xForm; shutterButton.alpha = 0.7 } , completion: {_ in
                self.cameraOverlay.countdownTimer.removeFromSuperview()
            })
        }
    }
    
    internal func showAlbumPicker() {
        delegate?.switchInput(to: .album, from: .camera)
    }
    
    internal func showNotecard() {
        delegate?.switchInput(to: .text, from: .camera)
    }
    
    internal func dismissCamera() {
        delegate?.dismissInput()
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            camera.stopAndRemoveCaptureSession()
            camera.maxRecordingDelegate = nil
            
            if cameraOverlay != nil {
                cameraOverlay = nil
            }
            
            if loadingOverlay != nil {
                loadingOverlay = nil
            }
            
            if cameraLayer != nil {
                cameraLayer = nil
            }
            
            delegate = nil
            screenTitle = nil
            
            if tap != nil {
                tap.delegate = nil
                tap = nil
            }
            
            if longTap != nil {
                longTap.delegate = nil
                longTap = nil
            }
            
            isLoaded = false
        }
    }
}
