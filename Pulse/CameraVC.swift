//
//  CameraVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseDatabase

protocol CameraManagerProtocol: class {
    func didReachMaxRecording(_ fileURL : URL?, image: UIImage?, error : NSError?)
}

class CameraVC: PulseVC, UIGestureRecognizerDelegate, CameraManagerProtocol {
    public var cameraMode : CameraOutputMode = .videoWithMic {
        didSet {
            camera.cameraOutputMode = cameraMode
            if longTap != nil {
                longTap.isEnabled = cameraMode == .stillImage ? false : true
            }
        }
    }
    
    fileprivate let camera = CameraManager()
    fileprivate var cameraOverlay : CameraOverlayView!
    fileprivate var loadingOverlay : LoadingView!
    
    /* duration set in milliseconds */
    fileprivate let videoDuration : Double = 60
    fileprivate var countdownTimer : CALayer!
    
    var screenTitle : String? //set by delegate
    weak var delegate : CameraDelegate?
    
    fileprivate var tap : UITapGestureRecognizer!
    fileprivate var longTap : UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
            super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !isLoaded {
            let zoomPinch = UIPinchGestureRecognizer()
            zoomPinch.delegate = self
            camera.maxRecordingDelegate = self
            
            view.isUserInteractionEnabled = true
            view.isMultipleTouchEnabled = true
            view.addGestureRecognizer(zoomPinch)
            
            cameraOverlay = CameraOverlayView(frame: UIScreen.main.bounds)
            
            setupLoading()
            setupCamera()
            setupCameraOverlay()
            
            isLoaded = true
        } else {
            camera.resumeCaptureSession()
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    //Camera is in video mode - so will take a 0.3 second image
    fileprivate func takeImage() {
        camera.startRecordingVideo()
    }
    
    //Camera is in still image mode
    fileprivate func takeStillImage() {
        camera.capturePictureWithCompletion({ (image, capturing, error) in
            if capturing {
                self.delegate!.doneRecording(isCapturing: true, url: nil, image: image, location: self.camera.location, assetType: .recordedImage)
            } else if let image = image {
                self.delegate!.doneRecording(isCapturing: false, url: nil, image: image, location: self.camera.location, assetType: .recordedImage)
            } else {
                self.delegate!.doneRecording(isCapturing: false, url: nil, image: nil, location: nil, assetType: nil)
            }
        })
    }
    
    fileprivate func startVideoCapture() {
        cameraOverlay.countdownTimer(videoDuration / 10) //convert to seconds
        camera.startRecordingVideo()
    }
    
    fileprivate func stopVideoCapture() {
        cameraOverlay.stopCountdown()
        camera.stopRecordingVideo({ (videoURL, image, error) -> Void in

            if let errorOccured = error {
                self.camera.showErrorBlock("Error occurred", errorOccured.localizedDescription)
            } else {
                if image != nil {
                    self.delegate!.doneRecording(isCapturing: false, url: nil, image: image, location: self.camera.location, assetType: .recordedImage)
                } else if videoURL != nil {
                    self.delegate!.doneRecording(isCapturing: false, url: videoURL, image: nil, location: self.camera.location, assetType: .recordedVideo)
                }
                self.camera.stopCaptureSession()
            }
        })
    }
    
    func didReachMaxRecording(_ fileURL : URL?, image: UIImage?, error : NSError?) {
        if image != nil {
            //it's an image
            camera.cameraVideoDuration = videoDuration //reset the duration

            if let errorOccured = error {
                camera.showErrorBlock("Error occurred", errorOccured.localizedDescription)
            } else {
                delegate!.doneRecording(isCapturing: false, url: nil, image: image, location: self.camera.location, assetType: .recordedImage)
                camera.stopCaptureSession()
            }
        } else {
            //it's a video
            cameraOverlay.stopCountdown()
            
            if let errorOccured = error {
                camera.showErrorBlock("Error occurred", errorOccured.localizedDescription)
            } else {
                delegate!.doneRecording(isCapturing: false, url: fileURL, image: nil, location: self.camera.location, assetType: .recordedVideo)
                camera.stopCaptureSession()
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

        let _ = camera.addPreviewLayerToView(view, newCameraOutputMode: cameraMode, completition: {() in
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
            
            let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (alertAction) -> Void in  }))
            
            self?.present(alertController, animated: true, completion: nil)
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
        
        cameraOverlay.getButton(.flip).addTarget(self, action: #selector(flipCamera), for: UIControlEvents.touchUpInside)
        cameraOverlay.getButton(.flash).addTarget(self, action: #selector(cycleFlash), for: UIControlEvents.touchUpInside)
        cameraOverlay.getButton(.album).addTarget(self, action: #selector(showAlbumPicker), for: UIControlEvents.touchUpInside)
    }
    
    func updateOverlayTitle(title: String) {
        cameraOverlay.updateTitle(title)
    }
    
    func respondToShutterTap() {
        if cameraMode == .stillImage {
            takeStillImage()
        } else {
            camera.cameraVideoDuration = 0.1
            takeImage()
        }
    }
    
    func respondToShutterLongTap(_ longPress : UILongPressGestureRecognizer) {
        if longPress.state == .began {
            startVideoCapture()
        } else if longPress.state == .ended {
            stopVideoCapture()
        }
    }
    
    func showAlbumPicker() {
        if let childDelegate = delegate {
            childDelegate.showAlbumPicker()
        }
    }
}
