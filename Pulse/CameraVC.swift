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
    func didReachMaxRecording(fileURL : NSURL?, image: UIImage?, error : NSError?)
}

class CameraVC: UIViewController, UIGestureRecognizerDelegate, CameraManagerProtocol {
    private let _Camera = CameraManager()
    private var _CameraOverlay : CameraOverlayView!
    private var _loadingOverlay : LoadingView!
    private var _isLoaded = false
    
    /* duration set in milliseconds */
    private let videoDuration : Double = 60
    private var countdownTimer : CALayer!
    
    var questionToShow : Question! //set by delegate
    weak var childDelegate : childVCDelegate?
    
    private var tap : UITapGestureRecognizer!
    private var longTap : UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
            super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        if !_isLoaded {
            let zoomPinch = UIPinchGestureRecognizer()
            zoomPinch.delegate = self
            _Camera.maxRecordingDelegate = self
            
            view.userInteractionEnabled = true
            view.multipleTouchEnabled = true
            view.addGestureRecognizer(zoomPinch)
            
            _CameraOverlay = CameraOverlayView(frame: UIScreen.mainScreen().bounds)
            
            setupLoading()
            setupCamera()
            setupCameraOverlay()
            
            _isLoaded = true
        } else {
            _Camera.resumeCaptureSession()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func takeImage() {
        _Camera.startRecordingVideo()
    }
    
    private func startVideoCapture() {
        _CameraOverlay.countdownTimer(videoDuration / 10) //convert to seconds
        _Camera.startRecordingVideo()
    }
    
    private func stopVideoCapture() {
        _CameraOverlay.stopCountdown()
        _Camera.stopRecordingVideo({ (videoURL, image, error) -> Void in
            if let errorOccured = error {
                self._Camera.showErrorBlock(erTitle: "Error occurred", erMessage: errorOccured.localizedDescription)
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
    
    func didReachMaxRecording(fileURL : NSURL?, image: UIImage?, error : NSError?) {
        if image != nil {
            //it's an image
            _Camera.cameraVideoDuration = videoDuration //reset the duration

            if let errorOccured = error {
                _Camera.showErrorBlock(erTitle: "Error occurred", erMessage: errorOccured.localizedDescription)
            } else {
                childDelegate!.doneRecording(nil, image: image, currentVC: self, location: self._Camera.recordedLocation, assetType: .recordedImage)
                _Camera.stopCaptureSession()
//                _Camera.stopAndRemoveCaptureSession()
            }
        } else {
            //it's a video
            _CameraOverlay.stopCountdown()
            
            if let errorOccured = error {
                _Camera.showErrorBlock(erTitle: "Error occurred", erMessage: errorOccured.localizedDescription)
            } else {
                childDelegate!.doneRecording(fileURL, image: nil, currentVC: self, location: self._Camera.recordedLocation, assetType: .recordedVideo)
                _Camera.stopCaptureSession()
//                _Camera.stopAndRemoveCaptureSession()
            }
        }
    }
    
    func cycleFlash(oldButton : UIButton) {
        _Camera.changeFlashMode()
        
        switch _Camera.flashMode {
        case .Off: _CameraOverlay._flashMode =  .Off
        case .On: _CameraOverlay._flashMode = .On
        case .Auto: _CameraOverlay._flashMode = .Auto
        }
    }
    
    func flipCamera() {
        if _Camera.cameraDevice == .Front {
            _Camera.cameraDevice = .Back
        } else {
            _Camera.cameraDevice = .Front
        }
    }
    
    private func setupLoading() {
        _loadingOverlay = LoadingView(frame: view.bounds, backgroundColor : UIColor.blackColor())
        view.addSubview(_loadingOverlay)
    }
    
    private func setupCamera() {
        _Camera.showAccessPermissionPopupAutomatically = true
        _Camera.shouldRespondToOrientationChanges = false
        _Camera.cameraDevice = .Front
        _Camera.cameraVideoDuration = videoDuration

        _Camera.addPreviewLayerToView(view, newCameraOutputMode: .VideoWithMic, completition: {() in
            dispatch_async(dispatch_get_main_queue()) {
                UIView.animateWithDuration(0.2, animations: { self._loadingOverlay.alpha = 0.0 } ,
                    completion: {(value: Bool) in
                        self._loadingOverlay.removeFromSuperview()
                })
                self.tap.enabled = true //enables tap when camera is ready
                self.longTap.enabled = true
            }
        })
        
        _Camera.showErrorBlock = { [weak self] (erTitle: String, erMessage: String) -> Void in
            
            let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alertAction) -> Void in  }))
            
            self?.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    private func setupCameraOverlay() {
        view.addSubview(_CameraOverlay)
        _CameraOverlay.updateQuestion(self.questionToShow.qTitle!)
        
        switch _Camera.flashMode {
        case .Off: _CameraOverlay._flashMode =  .Off
        case .On: _CameraOverlay._flashMode = .On
        case .Auto: _CameraOverlay._flashMode = .Auto
        }
        
        tap = UITapGestureRecognizer(target: self, action: #selector(respondToShutterTap))
        _CameraOverlay.getButton(.Shutter).addGestureRecognizer(tap)
        tap.enabled = false
        
        longTap = UILongPressGestureRecognizer(target: self, action: #selector(respondToShutterLongTap))
        longTap.minimumPressDuration = 0.3
        _CameraOverlay.getButton(.Shutter).addGestureRecognizer(longTap)
        longTap.enabled = false
        
        _CameraOverlay.getButton(.Flip).addTarget(self, action: #selector(flipCamera), forControlEvents: UIControlEvents.TouchUpInside)
        _CameraOverlay.getButton(.Flash).addTarget(self, action: #selector(cycleFlash), forControlEvents: UIControlEvents.TouchUpInside)
        _CameraOverlay.getButton(.Album).addTarget(self, action: #selector(showAlbumPicker), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    func respondToShutterTap() {
        _Camera.cameraVideoDuration = 0.1
        takeImage()
    }
    
    func respondToShutterLongTap(longPress : UILongPressGestureRecognizer) {
        if longPress.state == .Began {
            startVideoCapture()
        } else if longPress.state == .Ended {
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
