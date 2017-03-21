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
    public var currentItem : Item! {
        didSet {
            if currentItem != nil {
                view.addSubview(controlsOverlay)
                controlsOverlay.title = currentItem.itemTitle
                currentItem.itemTitle != "" ? controlsOverlay.showAddTitleField(makeFirstResponder: false) : controlsOverlay.clearAddTitleField()
                setupOverlayButtons()
                
                if currentItem.contentType == .recordedVideo || currentItem.contentType == .albumVideo {
                    setupVideoForAnswer()
                } else if currentItem.contentType == .recordedImage || currentItem.contentType == .albumImage {
                    setupImageForAnswer()
                }
            }
        }
    }
    
    public var selectedChannelID : String! //used to upload to right folders
    public var parentItemID : String! //to add to right collection
    public var coverAdded : Bool = false {
        didSet {
            if coverAdded {
                _post()
            }
        }
    }
    
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
                isNewEntry = false //return after user dismissed camera with existing videos to show
            } else {
                controlsOverlay.addPagers()
            }
        }
    }
    
    weak var delegate : ContentDelegate?
    
    fileprivate lazy var controlsOverlay : RecordingOverlay = RecordingOverlay(frame: self.view.bounds)
    fileprivate var itemFilters : FiltersOverlay?
    fileprivate var isVideoLoaded = false
    fileprivate var isImageViewLoaded = false
    
    fileprivate var aPlayer : AVQueuePlayer!
    fileprivate var avPlayerLayer : AVPlayerLayer!
    fileprivate var imageView : UIImageView!
    fileprivate var currentVideo : AVPlayerItem!
    fileprivate var looper : AVPlayerLooper!
    
    fileprivate var itemCollectionPost = [ String : String ]()
    
    fileprivate var mode : AddOrPostMode?
    enum AddOrPostMode {
        case post
        case add
    }
    fileprivate var placeholderText = "add a title"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        aPlayer.pause()
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
        
        currentVideo = AVPlayerItem(url: contentURL)
        
        if !isVideoLoaded {
            aPlayer = AVQueuePlayer(items: [currentVideo])
            avPlayerLayer = AVPlayerLayer(player: aPlayer)
            avPlayerLayer.frame = view.bounds
            avPlayerLayer.backgroundColor = UIColor.white.cgColor
        
            isVideoLoaded = true
        } else {
            arrangeViews()

            aPlayer.removeAllItems()
            aPlayer.insert(currentVideo, after: nil)
            aPlayer.advanceToNextItem()
        }
        
        //reorder views so controls & filters are still on top
        
        looper = AVPlayerLooper(player: aPlayer, templateItem: currentVideo)
        
        view.layer.addSublayer(avPlayerLayer)
        arrangeViews()
        
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
        
        controlsOverlay.getTitleField().delegate = self
    }
    
    fileprivate func updateItemTitle(text : String) {
        recordedItems[self.currentItemIndex - 1].itemTitle = text
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        controlsOverlay.endEditing(true)
    }

    func _addMore() {
        if recordedItems.count == 1, recordedItems.first?.itemTitle == "" {
            mode = .add
            controlsOverlay.showAddTitleField(makeFirstResponder: true, placeholderText: placeholderText)
        } else if let delegate = delegate {
            delegate.addMoreItems(self, recordedItems: recordedItems, isCover : false)
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
        if recordedItems.count == 1, recordedItems.first?.itemTitle == "" {
            //add a title if there is none and is first post
            mode = .add
            controlsOverlay.showAddTitleField(makeFirstResponder: true, placeholderText: placeholderText)
        } else {
            controlsOverlay.getButton(.post).isEnabled = false
            aPlayer.pause()
            
            if coverAdded {
                controlsOverlay.addProgressLabel("Posting...")
                controlsOverlay.getButton(.post).backgroundColor = UIColor.darkGray.withAlphaComponent(1)
                uploadItems(allItems: recordedItems)
            } else {
                confirmPost()
            }
        }
    }
    
    fileprivate func confirmPost() {
        let confirmLogout = UIAlertController(title: "Post", message: "Would you like to add a cover image? Cover images help content stand out.",
                                              preferredStyle: .actionSheet)
        
        confirmLogout.addAction(UIAlertAction(title: "Choose Cover", style: .default, handler: { (action: UIAlertAction!) in
            if let delegate = self.delegate {
                delegate.addMoreItems(self, recordedItems: self.recordedItems, isCover : true)
            }
        }))
        
        confirmLogout.addAction(UIAlertAction(title: "Continue Posting", style: .destructive, handler: { (action: UIAlertAction!) in
            self.controlsOverlay.addProgressLabel("Posting...")
            self.controlsOverlay.getButton(.post).backgroundColor = UIColor.darkGray.withAlphaComponent(1)
            self.uploadItems(allItems: self.recordedItems)
        }))
        
        confirmLogout.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            confirmLogout.dismiss(animated: true, completion: nil)
        }))
        
        present(confirmLogout, animated: true, completion: nil)
    }
    
    ///upload video to firebase and update current answer with URL upon success
    fileprivate func uploadItems( allItems : [Item]) {
        
        var allItems = allItems //needed because parameters are lets so can't mutate
        
        guard let item = allItems.last else {
            self.doneCreatingAnswer()
            return
        }
        guard let contentType = item.contentType else { return }
        
        if let _image = item.content as? UIImage  {
            Database.uploadThumbImage(channelID: selectedChannelID, itemID: item.itemID, image: _image, completion: { (success, error) in } )
        }
        
        if contentType == .recordedVideo || contentType == .albumVideo {
            uploadVideo(item, completion: {(success, _itemID) in
                self.itemCollectionPost[item.itemID] = item.type.rawValue
                allItems.removeLast()
                self.uploadItems(allItems: allItems)
            })
        }
        else if contentType == .recordedImage || contentType == .albumImage, let _image = item.content as? UIImage {
            let path = storageRef.child("channels").child(selectedChannelID).child(item.itemID).child("content")
            
            let data = _image.mediumQualityJPEGNSData
                
            let _metadata = FIRStorageMetadata()
            _metadata.contentType = "image/jpeg"
            
            uploadTask = path.put(data, metadata: _metadata) { metadata, error in
                if (error != nil) {
                    GlobalFunctions.showErrorBlock("Error Posting Answer", erMessage: error!.localizedDescription)
                } else {
                    item.contentURL = metadata?.downloadURL()
                    
                    Database.addItemToDatabase(item, channelID: self.selectedChannelID, completion: {(success, error) in
                        if !success {
                            GlobalFunctions.showErrorBlock("Error Posting Answer", erMessage: error!.localizedDescription)
                        } else {
                            self.itemCollectionPost[item.itemID] = item.type.rawValue
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

            let metadata = FIRStorageMetadata()
            metadata.contentType = "video/mp4"
            
            do {
                let attr:NSDictionary? = try FileManager.default.attributesOfItem(atPath: localFile.path) as NSDictionary?
                if let _attr = attr {
                    fileSize = _attr.fileSize()
                }
            } catch { }
            
            let path = storageRef.child("channels").child(selectedChannelID).child(item.itemID).child("content")
            
            do {
                let assetData = try Data(contentsOf: localFile)
                
                uploadTask = path.put(assetData, metadata: metadata) { metadata, error in
                    if (error != nil) {
                        GlobalFunctions.showErrorBlock(viewController: self, erTitle: "Error Posting Answer", erMessage: error!.localizedDescription)
                    } else {
                        // Metadata contains file metadata such as size, content-type, and download URL. This aURL was causing issues w/ upload
                        item.contentURL = metadata?.downloadURL()
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
            catch { }
            
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
                                             parentItemID: parentItemID,
                                             channelID: selectedChannelID,
                                             post: itemCollectionPost,
                                             completion: {(success, error) in
            if let delegate = self.delegate {
                self.itemCollectionPost.removeAll()
                self.recordedItems.removeAll()
                self.currentVideo = nil
                self.looper.disableLooping()
                
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

extension RecordedVideoVC: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text != "" {
            updateItemTitle(text: textView.text)
            textView.resignFirstResponder()
        } else {
            textView.resignFirstResponder()
        }
        
        if mode == .post {
            _post()
        } else if mode == .add {
            _addMore()
        }
    }
    
    func textViewShouldReturn(_ textView: UITextView) -> Bool {
        updateItemTitle(text: textView.text)
        textView.resignFirstResponder()
        
        if mode == .post {
            _post()
        } else if mode == .add {
            _addMore()
        }
        
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.text == placeholderText {
            textView.text = ""
            textView.textColor = UIColor.white
        }
        
        if text == "\n" {
            updateItemTitle(text: textView.text)
            textView.resignFirstResponder()
            return false
        }
        
        return textView.text.characters.count + (text.characters.count - range.length) <= 120
    }
}
