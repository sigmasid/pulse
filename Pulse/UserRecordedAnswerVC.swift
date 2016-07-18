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

class UserRecordedAnswerVC: UIViewController {
    
    private var uploadTask : FIRStorageUploadTask!
    
    // set by the delegate
    var fileURL : NSURL?
    var currentQuestion : Question?
    var aLocation : String?
    var currentAnswer : Answer!
    
    weak var answerDelegate : childVCDelegate?
    
    private var _controlsOverlay : RecordedAnswerOverlay!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        let aPlayer = AVPlayer()
        
        let avPlayerLayer = AVPlayerLayer(player: aPlayer)
        self.view.layer.insertSublayer(avPlayerLayer, atIndex: 0)
        avPlayerLayer.frame = self.view.frame

        _controlsOverlay = RecordedAnswerOverlay(frame: self.view.frame)
        self.view.addSubview(_controlsOverlay)
        self.setupOverlayButtons()
        
        let _ = processVideo(fileURL!, aQuestion : currentQuestion) { (result) in
            let currentVideo = AVPlayerItem(URL: result)
            self.fileURL = result
            aPlayer.replaceCurrentItemWithPlayerItem(currentVideo)
            aPlayer.play()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func setupOverlayButtons() {
        _controlsOverlay.getButton(.Post).addTarget(self, action: #selector(self._postVideo), forControlEvents: UIControlEvents.TouchUpInside)
        _controlsOverlay.getButton(.Save).addTarget(self, action: #selector(self._saveVideo), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    ///post video to firebase
    func _postVideo() {
        _controlsOverlay.getButton(.Post).enabled = false

        if User.isLoggedIn() {
            _controlsOverlay.getButton(.Post).setTitle("Posting...", forState: UIControlState.Disabled)
            _controlsOverlay.getButton(.Post).backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(1)
            self.currentAnswer = createAnswer()
            self.currentAnswer.addObserver(self, forKeyPath: "aURL", options: NSKeyValueObservingOptions.New, context: nil)
            
            self.uploadAnswer(self.currentAnswer.aID)
        } else {
            print("user is not logged in")
            if (self.answerDelegate != nil) {
                _controlsOverlay.getButton(.Post).enabled = true
                self.answerDelegate!.askUserToLogin(self)
            }
        }
    }
    
    ///upload video to firebase and update current answer with URL upon success
    private func uploadAnswer(uploadName : String) {
        
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
            } catch {
                print("error getting file size")
            }
            
            uploadTask = storageRef.child("answers/\(uploadName)").putFile(localFile, metadata: _metadata)
            
            uploadTask.observeStatus(.Success) { snapshot in
                print("succesfully uploaded file")
                self.currentAnswer.aURL = snapshot.metadata?.downloadURL()
            }
            
            uploadTask.observeStatus(.Failure) { snapshot in
                print("current user \(FIRAuth.auth()!.currentUser)")
                print("error is \(snapshot.error?.localizedDescription)")
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
        let answerKey = databaseRef.childByAutoId().key
        return Answer(aID: answerKey, qID: self.currentQuestion!.qID, uID: User.currentUser!.uID!)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "aURL" {
            let answersPath =  databaseRef.child("answers/\(self.currentAnswer!.aID)")
            var userPost = [String : String]()
            
            if aLocation != nil {
                let answerPost = ["qID": self.currentAnswer.qID, "uID": self.currentAnswer.uID!, "URL" : String(self.currentAnswer.aURL), "location" : aLocation!]
                answersPath.setValue(answerPost)
            } else {
                let answerPost = ["qID": self.currentAnswer.qID, "uID": self.currentAnswer.uID!, "URL" : String(self.currentAnswer.aURL)]
                answersPath.setValue(answerPost)
            }
            
            if let _profilePic = User.currentUser!.profilePic {
                userPost["profilePic"] = _profilePic
            }
            
            if let _userName = User.currentUser!.name {
                userPost["name"] = _userName
            }
            
            Database.addUserAnswersToDatabase(currentAnswer!.aID, qID: currentQuestion!.qID, completion: {(success, error) in
                if !success {
                    print(error)
                } else {
                    print("success creating answer")
                    self.uploadTask.removeAllObservers()
                    self.doneCreatingAnswer()
                }
            })
        }
    }
    
    ///Called after user has completed sharing the answer
    private func doneCreatingAnswer() {
        self.currentAnswer.removeObserver(self, forKeyPath: "aURL")
        answerDelegate?.doneUploadingAnswer(self)
    }
    
    ///User clicked save to album button
    func _saveVideo(sender: UIButton!) {
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
