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
    var currentAnswer : Answer!

    // set by the delegate
    var fileURL : NSURL?
    var capturedImage : UIImage?
    var currentQuestion : Question?
    var aLocation : String?
    var currentAssetType : AssetType?
    var currentAnswers : [Answer]!
    weak var delegate : childVCDelegate?
    
    private var _controlsOverlay : RecordedAnswerOverlay!
    private var _answersFilters : FiltersOverlay?
    private var _isVideoLoaded = false
    private var _isImageViewLoaded = false

    private var aPlayer : AVPlayer!
    private var avPlayerLayer : AVPlayerLayer!
    private var imageView : UIImageView!
    
    private var answerCollectionPost = [ String : Bool ]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)

        if let _currentQuestion = currentQuestion {
            currentAnswer = createAnswer()
            if currentAssetType != nil && currentAssetType == .recordedVideo || currentAssetType == .albumVideo {
                if !_isVideoLoaded {
                    aPlayer = AVPlayer()
                    
                    avPlayerLayer = AVPlayerLayer(player: aPlayer)
                    avPlayerLayer.frame = view.bounds

                    _isVideoLoaded = true
                }
                
                view.layer.addSublayer(avPlayerLayer)
                
                if currentAssetType == .recordedVideo {
                    processVideo(fileURL!) { (resultURL, thumbnailImage, error) in
                        if let resultURL = resultURL {
                            let currentVideo = AVPlayerItem(URL: resultURL)
                            self.currentAnswer.aURL = resultURL
                            self.currentAnswer.aType = .recordedVideo

                            print("video URL is \(self.currentAnswer.aURL)")
                            self.currentAnswer.thumbImage = thumbnailImage
                            self.aPlayer.replaceCurrentItemWithPlayerItem(currentVideo)
                            self.aPlayer.play()
                        } else {
                            GlobalFunctions.showErrorBlock(error!.domain, erMessage: error!.localizedDescription)
                        }
                    }
                } else if currentAssetType == .albumVideo {
                    compressVideo(fileURL!, completion: {(resultURL, thumbnailImage, error) in
                        if let resultURL = resultURL {
                            let currentVideo = AVPlayerItem(URL: resultURL)
                            self.currentAnswer.aURL = resultURL
                            self.currentAnswer.thumbImage = thumbnailImage
                            self.currentAnswer.aType = .albumVideo

                            self.aPlayer.replaceCurrentItemWithPlayerItem(currentVideo)
                            self.aPlayer.play()
                        } else {
                            GlobalFunctions.showErrorBlock(error!.domain, erMessage: error!.localizedDescription)
                        }
                    })
                }
                
            } else if currentAssetType != nil && currentAssetType == .recordedImage || currentAssetType == .albumImage {
                print("setting image for current answer")
                
                if !_isImageViewLoaded {
                    imageView = UIImageView(frame: view.bounds)
                    imageView.contentMode = .ScaleAspectFill
                    view.addSubview(imageView)

                    _isImageViewLoaded = true
                }
                
                view.bringSubviewToFront(imageView)
                imageView.image = capturedImage
                currentAnswer.aImage = capturedImage
                
                if currentAssetType == .recordedImage {
                    currentAnswer.aType = .recordedImage
                } else {
                    currentAnswer.aType = .albumImage
                }
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
        _controlsOverlay.getButton(.AddMore).addTarget(self, action: #selector(_addMore), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    func _addMore() {
        if let delegate = delegate {
            delegate.userClickedAddMoreToAnswer(self, currentAnswer: currentAnswer)
        }
    }
    
    ///close window and go back to camera
    func _close() {
        if let delegate = delegate {
            delegate.userDismissedRecording(self)
        }
    }
    
    ///post video to firebase
    func _post() {
        _controlsOverlay.getButton(.Post).enabled = false
        if User.isLoggedIn() {
            _controlsOverlay.getButton(.Post).setTitle("Posting...", forState: UIControlState.Disabled)
            _controlsOverlay.getButton(.Post).backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(1)
            
            uploadAnswer()
        } else {
            if let delegate = delegate {
                _controlsOverlay.getButton(.Post).enabled = true
                delegate.askUserToLogin(self)
            }
        }
    }
    
    ///upload video to firebase and update current answer with URL upon success
    private func uploadAnswer() {
        currentAnswers.append(currentAnswer)
        
        let totalAnswers = currentAnswers.count
        print("total answers is \(totalAnswers)")
        
        for answer in currentAnswers {
            answerCollectionPost[answer.aID] = false
            
            if answer.aType != nil && answer.aType == .recordedVideo || answer.aType == .albumVideo {
                print("currently uploading video \(answer.aID)")

                uploadVideo(answer, completion: {(success, _answerID) in
                    if success {
                        print("successfully uploaded video for answer \(answer.aID)")
                        self.answerCollectionPost[_answerID!] = true
                    } else {
                        print("did not successfully upload video")
                    }
                    
                    if answer == self.currentAnswers.last {
                        print("uploading last video")
                        self.doneCreatingAnswer()
                    }
                })
            }
                
            else if answer.aType != nil && answer.aType == .recordedImage || answer.aType == .albumImage {
                print("currently uploading image for \(answer.aID)")

                Database.uploadImage(.Answers, fileID: answer.aID, image: answer.aImage!, completion: {(success, error) in
                    if error != nil {
                        print("error uploading image")
//                        GlobalFunctions.showErrorBlock("Error Posting Image", erMessage: error!.localizedDescription)
                    } else {
                        print("successfully uploaded image for answer \(answer.aID)")
                        self.answerCollectionPost[answer.aID] = true
                        
                        Database.addUserAnswersToDatabase(answer, completion: {(success, error) in
                            if !success {
                                print(error)
                            } else {
                                print("added image to database")
                            }
                        })
                    }
                    
                    if answer == self.currentAnswers.last {
                        print("uploading last image")
                        self.doneCreatingAnswer()
                    }
                })
            }
        }
    }
    
    private func uploadVideo(answer : Answer, completion: (success : Bool, _answerID : String?) -> Void) {
        var fileSize = UInt64()
        _controlsOverlay.addUploadProgressBar()
        
        if let localFile: NSURL = answer.aURL {
            
            let _metadata = FIRStorageMetadata()
            _metadata.contentType = "video/mp4"
            
            do {
                let attr:NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(localFile.path!)
                if let _attr = attr {
                    fileSize = _attr.fileSize()
                }
            } catch {}
            
            let path = Database.getStoragePath(.Answers, itemID: answer.aID)
            uploadTask = path.putFile(localFile, metadata: _metadata)
            
            uploadTask.observeStatus(.Success) { snapshot in
                self.currentAnswer.aURL = snapshot.metadata?.downloadURL()
                
                if self.currentAnswer.thumbImage != nil {
                    Database.uploadImage(.AnswerThumbs, fileID: answer.aID, image: self.currentAnswer.thumbImage!, completion: { (success, error) in
                        if success {
                            print("uploaded thumbnail")
                        } else {
                            print("upload thumbnail failed \(error?.localizedDescription)")
                        }
                    })
                }
                
                Database.addUserAnswersToDatabase( answer, completion: {(success, error) in
                    if !success {
                        print(error)
                    } else {
                        
                        self.uploadTask.removeAllObservers()
                    }
                })

                completion(success: true, _answerID: answer.aID)
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
    }
    
    private func createAnswer() -> Answer {
        let answerKey = databaseRef.child("answers").childByAutoId().key
        print("answerKey is \(answerKey)")
        
        return Answer(aID: answerKey, qID: self.currentQuestion!.qID, uID: User.currentUser!.uID!, aType: currentAssetType!, aLocation: aLocation)
    }
    
    ///Called after user has completed sharing the answer
    private func doneCreatingAnswer() {
        print("done uploading answer")
        
        if let delegate = delegate {
            delegate.doneUploadingAnswer(self)
        }
    }
    
    ///User clicked save to album button
    func _save(sender: UIButton!) {
        _controlsOverlay.addSavingLabel("Saving...")
        if fileURL != nil && currentAssetType == .recordedVideo || currentAssetType == .albumVideo {
            _saveVideoToAlbum(fileURL!)
        } else if capturedImage != nil && currentAssetType == .recordedImage || currentAssetType == .albumImage {
            _saveImageToAlbum(capturedImage!)
        }
        else {
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
    
    ///Save to photoalbum and show saving dialog
    private func _saveImageToAlbum(image: UIImage) {
        let _ = PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            let _ = PHAssetChangeRequest.creationRequestForAssetFromImage(image)
            }, completionHandler: { success, error in
                if success {
                    dispatch_async(dispatch_get_main_queue()) {
                        self._controlsOverlay.hideSavingLabel("Saved image!")
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self._controlsOverlay.hideSavingLabel("Sorry there was an error")
                    }
                }
        })
    }
}
