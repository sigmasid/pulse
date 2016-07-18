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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let zoomPinch = UIPinchGestureRecognizer()
        zoomPinch.delegate = self
        _Camera.maxRecordingDelegate = self
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(CameraVC.respondToSwipeGesture(_:)))
        swipeDown.direction = UISwipeGestureRecognizerDirection.Down
        self.view.addGestureRecognizer(swipeDown)
        
        self.view.userInteractionEnabled = true
        self.view.multipleTouchEnabled = true
        self.view.addGestureRecognizer(zoomPinch)

//        self.view.hidden = true
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
    
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if (self.childDelegate != nil) {
            self.childDelegate!.userDismissedCamera(self)
        }
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
}

