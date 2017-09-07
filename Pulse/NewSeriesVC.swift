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

class NewSeriesVC: PulseVC  {
    //Set by parent
    public weak var selectedChannel : Channel! {
        didSet {
            if selectedChannel != nil {
                PulseDatabase.getSeriesTypes(completion: {[weak self] seriesTypes in
                    guard let `self` = self else { return }
                    self.allItems = seriesTypes
                    self.updateDataSource()
                })
            }
        }
    }
    
    //UI Vars
    fileprivate var sAddCover = UIView()
    fileprivate var sShowCamera = PulseButton(size: .xLarge, type: .camera, isRound: true, background: .white, tint: .black)
    fileprivate var sShowCameraLabel = UILabel()
    
    fileprivate var sTitle = PaddingTextField()
    fileprivate var sDescription = PaddingTextField()
    fileprivate var submitButton = PulseButton(title: "Add Series", isRound: false, hasShadow: false)
    
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
    fileprivate var inputVC : InputVC!
    fileprivate var fullImageData : Data?
    fileprivate var thumbImageData : Data?
    
    fileprivate var contentType : CreatedAssetType? = .recordedImage
    
    //Loading indicator for submit button
    fileprivate var loading: UIView!
    
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
        tabBarHidden = true
        updateHeader()
    }
    
    deinit {
        performCleanup()
    }
    
    override func goBack() {
        DispatchQueue.global(qos: .background).async {[weak self] in
            guard let `self` = self else { return }
            if self.inputVC != nil {
                self.inputVC.performCleanup()
                self.inputVC = nil
            }
        }
        super.goBack()
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            selectedChannel = nil
            
            if collectionView != nil {
                collectionView?.delegate = nil
                collectionView = nil
            }

            allItems.removeAll()
            
            fullImageData = nil
            thumbImageData = nil
            
            collectionViewLayout = nil
            
            sTitle.delegate = nil
            sDescription.delegate = nil
            
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
        updateChannelImage(channel: selectedChannel)
        
        headerNav?.setNav(title: "Start a New Series", subtitle: selectedChannel.cTitle)
        headerNav?.showNavbar(animated: true)
    }
    
    internal func updateDescription(index: Int) {
        sType.text = "selected: \(allItems[centerIndex].itemTitle)"
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
        if let image = allItems[indexPath.row].content  {
            cell.updateImage(image: image)
        }
        
        cell.updateOverlayLabel(title: allItems[indexPath.row].itemTitle)
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
        guard let fullImageData = fullImageData else {
            GlobalFunctions.showAlertBlock("Add Image", erMessage: "Please choose an image for the series")
            return
        }
        
        guard sTitle.text != "" else {
            GlobalFunctions.showAlertBlock("Add Title", erMessage: "Please add a title for the series")
            return
        }
        
        loading = submitButton.addLoadingIndicator()
        submitButton.setDisabled()
        
        let itemKey = PulseDatabase.getKey(forPath: "items")
        let item = Item(itemID: itemKey, type: getSelectedType())
        
        item.itemTitle = sTitle.text ?? ""
        item.itemUserID = PulseUser.currentUser.uID
        item.itemDescription = sDescription.text ?? ""
        item.contentType = contentType
        item.cID = selectedChannel.cID
        
        PulseDatabase.uploadImageData(channelID: item.cID, itemID: itemKey, imageData: fullImageData, fileType: .content,
                                      completion: {[weak self] (metadata, error) in
            guard let `self` = self else { return }
            
            if error == nil {
                item.contentURL = metadata?.downloadURL()
                self.addSeriesToDatabase(item: item)
            } else {
                self.showErrorMenu(error: error!)
            }
        })
        
        PulseDatabase.uploadImageData(channelID: item.cID, itemID: itemKey, imageData: thumbImageData, fileType: .thumb, completion: {_ in })
    }
    
    internal func addSeriesToDatabase(item: Item) {
        PulseDatabase.addNewSeries(channelID: selectedChannel.cID, item: item, completion: {[weak self] success, error in
            guard let `self` = self else {return}
            success ? self.showSuccessMenu() : self.showErrorMenu(error: error!)
            
            self.loading.removeFromSuperview()
            self.submitButton.setEnabled()
        })
    }
    
    internal func getSelectedType() -> String {
        return allItems[centerIndex].itemID
    }
    
    internal func showSuccessMenu() {
        let menu = UIAlertController(title: "Successfully Added Series",
                                     message: "Tap okay to return to the channel page and start creating!",
                                     preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "done", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else {return}
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
        
        cell.updateOverlayLabel(title: currentItem.itemTitle)
        cell.updateImage(image: UIImage(named: self.allItems[indexPath.row].itemID))
        
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
        sAddCover.heightAnchor.constraint(equalToConstant: 150).isActive = true
        sAddCover.layoutIfNeeded()
        
        sShowCamera.translatesAutoresizingMaskIntoConstraints = false
        sShowCamera.centerXAnchor.constraint(equalTo: sAddCover.centerXAnchor).isActive = true
        sShowCamera.centerYAnchor.constraint(equalTo: sAddCover.centerYAnchor).isActive = true
        sShowCamera.heightAnchor.constraint(equalToConstant: IconSizes.xLarge.rawValue).isActive = true
        sShowCamera.widthAnchor.constraint(equalToConstant: IconSizes.xLarge.rawValue).isActive = true
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
        sTitle.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        sTitle.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        sTitle.layoutIfNeeded()
        
        sDescription.translatesAutoresizingMaskIntoConstraints = false
        sDescription.topAnchor.constraint(equalTo: sTitle.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        sDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        sDescription.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        sDescription.layoutIfNeeded()
        
        sTitle.delegate = self
        sDescription.delegate = self
        
        sTitle.placeholder = "short title for series"
        sDescription.placeholder = "short series description"
        
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
        collectionView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        collectionView.layoutIfNeeded()
        
        collectionViewLayout = QuickBrowseLayout.configureLayout(collectionView: collectionView,
                                                                 itemSize: CGSize(width: collectionView.bounds.width * 0.3, height: collectionView.bounds.height - 10),
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
        submitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalToConstant: PulseButton.regularButtonHeight).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        submitButton.layoutIfNeeded()
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
            return text.characters.count + string.characters.count <= SERIES_TITLE_CHARACTER_COUNT
        } else if textField == sDescription, let text = textField.text?.lowercased() {
            return text.characters.count + string.characters.count <= POST_TITLE_CHARACTER_COUNT
        }
        
        return true
    }
}

extension NewSeriesVC: InputMasterDelegate {
    /* CAMERA FUNCTIONS & DELEGATE METHODS */
    func createCompressedImages(image: UIImage) {
        fullImageData = image.mediumQualityJPEGNSData
        thumbImageData = image.resizeImage(newWidth: PROFILE_THUMB_WIDTH)?.highQualityJPEGNSData
    }
    
    func showCamera() {
        if inputVC == nil {
            inputVC = InputVC(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            inputVC.cameraMode = .stillImage
            inputVC.captureSize = .square
            inputVC.albumShowsVideo = false
            inputVC.inputDelegate = self
            inputVC.transitioningDelegate = self
            inputVC.cameraTitle = "snap a pic to use as series cover!"
        }
        
        present(inputVC, animated: true, completion: nil)
    }
    
    func capturedItem(item: Any?, location: CLLocation?, assetType: CreatedAssetType) {
        guard let image = item as? UIImage else {
            GlobalFunctions.showAlertBlock("Error getting image", erMessage: "Sorry there was an error! Please try again")
            return
        }
                        
        sShowCamera.setImage(image, for: .normal)
        sShowCamera.imageView?.contentMode = .scaleAspectFill
        sShowCamera.imageView?.clipsToBounds = true
        
        sShowCamera.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        sShowCamera.clipsToBounds = true
        
        sShowCameraLabel.text = "tap image to change"
        sShowCameraLabel.textColor = .gray
        
        dismiss(animated: true, completion: {[weak self] in
            guard let `self` = self else { return }
            self.inputVC.updateAlpha()
        })
                
        createCompressedImages(image: image)
    }
    
    func dismissInput() {
        inputVC.dismiss(animated: true, completion: nil)
    }
}
