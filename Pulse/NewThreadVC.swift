//
//  StartThread.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/22/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import CoreLocation
import MobileCoreServices

class NewThreadVC: PulseVC, ListDelegate  {
    //Set by parent
    public var selectedChannel : Channel!
    public var selectedItem : Item!
    public var delegate: BrowseContentDelegate?
    
    //UI Vars
    fileprivate var containerView = UIView()
    fileprivate var threadCoverImage = UIImageView()
    //fileprivate lazy var backgroundBlurView = UIImageView()
    fileprivate var showCameraButton = PulseButton(size: .xLarge, type: .camera, isRound: true, background: .white, tint: .black)
    fileprivate var showCameraLabel = UILabel()
    
    fileprivate var threadTitle = PaddingTextField()
    fileprivate var threadDescription = PaddingTextField()
    fileprivate var submitButton = PulseButton(title: "Start Thread", isRound: true, hasShadow: false)
    fileprivate var threadExplanation = PaddingLabel()

    fileprivate var tableView : UITableView!
    fileprivate var allItems = [Item]() //for choices
    
    //After user edits / adds description so we set the correct one
    fileprivate var addMode: AddMode! = .none
    fileprivate var selectedItemTag : Int?
    
    //Capture Image
    fileprivate var inputVC : InputVC!
    fileprivate var fullImageData : Data?
    fileprivate var thumbImageData : Data?
    fileprivate var contentType : CreatedAssetType? = .recordedImage
    
    //Deinit check
    fileprivate var cleanupComplete = false
    
    //Loading icon on Button
    fileprivate var loading : UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            tabBarHidden = true
            containerView.frame = view.frame
            view.addSubview(containerView)
            
            updateHeader()
            setupLayout()
            hideKeyboardWhenTappedAround()
            
            //NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
            //NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
            
            isLoaded = true
        }
    }
    
    deinit {
        performCleanup()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        UIView.animate(withDuration: 0.3, animations: { self.containerView.frame.origin.y = -100 })
        containerView.layoutIfNeeded()
    }
    
    func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3, animations: { self.containerView.frame.origin.y = 0 })
        containerView.layoutIfNeeded()
    }
    
    override func goBack() {
        DispatchQueue.global(qos: .background).async {[weak self] in
            guard let `self` = self else { return }
            if self.inputVC != nil {
                self.inputVC.performCleanup()
                self.inputVC.inputDelegate = nil
                self.inputVC = nil
            }
        }
        super.goBack()
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            selectedChannel = nil
            selectedItem = nil
            
            fullImageData = nil
            thumbImageData = nil
            cleanupComplete = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarHidden = true
        updateHeader()
    }
    
    /** HEADER FUNCTIONS **/
    internal func updateHeader() {
        addBackButton()
        updateChannelImage(channel: selectedChannel)
        
        headerNav?.setNav(title: "Start a New Thread", subtitle: selectedItem.itemTitle != "" ? selectedItem.itemTitle : selectedChannel.cTitle)
        headerNav?.showNavbar(animated: true)
    }
    
    internal func handleSubmit() {
        guard PulseUser.isLoggedIn() else {
            GlobalFunctions.showAlertBlock("Please login", erMessage: "You need to be logged in to start threads!")
            return
        }
        
        loading = submitButton.addLoadingIndicator()
        submitButton.setDisabled()
        
        let itemKey = PulseDatabase.getKey(forPath: "items")
        let item = Item(itemID: itemKey, type: "thread")
        
        item.itemTitle = threadTitle.text ?? ""
        item.itemUserID = PulseUser.currentUser.uID
        item.itemDescription = threadDescription.text ?? ""
        item.contentType = contentType
        item.cID = selectedChannel.cID
        item.tag = selectedItem
        item.cTitle = selectedChannel.cTitle
        
        for (index, _) in self.allItems.enumerated() {
            let choiceID = "\(item.itemID)c\(index)"
            allItems[index].itemID = choiceID
        }
        item.choices = allItems
        
        if let fullImageData = self.fullImageData {
            PulseDatabase.uploadImageData(channelID: item.cID, itemID: itemKey, imageData: fullImageData, fileType: .content, completion: {[weak self] (metadata, error) in
                guard let `self` = self else { return }
                
                item.contentURL = metadata?.downloadURL()
                self.addThreadToDatabase(item: item)
                PulseDatabase.uploadImageData(channelID: item.cID, itemID: itemKey, imageData: self.thumbImageData, fileType: .thumb, completion: {_ in })
                
            })
        } else {
            self.addThreadToDatabase(item: item)
        }
    }
    
    internal func addThreadToDatabase(item: Item) {
        PulseDatabase.addThread(item: item, completion: {[weak self] success, error in
            guard let `self` = self else { return }
            
            success ? self.showSuccessMenu(item: item) : self.showErrorMenu(error: error!)
            if self.loading != nil {
                self.loading.removeFromSuperview()
            }
            self.submitButton.setEnabled()
        })
        
    }
    
    internal func showSuccessMenu(item: Item) {
        let menu = UIAlertController(title: "Successfully Added Thread",
                                     message: "Tap okay to return or start contributing to this thread!",
                                     preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "add Perspective", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self, let delegate = self.delegate else { return }
            self.goBack()
            delegate.addNewItem(selectedItem: item)
        }))
        
        menu.addAction(UIAlertAction(title: "done", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
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
    
    fileprivate func createCompressedImages(image: UIImage) {
        fullImageData = image.mediumQualityJPEGNSData
        thumbImageData = image.resizeImage(newWidth: ITEM_THUMB_WIDTH)?.highQualityJPEGNSData
    }
    
    internal func updateDataSource() {
        if tableView != nil {
            tableView?.dataSource = self
            tableView?.delegate = self
            
            tableView?.layoutIfNeeded()
            tableView?.reloadData()
        }
    }
    
    internal func addListItem(title : String) {
        let newItem = Item(itemID: String(allItems.count))
        newItem.itemTitle = title
        
        let newIndexPath = IndexPath(row: allItems.count, section: 0)
        allItems.append(newItem)
        tableView.insertRows(at: [newIndexPath], with: .left)
        
        if allItems.count == 1 {
            //so it reloads the header
            tableView.reloadData()
        }
    }
    
    internal func showMenuFor(itemID: String) {
        guard let _selectedItemTag = allItems.index(of: Item(itemID: itemID)) else {
            return
        }
        
        selectedItemTag = _selectedItemTag
        let currentItem = allItems[_selectedItemTag]
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "edit Title", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.showAddText(buttonText: "Done", bodyText: currentItem.itemTitle, keyboardType: .default)
            self.addMode = .title
            menu.dismiss(animated: true, completion: nil)
        }))
        
        menu.addAction(UIAlertAction(title: currentItem.content != nil ? "edit Picture" : "add Picture", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            
            if self.inputVC == nil {
                self.inputVC = InputVC(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
                self.inputVC.cameraMode = .stillImage
                self.inputVC.captureSize = .square
                self.inputVC.albumShowsVideo = false
                self.inputVC.inputDelegate = self
                self.inputVC.transitioningDelegate = self
            }
            
            self.inputVC.cameraTitle = "add a picture for list item"
            self.addMode = .image
            self.present(self.inputVC, animated: true, completion: nil)
        }))
        
        menu.addAction(UIAlertAction(title: "remove Item", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            let indexPath = IndexPath(row: _selectedItemTag, section: 0)
            self.allItems.remove(at: _selectedItemTag)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.selectedItemTag = nil
            menu.dismiss(animated: true, completion: nil)
        }))
        
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func userClickedListItem(itemID: String) {
        //ignore - supposed to be for clicking the image link which we don't use
    }
    
    override func addTextDone(_ text: String, sender: UIView) {
        guard let _selectedItemTag = selectedItemTag else {
            return
        }
        
        allItems[_selectedItemTag].itemTitle = text
        
        let reloadIndexPath = IndexPath(row: _selectedItemTag, section: 0)
        tableView.reloadRows(at: [reloadIndexPath], with: .fade)
        tableView.scrollToRow(at: reloadIndexPath, at: .bottom, animated: true)
        selectedItemTag = nil
    }
}

extension NewThreadVC: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == threadTitle, textField.text != "", threadDescription.text != "" {
            submitButton.setEnabled()
        } else if textField == threadDescription, textField.text != "", threadTitle.text != "" {
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
        
        if textField == threadTitle, let text = textField.text?.lowercased() {
            return text.characters.count + string.characters.count <= SERIES_TITLE_CHARACTER_COUNT
        } else if textField == threadDescription, let text = textField.text?.lowercased() {
            return text.characters.count + string.characters.count <= POST_TITLE_CHARACTER_COUNT
        }
        
        return true
    }
}

extension NewThreadVC: InputMasterDelegate {
    /* CAMERA FUNCTIONS & DELEGATE METHODS */
    func showCamera() {
        if inputVC == nil {
            inputVC = InputVC(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            inputVC.cameraMode = .stillImage
            inputVC.captureSize = .square
            inputVC.albumShowsVideo = false
            inputVC.inputDelegate = self
            inputVC.transitioningDelegate = self
            inputVC.cameraTitle = "snap a pic to use as cover image!"
        }
        
        present(inputVC, animated: true, completion: nil)
    }
    
    func capturedItem(item: Any?, location: CLLocation?, assetType: CreatedAssetType) {
        guard let image = item as? UIImage else {
            GlobalFunctions.showAlertBlock("Error getting image", erMessage: "Sorry there was an error! Please try again")
            return
        }
        
        if let _selectedItemTag = selectedItemTag, addMode == .image {
            //adding for a list item vs. for the full series
            allItems[_selectedItemTag].content = image
            let reloadIndexPath = IndexPath(row: _selectedItemTag, section: 0)
            tableView.reloadRows(at: [reloadIndexPath], with: .fade)
            addMode = .none
            selectedItemTag = nil
            
        } else {
            showCameraButton.setImage(image, for: .normal)
            showCameraButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
            showCameraLabel.text = "tap to edit image"
            showCameraLabel.textColor = .gray

            contentType = assetType
            
            createCompressedImages(image: image)

        }
        
        dismiss(animated: true, completion: {[weak self] in
            guard let `self` = self else { return }
            self.inputVC.updateAlpha()
        })
    }
    
    func dismissInput() {
        inputVC.dismiss(animated: true, completion: nil)
    }
}

extension NewThreadVC : UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allItems.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerReuseIdentifier) as? ListItemFooter else {
            return UITableViewHeaderFooterView()
        }
        
        cell.listDelegate = self
        cell.contentView.backgroundColor = UIColor.white
        cell.contentView.layer.cornerRadius = 5
        cell.updateLabels(title: "add Choices", subtitle: "(optional) experts will select prior to adding perspectives")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? ListItemCell else {
            return UITableViewCell()
        }
        
        let currentItem = allItems[indexPath.row]
        cell.updateItemDetails(title: currentItem.itemTitle, subtitle: nil)
        cell.showItemMenu()
        cell.itemID = currentItem.itemID
        
        if let image = currentItem.content {
            cell.updateImage(image: image)
        }
        
        cell.listDelegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.medium.rawValue * 1.1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return IconSizes.medium.rawValue * 1.3
    }
}

//UI Elements
extension NewThreadVC {
    func setupLayout() {
        
        containerView.addSubview(showCameraButton)
        containerView.addSubview(showCameraLabel)
        
        containerView.addSubview(threadTitle)
        containerView.addSubview(threadDescription)
        
        containerView.addSubview(threadCoverImage)
        threadCoverImage.translatesAutoresizingMaskIntoConstraints = false
        threadCoverImage.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        threadCoverImage.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        threadCoverImage.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        threadCoverImage.heightAnchor.constraint(equalToConstant: 150).isActive = true
        threadCoverImage.layoutIfNeeded()
        
        showCameraButton.translatesAutoresizingMaskIntoConstraints = false
        showCameraButton.centerXAnchor.constraint(equalTo: threadCoverImage.centerXAnchor).isActive = true
        showCameraButton.centerYAnchor.constraint(equalTo: threadCoverImage.centerYAnchor).isActive = true
        showCameraButton.heightAnchor.constraint(equalToConstant: IconSizes.xLarge.rawValue).isActive = true
        showCameraButton.widthAnchor.constraint(equalToConstant: IconSizes.xLarge.rawValue).isActive = true
        showCameraButton.layoutIfNeeded()
        showCameraButton.addTarget(self, action: #selector(showCamera), for: .touchUpInside)
        
        showCameraLabel.translatesAutoresizingMaskIntoConstraints = false
        showCameraLabel.centerXAnchor.constraint(equalTo: showCameraButton.centerXAnchor).isActive = true
        showCameraLabel.topAnchor.constraint(equalTo: showCameraButton.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        showCameraLabel.text = "add a cover image"
        showCameraLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .black, alignment: .center)
        
        threadTitle.translatesAutoresizingMaskIntoConstraints = false
        threadTitle.topAnchor.constraint(equalTo: showCameraLabel.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        threadTitle.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        threadTitle.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.9).isActive = true
        threadTitle.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        threadTitle.layoutIfNeeded()
        
        threadDescription.translatesAutoresizingMaskIntoConstraints = false
        threadDescription.topAnchor.constraint(equalTo: threadTitle.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        threadDescription.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        threadDescription.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.9).isActive = true
        threadDescription.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        threadDescription.layoutIfNeeded()
        
        threadTitle.delegate = self
        threadDescription.delegate = self
        
        threadTitle.placeholder = "short title for thread"
        threadDescription.placeholder = "short thread description"
        
        addSubmitButton()
    }
    
    internal func addSubmitButton() {
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        
        containerView.addSubview(tableView)
        view.addSubview(threadExplanation)
        view.addSubview(submitButton)
        
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalToConstant: PulseButton.regularButtonHeight).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        submitButton.setDisabled()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: threadDescription.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: threadExplanation.topAnchor).isActive = true
        
        threadExplanation.translatesAutoresizingMaskIntoConstraints = false
        threadExplanation.bottomAnchor.constraint(equalTo: submitButton.topAnchor).isActive = true
        threadExplanation.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        threadExplanation.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
        threadExplanation.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        
        threadExplanation.numberOfLines = 1
        threadExplanation.text = "threads are open to contributors & invited guests."
        
        tableView?.register(ListItemCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView?.register(ListItemFooter.self, forHeaderFooterViewReuseIdentifier: headerReuseIdentifier)
        
        tableView?.backgroundView = nil
        tableView?.backgroundColor = UIColor.clear
        tableView?.separatorStyle = UITableViewCellSeparatorStyle.none
        
        tableView?.showsVerticalScrollIndicator = false
        tableView?.tableFooterView = UIView()
        
        updateDataSource()
    }
}

/** adding image for full thread - old way was adding a background image of that size
 backgroundBlurView.frame = threadCoverImage.frame
 backgroundBlurView.backgroundColor = UIColor.init(patternImage: image)
 backgroundBlurView.contentMode = .center
 containerView.insertSubview(backgroundBlurView, at: 0)
 
 let blurBackground = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
 blurBackground.frame = backgroundBlurView.bounds
 backgroundBlurView.addSubview(blurBackground)
 
 threadCoverImage.image = image
 threadCoverImage.contentMode = .scaleAspectFit
 threadCoverImage.backgroundColor = .clear
 threadCoverImage.clipsToBounds = true
 
 showCameraLabel.removeFromSuperview()
 showCameraButton.removeFromSuperview()
 
 showCameraButton = PulseButton(size: .xSmall, type: .camera, isRound: true, background: UIColor.white.withAlphaComponent(0.7), tint: .black)
 showCameraButton.frame = CGRect(x: Spacing.xs.rawValue, y: self.threadCoverImage.frame.maxY - Spacing.xs.rawValue -  IconSizes.xSmall.rawValue,
 width: IconSizes.xSmall.rawValue, height: IconSizes.xSmall.rawValue)
 containerView.addSubview(showCameraButton)
 showCameraButton.addTarget(self, action: #selector(showCamera), for: .touchUpInside)
 **/
