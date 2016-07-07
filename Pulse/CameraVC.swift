//
//  CameraVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseDatabase

class CameraVC: UIViewController, UIGestureRecognizerDelegate {
    let _Camera = CameraManager()
    var _cameraOverlay : CameraOverlayView!
    
    private let videoDuration : Double = 6
    private var countdownTimer : CALayer!
    
    var questionToShow : Question!
    var camDelegate : childVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        _ = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(CameraVC.respondToSwipeGesture(_:)))
        swipeDown.direction = UISwipeGestureRecognizerDirection.Down
        self.view.addGestureRecognizer(swipeDown)
        
        //        zoomPinch.delegate = self
        //        cameraview.userInteractionEnabled = true
        //        cameraview.multipleTouchEnabled = true
        //        cameraview.addGestureRecognizer(zoomPinch)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        _cameraOverlay = CameraOverlayView(frame: UIScreen.mainScreen().bounds)
        
        setupCamera()
        setupCameraOverlay()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
//    func handlePinch(sender: UITapGestureRecognizer? = nil) {
//        print("handle pinch fired")
//    }
    
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if (self.camDelegate != nil) {
            self.camDelegate!.userDismissedCamera(self)
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
                self.camDelegate!.doneRecording(videoURL, currentVC: self, qID: self.questionToShow.qID, location: self._Camera.recordedLocation)
                self._Camera.stopAndRemoveCaptureSession()
                // upload the video
            }
        })
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
    
    func setupCamera() {
        _Camera.showAccessPermissionPopupAutomatically = true
        _Camera.shouldRespondToOrientationChanges = false
        _Camera.cameraDevice = .Front
        self._Camera.addPreviewLayerToView(self.view, newCameraOutputMode: .VideoWithMic)
        
        self._Camera.showErrorBlock = { [weak self] (erTitle: String, erMessage: String) -> Void in
            
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
        _cameraOverlay.getButton(.Shutter).addTarget(self, action: #selector(CameraVC.stopVideoCapture), forControlEvents: UIControlEvents.TouchUpInside)
        
        _cameraOverlay.getButton(.Flip).addTarget(self, action: #selector(CameraVC.flipCamera), forControlEvents: UIControlEvents.TouchUpInside)
        _cameraOverlay.getButton(.Flash).addTarget(self, action: #selector(CameraVC.cycleFlash), forControlEvents: UIControlEvents.TouchUpInside)
    }
}

