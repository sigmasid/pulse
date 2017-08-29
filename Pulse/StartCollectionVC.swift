//
//  NewListVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/21/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import CoreLocation

class NewCollectionVC: PulseVC, ListDelegate, InputMasterDelegate {
    /** Set by parent **/
    public var selectedChannel : Channel!
    public var selectedItem : Item!
    
    /** List UI Vars **/
    fileprivate var listTitle = PaddingTextField()
    fileprivate var listDescription = PaddingTextField()

    fileprivate var submitButton = PulseButton(title: "Submit", isRound: false, hasShadow: false)
    
    fileprivate var placeholderName = "short title for the list"
    fileprivate var placeholderDescription = "short description for list"
    
    fileprivate var listInstructions = PaddingLabel()
    
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
        
        let listItem : Item = Item(itemID: "tempID", itemUserID: PulseUser.currentUser.uID!,
                                   itemTitle: listTitle.text!, type: ItemTypes.collection, tag: selectedItem, cID: selectedChannel.cID)
        listItem.itemDescription = listDescription.text!
        
        PulseDatabase.createList(selectedItem: listItem, listItems: allItems, completion: { success, error in
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
            //so it reloads the header
            tableView.reloadData()
        }
    }
    
    internal func showSuccessMenu() {
        //offer to go to editCollectionVC -> to rank items
        
        let menu = UIAlertController(title: "Successfully Create Collection Template!", message: "Create your unique version of the collection or invite others next", preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "create Collection", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            let editCollectionVC = EditCollectionVC()
            editCollectionVC.selectedChannel = self.selectedChannel
            editCollectionVC.selectedItem = self.selectedItem
            self.navigationController?.pushViewController(editCollectionVC, animated: true)
        }))
        
        menu.addAction(UIAlertAction(title: "invite Guests", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            if let inviteType = self.selectedItem.inviteType() {
                menu.addAction(UIAlertAction(title: "invite Guests", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                    guard let `self` = self else { return }
                    self.showInviteMenu(currentItem: self.selectedItem,
                                        inviteTitle: "Invite Guests",
                                        inviteMessage: "know an expert who can \(self.selectedItem.childActionType())\(self.selectedItem.childType())?\nInvite them below!",
                        inviteType: inviteType)
                }))
            }
        }))
        
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
                self.inputVC.cameraTitle = "add a picture for list item"
                self.inputVC.transitioningDelegate = self
            }
            self.present(self.inputVC, animated: true, completion: nil)
        }))
        
        menu.addAction(UIAlertAction(title: currentItem.linkedURL != nil ? "edit Link" : "add Link", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.showAddText(buttonText: "Done", bodyText: currentItem.linkedURL != nil ? String(describing: currentItem.linkedURL!) : nil, defaultBodyText: "enter link url", keyboardType: .URL)
            self.addMode = .link
            menu.dismiss(animated: true, completion: nil)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    //ParentTextView Delegate
    override func dismiss(_ view : UIView) {
        view.removeFromSuperview()
    }
    
    override func buttonClicked(_ text: String, sender: UIView) {
        guard let _selectedItemTag = selectedItemTag else {
            return
        }
        
        switch addMode! {
        case .title:
            allItems[_selectedItemTag].itemTitle = text
        case .link:
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
        
        guard let _selectedItemTag = selectedItemTag else {
            return
        }
        
        allItems[_selectedItemTag].content = image
        let reloadIndexPath = IndexPath(row: _selectedItemTag, section: 0)
        tableView.reloadRows(at: [reloadIndexPath], with: .fade)
        addMode = .none
        selectedItemTag = nil
        
        dismiss(animated: true, completion: {[weak self] in
            guard let `self` = self else { return }
            self.inputVC.updateAlpha()
        })
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
        
        if currentItem.linkedURL != nil {
            DispatchQueue.main.async {
                cell.addLinkButton()
            }
        }
        
        if currentItem.content != nil {
            DispatchQueue.main.async {
                cell.updateImage(image: currentItem.content)
            }
        }
        
        cell.tag = indexPath.row
        cell.listDelegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.medium.rawValue * 1.2
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return IconSizes.medium.rawValue * 1.2
    }
}


//UI Elements
extension NewCollectionVC {
    fileprivate func setupLayout() {
        view.addSubview(listTitle)
        view.addSubview(listDescription)
        
        listTitle.translatesAutoresizingMaskIntoConstraints = false
        listTitle.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        listTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        listTitle.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
        listTitle.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        
        listDescription.translatesAutoresizingMaskIntoConstraints = false
        listDescription.topAnchor.constraint(equalTo: listTitle.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        listDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        listDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
        listDescription.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        
        listTitle.delegate = self
        listDescription.delegate = self
        
        listTitle.placeholder = placeholderName
        listDescription.placeholder = placeholderDescription
        
        addNextButton()
        addTableView()
    }
    
    internal func addTableView() {
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        view.addSubview(tableView)
        view.addSubview(listInstructions)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: listDescription.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
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
        listInstructions.text = "You can rank / arrange items for your list and invite contributors, guests & subscribers to share their lists. Leave this blank if you want users to create only new items"
        
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
