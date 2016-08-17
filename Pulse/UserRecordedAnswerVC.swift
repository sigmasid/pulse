//
//  UserRecordedAnswerVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation
import Photos

class UserRecordedAnswerVC: UIViewController, UIGestureRecognizerDelegate {
    
    private var uploadTask : FIRStorageUploadTask!
    
    // set by the delegate
    var fileURL : NSURL?
    var capturedImage : UIImage?
    var currentQuestion : Question?
    var aLocation : String?
    var currentAnswer : Answer!
    var currentAssetType : AssetType?
    
    weak var answerDelegate : childVCDelegate?
    
    private var _controlsOverlay : RecordedAnswerOverlay!
    private var _answersFilters : FiltersOverlay?
    private var _thumbnailImage : UIImage?
    private var _isObserving = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        if let _currentQuestion = currentQuestion {
            
            if currentAssetType != nil && currentAssetType == .recordedVideo || currentAssetType == .albumVideo {
                let aPlayer = AVPlayer()
                
                let avPlayerLayer = AVPlayerLayer(player: aPlayer)
                view.layer.insertSublayer(avPlayerLayer, atIndex: 0)
                avPlayerLayer.frame = view.frame
                
                if currentAssetType == .recordedVideo {
                    processVideo(fileURL!) { (resultURL, thumbnailImage, error) in
                        if let resultURL = resultURL {
                            let currentVideo = AVPlayerItem(URL: resultURL)
                            self.fileURL = resultURL
                            self._thumbnailImage = thumbnailImage
                            aPlayer.replaceCurrentItemWithPlayerItem(currentVideo)
                            aPlayer.play()
                        } else {
                            GlobalFunctions.showErrorBlock(error!.domain, erMessage: error!.localizedDescription)
                        }
                    }
                } else if currentAssetType == .albumVideo {
                    compressVideo(fileURL!, completion: {(resultURL, thumbnailImage, error) in
                        if let resultURL = resultURL {
                            let currentVideo = AVPlayerItem(URL: resultURL)
                            self.fileURL = resultURL
                            self._thumbnailImage = thumbnailImage
                            aPlayer.replaceCurrentItemWithPlayerItem(currentVideo)
                            aPlayer.play()
                        } else {
                            GlobalFunctions.showErrorBlock(error!.domain, erMessage: error!.localizedDescription)
                        }
                    })
                }
            } else if currentAssetType != nil && currentAssetType == .recordedImage || currentAssetType == .albumImage {
                let imageView = UIImageView(frame: view.bounds)
                imageView.contentMode = .ScaleAspectFill
                imageView.image = capturedImage
                view.addSubview(imageView)
            }
            
            _controlsOverlay = RecordedAnswerOverlay(frame: view.frame)
            
            if _currentQuestion.hasFilters() {
                _answersFilters = FiltersOverlay(frame: view.frame)
                _answersFilters!.currentQuestion = currentQuestion
                view.addSubview(_answersFilters!)
                view.addSubview(_controlsOverlay)
            } else {
                view.addSubview(_controlsOverlay)
            }
            setupOverlayButtons()
        }
    }
    
    func gestureRecognizer(gesture: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer : UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func setupOverlayButtons() {
        _controlsOverlay.getButton(.Post).addTarget(self, action: #selector(_post), forControlEvents: UIControlEvents.TouchUpInside)
        _controlsOverlay.getButton(.Save).addTarget(self, action: #selector(_save), forControlEvents: UIControlEvents.TouchUpInside)
        _controlsOverlay.getButton(.Close).addTarget(self, action: #selector(_close), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    ///close window and go back to camera
    func _close() {
        answerDelegate?.userDismissedRecording(self)
    }
    
    ///post video to firebase
    func _post() {
        _controlsOverlay.getButton(.Post).enabled = false
        if User.isLoggedIn() {
            _controlsOverlay.getButton(.Post).setTitle("Posting...", forState: UIControlState.Disabled)
            _controlsOverlay.getButton(.Post).backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(1)
            currentAnswer = createAnswer()
            
            uploadAnswer(currentAnswer.aID)
        } else {
            if (answerDelegate != nil) {
                _controlsOverlay.getButton(.Post).enabled = true
                answerDelegate!.askUserToLogin(self)
            }
        }
    }
    
    ///upload video to firebase and update current answer with URL upon success
    private func uploadAnswer(uploadName : String) {

        if currentAssetType != nil && currentAssetType == .recordedVideo || currentAssetType == .albumVideo {
            currentAnswer.addObserver(self, forKeyPath: "aURL", options: NSKeyValueObservingOptions.New, context: nil)
            _isObserving = true

            var fileSize = UInt64()
            _controlsOverlay.addUploadProgressBar()
           
            if let localFile: NSURL = fileURL! {
                
                let _metadata = FIRStorageMetadata()
                _metadata.contentType = "video/mp4"
                
                do {
                    let attr:NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(localFile.path!)
                    if let _attr = attr {
                        fileSize = _attr.fileSize()
                    }
                } catch {}
        
                if _thumbnailImage != nil {
                    Database.uploadImage(.AnswerThumbs, fileID: uploadName, image: _thumbnailImage!, completion: { (success, error) in
                        if success {
                            print("uploaded thumbnail")
                        } else {
                            print("upload thumbnail failed \(error?.localizedDescription)")
                        }
                    })
                }
                
                let path = Database.getStoragePath(.Answers, itemID: uploadName)
                uploadTask = path.putFile(localFile, metadata: _metadata)
                
                uploadTask.observeStatus(.Success) { snapshot in
                    self.currentAnswer.aURL = snapshot.metadata?.downloadURL()
                }
                
                uploadTask.observeStatus(.Failure) { snapshot in
                    if let _error = snapshot.error {
                        GlobalFunctions.showErrorBlock("Error Posting Video", erMessage: _error.localizedDescription)
                    }
                }
                
                uploadTask.observeStatus(.Progress) { snapshot in
                    if fileSize > 0 {
                        let percentComplete = Float(snapshot.progress!.completedUnitCount) / Float(fileSize)
                        dispatch_async(dispatch_get_main_queue()) {
                            self._controlsOverlay.updateProgressBar(percentComplete)
                        }
                    }
                }
            }
        } else if currentAssetType != nil && currentAssetType == .recordedImage || currentAssetType == .albumImage {
            print("trying to upload image")
            Database.uploadImage(.Answers, fileID: uploadName, image: capturedImage!, completion: {(success, error) in
                if error != nil {
                    GlobalFunctions.showErrorBlock("Error Posting Image", erMessage: error!.localizedDescription)
                } else {
                    self.doneCreatingAnswer()
                }

            })
        }
    }
    
    private func createAnswer() -> Answer {
        let answerKey = databaseRef.childByAutoId().key
        return Answer(aID: answerKey, qID: self.currentQuestion!.qID, uID: User.currentUser!.uID!)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "aURL" {
            let answersPath =  databaseRef.child("answers/\(self.currentAnswer!.aID)")
            
            if aLocation != nil {
                let answerPost = ["qID": currentAnswer.qID, "uID": currentAnswer.uID!, "URL" : String(self.currentAnswer.aURL), "location" : aLocation!]
                answersPath.setValue(answerPost)
            } else {
                let answerPost = ["qID": currentAnswer.qID, "uID": currentAnswer.uID!, "URL" : String(self.currentAnswer.aURL)]
                answersPath.setValue(answerPost)
            }
            
            Database.addUserAnswersToDatabase(currentAnswer!.aID, qID: currentQuestion!.qID, completion: {(success, error) in
                if !success {
                    print(error)
                } else {
                    self.uploadTask.removeAllObservers()
                    self.doneCreatingAnswer()
                }
            })
        }
    }
    
    ///Called after user has completed sharing the answer
    private func doneCreatingAnswer() {
        if _isObserving {
            currentAnswer.removeObserver(self, forKeyPath: "aURL")
            _isObserving = false
        }
        print("done uploading answer")
        answerDelegate?.doneUploadingAnswer(self)
    }
    
    ///User clicked save to album button
    func _save(sender: UIButton!) {
        _controlsOverlay.addSavingLabel("Saving...")
        if let videoURL = fileURL {
            _saveVideoToAlbum(videoURL)
        } else {
            _controlsOverlay.hideSavingLabel("Sorry there was an error")
        }
    }
    
    ///Save to photoalbum and show saving dialog
    private func _saveVideoToAlbum(url: NSURL) {
        let _ = PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            let _ = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(url)
            }, completionHandler: { success, error in
                if success {
                    dispatch_async(dispatch_get_main_queue()) {
                        self._controlsOverlay.hideSavingLabel("Saved video!")
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self._controlsOverlay.hideSavingLabel("Sorry there was an error")
                    }
                }
        })
    }
}
