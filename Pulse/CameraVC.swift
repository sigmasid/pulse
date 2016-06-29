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
    let aCamera = CameraManager()
    let cameraOverlay = CameraOverlayView(frame: UIScreen.mainScreen().bounds)
    private let videoDuration : Double = 6
    private var countdownTimer : CALayer!
    
    var questionToShow : Question!
    var camDelegate : childVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        cameraview.frame = UIScreen.mainScreen().bounds
        //        self.view.addSubview(cameraview)
        
        let zoomPinch = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))
        
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(CameraVC.respondToSwipeGesture(_:)))
        swipeDown.direction = UISwipeGestureRecognizerDirection.Down
        self.view.addGestureRecognizer(swipeDown)
        
        //        zoomPinch.delegate = self
        //        cameraview.userInteractionEnabled = true
        //        cameraview.multipleTouchEnabled = true
        //        cameraview.addGestureRecognizer(zoomPinch)
        
        if (aCamera.currentCameraStatus() == .Ready) {
            aCamera.shouldRespondToOrientationChanges = false
            aCamera.cameraDevice = .Back
            aCamera.cameraOutputQuality = .High
            
            showCamera()
        }
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
        print("started recording")
        self.view.layer.addSublayer(cameraOverlay.countdownTimer(videoDuration, size: 20))
        
        aCamera.startRecordingVideo()
    }
    
    func stopVideoCapture() {
        print("stopped recording")
        cameraOverlay.stopCountdown()
        aCamera.stopRecordingVideo({ (videoURL, error) -> Void in
            if let errorOccured = error {
                self.aCamera.showErrorBlock(erTitle: "Error occurred", erMessage: errorOccured.localizedDescription)
            } else {
                self.camDelegate!.doneRecording(videoURL, currentVC: self, qID: self.questionToShow.qID, location: self.aCamera.recordedLocation)
                self.aCamera.stopAndRemoveCaptureSession()
                // upload the video
            }
        })
    }
    
    func cycleFlash(oldButton : UIButton) {
        aCamera.changeFlashMode()
        if (cameraOverlay.flashMode ==  .Off) {
            cameraOverlay.flashMode = .On
            cameraOverlay.updateFlashImage(oldButton, newFlashMode: .On)
        } else {
            cameraOverlay.updateFlashImage(oldButton, newFlashMode: .Off)
            cameraOverlay.flashMode = .Off
        }
    }
    
    func flipCamera() {
        if aCamera.cameraDevice == .Front {
            aCamera.cameraDevice = .Back
        } else {
            aCamera.cameraDevice = .Front
        }
    }
    
    func showCamera() {
        
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
        
        self.aCamera.addPreviewLayerToView(self.view, newCameraOutputMode: .VideoWithMic)
        
        self.aCamera.showErrorBlock = { [weak self] (erTitle: String, erMessage: String) -> Void in
            
            let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alertAction) -> Void in  }))
            
            self?.presentViewController(alertController, animated: true, completion: nil)
        }
    }
}

