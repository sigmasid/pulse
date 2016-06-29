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
    
    var uploadTask : FIRStorageUploadTask!
    
    var fileURL : NSURL?
    var currentQuestion : Question?
    var aLocation : String?
    var currentAnswer : Answer!
    weak var answerDelegate : childVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let aPlayer = AVPlayer()
        let avPlayerLayer = AVPlayerLayer(player: aPlayer)
        self.view.layer.insertSublayer(avPlayerLayer, atIndex: 0)
        avPlayerLayer.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        self.view.addSubview(self.setupPlayer())
        
        let _ = processVideo(fileURL!, location: aLocation, aQuestion : currentQuestion) { (result) in
            let currentVideo = AVPlayerItem(URL: result)
            self.fileURL = result
            aPlayer.replaceCurrentItemWithPlayerItem(currentVideo)
            aPlayer.play()
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupPlayer() -> UIView {
        let overlayView = UIView()
        overlayView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        
        let postButton = UIButton()
        postButton.frame = CGRectMake(UIScreen.mainScreen().bounds.width / 2 - 50, UIScreen.mainScreen().bounds.height - 100, 100, 30)
        postButton.setTitle("Post", forState: .Normal)
        postButton.addTarget(self, action: #selector(self._postVideo(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        let saveToDiskButton = UIButton()
        let saveToDiskImage = UIImage(named: "saveFile.png")
        saveToDiskButton.setImage(saveToDiskImage, forState: UIControlState.Normal)
        saveToDiskButton.frame = CGRectMake(20, UIScreen.mainScreen().bounds.height - 100, saveToDiskImage!.size.width, saveToDiskImage!.size.width)
        saveToDiskButton.addTarget(self, action: #selector(self._saveVideo), forControlEvents: UIControlEvents.TouchUpInside)
        
        let locationLabel = UILabel(frame: CGRectMake(10,10,100,0))
        locationLabel.text = aLocation!
        print("the location is \(aLocation)")
        locationLabel.textColor = UIColor.blackColor()
        
        overlayView.addSubview(postButton)
        overlayView.addSubview(saveToDiskButton)
        overlayView.addSubview(locationLabel)
        return overlayView
    }
    
    ///post video to firebase
    func _postVideo(sender: UIButton!) {
        if User.currentUser.isLoggedIn() {
            self.currentAnswer = createAnswer()
            self.currentAnswer.addObserver(self, forKeyPath: "aURL", options: NSKeyValueObservingOptions.New, context: nil)
            
            self.uploadAnswer(self.currentAnswer.aID)
        } else {
            if (self.answerDelegate != nil) {
                self.answerDelegate!.askUserToLogin(self)
            }
        }
    }
    
    ///upload video to firebase and update current answer with URL upon success
    private func uploadAnswer(uploadName : String) {
        let progressBar = UIProgressView()
        progressBar.frame = CGRectMake(10,20,UIScreen.mainScreen().bounds.width - 40,20)
        progressBar.progressTintColor = UIColor.whiteColor()
        progressBar.progressViewStyle = .Bar
        
        self.view.addSubview(progressBar)
        var fileSize = UInt64()
        
        // File located on disk
        
        if let localFile: NSURL = fileURL! {
            
            do {
                let attr:NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(localFile.path!)
                if let _attr = attr {
                    fileSize = _attr.fileSize()
                }
            } catch {
                print("error getting file size")
            }
            
            uploadTask = storageRef.child("answers/\(uploadName)").putFile(localFile)
            
            uploadTask.observeStatus(.Success) { snapshot in
                self.currentAnswer.aURL = snapshot.metadata?.downloadURL()
            }
            
            uploadTask.observeStatus(.Progress) { snapshot in
                if fileSize > 0 {
                    let percentComplete = Float(snapshot.progress!.completedUnitCount) / Float(fileSize)
                    progressBar.setProgress(percentComplete, animated: true)
                }
            }
        }
    }
    
    
    
    private func createAnswer() -> Answer {
        let answerKey = databaseRef.childByAutoId().key
        return Answer(aID: answerKey, qID: self.currentQuestion!.qID, uID: User.currentUser.uID!)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "aURL" {
            let answersPath =  databaseRef.child("answers/\(self.currentAnswer!.aID)")
            let userPath =  databaseRef.child("users/\(self.currentAnswer!.uID)/answers")
            let questionsPath = databaseRef.child("questions/\(self.currentQuestion!.qID)/answers")
            let answerPost = ["qID": self.currentAnswer.qID, "uID": self.currentAnswer.uID!, "URL" : String(self.currentAnswer.aURL)]
            let questionPost = ["\(self.currentAnswer.aID)": "true"]
            answersPath.setValue(answerPost)
            questionsPath.updateChildValues(questionPost)
            userPath.updateChildValues(questionPost)
            uploadTask.removeAllObservers()
            self.doneCreatingAnswer()
        }
    }
    
    func doneCreatingAnswer() {
        self.currentAnswer.removeObserver(self, forKeyPath: "aURL")
        answerDelegate?.doneUploadingAnswer(self)
    }
    
    ///User clicked save to album button
    func _saveVideo(sender: UIButton!) {
        if let videoURL = fileURL {
            _saveVideoToAlbum(videoURL)
        } else {
            print("sorry there was an error uploading video")
        }
    }
    
    func _saveVideoToAlbum(url: NSURL) {
        let _ = PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            let _ = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(url)
            }, completionHandler: { success, error in
                print("Finished saving asset.", (success ? "Success." : error))
        })
    }
}
