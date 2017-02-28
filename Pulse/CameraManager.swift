//
//  CameraManager.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import ImageIO
import MobileCoreServices
import Photos
import CoreLocation

public enum CameraState {
    case ready, accessDenied, noDeviceFound, notDetermined
}

public enum CameraDevice {
    case front, back
}

public enum CameraFlashMode: Int {
    case off, on, auto
}

public enum CameraOutputMode {
    case stillImage, videoWithMic, videoOnly
}

public enum CameraOutputQuality: Int {
    case low, medium, high
}

/// Class for handling iDevices custom camera usage
open class CameraManager: NSObject, AVCaptureFileOutputRecordingDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate, AVCapturePhotoCaptureDelegate {
    
    
    var maxRecordingDelegate : CameraManagerProtocol!
    // MARK: - Public properties
    
    /// Capture session to customize camera settings.
    open var captureSession: AVCaptureSession?
    
    /// Property to determine if the manager should show the error for the user. If you want to show the errors yourself set this to false. If you want to add custom error UI set showErrorBlock property. Default value is false.
    open var showErrorsToUsers = true
    
    /// Property to determine if the manager should show the camera permission popup immediatly when it's needed or you want to show it manually. Default value is true. Be carful cause using the camera requires permission, if you set this value to false and don't ask manually you won't be able to use the camera.
    open var showAccessPermissionPopupAutomatically = true
    
    /// A block creating UI to present error message to the user. This can be customised to be presented on the Window root view controller, or to pass in the viewController which will present the UIAlertController, for example.
    open var showErrorBlock:(_ erTitle: String, _ erMessage: String) -> Void = { (erTitle: String, erMessage: String) -> Void in
        
        //        var alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .Alert)
        //        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alertAction) -> Void in  }))
        //
        //        if let topController = UIApplication.sharedApplication().keyWindow?.rootViewController {
        //            topController.presentViewController(alertController, animated: true, completion:nil)
        //        }
    }
    
    /// Property to determine if manager should write the resources to the phone library. Default value is false.
    open var writeFilesToPhoneLibrary = false
    
    /// Property to determine if manager should follow device orientation. Default value is true.
    open var shouldRespondToOrientationChanges = true {
        didSet {
            if shouldRespondToOrientationChanges {
                _startFollowingDeviceOrientation()
            } else {
                _stopFollowingDeviceOrientation()
            }
        }
    }
    
    open var shouldKeepViewAtOrientationChanges = false

    
    /// The Bool property to determine if the camera is ready to use.
    open var cameraIsReady: Bool {
        get {
            return cameraIsSetup
        }
    }
    
    /// The Bool property to determine if current device has front camera.
    open var hasFrontCamera: Bool = {
        if let _ = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
            return true
        }

        return false
    }()
    
    /// The Bool property to determine if current device has flash.
    open var hasFlash: Bool = {
        if let deviceDescoverySession = AVCaptureDeviceDiscoverySession.init(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera],
                                                                             mediaType: AVMediaTypeVideo,
                                                                             position: AVCaptureDevicePosition.unspecified) {
            
            for device in deviceDescoverySession.devices {
                if (device.position == .back) {
                    return true
                }
            }
        }
        return false
    }()
    
    /// Property to enable or disable switch animation
    open var animateCameraDeviceChange: Bool = true
    
    /// Property to change camera device between front and back.
    open var cameraDevice = CameraDevice.back {
        didSet {
            if cameraIsSetup {
                if cameraDevice != oldValue {
                    _updateCameraDevice(cameraDevice)
                    _setupMaxZoomScale()
                    _zoom(0)
                }
            }
        }
    }
    
    /// Property to change camera flash mode.
    open var flashMode = CameraFlashMode.off {
        didSet {
            if cameraIsSetup {
                if flashMode != oldValue {
                    _updateFlasMode(flashMode)
                }
            }
        }
    }
    /// Property to change video duration.
    open var cameraVideoDuration : Double = 60 {
        didSet {
            if cameraIsSetup {
                _updateMaxDuration(cameraVideoDuration)
            }
        }
    }
    
    /// Property to change camera output quality.
    open var cameraOutputQuality = CameraOutputQuality.high {
        didSet {
            if cameraIsSetup {
                if cameraOutputQuality != oldValue {
                    _updateCameraQualityMode(cameraOutputQuality)
                }
            }
        }
    }
    
    /// Property to change camera output.
    open var cameraOutputMode = CameraOutputMode.stillImage {
        didSet {
            if cameraIsSetup {
                if cameraOutputMode != oldValue {
                    _setupOutputMode(cameraOutputMode, oldCameraOutputMode: oldValue)
                }
                _setupMaxZoomScale()
                _zoom(0)
            }
        }
    }
    
    fileprivate var locationManager = CameraLocationManager()
    
    /// Property to check video recording duration when in progress
    open var recordedDuration : CMTime { return movieOutput?.recordedDuration ?? kCMTimeZero }
    
    /// Property to check video recording file size when in progress
    open var recordedFileSize : Int64 { return movieOutput?.recordedFileSize ?? 0 }
    
    open var location : CLLocation? { return self.locationManager.latestLocation }
    
    func cameraWithPosition(_ position: AVCaptureDevicePosition?) -> AVCaptureDevice?
    {
        if let deviceDescoverySession = AVCaptureDeviceDiscoverySession.init(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera],
                                                                             mediaType: AVMediaTypeVideo,
                                                                             position: AVCaptureDevicePosition.unspecified) {
            
            if let position = position {
                for device in deviceDescoverySession.devices {
                    if device.position == position {
                        return device
                    }
                }
            }
            
            return deviceDescoverySession.devices.first

        }
        
        return nil
    }
    
    
    // MARK: - Private properties
    fileprivate var _didReachMaxRecording = false

    fileprivate weak var embeddingView: UIView?
    fileprivate var videoCompletition: ((_ videoURL: URL?, _ image: UIImage?, _ error: NSError?) -> Void)?
    
    fileprivate var sessionQueue: DispatchQueue = DispatchQueue(label: "CameraSessionQueue", attributes: [])
    
    fileprivate lazy var frontCameraDevice: AVCaptureDevice? = {
        if let device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
            return device
        }
        return nil
    }()
    
    fileprivate lazy var backCameraDevice: AVCaptureDevice? = {
        if let device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back) {
            return device
        }
        return nil
    }()
    
    fileprivate lazy var mic: AVCaptureDevice? = {
        return AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
    }()
    
    fileprivate var stillImageOutput: AVCapturePhotoOutput?
    fileprivate var movieOutput: AVCaptureMovieFileOutput?
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    fileprivate var library: PHPhotoLibrary?
    
    fileprivate var cameraIsSetup = false
    fileprivate var cameraIsObservingDeviceOrientation = false
    
    fileprivate var zoomScale       = CGFloat(1.0)
    fileprivate var beginZoomScale  = CGFloat(1.0)
    fileprivate var maxZoomScale    = CGFloat(1.0)
    
    fileprivate var tempFilePath: URL = {
        let tempPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempMovie").appendingPathExtension("mp4").absoluteString
        if FileManager.default.fileExists(atPath: tempPath) {
            do {
                try FileManager.default.removeItem(atPath: tempPath)
            } catch { }
        }
        return URL(string: tempPath)!
    }()
    
    
    // MARK: - CameraManager
    
    /**
     Inits a capture session and adds a preview layer to the given view. Preview layer bounds will automaticaly be set to match given view. Default session is initialized with still image output.
     
     :param: view The view you want to add the preview layer to
     :param: cameraOutputMode The mode you want capturesession to run image / video / video and microphone
     :param: completition Optional completition block
     
     :returns: Current state of the camera: Ready / AccessDenied / NoDeviceFound / NotDetermined.
     */
    open func addPreviewLayerToView(_ view: UIView) -> CameraState {
        return addPreviewLayerToView(view, newCameraOutputMode: cameraOutputMode)
    }
    open func addPreviewLayerToView(_ view: UIView, newCameraOutputMode: CameraOutputMode) -> CameraState {
        return addPreviewLayerToView(view, newCameraOutputMode: newCameraOutputMode, completition: nil)
    }
    open func addPreviewLayerToView(_ view: UIView, newCameraOutputMode: CameraOutputMode, completition: ((Void) -> Void)?) -> CameraState {
        if _canLoadCamera() {
            if let _ = embeddingView {
                if let validPreviewLayer = previewLayer {
                    validPreviewLayer.removeFromSuperlayer()
                }
            }
            if cameraIsSetup {
                _addPreviewLayerToView(view)
                cameraOutputMode = newCameraOutputMode
                if let validCompletition = completition {
                    validCompletition()
                }
            } else {
                _setupCamera({ Void -> Void in
                    self._addPreviewLayerToView(view)
                    self.cameraOutputMode = newCameraOutputMode
                    if let validCompletition = completition {
                        validCompletition()
                    }
                })
            }
        }
        return _checkIfCameraIsAvailable()
    }
    
    /**
     Asks the user for camera permissions. Only works if the permissions are not yet determined. Note that it'll also automaticaly ask about the microphone permissions if you selected VideoWithMic output.
     
     :param: completition Completition block with the result of permission request
     */
    open func askUserForCameraPermissions(_ completition: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (alowedAccess) -> Void in
            if self.cameraOutputMode == .videoWithMic {
                AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio, completionHandler: { (alowedAccess) -> Void in
                    DispatchQueue.main.sync(execute: { () -> Void in
                        completition(alowedAccess)
                    })
                })
            } else {
                DispatchQueue.main.sync(execute: { () -> Void in
                    completition(alowedAccess)
                })
                
            }
        })
        
    }
    
    /**
     Stops running capture session but all setup devices, inputs and outputs stay for further reuse.
     */
    open func stopCaptureSession() {
        captureSession?.stopRunning()
        _stopFollowingDeviceOrientation()
    }
    
    /**
     Resumes capture session.
     */
    open func resumeCaptureSession() {
        if let validCaptureSession = captureSession {
            if !validCaptureSession.isRunning && cameraIsSetup {
                validCaptureSession.startRunning()
                _startFollowingDeviceOrientation()
            }
        } else {
            if _canLoadCamera() {
                if cameraIsSetup {
                    stopAndRemoveCaptureSession()
                }
                _setupCamera({Void -> Void in
                    if let validEmbeddingView = self.embeddingView {
                        self._addPreviewLayerToView(validEmbeddingView)
                    }
                    self._startFollowingDeviceOrientation()
                })
            }
        }
    }
    
    /**
     Stops running capture session and removes all setup devices, inputs and outputs.
     */
    open func stopAndRemoveCaptureSession() {
        stopCaptureSession()
        cameraDevice = .back
        cameraIsSetup = false
        previewLayer = nil
        captureSession = nil
        frontCameraDevice = nil
        backCameraDevice = nil
        mic = nil
        stillImageOutput = nil
        movieOutput = nil
    }
    
    fileprivate func _performShutterAnimation(_ completion: (() -> Void)?) {
        
        if let validPreviewLayer = previewLayer {
            
            DispatchQueue.main.async {
                
                let duration = 0.1
                
                CATransaction.begin()
                
                if let completion = completion {
                    
                    CATransaction.setCompletionBlock(completion)
                }
                
                let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
                fadeOutAnimation.fromValue = 1.0
                fadeOutAnimation.toValue = 0.0
                validPreviewLayer.add(fadeOutAnimation, forKey: "opacity")
                
                let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
                fadeInAnimation.fromValue = 0.0
                fadeInAnimation.toValue = 1.0
                fadeInAnimation.beginTime = CACurrentMediaTime() + duration * 2.0
                validPreviewLayer.add(fadeInAnimation, forKey: "opacity")
                
                CATransaction.commit()
            }
        }
    }
    
    /**
     Captures still image from currently running capture session.
     
     :param: imageCompletition Completition block containing the captured UIImage
     */
    open func capturePictureWithCompletition(_ imageCompletion: @escaping (UIImage?, NSError?) -> Void) {
        self.capturePhoto { data, error in
            
            guard error == nil, let imageData = data else {
                imageCompletion(nil, error)
                return
            }
            
            self._performShutterAnimation() {
                if self.writeFilesToPhoneLibrary == true, let library = self.library  {
                    var flippedImage = UIImage(data: imageData)!
                    if self.cameraDevice == .front {
                        flippedImage = UIImage(cgImage: flippedImage.cgImage!, scale: (flippedImage.scale), orientation:.rightMirrored)
                    }
                    
                    library.performChanges({
                        let request = PHAssetChangeRequest.creationRequestForAsset(from: flippedImage)
                        request.creationDate = Date()
                        
                        if let location = self.locationManager.latestLocation {
                            request.location = location
                        }
                    }, completionHandler: { success, error in
                        guard error != nil else {
                            return
                        }
                        
                        DispatchQueue.main.async(execute: {
                            self._show(NSLocalizedString("Error", comment:""), message: (error?.localizedDescription)!)
                        })
                    })
                }
                imageCompletion(UIImage(data: imageData), nil)
            }
            
        }
        
    }
    
    /**
     Captures still image from currently running video session
     
     :param: imageCompletition Completition block containing the captured imageData
     */
    open func capturePictureDataFromVideoWithCompletition(_ videoURL: URL, imageCompletion: (UIImage?, NSError?) -> Void) {
        
        let urlAsset = AVURLAsset(url: videoURL, options: nil)
        
        if cameraDevice == .front {
            let imageData = thumbnailForVideoAtURL(urlAsset, orientation: .leftMirrored)
            imageCompletion(imageData, nil)

        } else {
            let imageData = thumbnailForVideoAtURL(urlAsset, orientation: .right)
            imageCompletion(imageData, nil)
        }
        
    }

    
    /**
     Captures still image from currently running capture session.
     
     :param: imageCompletition Completition block containing the captured imageData
     */
    
    private var inProgressPhotoCaptureDelegates = [Int64 : PhotoCaptureDelegate]()

    private var inProgressLivePhotoCapturesCount = 0

    private func capturePhoto(_ imageCompletion: @escaping (Data?, NSError?) -> Void) {
        
        guard cameraIsSetup else {
            _show(NSLocalizedString("No capture session setup", comment:""), message: NSLocalizedString("I can't take any pictures", comment:""))
            return
        }
        
        guard cameraOutputMode == .stillImage else {
            _show(NSLocalizedString("Capture session output mode video", comment:""), message: NSLocalizedString("I can't take any pictures", comment:""))
            return
        }
        
        sessionQueue.async(execute: {
            
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto
            settings.isHighResolutionPhotoEnabled = true
            
            if settings.availablePreviewPhotoPixelFormatTypes.count > 0 {
                settings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String : settings.availablePreviewPhotoPixelFormatTypes.first!]
            }
            
            self._getStillImageOutput().capturePhoto(with: settings, delegate: self)
            
        })
        
        /*
         Retrieve the video preview layer's video orientation on the main queue before
         entering the session queue. We do this to ensure UI elements are accessed on
         the main thread and session configuration is done on the session queue.
         */
        let videoPreviewLayerOrientation = previewLayer?.connection.videoOrientation
        
        sessionQueue.async {
            // Update the photo output's connection to match the video orientation of the video preview layer.
            if let photoOutputConnection = self._getStillImageOutput().connection(withMediaType: AVMediaTypeVideo) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            
            // Capture a JPEG photo with flash set to auto and high resolution photo enabled.
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.flashMode = .auto
            photoSettings.isHighResolutionPhotoEnabled = true
            if photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String : photoSettings.availablePreviewPhotoPixelFormatTypes.first!]
            }
            
            // Use a separate object for the photo capture delegate to isolate each capture life cycle.
            let photoCaptureDelegate = PhotoCaptureDelegate(with: photoSettings, willCapturePhotoAnimation: {
                DispatchQueue.main.async { [unowned self] in
                    self.previewLayer?.opacity = 0
                    UIView.animate(withDuration: 0.25) { [unowned self] in
                        self.previewLayer?.opacity = 1
                    }
                }
            }, capturingLivePhoto: { capturing in
                /*
                 Because Live Photo captures can overlap, we need to keep track of the
                 number of in progress Live Photo captures to ensure that the
                 Live Photo label stays visible during these captures.
                 */

            }, completed: { [unowned self] photoCaptureDelegate, photoData in
                // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                self.sessionQueue.async { [unowned self] in
                    self.inProgressPhotoCaptureDelegates[photoCaptureDelegate.requestedPhotoSettings.uniqueID] = nil
                }
                
                imageCompletion(photoData, nil)
                }
            )
            
            /*
             The Photo Output keeps a weak reference to the photo capture delegate so
             we store it in an array to maintain a strong reference to this object
             until the capture is completed.
             */
            self.inProgressPhotoCaptureDelegates[photoCaptureDelegate.requestedPhotoSettings.uniqueID] = photoCaptureDelegate
            self._getStillImageOutput().capturePhoto(with: photoSettings, delegate: photoCaptureDelegate)
        }
    }
    
    /**
     Starts recording a video with or without voice as in the session preset.
     */
    open func startRecordingVideo() {
        if cameraOutputMode != .stillImage {
            _getMovieOutput().startRecording(toOutputFileURL: tempFilePath, recordingDelegate: self)
        } else {
            _show(NSLocalizedString("Capture session output still image", comment:""), message: NSLocalizedString("I can only take pictures", comment:""))
        }
    }
    
    /**
     Stop recording a video. Save it to the cameraRoll and give back the url.
     */
    open func stopRecordingVideo(_ completion:@escaping (_ videoURL: URL?, _ image: UIImage?, _ error: NSError?) -> Void) {
        if let runningMovieOutput = movieOutput {
            if runningMovieOutput.isRecording {
                videoCompletition = completion
                runningMovieOutput.stopRecording()
            }
        }
    }
    
    /**
    Max time reached.
    */
    
    /**
     Current camera status.
     
     :returns: Current state of the camera: Ready / AccessDenied / NoDeviceFound / NotDetermined
     */
    open func currentCameraStatus() -> CameraState {
        return _checkIfCameraIsAvailable()
    }
    
    /**
     Change current flash mode to next value from available ones.
     
     :returns: Current flash mode: Off / On / Auto
     */
    open func changeFlashMode() -> CameraFlashMode {
        flashMode = CameraFlashMode(rawValue: (flashMode.rawValue+1)%3)!
        return flashMode
    }
    
    /**
     Change current output quality mode to next value from available ones.
     
     :returns: Current quality mode: Low / Medium / High
     */
    open func changeQualityMode() -> CameraOutputQuality {
        cameraOutputQuality = CameraOutputQuality(rawValue: (cameraOutputQuality.rawValue+1)%3)!
        return cameraOutputQuality
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    
    open func capture(_: AVCaptureFileOutput!, didStartRecordingToOutputFileAt: URL!, fromConnections: [Any]!) {
        captureSession?.beginConfiguration()
        if flashMode != .off {
            _updateTorch(flashMode)
        }
        captureSession?.commitConfiguration()
    }
    
    open func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        _updateTorch(.off)
        if (error != nil) {
            if ((error as NSError).code == AVError.Code.maximumDurationReached.rawValue) {
                //if it reaches max recording - we have to deal with the error
                _didReachMaxRecording = true
                
                if writeFilesToPhoneLibrary {
                    _saveVideoToAlbum(outputFileURL, completionBlock: { (assetURL: URL?, error: NSError?) -> Void in
                        if (error != nil) {
                            self._show(NSLocalizedString("Unable to save video to the iPhone.", comment:""), message: error!.localizedDescription)
                            self._executeVideoCompletitionWithURL(nil, blockError: error)
                        } else {
                            if let validAssetURL = assetURL {
                                self._executeVideoCompletitionWithURL(validAssetURL, blockError: error)
                            }
                        }
                    })
                } else {
                    _executeVideoCompletitionWithURL(outputFileURL, blockError: nil)
                }
            } else {
                _executeVideoCompletitionWithURL(outputFileURL, blockError: error as NSError?)
                _show(NSLocalizedString("Unable to save video to the phone", comment:""), message: error.localizedDescription)
            }
        } else {
            if writeFilesToPhoneLibrary {
                _saveVideoToAlbum(outputFileURL, completionBlock: { (assetURL: URL?, error: NSError?) -> Void in
                    if (error != nil) {
                        self._show(NSLocalizedString("Unable to save video to the iPhone.", comment:""), message: error!.localizedDescription)
                        self._executeVideoCompletitionWithURL(nil, blockError: error)
                    } else {
                        if let validAssetURL = assetURL {
                            self._executeVideoCompletitionWithURL(validAssetURL, blockError: error)
                        }
                    }
                })
            } else {
                _executeVideoCompletitionWithURL(outputFileURL, blockError: error as NSError?)
//                    _saveVideoToAlbum(outputFileURL, error: error)
            }
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    fileprivate func attachZoom(_ view: UIView) {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(CameraManager._zoomStart(_:)))
        view.addGestureRecognizer(pinch)
        pinch.delegate = self
    }
    
    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) {
            beginZoomScale = zoomScale
        }
        
        return true
    }
    
    @objc
    fileprivate func _zoomStart(_ recognizer: UIPinchGestureRecognizer) {
        guard let view = embeddingView,
            let previewLayer = previewLayer
            else { return }
        
        var allTouchesOnPreviewLayer = true
        let numTouch = recognizer.numberOfTouches
        
        for i in 0 ..< numTouch {
            let location = recognizer.location(ofTouch: i, in: view)
            let convertedTouch = previewLayer.convert(location, from: previewLayer.superlayer)
            if !previewLayer.contains(convertedTouch) {
                allTouchesOnPreviewLayer = false
                break
            }
        }
        if allTouchesOnPreviewLayer {
            _zoom(recognizer.scale)
        }
    }
    
    /// set the max video duration to specified duration in milliseconds
    fileprivate func _updateMaxDuration(_ duration: Double) {
        let preferredTimeScale : Int32 = 600
        movieOutput?.maxRecordedDuration = CMTimeMakeWithSeconds(duration / 10, preferredTimeScale)
    }
    
    fileprivate func _zoom(_ scale: CGFloat) {
        do {
            let captureDevice = cameraWithPosition(nil)
            
            try captureDevice?.lockForConfiguration()
            
            zoomScale = max(1.0, min(beginZoomScale * scale, maxZoomScale))
            
            captureDevice!.videoZoomFactor = zoomScale
            
            captureDevice?.unlockForConfiguration()
            
        } catch {
            //print("Error locking configuration")
        }
    }
    
    // MARK: - CameraManager()
    
    fileprivate func _updateTorch(_ flashMode: CameraFlashMode) {
        captureSession?.beginConfiguration()
        
        if let deviceDescoverySession = AVCaptureDeviceDiscoverySession.init(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera],
                                                                             mediaType: AVMediaTypeVideo,
                                                                             position: AVCaptureDevicePosition.unspecified) {
            
            for device in deviceDescoverySession.devices {
                if (device.position == AVCaptureDevicePosition.back) {
                    let avTorchMode = AVCaptureTorchMode(rawValue: flashMode.rawValue)
                    if (device.isTorchModeSupported(avTorchMode!)) {
                        do {
                            try device.lockForConfiguration()
                        } catch {
                            return;
                        }
                        device.torchMode = avTorchMode!
                        device.unlockForConfiguration()
                    }
                }
            }
        }
        
        captureSession?.commitConfiguration()
    }
    
    fileprivate func _executeVideoCompletitionWithURL(_ url: URL?, blockError: NSError?) {
        if let validCompletition = videoCompletition {

            if let _duration = movieOutput?.recordedDuration.seconds {

                if _duration > 0.5 {
                    validCompletition(url, nil, blockError)
                    self.videoCompletition = nil
                } else {
                    if let url = url {
                        capturePictureDataFromVideoWithCompletition(url, imageCompletion: {(image, blockError) in
                            validCompletition(nil, image, blockError)
                            self.videoCompletition = nil
                        })
                    }
                }
            }
        } else if _didReachMaxRecording {
            if let _duration = movieOutput?.recordedDuration.seconds {

                if _duration > 0.5 {
                    maxRecordingDelegate.didReachMaxRecording(url, image: nil, error: blockError)
                } else {
                    if let url = url {
                        capturePictureDataFromVideoWithCompletition(url, imageCompletion: {(image, blockError) in
                            if self._didReachMaxRecording {
                                self.maxRecordingDelegate.didReachMaxRecording(nil, image: image, error: blockError)
                            }
                        })
                    }
                }
            }
        }
    }
    
    fileprivate func _saveVideoToAlbum(_ url: URL?, completionBlock: @escaping (_ assetURL: URL?, _ error: NSError?) -> Void) {
        let _ = PHPhotoLibrary.shared().performChanges({
            let _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url!)
            }, completionHandler: { success, error in
                if success {
                    completionBlock(url, nil)
                } else {
                    completionBlock(nil, error as NSError?)
                }
        })
    }
    
    fileprivate func _getMovieOutput() -> AVCaptureMovieFileOutput {
        var shouldReinitializeMovieOutput = movieOutput == nil
        
        if !shouldReinitializeMovieOutput {
            if let connection = movieOutput!.connection(withMediaType: AVMediaTypeVideo) {
                shouldReinitializeMovieOutput = shouldReinitializeMovieOutput || !connection.isActive
            }
        }
        
        if shouldReinitializeMovieOutput {
            movieOutput = AVCaptureMovieFileOutput()
            movieOutput!.movieFragmentInterval = kCMTimeInvalid
            
            captureSession?.beginConfiguration()
            captureSession?.addOutput(movieOutput)
            captureSession?.commitConfiguration()
        }
        return movieOutput!
        
    }
    
    
    fileprivate func _getStillImageOutput() -> AVCapturePhotoOutput {
        var shouldReinitializeStillImageOutput = stillImageOutput == nil
        
        if !shouldReinitializeStillImageOutput {
            if let connection = stillImageOutput!.connection(withMediaType: AVMediaTypeVideo) {
                shouldReinitializeStillImageOutput = shouldReinitializeStillImageOutput || !connection.isActive
            }
        }
        
        
        if shouldReinitializeStillImageOutput {
            stillImageOutput = AVCapturePhotoOutput()
            
            captureSession?.beginConfiguration()
            captureSession?.addOutput(stillImageOutput)
            captureSession?.commitConfiguration()
        }
        
        return stillImageOutput!
    }
    
    @objc fileprivate func _orientationChanged() {
        var currentConnection: AVCaptureConnection?;
        switch cameraOutputMode {
        case .stillImage:
            currentConnection = stillImageOutput?.connection(withMediaType: AVMediaTypeVideo)
        case .videoOnly, .videoWithMic:
            currentConnection = _getMovieOutput().connection(withMediaType: AVMediaTypeVideo)
        }
        if let validPreviewLayer = previewLayer {
            if let validPreviewLayerConnection = validPreviewLayer.connection {
                if validPreviewLayerConnection.isVideoOrientationSupported {
                    validPreviewLayerConnection.videoOrientation = _currentVideoOrientation()
                }
            }
            if let validOutputLayerConnection = currentConnection {
                if validOutputLayerConnection.isVideoOrientationSupported {
                    validOutputLayerConnection.videoOrientation = _currentVideoOrientation()
                }
            }
            DispatchQueue.main.async(execute: { () -> Void in
                if let validEmbeddingView = self.embeddingView {
                    validPreviewLayer.frame = validEmbeddingView.bounds
                }
            })
        }
    }
    
    fileprivate func _currentVideoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
    
    fileprivate func _canLoadCamera() -> Bool {
        let currentCameraState = _checkIfCameraIsAvailable()
        return currentCameraState == .ready || (currentCameraState == .notDetermined && showAccessPermissionPopupAutomatically)
    }
    
    fileprivate func _setupCamera(_ completition: @escaping (Void) -> Void) {
        captureSession = AVCaptureSession()
        
        sessionQueue.async(execute: {
            if let validCaptureSession = self.captureSession {
                validCaptureSession.beginConfiguration()
                validCaptureSession.sessionPreset = AVCaptureSessionPresetHigh
                self._updateCameraDevice(self.cameraDevice)
                self._setupOutputs()
                self._setupOutputMode(self.cameraOutputMode, oldCameraOutputMode: nil)
                self._setupPreviewLayer()
                validCaptureSession.commitConfiguration()
                self._updateFlasMode(self.flashMode)
                self._updateMaxDuration(self.cameraVideoDuration)
                self._updateCameraQualityMode(self.cameraOutputQuality)
                validCaptureSession.startRunning()
                self._startFollowingDeviceOrientation()
                self.cameraIsSetup = true
                self._orientationChanged()
                
                completition()
            }
        })
    }
    
    fileprivate func _startFollowingDeviceOrientation() {
        if shouldRespondToOrientationChanges && !cameraIsObservingDeviceOrientation {
            NotificationCenter.default.addObserver(self, selector: #selector(CameraManager._orientationChanged), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
            cameraIsObservingDeviceOrientation = true
        }
    }
    
    fileprivate func _stopFollowingDeviceOrientation() {
        if cameraIsObservingDeviceOrientation {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
            cameraIsObservingDeviceOrientation = false
        }
    }
    
    fileprivate func _addPreviewLayerToView(_ view: UIView) {
        embeddingView = view
        attachZoom(view)
        
        DispatchQueue.main.async(execute: { () -> Void in
            guard let _ = self.previewLayer else {
                return
            }
            self.previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.previewLayer!.frame = view.layer.bounds
            view.clipsToBounds = true
            view.layer.insertSublayer(self.previewLayer!, at: 0)
        })
    }
    
    fileprivate func _setupMaxZoomScale() {
        var maxZoom = CGFloat(1.0)
        beginZoomScale = CGFloat(1.0)
        
        if cameraDevice == .back {
            maxZoom = (backCameraDevice?.activeFormat.videoMaxZoomFactor)!
        }
        else if cameraDevice == .front {
            maxZoom = (frontCameraDevice?.activeFormat.videoMaxZoomFactor)!
        }
        
        maxZoomScale = maxZoom
    }
    
    fileprivate func _checkIfCameraIsAvailable() -> CameraState {
        let deviceHasCamera = UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.rear) || UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.front)
        if deviceHasCamera {
            let authorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
            let userAgreedToUseIt = authorizationStatus == .authorized
            if userAgreedToUseIt {
                return .ready
            } else if authorizationStatus == AVAuthorizationStatus.notDetermined {
                return .notDetermined
            } else {
                _show(NSLocalizedString("Camera access denied", comment:""), message:NSLocalizedString("You need to go to settings app and grant acces to the camera device to use it.", comment:""))
                return .accessDenied
            }
        } else {
            _show(NSLocalizedString("Camera unavailable", comment:""), message:NSLocalizedString("The device does not have a camera.", comment:""))
            return .noDeviceFound
        }
    }
    
    fileprivate func _setupOutputMode(_ newCameraOutputMode: CameraOutputMode, oldCameraOutputMode: CameraOutputMode?) {
        captureSession?.beginConfiguration()
        
        if let cameraOutputToRemove = oldCameraOutputMode {
            // remove current setting
            switch cameraOutputToRemove {
            case .stillImage:
                if let validStillImageOutput = stillImageOutput {
                    captureSession?.removeOutput(validStillImageOutput)
                }
            case .videoOnly, .videoWithMic:
                if let validMovieOutput = movieOutput {
                    captureSession?.removeOutput(validMovieOutput)
                }
                if cameraOutputToRemove == .videoWithMic {
                    _removeMicInput()
                }
            }
        }
        
        // configure new devices
        switch newCameraOutputMode {
        case .stillImage:
            if (stillImageOutput == nil) {
                _setupOutputs()
            }
            if let validStillImageOutput = stillImageOutput {
                captureSession?.addOutput(validStillImageOutput)
            }
        case .videoOnly, .videoWithMic:
            captureSession?.addOutput(_getMovieOutput())
            
            if newCameraOutputMode == .videoWithMic {
                if let validMic = _deviceInputFromDevice(mic) {
                    captureSession?.addInput(validMic)
                }
            }
        }
        captureSession?.commitConfiguration()
        _updateCameraQualityMode(cameraOutputQuality)
        _orientationChanged()
    }
    
    fileprivate func _setupOutputs() {
        if (stillImageOutput == nil) {
            stillImageOutput = AVCapturePhotoOutput()
        }
        if (movieOutput == nil) {
            movieOutput = AVCaptureMovieFileOutput()
            movieOutput?.maxRecordedDuration = CMTimeMakeWithSeconds(6, 1)
            movieOutput!.movieFragmentInterval = kCMTimeInvalid
        }
    }
    
    fileprivate func _setupPreviewLayer() {
        if let validCaptureSession = captureSession {
            previewLayer = AVCaptureVideoPreviewLayer(session: validCaptureSession)
        }
    }
    
    fileprivate func _updateCameraDevice(_ deviceType: CameraDevice) {
        if let validCaptureSession = captureSession {
            validCaptureSession.beginConfiguration()
            let inputs = validCaptureSession.inputs as! [AVCaptureInput]
            
            for input in inputs {
                if let deviceInput = input as? AVCaptureDeviceInput {
                    if deviceInput.device == backCameraDevice && cameraDevice == .front {
                        validCaptureSession.removeInput(deviceInput)
                        break;
                    } else if deviceInput.device == frontCameraDevice && cameraDevice == .back {
                        validCaptureSession.removeInput(deviceInput)
                        break;
                    }
                }
            }
            switch cameraDevice {
            case .front:
                if hasFrontCamera {
                    if let validFrontDevice = _deviceInputFromDevice(frontCameraDevice) {
                        if !inputs.contains(validFrontDevice) {
                            validCaptureSession.addInput(validFrontDevice)
                        }
                    }
                }
            case .back:
                if let validBackDevice = _deviceInputFromDevice(backCameraDevice) {
                    if !inputs.contains(validBackDevice) {
                        validCaptureSession.addInput(validBackDevice)
                    }
                }
            }
            validCaptureSession.commitConfiguration()
        }
    }
    
    fileprivate func _updateFlasMode(_ flashMode: CameraFlashMode) {
        captureSession?.beginConfiguration()
        
        if let device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back) {
            
            let avFlashMode = AVCaptureFlashMode(rawValue: flashMode.rawValue)
            if (device.isFlashModeSupported(avFlashMode!)) {
                do {
                    try device.lockForConfiguration()
                } catch {
                    return
                }
                device.flashMode = avFlashMode!
                device.unlockForConfiguration()
            }
        }
        
        captureSession?.commitConfiguration()
    }
    
    fileprivate func _updateCameraQualityMode(_ newCameraOutputQuality: CameraOutputQuality) {
        if let validCaptureSession = captureSession {
            var sessionPreset = AVCaptureSessionPresetLow
            switch (newCameraOutputQuality) {
            case CameraOutputQuality.low:
                sessionPreset = AVCaptureSessionPresetLow
            case CameraOutputQuality.medium:
                sessionPreset = AVCaptureSessionPresetMedium
            case CameraOutputQuality.high:
                if cameraOutputMode == .stillImage {
                    sessionPreset = AVCaptureSessionPresetPhoto
                } else {
                    sessionPreset = AVCaptureSessionPresetHigh
                }
            }
            if validCaptureSession.canSetSessionPreset(sessionPreset) {
                validCaptureSession.beginConfiguration()
                validCaptureSession.sessionPreset = sessionPreset
                validCaptureSession.commitConfiguration()
            } else {
                _show(NSLocalizedString("Preset not supported", comment:""), message: NSLocalizedString("Camera preset not supported. Please try another one.", comment:""))
            }
        } else {
            _show(NSLocalizedString("Camera error", comment:""), message: NSLocalizedString("No valid capture session found, I can't take any pictures or videos.", comment:""))
        }
    }
    
    fileprivate func _removeMicInput() {
        guard let inputs = captureSession?.inputs as? [AVCaptureInput] else { return }
        
        for input in inputs {
            if let deviceInput = input as? AVCaptureDeviceInput {
                if deviceInput.device == mic {
                    captureSession?.removeInput(deviceInput)
                    break;
                }
            }
        }
    }
    
    fileprivate func _show(_ title: String, message: String) {
        if showErrorsToUsers {
            DispatchQueue.main.async(execute: { () -> Void in
                self.showErrorBlock(title, message)
            })
        }
    }
    
    fileprivate func _deviceInputFromDevice(_ device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
        guard let validDevice = device else { return nil }
        do {
            return try AVCaptureDeviceInput(device: validDevice)
        } catch let outError {
            _show(NSLocalizedString("Device setup error occured", comment:""), message: "\(outError)")
            return nil
        }
    }
    
    /* Location vars */
    /// setup the location tracking defaults
    fileprivate class CameraLocationManager: NSObject, CLLocationManagerDelegate {
        var locationManager = CLLocationManager()
        var latestLocation: CLLocation?
        
        override init() {
            super.init()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.distanceFilter = 100.0
            locationManager.requestWhenInUseAuthorization()
        }
        
        func startUpdatingLocation() {
            locationManager.startUpdatingLocation()
        }
        
        func stopUpdatingLocation() {
            locationManager.stopUpdatingLocation()
        }
        
        // MARK: - CLLocationManagerDelegate
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            // Pick the location with best (= smallest value) horizontal accuracy
            latestLocation = locations.sorted { $0.horizontalAccuracy < $1.horizontalAccuracy }.first
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("Error while updating location " + error.localizedDescription)
        }
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                locationManager.startUpdatingLocation()
            } else {
                locationManager.stopUpdatingLocation()
            }
        }
    }

    
    open func tranlsateLocationToPlacemark(location: CLLocation?, completion: @escaping (CLPlacemark?) -> Void) {
        if let location = location {
            CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error)-> Void in
                if (error != nil) {
                    completion(nil)
                }
                
                if let allPlacemarks = placemarks {
                    if allPlacemarks.count != 0 {
                        let pm = allPlacemarks[0] as CLPlacemark
                        completion(pm)
                    }
                } else {
                    completion(nil)
                }
            })
        } else {
            completion(nil)
        }
    }
    
    deinit {
        stopAndRemoveCaptureSession()
        _stopFollowingDeviceOrientation()
    }
}
