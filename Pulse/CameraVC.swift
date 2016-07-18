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
    func didReachMaxRecording(fileURL : NSURL?, error : NSError?)
}

class CameraVC: UIViewController, UIGestureRecognizerDelegate, CameraManagerProtocol {
    private let _Camera = CameraManager()
    private var _cameraOverlay : CameraOverlayView!
    private var _loadingOverlay : UIView!
    
    private let videoDuration : Double = 6
    private var countdownTimer : CALayer!
    
    var questionToShow : Question!
    weak var childDelegate : childVCDelegate?
    
    private var panStartingPointX : CGFloat = 0
    private var panStartingPointY : CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let zoomPinch = UIPinchGestureRecognizer()
        zoomPinch.delegate = self
        _Camera.maxRecordingDelegate = self
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(CameraVC.respondToPanGesture(_:)))
        panGesture.minimumNumberOfTouches = 1

        self.view.addGestureRecognizer(panGesture)
        
        self.view.userInteractionEnabled = true
        self.view.multipleTouchEnabled = true
        self.view.addGestureRecognizer(zoomPinch)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        _cameraOverlay = CameraOverlayView(frame: UIScreen.mainScreen().bounds)
        
        setupCamera()
        setupLoading()
        setupCameraOverlay()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    func startVideoCapture() {
        _cameraOverlay.countdownTimer(videoDuration)
        _Camera.startRecordingVideo()
    }
    
    func stopVideoCapture() {
        _cameraOverlay.stopCountdown()
        _Camera.stopRecordingVideo({ (videoURL, error) -> Void in
            if let errorOccured = error {
                self._Camera.showErrorBlock(erTitle: "Error occurred", erMessage: errorOccured.localizedDescription)
            } else {
                self.childDelegate!.doneRecording(videoURL, currentVC: self, qID: self.questionToShow.qID, location: self._Camera.recordedLocation)
                self._Camera.stopAndRemoveCaptureSession()
            }
        })
    }
    
    func didReachMaxRecording(fileURL : NSURL?, error : NSError?) {
        _cameraOverlay.stopCountdown()
        
        if let errorOccured = error {
            self._Camera.showErrorBlock(erTitle: "Error occurred", erMessage: errorOccured.localizedDescription)
        } else {
            self.childDelegate!.doneRecording(fileURL, currentVC: self, qID: self.questionToShow.qID, location: self._Camera.recordedLocation)
            self._Camera.stopAndRemoveCaptureSession()
        }
    }
    
    func cycleFlash(oldButton : UIButton) {
        _Camera.changeFlashMode()
        
        switch _Camera.flashMode {
        case .Off: _cameraOverlay._flashMode =  .Off
        case .On: _cameraOverlay._flashMode = .On
        case .Auto: _cameraOverlay._flashMode = .Auto
        }
    }
    
    func flipCamera() {
        if _Camera.cameraDevice == .Front {
            _Camera.cameraDevice = .Back
        } else {
            _Camera.cameraDevice = .Front
        }
    }
    
    func setupLoading() {
        _loadingOverlay = UIView(frame: self.view.bounds)
        _loadingOverlay.backgroundColor = UIColor.blackColor()
        view.addSubview(_loadingOverlay)
    }
    
    func setupCamera() {
        _Camera.showAccessPermissionPopupAutomatically = true
        _Camera.shouldRespondToOrientationChanges = false
        _Camera.cameraDevice = .Front
        _Camera.cameraVideoDuration = videoDuration
        

        _Camera.addPreviewLayerToView(self.view, newCameraOutputMode: .VideoWithMic, completition: {() in
            dispatch_async(dispatch_get_main_queue()) {
                UIView.animateWithDuration(0.2, animations: { self._loadingOverlay.alpha = 0.0 } ,
                    completion: {(value: Bool) in
                        self._loadingOverlay.removeFromSuperview()
                })
                self._cameraOverlay.getButton(.Shutter).enabled = true
            }
        })
        
        _Camera.showErrorBlock = { [weak self] (erTitle: String, erMessage: String) -> Void in
            
            let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alertAction) -> Void in  }))
            
            self?.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func setupCameraOverlay() {
        self.view.addSubview(_cameraOverlay)
        _cameraOverlay.updateQuestion(self.questionToShow.qTitle!)
        
        switch _Camera.flashMode {
        case .Off: _cameraOverlay._flashMode =  .Off
        case .On: _cameraOverlay._flashMode = .On
        case .Auto: _cameraOverlay._flashMode = .Auto
        }
        
        _cameraOverlay.getButton(.Shutter).addTarget(self, action: #selector(CameraVC.startVideoCapture), forControlEvents: UIControlEvents.TouchDown)
        _cameraOverlay.getButton(.Shutter).enabled = false
        _cameraOverlay.getButton(.Shutter).addTarget(self, action: #selector(CameraVC.stopVideoCapture), forControlEvents: UIControlEvents.TouchUpInside)
        
        _cameraOverlay.getButton(.Flip).addTarget(self, action: #selector(CameraVC.flipCamera), forControlEvents: UIControlEvents.TouchUpInside)
        _cameraOverlay.getButton(.Flash).addTarget(self, action: #selector(CameraVC.cycleFlash), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    func respondToPanGesture(pan: UIPanGestureRecognizer) {
        let panCurrentPointX = pan.view!.center.x
        let panCurrentPointY = pan.view!.center.y
        
        if (pan.state == UIGestureRecognizerState.Began) {
            panStartingPointX = pan.view!.center.x
            panStartingPointY = pan.view!.center.y
        }
        else if (pan.state == UIGestureRecognizerState.Ended) {
            print("current pan point y is \(panCurrentPointY)")
            switch panCurrentPointY {
            case _ where panCurrentPointY > panStartingPointY + (self.view.bounds.height / 3) :
                if (self.childDelegate != nil) {
                    self.childDelegate!.userDismissedCamera(self)
                }
                pan.setTranslation(CGPointZero, inView: self.view)
                self.view.center = CGPoint(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2)
            default:
                self.view.center = CGPoint(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2)
                pan.setTranslation(CGPointZero, inView: self.view)
            }
        } else {
            let translation = pan.translationInView(self.view)
            if translation.y > 20 { ///only allow vertical pulldown
                self.view.center = CGPoint(x: pan.view!.center.x, y: pan.view!.center.y + translation.y)
                pan.setTranslation(CGPointZero, inView: self.view)
            }
        }
    }
}

