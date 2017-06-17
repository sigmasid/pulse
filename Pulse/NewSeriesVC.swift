//
//  NewSeriesVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/20/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import CoreLocation
import MobileCoreServices

class NewSeriesVC: PulseVC, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    //Set by parent
    public var selectedChannel : Channel! {
        didSet {
            if selectedChannel != nil {
                PulseDatabase.getSeriesTypes(completion: { seriesTypes in
                    self.allItems = seriesTypes
                    self.updateDataSource()
                })
            }
        }
    }
    
    //UI Vars
    fileprivate var sAddCover = UIView()
    fileprivate var sShowCamera = PulseButton(size: .large, type: .camera, isRound: true, background: .white, tint: .black)
    fileprivate var sShowCameraLabel = UILabel()
    
    fileprivate var sTitle = UITextField()
    fileprivate var sDescription = UITextField()
    fileprivate var submitButton = UIButton()
    
    fileprivate var sType = PaddingLabel()
    fileprivate var sTypeDescription = PaddingLabel()
    
    //Collection View Vars
    fileprivate var collectionView : UICollectionView!
    fileprivate var allItems = [Item]()
    fileprivate var centerIndex = 0 {
        didSet {
            updateDescription(index: centerIndex)
        }
    }
    internal var collectionViewLayout: QuickBrowseLayout!
    
    //Capture Image
    internal lazy var panDismissCameraInteractionController = PanContainerInteractionController()
    fileprivate lazy var cameraVC : CameraVC! = CameraVC()
    fileprivate var capturedImage : UIImage?
    fileprivate var contentType : CreatedAssetType? = .recordedImage
    
    //Collection View Animation Vars
    fileprivate var animationsCount = 0
    internal var pageWidth: CGFloat {
        return collectionViewLayout.itemSize.width + collectionViewLayout.minimumLineSpacing
    }
    
    internal var contentOffset: CGFloat {
        return collectionView.contentOffset.x + collectionView.contentInset.left
    }
    fileprivate var cleanupComplete = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            tabBarHidden = true
            updateHeader()
            setupLayout()
            hideKeyboardWhenTappedAround()
            
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader()
    }
    
    deinit {
        performCleanup()
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            selectedChannel = nil
            
            sAddCover.removeFromSuperview()
            sShowCamera.removeFromSuperview()
            sShowCameraLabel.removeFromSuperview()
            
            collectionView = nil
            allItems.removeAll()
            cameraVC = nil
            capturedImage = nil
            panDismissCameraInteractionController.delegate = nil
            collectionViewLayout = nil
            
            cleanupComplete = true
        }
    }
    
    internal func scrollToPage(index: Int, animated: Bool) {
        collectionView.isUserInteractionEnabled = false
        animationsCount += 1
        
        let pageOffset = CGFloat(index) * self.pageWidth - self.collectionView.contentInset.left
        collectionView.setContentOffset(CGPoint(x: pageOffset, y: 0), animated: true)
        
        centerIndex = index
    }
    
    /** HEADER FUNCTIONS **/
    internal func updateHeader() {
        addBackButton()
        
        headerNav?.setNav(title: "Start a New Series", subtitle: selectedChannel.cTitle)
        headerNav?.updateBackgroundImage(image: GlobalFunctions.processImage(selectedChannel.cPreviewImage))
        headerNav?.showNavbar(animated: true)
    }
    
    internal func updateDescription(index: Int) {
        sTypeDescription.text = allItems[index].itemDescription
    }
    
    internal func updateDataSource() {
        if collectionView != nil {
            collectionView?.dataSource = self
            collectionView?.delegate = self
            
            collectionView?.layoutIfNeeded()
            collectionView?.reloadData()
            
            updateDescription(index: centerIndex)
        }
    }
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    internal func updateCell(_ cell: BrowseContentCell, atIndexPath indexPath: IndexPath) {
        if let image = allItems[indexPath.row].content as? UIImage  {
            cell.updateImage(image: image)
        }
        
        if indexPath.row == centerIndex {
            cell.updateLabel("\u{2714}   \(allItems[indexPath.row].itemTitle)", _subtitle: nil)
        } else {
            cell.updateLabel(allItems[indexPath.row].itemTitle, _subtitle: nil)
        }
    }
    
    internal func updateOnscreenRows() {
        if let visiblePaths = collectionView?.indexPathsForVisibleItems {
            for indexPath in visiblePaths {
                let cell = collectionView?.cellForItem(at: indexPath) as! BrowseContentCell
                updateCell(cell, atIndexPath: indexPath)
            }
        }
    }
    
    internal func handleSubmit() {
        let loading = submitButton.addLoadingIndicator()
        submitButton.setDisabled()
        
        let itemKey = databaseRef.child("items").childByAutoId().key
        let item = Item(itemID: itemKey, type: getSelectedType())
        
        item.itemTitle = sTitle.text ?? ""
        item.itemUserID = PulseUser.currentUser.uID
        item.itemDescription = sDescription.text ?? ""
        item.content = capturedImage
        item.contentType = contentType
        item.cID = selectedChannel.cID
        
        PulseDatabase.addNewSeries(channelID: selectedChannel.cID, item: item, completion: { success, error in
            if success, let capturedImage = self.capturedImage {
                PulseDatabase.uploadImage(channelID: item.cID, itemID: itemKey, image: capturedImage, fileType: .content, completion: {(success, error) in
                    success ? self.showSuccessMenu() : self.showErrorMenu(error: error!)
                    loading.removeFromSuperview()
                    self.submitButton.setEnabled()
                })
                PulseDatabase.uploadImage(channelID: item.cID, itemID: itemKey, image: capturedImage, fileType: .thumb, completion: {(success, error) in
                    loading.removeFromSuperview()
                })
            } else {
                loading.removeFromSuperview()
                self.showErrorMenu(error: error!)
            }
        })
    }
    
    internal func getSelectedType() -> String {
        return allItems[centerIndex].itemID
    }
    
    internal func showSuccessMenu() {
        let menu = UIAlertController(title: "Successfully Added Series",
                                     message: "Tap okay to return to the channel page and start creating!",
                                     preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "done", style: .default, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
            self.goBack()
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showErrorMenu(error : Error) {
        let menu = UIAlertController(title: "Error Creating Series", message: error.localizedDescription, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "cancel", style: .default, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
}

extension NewSeriesVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allItems.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int{
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 0.0, bottom: 10.0, right: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BrowseContentCell
        
        let currentItem = allItems[indexPath.row]
        
        
        if indexPath.row == centerIndex {
            cell.updateLabel("\u{2714}   \(currentItem.itemTitle)", _subtitle: nil)
        } else {
            cell.updateLabel(currentItem.itemTitle, _subtitle: nil)
        }
        cell.updateImage(image: allItems[indexPath.row].content as? UIImage)
        
        if !currentItem.fetchedContent {
            PulseDatabase.getSeriesImage(seriesName: self.allItems[indexPath.row].itemID,
                                    fileType: .thumb, maxImgSize: maxImgSize, completion: { (data, error) in
                if let data = data {
                    self.allItems[indexPath.row].content = UIImage(data: data)
                    
                    DispatchQueue.main.async {
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            cell.updateImage(image : self.allItems[indexPath.row].content as? UIImage)
                        }
                    }
                }
                
                self.allItems[indexPath.row].fetchedContent = true
            })
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView.isDragging || collectionView.isDecelerating || collectionView.isTracking {
            return
        }
        
        if indexPath.row != centerIndex {
            scrollToPage(index: indexPath.row, animated: true)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        centerIndex = Int(self.contentOffset / self.pageWidth)
        updateOnscreenRows()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if animationsCount - 1 == 0 {
            collectionView.isUserInteractionEnabled = true
        }
    }
}

//UI Elements
extension NewSeriesVC {
    func setupLayout() {
        view.addSubview(sAddCover)
        view.addSubview(sShowCamera)
        view.addSubview(sShowCameraLabel)

        view.addSubview(sTitle)
        view.addSubview(sDescription)
        view.addSubview(sType)

        view.addSubview(submitButton)
        
        sAddCover.translatesAutoresizingMaskIntoConstraints = false
        sAddCover.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        sAddCover.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        sAddCover.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        sAddCover.heightAnchor.constraint(equalToConstant: 125).isActive = true
        sAddCover.layoutIfNeeded()
        sAddCover.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        
        sShowCamera.translatesAutoresizingMaskIntoConstraints = false
        sShowCamera.centerXAnchor.constraint(equalTo: sAddCover.centerXAnchor).isActive = true
        sShowCamera.centerYAnchor.constraint(equalTo: sAddCover.centerYAnchor).isActive = true
        sShowCamera.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        sShowCamera.widthAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        sShowCamera.layoutIfNeeded()
        
        sShowCamera.addTarget(self, action: #selector(showCamera), for: .touchUpInside)

        sShowCameraLabel.translatesAutoresizingMaskIntoConstraints = false
        sShowCameraLabel.centerXAnchor.constraint(equalTo: sShowCamera.centerXAnchor).isActive = true
        sShowCameraLabel.topAnchor.constraint(equalTo: sShowCamera.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        sShowCameraLabel.text = "add a cover image"
        sShowCameraLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .black, alignment: .center)
        
        sTitle.translatesAutoresizingMaskIntoConstraints = false
        sTitle.topAnchor.constraint(equalTo: sAddCover.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        sTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sTitle.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        sTitle.layoutIfNeeded()
        
        sDescription.translatesAutoresizingMaskIntoConstraints = false
        sDescription.topAnchor.constraint(equalTo: sTitle.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        sDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        sDescription.layoutIfNeeded()
        
        sTitle.delegate = self
        sDescription.delegate = self

        sTitle.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        sDescription.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        
        sTitle.layer.addSublayer(GlobalFunctions.addBorders(self.sTitle, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        sDescription.layer.addSublayer(GlobalFunctions.addBorders(self.sDescription, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        
        sTitle.attributedPlaceholder = NSAttributedString(string: "short title for series",
                                                             attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        sDescription.attributedPlaceholder = NSAttributedString(string: "short series description",
                                                                attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        
        sType.translatesAutoresizingMaskIntoConstraints = false
        sType.topAnchor.constraint(equalTo: sDescription.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        sType.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sType.layoutIfNeeded()
        
        sType.text = "type of series"
        sType.setFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: .black, alignment: .center)

        addCollectionView()
        addSubmitButton()
        
    }
    
    internal func addCollectionView() {
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.addSubview(collectionView)
        view.addSubview(sTypeDescription)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: sType.bottomAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.heightAnchor.constraint(equalToConstant: 125).isActive = true
        collectionView.layoutIfNeeded()
        
        collectionViewLayout = QuickBrowseLayout.configureLayout(collectionView: collectionView,
                                                                 itemSize:   CGSize(width: collectionView.bounds.width * 0.3,
                                                                                    height: collectionView.bounds.height - 10),
                                                                 minimumLineSpacing: collectionView.bounds.width * 0.05)
        collectionView?.register(BrowseContentCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView?.backgroundColor = UIColor.clear
        
        sTypeDescription.translatesAutoresizingMaskIntoConstraints = false
        sTypeDescription.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        sTypeDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sTypeDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        sTypeDescription.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        sTypeDescription.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)

        sTypeDescription.numberOfLines = 3
        sTypeDescription.text = "description for the type of series"
    }
    
    internal func addSubmitButton() {
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.topAnchor.constraint(equalTo: sTypeDescription.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        
        submitButton.layer.cornerRadius = buttonCornerRadius.radius(.regular)
        submitButton.setTitle("Add Series", for: UIControlState())
        submitButton.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        submitButton.setDisabled()
        
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
    }
}

extension NewSeriesVC: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == sTitle, textField.text != "", sDescription.text != "" {
            submitButton.setEnabled()
        } else if textField == sDescription, textField.text != "", sTitle.text != "" {
            submitButton.setEnabled()
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string == "\n" {
            textField.resignFirstResponder()
            return false
        }
        
        let  char = string.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        
        if isBackSpace == -92, textField.text != "" {
            return true
        }
        
        if textField == sTitle, let text = textField.text?.lowercased() {
            return text.characters.count + (text.characters.count - range.length) <= 33
        } else if textField == sDescription, let text = textField.text?.lowercased() {
            return text.characters.count + (text.characters.count - range.length) <= 70
        }
        
        return true
    }
}

extension NewSeriesVC: CameraDelegate, PanAnimationDelegate {
    /* CAMERA FUNCTIONS & DELEGATE METHODS */
    func panCompleted(success: Bool, fromVC: UIViewController?) {
        if success {
            if fromVC is CameraVC {
                cameraVC.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func showCamera() {
        guard let nav = navigationController else { return }
        
        cameraVC = CameraVC()
        cameraVC.cameraMode = .stillImage
        
        cameraVC.delegate = self
        cameraVC.screenTitle = "snap a pic to use as series cover!"
        
        panDismissCameraInteractionController.wireToViewController(cameraVC, toViewController: nil, parentViewController: nav, modal: true)
        panDismissCameraInteractionController.delegate = self
        
        present(cameraVC, animated: true, completion: nil)
    }
    
    func doneRecording(isCapturing: Bool, url : URL?, image: UIImage?, location: CLLocation?, assetType : CreatedAssetType?) {
        guard let imageData = image?.mediumQualityJPEGNSData else {
            if isCapturing {
                self.cameraVC.toggleLoading(show: true, message: "saving! just a sec...")
            }
            return
        }
        
        capturedImage = UIImage(data: imageData)
        
        UIView.animate(withDuration: 0.1, animations: { self.cameraVC.view.alpha = 0.0 } ,
                       completion: {(value: Bool) in
                        
            DispatchQueue.main.async {
                self.cameraVC.toggleLoading(show: false, message: nil)
                
                if let capturedImage = self.capturedImage {
                    self.sShowCamera.setImage(capturedImage, for: .normal)
                    self.sShowCamera.imageView?.contentMode = .scaleAspectFill
                    self.sShowCamera.imageView?.clipsToBounds = true
                    self.sShowCamera.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
                    self.sShowCamera.clipsToBounds = true
                    
                    self.sShowCameraLabel.text = "tap image to change"
                    self.sShowCameraLabel.textColor = .gray
                }
                
                //update the header
                self.cameraVC.dismiss(animated: true, completion: nil)
            }

        })

    }
    
    func userDismissedCamera() {
        cameraVC.dismiss(animated: true, completion: nil)
    }
    
    func showAlbumPicker() {
        let albumPicker = UIImagePickerController()
        
        albumPicker.delegate = self
        albumPicker.allowsEditing = false
        albumPicker.sourceType = .photoLibrary
        albumPicker.mediaTypes = [kUTTypeImage as String]
        
        cameraVC.present(albumPicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        guard mediaType.isEqual(to: kUTTypeImage as String) else {
            return
        }
        
        picker.dismiss(animated: true, completion: nil)
        capturedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        if let capturedImage = capturedImage {
            self.sShowCamera.setImage(capturedImage, for: .normal)
            self.sShowCamera.imageView?.contentMode = .scaleAspectFill
            self.sShowCamera.imageView?.clipsToBounds = true
            self.sShowCamera.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
            self.sShowCamera.clipsToBounds = true
            
            self.sShowCameraLabel.text = "tap image to change"
            self.sShowCameraLabel.textColor = .gray
            
            cameraVC.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
