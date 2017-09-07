//
//  NewListVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/21/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import CoreLocation
import SafariServices

class NewCollectionVC: PulseVC, ListDelegate, InputMasterDelegate {
    /** Set by parent **/
    public var selectedChannel : Channel!
    public var selectedItem : Item!
    
    /** List UI Vars **/
    fileprivate var listTitle = PaddingTextField()
    fileprivate var listDescription = PaddingTextField()

    fileprivate var showCameraButton = PulseButton(size: .large, type: .camera, isRound: true, background: .white, tint: .black)
    fileprivate var showCameraLabel = PaddingLabel()
    fileprivate var submitButton = PulseButton(title: "Submit", isRound: false, hasShadow: false)
    
    fileprivate var placeholderName = "short title for the list"
    fileprivate var placeholderDescription = "short description for list"
    
    fileprivate var listInstructions = PaddingLabel()
    
    fileprivate var fullImageData : Data?
    fileprivate var thumbImageData : Data?
    
    /** Table View Vars **/
    fileprivate var tableView : UITableView!
    fileprivate var allItems = [Item]()
    fileprivate var startedCollection = false
    
    fileprivate var headerSetup = false    
    fileprivate var cleanupComplete = false
    
    fileprivate var inputVC : InputVC!
    
    //After user edits / adds text or URL so we set the correct one
    private var addMode: AddMode! = .none
    private var selectedItemTag : Int?
    
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
    
    public func performCleanup() {
        if !cleanupComplete {
            allItems = []
            selectedChannel = nil
            selectedItem = nil
            
            if tableView != nil {
                tableView = nil
            }
            
            cleanupComplete = true
        }
    }
    
    /** HEADER FUNCTIONS **/
    internal func updateHeader() {
        addBackButton()
        updateChannelImage(channel: selectedChannel)
        headerNav?.setNav(title: "New List", subtitle: selectedItem.itemTitle != "" ? selectedItem.itemTitle : selectedChannel.cTitle)
        headerNav?.showNavbar(animated: true)
    }
    
    internal func updateDataSource() {
        if tableView != nil {
            tableView?.dataSource = self
            tableView?.delegate = self
            
            tableView?.layoutIfNeeded()
            tableView?.reloadData()
        }
    }
    
    internal func handleSubmit() {
        guard PulseUser.isLoggedIn() else {
            GlobalFunctions.showAlertBlock("Please login", erMessage: "You must be logged in to create a list!")
            return
        }
        
        submitButton.setDisabled()
        
        let listItem : Item = Item(itemID: "tempID", itemUserID: PulseUser.currentUser.uID!,
                                   itemTitle: listTitle.text!, type: ItemTypes.collection, tag: selectedItem, cID: selectedChannel.cID)
        listItem.itemDescription = listDescription.text!
        
        PulseDatabase.createList(selectedItem: listItem, listItems: allItems, completion: {[weak self] listCollectionID, error in
            guard let `self` = self else { return }
            if let listCollectionID = listCollectionID, let fullImageData = self.fullImageData {
                //upload image but successfully added image - so show success after uploading image
                PulseDatabase.uploadImageData(channelID: self.selectedChannel.cID, itemID: listCollectionID, imageData: fullImageData, fileType: .content, completion: {[weak self] _ , _ in
                    guard let `self` = self else { return }
                    self.showSuccessMenu()
                    self.submitButton.setEnabled()
                    PulseDatabase.uploadImageData(channelID: self.selectedChannel.cID, itemID: listCollectionID, imageData: self.thumbImageData, fileType: .thumb, completion: { _, _ in })
                })
            } else if let _ = listCollectionID {
                //no image but successfully added image - so show success
                self.showSuccessMenu()
                self.submitButton.setEnabled()
            } else {
                GlobalFunctions.showAlertBlock("Sorry Error Creating Collection", erMessage: error?.localizedDescription)
                self.submitButton.setEnabled()
            }
        })
    }
    
    internal func checkEnableButton() {
        if listTitle.text != "", listDescription.text != "" {
            submitButton.setEnabled()
        } else {
            submitButton.setDisabled()
        }
    }
    
    internal func addListItem(title : String) {
        let newItem = Item(itemID: String(allItems.count))
        newItem.itemTitle = title
        
        let newIndexPath = IndexPath(row: allItems.count, section: 0)
        allItems.append(newItem)
        tableView.insertRows(at: [newIndexPath], with: .left)
        startedCollection = true
        
        if allItems.count == 1 {
            tableView.reloadData() //so it reloads the header
        } else {
            tableView.scrollToRow(at: newIndexPath, at: .bottom, animated: true)
        }
    }
    
    internal func showCamera() {
        if self.inputVC == nil {
            self.inputVC = InputVC(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            self.inputVC.cameraMode = .stillImage
            self.inputVC.captureSize = .square
            self.inputVC.albumShowsVideo = false
            self.inputVC.inputDelegate = self
            self.inputVC.transitioningDelegate = self
        }
        
        self.inputVC.cameraTitle = "add a cover image for the list"
        self.present(self.inputVC, animated: true, completion: nil)
    }
    
    internal func userClickedListItem(itemID: String) {
        //check the listID - if it has url - open the URL
        guard let _selectedItemTag = allItems.index(of: Item(itemID: itemID)) else {
            return
        }
        
        let currentItem = allItems[_selectedItemTag]
        
        guard let url = currentItem.linkedURL else {
            return
        }
        
        let svc = SFSafariViewController(url: url)
        present(svc, animated: true, completion: nil)
    }

    
    internal func showSuccessMenu() {
        //offer to go to editCollectionVC -> to rank items
        
        let menu = UIAlertController(title: "Successfully Started Collection!", message: "Create your unique version or invite guests next", preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "create Collection", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            let editCollectionVC = EditCollectionVC()
            editCollectionVC.selectedChannel = self.selectedChannel
            editCollectionVC.selectedItem = self.selectedItem
            self.navigationController?.pushViewController(editCollectionVC, animated: true)
        }))
        
        if let inviteType = selectedItem.inviteType() {
            menu.addAction(UIAlertAction(title: "invite Guests", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                guard let `self` = self else { return }
                self.showInviteMenu(currentItem: self.selectedItem,
                                    inviteTitle: "Invite Guests",
                                    inviteMessage: "know an expert who can \(self.selectedItem.childActionType())\(self.selectedItem.childType())?\nInvite them below!",
                    inviteType: inviteType)
            }))
        }
        
        menu.addAction(UIAlertAction(title: "done", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.goBack()
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
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
        
        menu.addAction(UIAlertAction(title: currentItem.linkedURL != nil ? "edit Link" : "add Link", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.showAddText(buttonText: "Done", bodyText: currentItem.linkedURL != nil ? String(describing: currentItem.linkedURL!) : "http://", keyboardType: .URL)
            self.addMode = .link
            menu.dismiss(animated: true, completion: nil)
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
    
    override func addTextDone(_ text: String, sender: UIView) {
        guard let _selectedItemTag = selectedItemTag else {
            return
        }
        
        switch addMode! {
        case .title:
            allItems[_selectedItemTag].itemTitle = text
        case .link:
            guard GlobalFunctions.validateURL(urlString: text), text != "http://" else {
                showAddText(buttonText: "Done", bodyText: "http://", keyboardType: .URL)
                return
            }
            allItems[_selectedItemTag].linkedURL = URL(string: text)

        default: break
        }
        
        addMode = .none
        let reloadIndexPath = IndexPath(row: _selectedItemTag, section: 0)
        tableView.reloadRows(at: [reloadIndexPath], with: .fade)
        selectedItemTag = nil
    }
    
    func dismissInput() {
        inputVC.dismiss(animated: true, completion: nil)
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
            //is for the full list vs. for individual list item
            createCompressedImages(image: image)
            showCameraButton.setImage(image, for: .normal)
            showCameraButton.imageEdgeInsets = UIEdgeInsets.zero
        }
        
        dismiss(animated: true, completion: {[weak self] in
            guard let `self` = self else { return }
            self.inputVC.updateAlpha()
        })
    }
    
    fileprivate func createCompressedImages(image: UIImage) {
        fullImageData = image.mediumQualityJPEGNSData
        thumbImageData = image.resizeImage(newWidth: ITEM_THUMB_WIDTH)?.highQualityJPEGNSData
    }
}

extension NewCollectionVC : UITableViewDelegate, UITableViewDataSource {
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
        
        if !startedCollection {
            cell.updateLabels(title: "new Collection", subtitle: "start a new list or browse sample collections")
        } else {
            cell.updateLabels(title: "add Item", subtitle: "tap to add a new item to your collection")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? ListItemCell else {
            return UITableViewCell()
        }
        
        let currentItem = allItems[indexPath.row]
        cell.updateItemDetails(title: currentItem.itemTitle, subtitle: currentItem.itemDescription)
        cell.showItemMenu()
        cell.showImageBorder(show: currentItem.linkedURL != nil ? true : false)
        
        if currentItem.content != nil {
            DispatchQueue.main.async {
                cell.updateImage(image: currentItem.content)
            }
        }
        
        cell.itemID = String(indexPath.row)
        cell.listDelegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.medium.rawValue * 1.1 //don't have subtitle so can be smaller
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return IconSizes.medium.rawValue * 1.2 //only adding titles so doesn't need to be as big
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}


//UI Elements
extension NewCollectionVC {
    fileprivate func setupLayout() {
        view.addSubview(listTitle)
        view.addSubview(listDescription)
        view.addSubview(showCameraButton)
        view.addSubview(showCameraLabel)

        showCameraButton.translatesAutoresizingMaskIntoConstraints = false
        showCameraButton.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        showCameraButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.xxs.rawValue).isActive = true
        showCameraButton.widthAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        showCameraButton.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        
        showCameraLabel.translatesAutoresizingMaskIntoConstraints = false
        showCameraLabel.topAnchor.constraint(equalTo: showCameraButton.bottomAnchor).isActive = true
        showCameraLabel.leadingAnchor.constraint(equalTo: showCameraButton.leadingAnchor).isActive = true
        showCameraLabel.trailingAnchor.constraint(equalTo: showCameraButton.trailingAnchor).isActive = true

        listTitle.translatesAutoresizingMaskIntoConstraints = false
        listTitle.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        listTitle.leadingAnchor.constraint(equalTo: showCameraButton.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
        listTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        listTitle.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        
        listDescription.translatesAutoresizingMaskIntoConstraints = false
        listDescription.topAnchor.constraint(equalTo: listTitle.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        listDescription.leadingAnchor.constraint(equalTo: showCameraButton.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
        listDescription.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        listDescription.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        
        listTitle.delegate = self
        listDescription.delegate = self
        
        listTitle.placeholder = placeholderName
        listDescription.placeholder = placeholderDescription
        
        showCameraButton.addTarget(self, action: #selector(showCamera), for: .touchUpInside)
        showCameraLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightThin, color: .placeholderGrey, alignment: .center)
        showCameraLabel.text = "collection cover image"
        showCameraLabel.lineBreakMode = .byWordWrapping
        showCameraLabel.numberOfLines = 2
        
        addNextButton()
        addTableView()
    }
    
    internal func addTableView() {
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        view.addSubview(tableView)
        view.addSubview(listInstructions)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: showCameraLabel.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: listInstructions.topAnchor, constant: -Spacing.xs.rawValue).isActive = true
        
        tableView?.register(ListItemCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView?.register(ListItemFooter.self, forHeaderFooterViewReuseIdentifier: headerReuseIdentifier)
        
        tableView?.backgroundView = nil
        tableView?.backgroundColor = UIColor.clear
        tableView?.separatorStyle = UITableViewCellSeparatorStyle.none
        
        tableView?.showsVerticalScrollIndicator = false
        tableView?.tableFooterView = UIView()
        
        listInstructions.translatesAutoresizingMaskIntoConstraints = false
        listInstructions.bottomAnchor.constraint(equalTo: submitButton.topAnchor).isActive = true
        listInstructions.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        listInstructions.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
        listInstructions.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        
        listInstructions.numberOfLines = 3
        listInstructions.text = "Create a template with item choices - you can rank / arrange items for your unique list & invite guests to create lists next. Leave items blank if you want users to add new items"
        
        updateDataSource()
    }
    
    internal func addNextButton() {
        view.addSubview(submitButton)

        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalToConstant: PulseButton.regularButtonHeight).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        submitButton.setDisabled()
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
    }
}

extension NewCollectionVC: UITextFieldDelegate, UITextViewDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        checkEnableButton()
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
        
        return true
    }
}
