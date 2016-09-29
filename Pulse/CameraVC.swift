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

class CameraVC: UIViewController, UIGestureRecognizerDelegate, CameraManagerProtocol {
    fileprivate let _Camera = CameraManager()
    fileprivate var _CameraOverlay : CameraOverlayView!
    fileprivate var _loadingOverlay : LoadingView!
    fileprivate var _isLoaded = false
    
    /* duration set in milliseconds */
    fileprivate let videoDuration : Double = 60
    fileprivate var countdownTimer : CALayer!
    
    var questionToShow : Question! //set by delegate
    weak var childDelegate : childVCDelegate?
    
    fileprivate var tap : UITapGestureRecognizer!
    fileprivate var longTap : UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
            super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !_isLoaded {
            let zoomPinch = UIPinchGestureRecognizer()
            zoomPinch.delegate = self
            _Camera.maxRecordingDelegate = self
            
            view.isUserInteractionEnabled = true
            view.isMultipleTouchEnabled = true
            view.addGestureRecognizer(zoomPinch)
            
            _CameraOverlay = CameraOverlayView(frame: UIScreen.main.bounds)
            
            setupLoading()
            setupCamera()
            setupCameraOverlay()
            
            _isLoaded = true
        } else {
            _Camera.resumeCaptureSession()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func takeImage() {
        _Camera.startRecordingVideo()
    }
    
    fileprivate func startVideoCapture() {
        _CameraOverlay.countdownTimer(videoDuration / 10) //convert to seconds
        _Camera.startRecordingVideo()
    }
    
    fileprivate func stopVideoCapture() {
        _CameraOverlay.stopCountdown()
        _Camera.stopRecordingVideo({ (videoURL, image, error) -> Void in
            if let errorOccured = error {
                self._Camera.showErrorBlock("Error occurred", errorOccured.localizedDescription)
            } else {
                if image != nil {
                    self.childDelegate!.doneRecording(nil, image: image, currentVC: self, location: self._Camera.recordedLocation, assetType: .recordedImage)
                } else if videoURL != nil {
                    self.childDelegate!.doneRecording(videoURL, image: nil, currentVC: self, location: self._Camera.recordedLocation, assetType: .recordedVideo)
                }
                self._Camera.stopCaptureSession()
//                self._Camera.stopAndRemoveCaptureSession()
            }
        })
    }
    
    func didReachMaxRecording(_ fileURL : URL?, image: UIImage?, error : NSError?) {
        if image != nil {
            //it's an image
            _Camera.cameraVideoDuration = videoDuration //reset the duration

            if let errorOccured = error {
                _Camera.showErrorBlock("Error occurred", errorOccured.localizedDescription)
            } else {
                childDelegate!.doneRecording(nil, image: image, currentVC: self, location: self._Camera.recordedLocation, assetType: .recordedImage)
                _Camera.stopCaptureSession()
//                _Camera.stopAndRemoveCaptureSession()
            }
        } else {
            //it's a video
            _CameraOverlay.stopCountdown()
            
            if let errorOccured = error {
                _Camera.showErrorBlock("Error occurred", errorOccured.localizedDescription)
            } else {
                childDelegate!.doneRecording(fileURL, image: nil, currentVC: self, location: self._Camera.recordedLocation, assetType: .recordedVideo)
                _Camera.stopCaptureSession()
//                _Camera.stopAndRemoveCaptureSession()
            }
        }
    }
    
    func cycleFlash(_ oldButton : UIButton) {
        let newFlashMode = _Camera.changeFlashMode()
        
        switch newFlashMode {
        case .off: _CameraOverlay._flashMode =  .off
        case .on: _CameraOverlay._flashMode = .on
        case .auto: _CameraOverlay._flashMode = .auto
        }
    }
    
    func flipCamera() {
        if _Camera.cameraDevice == .front {
            _Camera.cameraDevice = .back
        } else {
            _Camera.cameraDevice = .front
        }
    }
    
    fileprivate func setupLoading() {
        _loadingOverlay = LoadingView(frame: view.bounds, backgroundColor : UIColor.black)
        view.addSubview(_loadingOverlay)
    }
    
    fileprivate func setupCamera() {
        _Camera.showAccessPermissionPopupAutomatically = true
        _Camera.shouldRespondToOrientationChanges = false
        _Camera.cameraDevice = .front
        _Camera.cameraVideoDuration = videoDuration

        let _ = _Camera.addPreviewLayerToView(view, newCameraOutputMode: .videoWithMic, completition: {() in
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2, animations: { self._loadingOverlay.alpha = 0.0 } ,
                    completion: {(value: Bool) in
                        self._loadingOverlay.removeFromSuperview()
                })
                self.tap.isEnabled = true //enables tap when camera is ready
                self.longTap.isEnabled = true
            }
        })
        
        _Camera.showErrorBlock = { [weak self] (erTitle: String, erMessage: String) -> Void in
            
            let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (alertAction) -> Void in  }))
            
            self?.present(alertController, animated: true, completion: nil)
        }
    }
    
    fileprivate func setupCameraOverlay() {
        view.addSubview(_CameraOverlay)
        _CameraOverlay.updateQuestion(self.questionToShow.qTitle!)
        
        switch _Camera.flashMode {
        case .off: _CameraOverlay._flashMode =  .off
        case .on: _CameraOverlay._flashMode = .on
        case .auto: _CameraOverlay._flashMode = .auto
        }
        
        tap = UITapGestureRecognizer(target: self, action: #selector(respondToShutterTap))
        _CameraOverlay.getButton(.shutter).addGestureRecognizer(tap)
        tap.isEnabled = false
        
        longTap = UILongPressGestureRecognizer(target: self, action: #selector(respondToShutterLongTap))
        longTap.minimumPressDuration = 0.3
        _CameraOverlay.getButton(.shutter).addGestureRecognizer(longTap)
        longTap.isEnabled = false
        
        _CameraOverlay.getButton(.flip).addTarget(self, action: #selector(flipCamera), for: UIControlEvents.touchUpInside)
        _CameraOverlay.getButton(.flash).addTarget(self, action: #selector(cycleFlash), for: UIControlEvents.touchUpInside)
        _CameraOverlay.getButton(.album).addTarget(self, action: #selector(showAlbumPicker), for: UIControlEvents.touchUpInside)
    }
    
    func respondToShutterTap() {
        _Camera.cameraVideoDuration = 0.1
        takeImage()
    }
    
    func respondToShutterLongTap(_ longPress : UILongPressGestureRecognizer) {
        if longPress.state == .began {
            startVideoCapture()
        } else if longPress.state == .ended {
            stopVideoCapture()
        }
    }
    
    func showAlbumPicker() {
        if let childDelegate = childDelegate {
            childDelegate.showAlbumPicker(self)
        }
    }
}

//    func respondToPanGesture(pan: UIPanGestureRecognizer) {
//        let _ = pan.view!.center.x
//        let panCurrentPointY = pan.view!.center.y
//        
//        if (pan.state == UIGestureRecognizerState.Began) {
//            panStartingPointX = pan.view!.center.x
//            panStartingPointY = pan.view!.center.y
//        }
//        else if (pan.state == UIGestureRecognizerState.Ended) {
//            switch panCurrentPointY {
//            case _ where panCurrentPointY > panStartingPointY + (view.bounds.height / 3) :
//                if (childDelegate != nil) {
//                    childDelegate!.userDismissedCamera()
//                }
//                pan.setTranslation(CGPointZero, inView: view)
//                view.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
//            default:
//                view.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
//                pan.setTranslation(CGPointZero, inView: view)
//            }
//        } else {
//            let translation = pan.translationInView(view)
//            if translation.y > 20 { ///only allow vertical pulldown
//                view.center = CGPoint(x: pan.view!.center.x, y: pan.view!.center.y + translation.y)
//                pan.setTranslation(CGPointZero, inView: view)
//            }
//        }
//    }

//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(respondToPanGesture(_:)))
//        panGesture.minimumNumberOfTouches = 1
//        view.addGestureRecognizer(panGesture)

//        _cameraOverlay.getButton(.Shutter).addTarget(self, action: #selector(startVideoCapture), forControlEvents: UIControlEvents.TouchDown)
//        _cameraOverlay.getButton(.Shutter).enabled = false
//        _cameraOverlay.getButton(.Shutter).addTarget(self, action: #selector(stopVideoCapture), forControlEvents: UIControlEvents.TouchUpInside)
