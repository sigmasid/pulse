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
    let cameraOverlay = CameraOverlayView(frame: UIScreen.mainScreen().bounds)
    private let videoDuration : Double = 6
    private var countdownTimer : CALayer!
    
    var questionToShow : Question!
    var camDelegate : childVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))
        
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(CameraVC.respondToSwipeGesture(_:)))
        swipeDown.direction = UISwipeGestureRecognizerDirection.Down
        self.view.addGestureRecognizer(swipeDown)
        
        //        zoomPinch.delegate = self
        //        cameraview.userInteractionEnabled = true
        //        cameraview.multipleTouchEnabled = true
        //        cameraview.addGestureRecognizer(zoomPinch)
    
        showCamera()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handlePinch(sender: UITapGestureRecognizer? = nil) {
        print("handle pinch fired")
    }
    
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if (self.camDelegate != nil) {
            self.camDelegate!.userDismissedCamera(self)
        }
    }
    
    func startVideoCapture() {
        self.view.layer.addSublayer(cameraOverlay.countdownTimer(videoDuration, size: 20))
        
        _Camera.startRecordingVideo()
    }
    
    func stopVideoCapture() {
        cameraOverlay.stopCountdown()
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
        if (cameraOverlay.flashMode ==  .Off) {
            cameraOverlay.flashMode = .On
            cameraOverlay.updateFlashImage(oldButton, newFlashMode: .On)
        } else {
            cameraOverlay.updateFlashImage(oldButton, newFlashMode: .Off)
            cameraOverlay.flashMode = .Off
        }
    }
    
    func flipCamera() {
        if _Camera.cameraDevice == .Front {
            _Camera.cameraDevice = .Back
        } else {
            _Camera.cameraDevice = .Front
        }
    }
    
    func showCamera() {
        
        _Camera.showAccessPermissionPopupAutomatically = true
        _Camera.shouldRespondToOrientationChanges = false
        _Camera.cameraDevice = .Back
        _Camera.cameraOutputQuality = .High
        
        let takeButton = cameraOverlay.takeButton
        let flipButton = cameraOverlay.flipCamera
        let flashButton = cameraOverlay.flashCamera(.Off)
        let questionBackground = cameraOverlay.questionBackground
        
        
        questionBackground.text = self.questionToShow.qTitle
        
        self.view.addSubview(takeButton)
        self.view.addSubview(flipButton)
        self.view.addSubview(flashButton)
        self.view.addSubview(questionBackground)
        
        takeButton.addTarget(self, action: #selector(CameraVC.startVideoCapture), forControlEvents: UIControlEvents.TouchDown)
        takeButton.addTarget(self, action: #selector(CameraVC.stopVideoCapture), forControlEvents: UIControlEvents.TouchUpInside)
        
        flipButton.addTarget(self, action: #selector(CameraVC.flipCamera), forControlEvents: UIControlEvents.TouchUpInside)
        flashButton.addTarget(self, action: #selector(CameraVC.cycleFlash), forControlEvents: UIControlEvents.TouchUpInside)
        
        self._Camera.addPreviewLayerToView(self.view, newCameraOutputMode: .VideoWithMic)
        
        self._Camera.showErrorBlock = { [weak self] (erTitle: String, erMessage: String) -> Void in
            
            let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alertAction) -> Void in  }))
            
            self?.presentViewController(alertController, animated: true, completion: nil)
        }
    }
}

