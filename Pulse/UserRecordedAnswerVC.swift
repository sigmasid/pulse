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
    
    fileprivate var uploadTask : FIRStorageUploadTask!

    // set by the delegate
    var currentAnswer : Answer! {
        didSet {
            if currentAnswer.aType == .recordedVideo || currentAnswer.aType == .albumVideo {
                setupVideoForAnswer()
            } else if currentAnswer.aType == .recordedImage || currentAnswer.aType == .albumImage {
                setupImageForAnswer()
            }
        }
    }
    
    var currentQuestion : Question! {
        didSet {
//            _controlsOverlay = RecordedAnswerOverlay(frame: view.bounds)
            
            if currentQuestion.hasFilters() {
                _answersFilters = FiltersOverlay(frame: view.bounds)
                _answersFilters!.currentQuestion = currentQuestion
//                view.addSubview(_answersFilters!) //NEED TO PUT BACK IN 
                view.addSubview(_controlsOverlay)
            } else {
                view.addSubview(_controlsOverlay)
            }
            setupOverlayButtons()
        }
    }
    
    //includes currentAnswer - set by delegate - the image / video is replaced after processing when uploading file or adding more
    var currentAnswers : [Answer]!
    var isNewEntry = true //don't reprocess video / image if the user is returning back to prior entry
    
    var currentAnswerIndex : Int = 0 {
        didSet {
            if currentAnswerIndex == 0 {
                if let delegate = delegate {
                    delegate.userDismissedRecording(self, _currentAnswers : currentAnswers)
                }
            } else {
                currentAnswer = currentAnswers[currentAnswerIndex - 1] // adjust for array index vs. count
            }
        }
        willSet {
            if newValue < currentAnswerIndex {
                isNewEntry = false
            } else {
                _controlsOverlay.addAnswerPagers()
            }
        }
    }
    
    weak var delegate : childVCDelegate?
    
    fileprivate lazy var _controlsOverlay : RecordedAnswerOverlay = RecordedAnswerOverlay(frame: self.view.bounds)
    fileprivate var _answersFilters : FiltersOverlay?
    fileprivate var _isVideoLoaded = false
    fileprivate var _isImageViewLoaded = false

    fileprivate var aPlayer : AVPlayer!
    fileprivate var avPlayerLayer : AVPlayerLayer!
    fileprivate var imageView : UIImageView!
    
    fileprivate var answerCollectionPost = [ String : Bool ]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    fileprivate func setupImageForAnswer() {
        if !_isImageViewLoaded {
            imageView = UIImageView(frame: view.bounds)
            imageView.contentMode = .scaleAspectFill
            view.addSubview(imageView)
            
            _isImageViewLoaded = true
        }
        
        view.bringSubview(toFront: imageView)
        arrangeViews()
        
        imageView.image = currentAnswer.aImage
        currentAnswer.thumbImage = currentAnswer.aImage
    }
    
    fileprivate func setupVideoForAnswer() {
        //don't create new AVPlayer if it already exists
        if !_isVideoLoaded {
            aPlayer = AVPlayer()
            
            avPlayerLayer = AVPlayerLayer(player: aPlayer)
            avPlayerLayer.frame = view.bounds
            
            _isVideoLoaded = true
        }
        
        //reorder views so controls & filters are still on top
        view.layer.addSublayer(avPlayerLayer)
        arrangeViews()
        
        if isNewEntry {
            if currentAnswer.aType == .recordedVideo {
                aPlayer.replaceCurrentItem(with: nil)
                
                processVideo(currentAnswer.aURL) { (resultURL, thumbnailImage, error) in
                    if let resultURL = resultURL {
                        let currentVideo = AVPlayerItem(url: resultURL)
                        self.currentAnswer.aURL = resultURL
                        self.currentAnswer.thumbImage = thumbnailImage
                        self.currentAnswers[self.currentAnswerIndex - 1] = self.currentAnswer

                        self.aPlayer.replaceCurrentItem(with: currentVideo)
                        self.aPlayer.play()
                    } else {
                        GlobalFunctions.showErrorBlock(error!.domain, erMessage: error!.localizedDescription)
                    }
                }
            } else if currentAnswer.aType == .albumVideo {
                aPlayer.replaceCurrentItem(with: nil)

                compressVideo(currentAnswer.aURL, completion: {(resultURL, thumbnailImage, error) in
                    if let resultURL = resultURL {
                        let currentVideo = AVPlayerItem(url: resultURL)
                        self.currentAnswer.aURL = resultURL
                        self.currentAnswer.thumbImage = thumbnailImage
                        self.currentAnswers[self.currentAnswerIndex - 1] = self.currentAnswer
                        
                        self.aPlayer.replaceCurrentItem(with: currentVideo)
                        self.aPlayer.play()
                    } else {
                        GlobalFunctions.showErrorBlock(error!.domain, erMessage: error!.localizedDescription)
                    }
                })
            }
        } else {
            aPlayer.replaceCurrentItem(with: nil)

            let currentVideo = AVPlayerItem(url: currentAnswer.aURL as URL)
            aPlayer.replaceCurrentItem(with: currentVideo)
            aPlayer.play()
        }
    }
    
    //move the controls and filters to top layer
    fileprivate func arrangeViews() {
        if _answersFilters != nil {
            view.bringSubview(toFront: _answersFilters!)
        }
        view.bringSubview(toFront: _controlsOverlay)
    }
    
    func gestureRecognizer(_ gesture: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer : UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func setupOverlayButtons() {
        _controlsOverlay.getButton(.post).addTarget(self, action: #selector(_post), for: UIControlEvents.touchUpInside)
        _controlsOverlay.getButton(.save).addTarget(self, action: #selector(_save), for: UIControlEvents.touchUpInside)
        _controlsOverlay.getButton(.close).addTarget(self, action: #selector(_close), for: UIControlEvents.touchUpInside)
        _controlsOverlay.getButton(.addMore).addTarget(self, action: #selector(_addMore), for: UIControlEvents.touchUpInside)
    }
    
    func _addMore() {
        if let delegate = delegate {
            delegate.userClickedAddMoreToAnswer(self, _currentAnswers: currentAnswers)
        }
    }
    
    ///close window and go back to camera
    func _close() {
        // need to check if it was first answer -> if yes, go to camera else stay in UserRecordedAnswer and go back to last question, remove the current answer value from currentAnswers
        _controlsOverlay.removeAnswerPager()
        currentAnswers.remove(at: currentAnswerIndex - 1)
        currentAnswerIndex = currentAnswerIndex - 1
    }
    
    ///post video to firebase
    func _post() {
        _controlsOverlay.getButton(.post).isEnabled = false
        if User.isLoggedIn() {
            _controlsOverlay.getButton(.post).setTitle("Posting...", for: UIControlState.disabled)
            _controlsOverlay.getButton(.post).backgroundColor = UIColor.darkGray.withAlphaComponent(1)
            
            uploadAnswer()
        } else {
            if let delegate = delegate {
                _controlsOverlay.getButton(.post).isEnabled = true
                delegate.askUserToLogin(self)
            }
        }
    }
    
    ///upload video to firebase and update current answer with URL upon success
    fileprivate func uploadAnswer() {
        
        if let _image = currentAnswers.first?.thumbImage  {
            Database.uploadImage(.AnswerThumbs, fileID: currentAnswers.first!.aID, image: _image, completion: { (success, error) in } )
        }
        
        for answer in currentAnswers {
            answerCollectionPost[answer.aID] = true
            
            if answer.aType != nil && answer.aType == .recordedVideo || answer.aType == .albumVideo {

                uploadVideo(answer, completion: {(success, _answerID) in
                    
                    if answer == self.currentAnswers.last {
                        self.doneCreatingAnswer()
                    }
                })
            }
                
            else if answer.aType != nil && answer.aType == .recordedImage || answer.aType == .albumImage {
                Database.uploadImage(.Answers, fileID: answer.aID, image: answer.aImage!, completion: {(success, error) in
                    if error != nil {
                        GlobalFunctions.showErrorBlock("Error Posting Image", erMessage: error!.localizedDescription)
                    } else {
                        
                        Database.addUserAnswersToDatabase(answer, completion: {(success, error) in
                            if !success {
                                print(error)
                            }
                        })
                    }
                    
                    if answer == self.currentAnswers.last {
                        self.doneCreatingAnswer()
                    }
                })
            }
        }
    }
    
    fileprivate func uploadVideo(_ answer : Answer, completion: @escaping (_ success : Bool, _ _answerID : String?) -> Void) {
        var fileSize = UInt64()
        _controlsOverlay.addUploadProgressBar()
        
        if let localFile: URL = answer.aURL as URL? {
            
            let _metadata = FIRStorageMetadata()
            _metadata.contentType = "video/mp4"
            
            do {
                let attr:NSDictionary? = try FileManager.default.attributesOfItem(atPath: localFile.path) as NSDictionary?
                if let _attr = attr {
                    fileSize = _attr.fileSize()
                }
            } catch {}
            
            let path = Database.getStoragePath(.Answers, itemID: answer.aID)
            uploadTask = path.putFile(localFile, metadata: _metadata)
            
            uploadTask.observe(.success) { snapshot in
                self.currentAnswer.aURL = snapshot.metadata?.downloadURL()
                
                Database.addUserAnswersToDatabase( answer, completion: {(success, error) in
                    if !success {
                        print(error)
                    } else {
                        
                        self.uploadTask.removeAllObservers()
                    }
                })

                completion(true, answer.aID)
            }
            
            uploadTask.observe(.failure) { snapshot in
                if let _error = snapshot.error {
                    GlobalFunctions.showErrorBlock("Error Posting Video", erMessage: _error.localizedDescription)
                }
            }
            
            uploadTask.observe(.progress) { snapshot in
                if fileSize > 0 {
                    let percentComplete = Float(snapshot.progress!.completedUnitCount) / Float(fileSize)
                    DispatchQueue.main.async {
                        self._controlsOverlay.updateProgressBar(percentComplete)
                    }
                }
            }
        }
    }
    
    ///Called after user has completed sharing the answer
    fileprivate func doneCreatingAnswer() {
        Database.addAnswerCollectionToDatabase(currentAnswers.first!, post: answerCollectionPost, completion: {(success, error) in
            if let delegate = self.delegate {
                delegate.doneUploadingAnswer(self)
            }
        })
    }
    
    ///User clicked save to album button
    func _save(_ sender: UIButton!) {
        _controlsOverlay.addSavingLabel("Saving...")
        
        if currentAnswer.aType == .recordedVideo || currentAnswer.aType == .albumVideo {
            _saveVideoToAlbum(currentAnswer.aURL as URL)
        } else if currentAnswer.aType == .recordedVideo || currentAnswer.aType == .albumVideo {
            _saveImageToAlbum(currentAnswer.aImage!)
        }
        else {
            _controlsOverlay.hideSavingLabel("Sorry error saving file")
        }
    }
    
    ///Save to photoalbum and show saving dialog
    fileprivate func _saveVideoToAlbum(_ url: URL) {
        let _ = PHPhotoLibrary.shared().performChanges({
            let _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }, completionHandler: { success, error in
                if success {
                    DispatchQueue.main.async {
                        self._controlsOverlay.hideSavingLabel("Saved video!")
                    }
                } else {
                    DispatchQueue.main.async {
                        self._controlsOverlay.hideSavingLabel("Sorry there was an error")
                    }
                }
        })
    }
    
    ///Save to photoalbum and show saving dialog
    fileprivate func _saveImageToAlbum(_ image: UIImage) {
        let _ = PHPhotoLibrary.shared().performChanges({
            let _ = PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, error in
                if success {
                    DispatchQueue.main.async {
                        self._controlsOverlay.hideSavingLabel("Saved image!")
                    }
                } else {
                    DispatchQueue.main.async {
                        self._controlsOverlay.hideSavingLabel("Sorry there was an error")
                    }
                }
        })
    }
}
