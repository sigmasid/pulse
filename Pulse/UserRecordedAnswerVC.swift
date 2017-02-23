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

class RecordedVideoVC: UIViewController, UIGestureRecognizerDelegate {
    
    fileprivate var uploadTask : FIRStorageUploadTask!
    
    // set by the delegate
    var currentItem : Item! {
        didSet {
            view.addSubview(controlsOverlay)
            setupOverlayButtons()
            
            if currentItem.contentType == .recordedVideo || currentItem.contentType == .albumVideo {
                setupVideoForAnswer()
            } else if currentItem.contentType == .recordedImage || currentItem.contentType == .albumImage {
                setupImageForAnswer()
            }
        }
    }
    
    var selectedChannelID : String! //used to upload to right folders
    
    //includes currentItem - set by delegate - the image / video is replaced after processing when uploading file or adding more
    var recordedItems = [Item]()
    var isNewEntry = true //don't reprocess video / image if the user is returning back to prior entry
    
    var currentItemIndex : Int = 0 {
        didSet {
            if currentItemIndex == 0 {
                if let delegate = delegate {
                    delegate.userDismissedRecording(self, recordedItems : recordedItems)
                }
            } else {
                currentItem = recordedItems[currentItemIndex - 1] // adjust for array index vs. count
            }
        }
        willSet {
            if newValue < currentItemIndex {
                isNewEntry = false
            } else {
                controlsOverlay.addPagers()
            }
        }
    }
    
    weak var delegate : childVCDelegate?
    
    fileprivate lazy var controlsOverlay : RecordingOverlay = RecordingOverlay(frame: self.view.bounds)
    fileprivate var itemFilters : FiltersOverlay?
    fileprivate var isVideoLoaded = false
    fileprivate var isImageViewLoaded = false
    
    fileprivate var aPlayer : AVPlayer!
    fileprivate var avPlayerLayer : AVPlayerLayer!
    fileprivate var imageView : UIImageView!
    
    fileprivate var itemCollectionPost = [ String : Bool ]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    fileprivate func setupImageForAnswer() {
        if !isImageViewLoaded {
            imageView = UIImageView(frame: view.bounds)
            imageView.contentMode = .scaleAspectFill
            view.addSubview(imageView)
            
            isImageViewLoaded = true
        }
        
        view.bringSubview(toFront: imageView)
        arrangeViews()
        
        imageView.image = currentItem.content as? UIImage
    }
    
    fileprivate func setupVideoForAnswer() {
        //don't create new AVPlayer if it already exists
        guard let contentURL = currentItem.contentURL else { return }
        if !isVideoLoaded {
            aPlayer = AVPlayer()
            
            avPlayerLayer = AVPlayerLayer(player: aPlayer)
            avPlayerLayer.frame = view.bounds
            avPlayerLayer.backgroundColor = UIColor.darkGray.cgColor
            
            isVideoLoaded = true
        }
        
        //reorder views so controls & filters are still on top
        view.layer.addSublayer(avPlayerLayer)
        arrangeViews()
        
        aPlayer.replaceCurrentItem(with: nil)
        
        let currentVideo = AVPlayerItem(url: contentURL)
        aPlayer.replaceCurrentItem(with: currentVideo)
        aPlayer.play()
        
        if isNewEntry && currentItem.contentType == .albumVideo || currentItem.contentType == .recordedVideo {
            DispatchQueue.global(qos: .background).async {
                compressVideo(contentURL, completion: {(resultURL, thumbnailImage, error) in
                    if let resultURL = resultURL {
                        self.currentItem.contentURL = resultURL
                        self.currentItem.content = thumbnailImage
                        self.recordedItems[self.currentItemIndex - 1] = self.currentItem
                    } else {

                        let videoAsset = AVAsset(url: contentURL)
                        let thumbImage = thumbnailForVideoAtURL(videoAsset, orientation: .left)

                        self.currentItem.content = thumbImage
                        self.recordedItems[self.currentItemIndex - 1] = self.currentItem
                    }
                })
            }
        }
    }
    
    //move the controls and filters to top layer
    fileprivate func arrangeViews() {
        if itemFilters != nil {
            view.bringSubview(toFront: itemFilters!)
        }
        view.bringSubview(toFront: controlsOverlay)
    }
    
    func gestureRecognizer(_ gesture: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer : UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func setupOverlayButtons() {
        controlsOverlay.getButton(.post).addTarget(self, action: #selector(_post), for: UIControlEvents.touchUpInside)
        controlsOverlay.getButton(.save).addTarget(self, action: #selector(_save), for: UIControlEvents.touchUpInside)
        controlsOverlay.getButton(.close).addTarget(self, action: #selector(_close), for: UIControlEvents.touchUpInside)
        controlsOverlay.getButton(.addMore).addTarget(self, action: #selector(_addMore), for: UIControlEvents.touchUpInside)
    }
    
    func _addMore() {
        if let delegate = delegate {
            delegate.addMoreItems(self, recordedItems: recordedItems)
        }
    }
    
    ///close window and go back to camera
    func _close() {
        // need to check if it was first answer -> if yes, go to camera else stay in UserRecordedAnswer and go back to last question, remove the current answer value from recordedItems
        controlsOverlay.removePager()
        recordedItems.remove(at: currentItemIndex - 1)
        currentItemIndex = currentItemIndex - 1
    }
    
    ///post video to firebase
    func _post() {
        controlsOverlay.getButton(.post).isEnabled = false
        aPlayer.pause()

        if User.isLoggedIn() {
            controlsOverlay.addProgressLabel("Posting...")
            controlsOverlay.getButton(.post).backgroundColor = UIColor.darkGray.withAlphaComponent(1)
            uploadItems(allItems: recordedItems)
        } else {
            if let delegate = delegate {
                controlsOverlay.getButton(.post).isEnabled = true
                delegate.askUserToLogin(self)
            }
        }
    }
    
    ///upload video to firebase and update current answer with URL upon success
    fileprivate func uploadItems( allItems : [Item]) {
        
        var allItems = allItems //needed because parameters are lets so can't edit
        guard let item = allItems.last else {
            self.doneCreatingAnswer()
            return
        }
        guard let contentType = item.contentType else { return }
        
        if let _image = item.content as? UIImage  {
            Database.uploadImage(.AnswerThumbs, fileID: item.itemID, image: _image, completion: { (success, error) in } )
        }
        
        if contentType == .recordedVideo || contentType == .albumVideo {
            uploadVideo(item, completion: {(success, _itemID) in
                allItems.removeLast()
                self.uploadItems(allItems: allItems)
            })
        }
        else if contentType == .recordedImage || contentType == .albumImage, let _image = item.content as? UIImage {
            let path = storageRef.child("channels").child(selectedChannelID).child(item.itemID)
            
            let data = _image.mediumQualityJPEGNSData
                
            let _metadata = FIRStorageMetadata()
            _metadata.contentType = "image/jpeg"
            
            uploadTask = path.put(data, metadata: _metadata) { metadata, error in
                if (error != nil) {
                    GlobalFunctions.showErrorBlock("Error Posting Answer", erMessage: error!.localizedDescription)
                } else {
                    // Metadata contains file metadata such as size, content-type, and download URL. This aURL was causing issues w/ upload
                    item.contentURL = metadata?.downloadURL()
                    
                    Database.addItemToDatabase(item, channelID: self.selectedChannelID, completion: {(success, error) in
                        if !success {
                            GlobalFunctions.showErrorBlock("Error Posting Answer", erMessage: error!.localizedDescription)
                        } else {
                            self.itemCollectionPost[item.itemID] = true
                            allItems.removeLast()
                            self.uploadItems(allItems: allItems)
                        }
                    })
                }
            }
        }
    }
    
    fileprivate func uploadVideo(_ item : Item, completion: @escaping (_ success : Bool, _ _itemID : String?) -> Void) {
        var fileSize = UInt64()
        controlsOverlay.addUploadProgressBar()
        
        if let localFile: URL = item.contentURL as URL? {
            print("file to upload link is \(localFile)")

            let metadata = FIRStorageMetadata()
            metadata.contentType = "video/mp4"
            
            do {
                let attr:NSDictionary? = try FileManager.default.attributesOfItem(atPath: localFile.path) as NSDictionary?
                if let _attr = attr {
                    fileSize = _attr.fileSize()
                }
            } catch { }
            
            let path = storageRef.child("channels").child(selectedChannelID).child(item.type.rawValue).child(item.itemID)
            
            do {
                let assetData = try Data(contentsOf: localFile)
                
                uploadTask = path.put(assetData, metadata: metadata) { metadata, error in
                    if (error != nil) {
                        GlobalFunctions.showErrorBlock(viewController: self, erTitle: "Error Posting Answer", erMessage: error!.localizedDescription)
                    } else {
                        // Metadata contains file metadata such as size, content-type, and download URL. This aURL was causing issues w/ upload
                        item.contentURL = metadata?.downloadURL()
                        print("download url is \(metadata?.downloadURL())")
                        Database.addItemToDatabase(item, channelID: self.selectedChannelID, completion: {(success, error) in
                            if !success {
                                GlobalFunctions.showErrorBlock("Error Posting Item", erMessage: error!.localizedDescription)
                                completion(false, nil)
                            } else {
                                self.uploadTask.removeAllObservers()
                                completion(true, item.itemID)
                            }
                        })
                    }
                }
            }
            catch {
                print("went into catch")
            }
            
            /*
             //NEED TO CHECK IF THIS STILL WORKS - FOR FAILURE & SUCCESS
             uploadTask.observe(.success) { snapshot in
             print("successfully added file to storage")
             self.currentItem.aURL = snapshot.metadata?.downloadURL()
             
             Database.addUserAnswersToDatabase( answer, completion: {(success, error) in
             if !success {
             print("error adding file to database")
             GlobalFunctions.showErrorBlock("Error Posting Answer", erMessage: error!.localizedDescription)
             completion(false, nil)
             } else {
             print("successfully uploaded to real time database")
             
             self.uploadTask.removeAllObservers()
             completion(true, answer.aID)
             }
             })
             }
             
             uploadTask.observe(.failure) { snapshot in
             if let _error = snapshot.error {
             print("went into error posting video")
             GlobalFunctions.showErrorBlock("Error Posting Video", erMessage: _error.localizedDescription)
             }
             } */
            
            uploadTask.observe(.progress) { snapshot in
                if fileSize > 0 {
                    let percentComplete = Float(snapshot.progress!.completedUnitCount) / Float(fileSize)
                    DispatchQueue.main.async {
                        self.controlsOverlay.updateProgressBar(percentComplete)
                    }
                }
            }
        }
    }
    
    ///Called after user has uploaded full answer
    fileprivate func doneCreatingAnswer() {
        Database.addItemCollectionToDatabase(recordedItems.first!,
                                             channelID: selectedChannelID,
                                             post: itemCollectionPost,
                                             completion: {(success, error) in
            if let delegate = self.delegate {
                delegate.doneUploadingAnswer(self)
            }
        })
    }
    
    ///User clicked save to album button
    func _save(_ sender: UIButton!) {
        controlsOverlay.addProgressLabel("Saving...")
        
        if currentItem.contentType == .recordedVideo || currentItem.contentType == .albumVideo, let contentURL = currentItem.contentURL {
            _saveVideoToAlbum(contentURL)
        } else if currentItem.contentType == .recordedImage || currentItem.contentType == .albumImage, let _image = currentItem.content as? UIImage {
            _saveImageToAlbum(_image)
        }
        else {
            controlsOverlay.hideProgressLabel("Sorry error saving file")
        }
    }
    
    ///Save to photoalbum and show saving dialog
    fileprivate func _saveVideoToAlbum(_ url: URL) {
        let _ = PHPhotoLibrary.shared().performChanges({
            let _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }, completionHandler: { success, error in
            if success {
                DispatchQueue.main.async {
                    self.controlsOverlay.hideProgressLabel("Saved video!")
                }
            } else {
                DispatchQueue.main.async {
                    self.controlsOverlay.hideProgressLabel("Sorry there was an error")
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
                    self.controlsOverlay.hideProgressLabel("Saved image!")
                }
            } else {
                DispatchQueue.main.async {
                    self.controlsOverlay.hideProgressLabel("Sorry there was an error")
                }
            }
        })
    }
}
