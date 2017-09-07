//
//  NewInterviewVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/23/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import CoreLocation
import MobileCoreServices

class NewInterviewVC: PulseVC, ListDelegate {
    //Set by parent
    public var selectedChannel : Channel!
    public var selectedItem : Item!
    
    fileprivate var selectedUser : PulseUser?
    fileprivate var interviewID: String!

    fileprivate var iImage : PulseButton?
    fileprivate var iName = PaddingTextField()
    fileprivate var iNameDescription = UILabel()
    fileprivate var iTopic = PaddingTextField()
    fileprivate var submitButton = PulseButton(title: "Send Invite", isRound: true, hasShadow: false)
    
    fileprivate var placeholderName = "enter name or tap search"
    fileprivate var placeholderDescription = "brief description for interview"

    fileprivate var sTypeDescription = PaddingLabel()
    fileprivate var selectedItemTag : Int?

    //Table View Vars
    fileprivate var tableView : UITableView!
    fileprivate var allItems = [Item]()
    
    fileprivate var headerSetup = false
    fileprivate let addButton = PulseButton(size: .xSmall, type: .add, isRound: true, background: .white, tint: .black)
    fileprivate let searchButton = PulseButton(size: .small, type: .search, isRound: true, hasBackground: false, tint: .black)

    fileprivate var selectedIndex : Int?
    fileprivate var cleanupComplete = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            tabBarHidden = true
            
            updateHeader()
            setupLayout()
            addChannelContributors()
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
            selectedUser = nil
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
        iImage = addRightButton(type: .profile)
        headerNav?.setNav(title: "New Interview", subtitle: selectedItem.itemTitle != "" ? selectedItem.itemTitle : selectedChannel.cTitle)
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
        if selectedUser != nil {
            createInterviewRequest(completion: {[weak self] success, item in
                guard let `self` = self else { return }
                if success {
                    //clear interview stuff
                    self.selectedUser = nil
                    self.iName.text = self.placeholderName
                    self.iTopic.text = self.placeholderDescription
                    
                    self.showSuccessMenu(message: "Invite Sent!")
                    
                } else {
                    GlobalFunctions.showAlertBlock(viewController: self,
                                                   erTitle: "Error Sending Invite",
                                                   erMessage: "Sorry there was an error sending the invite")
                }
            })
        } else {
            showNewUserInterviewMenu()
        }
    }
    
    internal func createInterviewRequest(email: String? = nil, completion: @escaping (_ success : Bool, _ item : Item?) -> Void) {
        guard PulseUser.isLoggedIn() else {
            GlobalFunctions.showAlertBlock("Please Login", erMessage: "You need to be logged in to send interview requests")
            return
        }
        
        let loading = submitButton.addLoadingIndicator()
        submitButton.setDisabled()
        
        let itemKey = PulseDatabase.getKey(forPath: "items")
        let item = Item(itemID: itemKey)
        
        item.itemTitle = iTopic.text ?? ""
        item.itemUserID = PulseUser.currentUser.uID!
        item.cID = selectedChannel.cID
        item.cTitle = selectedChannel.cTitle
        item.tag = selectedItem

        PulseDatabase.createInviteRequest(item: item, type: .interviewInvite, toUser: selectedUser, toName: iName.text!, toEmail: email, childItems: allItems, parentItemID: nil, completion: {[weak self] success, error in
            guard let `self` = self else { return }
            success ? completion(true, item) : completion(false, nil)
            self.toggleLoading(show: false, message: nil)
            loading.removeFromSuperview()
        })
    }
    
    internal func userClickedSearchUsers() {
        let browseUsers = MiniUserSearchVC()
        browseUsers.modalPresentationStyle = .overCurrentContext
        browseUsers.modalTransitionStyle = .crossDissolve
        browseUsers.modalDelegate = self
        browseUsers.selectionDelegate = self
        browseUsers.selectedChannel = selectedChannel
        navigationController?.present(browseUsers, animated: true, completion: nil)
    }
    
    internal func addChannelContributors() {
        if selectedChannel.contributors.isEmpty {
            PulseDatabase.getChannelContributors(channelID: selectedChannel.cID, completion: {[weak self] success, contributors in
                guard let `self` = self else { return }
                self.selectedChannel.contributors = contributors
            })
        }
    }
    
    internal func checkEnableButton() {
        if iName.text != "", iTopic.text != "", allItems.count > 0 {
            submitButton.setEnabled()
        } else {
            submitButton.setDisabled()
        }
    }
    
    /** Delegate Functions **/
    override func addTextDone(_ text: String, sender: UIView) {
        
        if let _selectedItemTag = selectedItemTag {
            allItems[_selectedItemTag].itemTitle = text
            
            let reloadIndexPath = IndexPath(row: _selectedItemTag, section: 0)
            tableView.reloadRows(at: [reloadIndexPath], with: .fade)
            selectedItemTag = nil
            checkEnableButton()
            
        } else {
            GlobalFunctions.validateEmail(text, completion: {[weak self] (success, error) in
                guard let `self` = self else { return }
                if !success {
                    self.showAddText(buttonText: "Send", bodyText: nil, defaultBodyText: "invalid email - try again")
                } else {
                    self.createInterviewRequest(email: text, completion: {[weak self] success, item in
                        guard let `self` = self else { return }
                        if success {
                            self.showSuccessMenu(message: "Invite Sent!")
                            self.iTopic.text = self.placeholderDescription
                            self.iName.text = self.placeholderName
                        } else {
                            GlobalFunctions.showAlertBlock(viewController: self,
                                                           erTitle: "Error Sending Invite",
                                                           erMessage: "Sorry there was an error sending the invite")
                        }
                    })
                }
            })
        }
    }
    
    override func userSelected(item : Any) {
        if let user = item as? PulseUser {
            selectedUser = user
            iNameDescription.text = "Pulse user! Invite will be sent in-app"
            iName.text = user.name?.capitalized
            checkEnableButton()
            
            PulseDatabase.getCachedUserPic(uid: user.uID!, completion: {[weak self] image in
                guard let `self` = self else { return }
                
                DispatchQueue.main.async {
                    self.iImage?.setImage(image, for: .normal)
                    self.iImage?.clipsToBounds = true
                    self.iImage?.contentMode = .scaleAspectFill
                    self.iImage?.imageView?.contentMode = .scaleAspectFill
                }
            })
        }
    }
    
    internal func showNewUserInterviewMenu() {
        let menu = UIAlertController(title: "Send Options",
                                     message: "How would you like to send it to the recipient?",
                                     preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "copy Interview Link", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.toggleLoading(show: true, message: "creating interview link...", showIcon: true)
            self.createInterviewRequest(completion: {[weak self] success, item in
                guard let `self` = self else { return }
                success ?
                    item?.createShareLink(invite: true, completion: {[weak self] link in
                        guard let `self` = self else { return }
                        UIPasteboard.general.url = link
                        self.showSuccessMenu(message: "Copied link to clipboard!")
                        self.toggleLoading(show: false, message: nil)
                    }) :
                    GlobalFunctions.showAlertBlock(viewController: self,
                                                   erTitle: "Error Sending Invite",
                                                   erMessage: "Sorry there was an error sending the invite")
            })
        }))
        
        menu.addAction(UIAlertAction(title: "send Interview Email", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.showAddText(buttonText: "Send", bodyText: nil, defaultBodyText: "enter interviewee email")
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            menu.dismiss(animated: true, completion: nil)
            DispatchQueue.main.async {
                self.submitButton.setTitle("Send Invite", for: .normal)
                self.checkEnableButton()
            }
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    
    internal func showSuccessMenu(message: String) {
        let menu = UIAlertController(title: message,
                                     message: "Tap okay to return to the series page!",
                                     preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "done", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            menu.dismiss(animated: true, completion: nil)
            self.checkEnableButton()
            self.goBack()
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    func addListItem(title : String) {
        let newItem = Item(itemID: String(allItems.count))
        newItem.itemTitle = title
        
        let newIndexPath = IndexPath(row: allItems.count, section: 0)
        allItems.append(newItem)
        tableView.insertRows(at: [newIndexPath], with: .left)
        tableView.scrollToRow(at: newIndexPath, at: .bottom, animated: true)
    }
    
    func showMenuFor(itemID: String) {
        guard let _selectedItemTag = allItems.index(of: Item(itemID: itemID)) else {
            return
        }
        
        selectedItemTag = _selectedItemTag
        let currentItem = allItems[_selectedItemTag]
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "edit Question", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.showAddText(buttonText: "Done", bodyText: currentItem.itemTitle, keyboardType: .default)
            menu.dismiss(animated: true, completion: nil)
        }))
        
        menu.addAction(UIAlertAction(title: "remove Question", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
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
    
    func userClickedListItem(itemID: String) {
        //ignore - supposed to be for clicking the image link which we don't use
    }
}


extension NewInterviewVC : UITableViewDelegate, UITableViewDataSource {
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
        cell.updateLabels(title: "add Interview Questions", subtitle: "interviewee can answer any or all of your questions - keep them short & specific!")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? ListItemCell else {
            return UITableViewCell()
        }
        
        let currentItem = allItems[indexPath.row]
        cell.updateItemDetails(title: nil, subtitle: allItems[indexPath.row].itemTitle)
        cell.showItemMenu()
        cell.itemID = currentItem.itemID
        
        cell.listDelegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.medium.rawValue * 1.1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return IconSizes.medium.rawValue * 1.25
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}


//UI Elements
extension NewInterviewVC {
    func setupLayout() {
        view.addSubview(iName)
        view.addSubview(iNameDescription)
        view.addSubview(iTopic)
        view.addSubview(searchButton)
        view.addSubview(submitButton)
        
        iName.translatesAutoresizingMaskIntoConstraints = false
        iName.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        iName.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        iName.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
        iName.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        iName.layoutIfNeeded()
        
        iNameDescription.translatesAutoresizingMaskIntoConstraints = false
        iNameDescription.topAnchor.constraint(equalTo: iName.bottomAnchor, constant: Spacing.xxs.rawValue).isActive = true
        iNameDescription.leadingAnchor.constraint(equalTo: iName.leadingAnchor).isActive = true
        iNameDescription.trailingAnchor.constraint(equalTo: iName.trailingAnchor).isActive = true
        iNameDescription.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .lightGray, alignment: .left)
        
        iTopic.translatesAutoresizingMaskIntoConstraints = false
        iTopic.topAnchor.constraint(equalTo: iName.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        iTopic.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        iTopic.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
        iTopic.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        iTopic.layoutIfNeeded()
        
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.trailingAnchor.constraint(equalTo: iName.trailingAnchor).isActive = true
        searchButton.centerYAnchor.constraint(equalTo: iName.centerYAnchor).isActive = true
        searchButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        searchButton.heightAnchor.constraint(equalTo: searchButton.widthAnchor).isActive = true
        searchButton.layoutIfNeeded()
        searchButton.removeShadow()
        
        searchButton.addTarget(self, action: #selector(userClickedSearchUsers), for: .touchUpInside)
        
        iName.delegate = self
        iTopic.delegate = self

        iName.placeholder = placeholderName
        iTopic.placeholder = placeholderDescription
        
        addSubmitButton()
        addTableView()
        
        
    }
    
    internal func addTableView() {
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        view.addSubview(tableView)
        view.addSubview(sTypeDescription)
        
        sTypeDescription.translatesAutoresizingMaskIntoConstraints = false
        sTypeDescription.bottomAnchor.constraint(equalTo: submitButton.topAnchor).isActive = true
        sTypeDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sTypeDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
        sTypeDescription.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: iTopic.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: sTypeDescription.topAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        tableView.layoutIfNeeded()
        
        tableView?.register(ListItemCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView?.register(ListItemFooter.self, forHeaderFooterViewReuseIdentifier: headerReuseIdentifier)

        tableView?.backgroundView = nil
        tableView?.backgroundColor = UIColor.clear
        tableView?.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        tableView?.separatorColor = UIColor.pulseGrey.withAlphaComponent(0.7)
        
        tableView?.showsVerticalScrollIndicator = false
        tableView?.layoutIfNeeded()
        tableView?.tableFooterView = UIView()
        
        sTypeDescription.numberOfLines = 3
        sTypeDescription.text = "Requests are sent directly in-app to Pulse users or choose to send via email or text message on the next screen."
        
        updateDataSource()
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

extension NewInterviewVC: UITextFieldDelegate, UITextViewDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == iName, textField.text != "" {
            iNameDescription.text = "New user! Pick how to send invite next"
            checkEnableButton()
            selectedUser = nil
        } else {
            checkEnableButton()
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
        
        return true
    }
}
