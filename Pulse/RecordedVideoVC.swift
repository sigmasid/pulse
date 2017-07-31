//
//  RecordedVideoVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation
import Photos

class RecordedVideoVC: UIViewController, UIGestureRecognizerDelegate, AddCoverDelegate {
    fileprivate var uploadTask : StorageUploadTask!
    
    // set by the delegate
    public var currentItem : Item! {
        didSet {
            if currentItem != nil, let itemType = currentItem.contentType {
                controlsOverlay.updateControls(type: itemType)
                view.addSubview(controlsOverlay)
                
                addButtonTargets()
                
                switch itemType {
                case .recordedVideo, .albumVideo:
                    setupVideo()
                    controlsOverlay.title = currentItem.itemTitle
                    currentItem.itemTitle != "" ? controlsOverlay.showAddTitleField(makeFirstResponder: false) : controlsOverlay.clearAddTitleField()
                    currentMode = .video
                case .recordedImage, .albumImage:
                    setupImageView()
                    controlsOverlay.title = currentItem.itemTitle
                    currentItem.itemTitle != "" ? controlsOverlay.showAddTitleField(makeFirstResponder: false) : controlsOverlay.clearAddTitleField()
                    currentMode = .image
                    
                case .postcard:
                    setupTextView(text: currentItem.itemTitle)
                    controlsOverlay.clearAddTitleField()
                    currentMode = .text
                }
            }
        }
    }
    
    public var selectedChannelID : String! //used to upload to right folders
    public var parentItem : Item! //to add to right collection
    
    //set after user returns from cover added - if set to true go straight to post
    private var coverAdded : Bool = false {
        didSet {
            if coverAdded {
                _post()
            }
        }
    }
    
    //includes currentItem - set by delegate - the image / video is replaced after processing when uploading file or adding more
    public var recordedItems : [Item]! = [Item]()
    
    //don't reprocess video / image if the user is returning back to prior entry
    public var isNewEntry = false {
        didSet {
            if isNewEntry {
                controlsOverlay.addPagers()
            }
        }
    }
    private var coverItem: Item?
    private var currentMode : ContentMode!
    fileprivate var addCoverVC: AddCoverVC?
    
    var currentItemIndex : Int = 0 {
        didSet {
            if recordedItems.count == 0 {
                //no other items in stack so dismiss recording
                delegate?.userDismissedRecording(self, recordedItems : recordedItems)
            } else {
                currentItem = recordedItems[currentItemIndex] // adjust for array index vs. count
            }
        }
    }
    
    public weak var delegate : ContentDelegate?
    
    fileprivate lazy var controlsOverlay : RecordingOverlay = RecordingOverlay(frame: self.view.bounds)
    
    fileprivate var imageView : ImageCropView!
    fileprivate var textBox : RecordedTextView!
    fileprivate var aPlayer : AVQueuePlayer!
    fileprivate var avPlayerLayer : AVPlayerLayer!
    fileprivate var currentVideo : AVPlayerItem!
    fileprivate var looper : AVPlayerLooper!
    
    fileprivate var itemCollectionPost = [ String : String ]()
    fileprivate var cleanupComplete = false
    
    fileprivate var placeholderText = "add a title"
    
    deinit {
        performCleanup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if aPlayer != nil {
            aPlayer.pause()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        restartPlayer()
    }
    
    private func restartPlayer() {
        if currentMode == .video, aPlayer != nil, aPlayer.currentItem != nil {
            aPlayer.play()
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    fileprivate func setupImageView() {
        if imageView == nil {
            imageView = ImageCropView(frame: view.frame)
            view.addSubview(imageView)
        }
        
        view.bringSubview(toFront: imageView)
        arrangeViews()
        
        imageView.image = currentItem.content
    }
    
    fileprivate func setupTextView(text: String) {
        if textBox == nil {
            textBox = RecordedTextView(frame: view.bounds, text: text)
            view.addSubview(textBox)
        }
        
        textBox.textToShow = text
        textBox.isEditable = false
        
        view.bringSubview(toFront: textBox)
        arrangeViews()
    }
    
    fileprivate func setupVideo() {
        //don't create new AVPlayer if it already exists
        guard let contentURL = currentItem.contentURL else { return }
        currentVideo = AVPlayerItem(url: contentURL)
        
        if avPlayerLayer == nil || aPlayer == nil {
            aPlayer = AVQueuePlayer(items: [currentVideo])
            avPlayerLayer = AVPlayerLayer(player: aPlayer)
            avPlayerLayer.frame = view.bounds
            avPlayerLayer.backgroundColor = UIColor.black.cgColor
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
        
        if isNewEntry {
            DispatchQueue.global(qos: .background).async {
                compressVideo(contentURL, completion: {[weak self] (resultURL, thumbnailImage, error) in
                    guard let `self` = self, !self.recordedItems.isEmpty else {
                        return
                    }
                    
                    if let resultURL = resultURL {
                        self.currentItem.contentURL = resultURL
                        self.currentItem.content = thumbnailImage
                        self.recordedItems[self.currentItemIndex] = self.currentItem
                    } else {
                        let videoAsset = AVAsset(url: contentURL)
                        let thumbImage = thumbnailForVideoAtURL(videoAsset, orientation: .left)

                        self.currentItem.content = thumbImage
                        self.recordedItems[self.currentItemIndex] = self.currentItem
                    }
                    
                    self.isNewEntry = false
                })
            }
        }
    }
    
    //move the controls and filters to top layer
    fileprivate func arrangeViews() {
        view.bringSubview(toFront: controlsOverlay)
    }
    
    func gestureRecognizer(_ gesture: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer : UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func addButtonTargets() {
        controlsOverlay.getButton(.post).addTarget(self, action: #selector(_post), for: UIControlEvents.touchUpInside)
        controlsOverlay.getButton(.save).addTarget(self, action: #selector(_save), for: UIControlEvents.touchUpInside)
        controlsOverlay.getButton(.close).addTarget(self, action: #selector(_close), for: UIControlEvents.touchUpInside)
        controlsOverlay.getButton(.addMore).addTarget(self, action: #selector(_addMore), for: UIControlEvents.touchUpInside)
        
        controlsOverlay.getButton(.goUp).addTarget(self, action: #selector(_goUp), for: UIControlEvents.touchUpInside)
        controlsOverlay.getButton(.goDown).addTarget(self, action: #selector(_goDown), for: UIControlEvents.touchUpInside)
        
        controlsOverlay.getTitleField().delegate = self
        controlsOverlay.updatePostLabel(text: currentItem.cameraButtonText())
    }
    
    //takes the title from the text box and adds it to the last time
    fileprivate func updateItemTitle(text : String) {
        recordedItems[currentItemIndex].itemTitle = text
    }
    
    fileprivate func updateItemImage() {
        recordedItems[currentItemIndex].content = imageView.getCroppedImage()?.resizeImage(newWidth: FULL_IMAGE_WIDTH)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        controlsOverlay.endEditing(true)
    }
    
    internal func updateItems() {
        guard let type = currentItem.contentType else { return }
        switch type {
        case .albumImage, .recordedImage:
            updateItemImage()
        case .postcard:
            updateItemTitle(text: textBox.finalText)
        default: break
        }
    }
    
    internal func _goUp() {
        guard currentItemIndex > 0 else {
            //check if can go up - if not then ignore
            return
        }
        
        controlsOverlay.selectPager(at: currentItemIndex - 1, prior: currentItemIndex)
        currentItemIndex = currentItemIndex - 1
    }
    
    internal func _goDown() {
        guard currentItemIndex < recordedItems.count - 1 else {
            //check if can go down - if not then ignore
            return
        }
        
        controlsOverlay.selectPager(at: currentItemIndex + 1, prior: currentItemIndex)
        currentItemIndex = currentItemIndex + 1
    }

    func _addMore() {
        updateItems()
        if recordedItems.count < MAX_ITEM_COUNT {
            delegate?.addMoreItems(self, recordedItems: recordedItems)
        } else {
            GlobalFunctions.showAlertBlock(viewController: self,
                                           erTitle: "Max Limit Reached",
                                           erMessage: "Sorry! You can only have 7 items for any new entry! This keeps the content short & interesting for your viewers.")
        }
    }
    
    ///close window and go back to camera
    internal func _close() {
        // need to check if it was first item -> if yes, go to camera else stay in RecordedVideoVC and 
        // go back to last question, remove the current item value from recordedItems
        controlsOverlay.removePager(at: currentItemIndex)
        recordedItems.remove(at: currentItemIndex)
        
        //if more than 1 total items then go back one else go to the only item 0
        currentItemIndex = currentItemIndex > 0 ? currentItemIndex - 1 : 0
    }
    
    ///post video to firebase
    internal func _post() {
        updateItems()
        
        if aPlayer != nil {
            aPlayer.pause()
        }
            
        if currentItem.needsCover() && !coverAdded {
            addCoverVC = AddCoverVC()
            addCoverVC?.delegate = self
            navigationController?.pushViewController(addCoverVC!, animated: true)
        } else {
            //continue w/ the post
            controlsOverlay.addProgressLabel("Posting...")
            controlsOverlay.getButton(.post).backgroundColor = UIColor.darkGray.withAlphaComponent(1)
            uploadItems(allItems: recordedItems)
        }
    }
    
    internal func createCoverItem() {
        guard coverItem == nil else { return }
        
        let itemKey = databaseRef.child("items").childByAutoId().key
        
        coverItem = Item(itemID: itemKey,
                        itemUserID: PulseUser.currentUser.uID!,
                        itemTitle: "",
                        type: currentItem.type,
                        tag: currentItem.tag,
                        cID: currentItem.cID)
        
        coverItem?.cTitle = currentItem.cTitle
    }
    
    /** ADD COVER DELEGATE **/
    internal func addCover(image: UIImage, title: String, location: CLLocation?, assetType: CreatedAssetType) {
        navigationController?.popViewController(animated: true)
        
        if addCoverVC != nil {
            addCoverVC?.performCleanup()
            addCoverVC = nil
        }
        
        createCoverItem()
        
        coverItem!.itemTitle = title
        coverItem!.content = image
        coverItem!.contentType = assetType
        
        recordedItems.append(coverItem!)
        coverAdded = true
        _post()
    }
    
    internal func dismissAddCover() {
        restartPlayer()
    }
    /** END ADD COVER DELEGATE **/
    
    ///upload video to firebase and update current item with URL upon success
    fileprivate func uploadItems( allItems : [Item]) {
        
        var allItems = allItems //needed because parameters are lets so can't mutate
        
        guard let item = allItems.last else {
            self.doneCreatingItem()
            return
        }
        guard let contentType = item.contentType else { return }
        
        if let _image = item.content  {
            let thumbImageData : Data? = _image.resizeImage(newWidth: ITEM_THUMB_WIDTH)?.mediumQualityJPEGNSData
            PulseDatabase.uploadImageData(channelID: selectedChannelID, itemID: item.itemID, imageData: thumbImageData, fileType: .thumb, completion: { _ in })
        }
        
        switch contentType {
        case .recordedVideo, .albumVideo:
            uploadVideo(item, completion: {[weak self] (success, _itemID) in
                guard let `self` = self else { return }
                
                self.itemCollectionPost[item.itemID] = item.type.rawValue
                allItems.removeLast()
                self.uploadItems(allItems: allItems)
            })
        case .recordedImage, .albumImage:
            guard let image = item.content else { return }
            PulseDatabase.uploadImage(channelID: selectedChannelID, itemID: item.itemID, image: image, fileType: .content, completion: {[weak self] metadata, error in
                guard let `self` = self else { return }
                
                if (error != nil) {
                    GlobalFunctions.showAlertBlock("Error Posting Item", erMessage: error!.localizedDescription)
                } else {
                    item.contentURL = metadata?.downloadURL()
                    
                    PulseDatabase.addItemToDatabase(item, channelID: self.selectedChannelID, completion: {[weak self] (success, error) in
                        guard let `self` = self else { return }
                        if !success {
                            GlobalFunctions.showAlertBlock("Error Posting Item", erMessage: error!.localizedDescription)
                        } else {
                            self.itemCollectionPost[item.itemID] = item.type.rawValue
                            allItems.removeLast()
                            self.uploadItems(allItems: allItems)
                        }
                    })
                }
            })
        case .postcard:
            PulseDatabase.addItemToDatabase(item, channelID: selectedChannelID, completion: {[weak self] (success, error) in
                guard let `self` = self else { return }
                if !success {
                    GlobalFunctions.showAlertBlock("Error Posting Item", erMessage: error!.localizedDescription)
                } else {
                    self.itemCollectionPost[item.itemID] = item.type.rawValue
                    allItems.removeLast()
                    self.uploadItems(allItems: allItems)
                }
            })
        }
    }
    
    fileprivate func uploadVideo(_ item : Item, completion: @escaping (_ success : Bool, _ _itemID : String?) -> Void) {
        var fileSize = UInt64()
        controlsOverlay.addUploadProgressBar()
        
        if let localFile: URL = item.contentURL as URL? {

            let metadata = StorageMetadata()
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
                
                uploadTask = path.putData(assetData, metadata: metadata) {[weak self] metadata, error in
                    guard let `self` = self else { return }

                    if (error != nil) {
                        GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Error Posting Item", erMessage: error!.localizedDescription)
                    } else {
                        // Metadata contains file metadata such as size, content-type, and download URL. This aURL was causing issues w/ upload
                        item.contentURL = metadata?.downloadURL()
                        PulseDatabase.addItemToDatabase(item, channelID: self.selectedChannelID, completion: {[weak self] (success, error) in
                            guard let `self` = self else { return }

                            if !success {
                                GlobalFunctions.showAlertBlock("Error Posting Item", erMessage: error!.localizedDescription)
                                self.uploadTask.removeAllObservers()
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
            
            uploadTask.observe(.progress) {[unowned self] snapshot in
                if fileSize > 0 {
                    let percentComplete = Float(snapshot.progress!.completedUnitCount) / Float(fileSize)
                    DispatchQueue.main.async {
                        self.controlsOverlay.updateProgressBar(percentComplete)
                    }
                }
            }
        }
    }
    
    ///Called after user has uploaded full item
    fileprivate func doneCreatingItem() {
        guard let firstItem = coverItem != nil ? coverItem : recordedItems.first else { return }
        
        PulseDatabase.addItemCollectionToDatabase(firstItem,
                                             parentItem: parentItem,
                                             channelID: selectedChannelID,
                                             post: itemCollectionPost,
                                             completion: {[weak self] (success, error) in
            guard let `self` = self else { return }

            if success {
                self.itemCollectionPost.removeAll()
                self.recordedItems.removeAll()
                self.currentVideo = nil
                
                if self.looper != nil { self.looper.disableLooping() }
                
                self.delegate?.doneUploadingItem(self, item: firstItem, success: success)
                Analytics.logEvent("created_content", parameters: ["type": self.parentItem.type.rawValue as NSObject,
                                                                   "item_id": firstItem.itemID as NSObject,
                                                                   "item_title": self.parentItem.itemTitle as NSObject ])
            } else {
                DispatchQueue.main.async {
                    GlobalFunctions.showAlertBlock("Error Posting", erMessage: error?.localizedDescription)
                }
           }
        })
    }
    
    ///User clicked save to album button
    func _save(_ sender: UIButton!) {
        guard let type = currentItem.contentType else { return }
        controlsOverlay.addProgressLabel("Saving...")
        
        switch type {
        case .recordedVideo, .albumVideo:
            currentItem.contentURL != nil ? _saveVideoToAlbum(currentItem.contentURL!) : controlsOverlay.hideProgressLabel("Sorry error saving file")
        case .recordedImage, .albumImage:
            currentItem.content != nil ? _saveImageToAlbum(currentItem.content!) : controlsOverlay.hideProgressLabel("Sorry error saving file")
        case .postcard:
            break
        }
    }
    
    ///Save to photoalbum and show saving dialog
    fileprivate func _saveVideoToAlbum(_ url: URL) {
        let _ = PHPhotoLibrary.shared().performChanges({
            let _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }, completionHandler: {[weak self] success, error in
            guard let `self` = self else { return }

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
        }, completionHandler: {[weak self] success, error in
            guard let `self` = self else { return }

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
    
    public func performCleanup() {
        if !cleanupComplete {
            uploadTask = nil
            currentItem = nil
            parentItem = nil
            recordedItems.removeAll()
            recordedItems = nil
            delegate = nil
            
            if addCoverVC != nil {
                addCoverVC?.performCleanup()
                addCoverVC = nil
            }
            
            if aPlayer != nil {
                aPlayer.removeAllItems()
                aPlayer = nil
                looper = nil
                currentVideo = nil
            }
            
            if imageView != nil {
                imageView.image = nil
                imageView = nil
            }
            
            itemCollectionPost.removeAll()
            cleanupComplete = true
        }
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
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            let currentHeight = textView.frame.height
            let sizeThatFitsTextView = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
            
            if currentHeight != sizeThatFitsTextView.height {
                //if new height is bigger, move the text view up and increase height
                textView.frame = CGRect(x: textView.frame.origin.x, y: textView.frame.origin.y - (sizeThatFitsTextView.height - currentHeight),
                                        width: textView.frame.width, height: sizeThatFitsTextView.height)
                textView.textContainer.size = CGSize(width: textView.frame.width, height: textView.frame.height)
            }
        }
    }
    
    func textViewShouldReturn(_ textView: UITextView) -> Bool {
        updateItemTitle(text: textView.text)
        textView.resignFirstResponder()
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
