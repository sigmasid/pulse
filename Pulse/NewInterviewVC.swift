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

class NewInterviewVC: PulseVC, ParentTextViewDelegate, ModalDelegate, SelectionDelegate  {
    //Set by parent
    public var selectedChannel : Channel!
    public var selectedItem : Item!
    
    fileprivate var selectedUser : PulseUser?
    fileprivate var addEmail : AddText!
    fileprivate var interviewID: String!

    fileprivate var iImage = PulseButton(size: .small, type: .profile, isRound: true, hasBackground: false, tint: .black)
    fileprivate var iName = UITextField()
    fileprivate var iNameDescription = UILabel()
    fileprivate var iTopic = UITextField()
    fileprivate var submitButton = UIButton()
    
    fileprivate var placeholderName = "enter name or tap search"
    fileprivate var placeholderDescription = "brief description for interview"

    fileprivate var sTypeDescription = PaddingLabel()
    fileprivate var addQuestion : AddText!
    
    //Table View Vars
    fileprivate var tableView : UITableView!
    fileprivate var allQuestions = [String]()
    
    fileprivate var headerSetup = false
    fileprivate let addButton = PulseButton(size: .small, type: .add, isRound: true, background: .white, tint: .black)
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
        updateHeader()
    }
    
    deinit {
        performCleanup()
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            allQuestions = []
            selectedUser = nil
            selectedChannel = nil
            selectedItem = nil
            
            if tableView != nil {
                tableView = nil
            }
            
            if addQuestion != nil {
                addQuestion = nil
            }
            
            cleanupComplete = true
        }
    }
    
    /** HEADER FUNCTIONS **/
    internal func updateHeader() {
        addBackButton()
        
        headerNav?.setNav(title: "New Interview", subtitle: selectedItem.itemTitle != "" ? selectedItem.itemTitle : selectedChannel.cTitle)
        headerNav?.updateBackgroundImage(image: selectedChannel.getNavImage())
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
        
        let itemKey = databaseRef.child("items").childByAutoId().key
        let item = Item(itemID: itemKey)
        
        item.itemTitle = iTopic.text ?? ""
        item.itemUserID = PulseUser.currentUser.uID!
        item.cID = selectedChannel.cID
        item.cTitle = selectedChannel.cTitle
        item.tag = selectedItem

        PulseDatabase.createInviteRequest(item: item, type: .interviewInvite, toUser: selectedUser, toName: iName.text!, toEmail: email, childItems: allQuestions, parentItemID: nil, completion: {[weak self] success, error in
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
        if iName.text != "", iTopic.text != "", allQuestions.count > 0 {
            submitButton.setEnabled()
        } else {
            submitButton.setDisabled()
        }
    }
    
    /** Delegate Functions **/
    internal func userClosedModal(_ viewController : UIViewController) {
        dismiss(animated: true, completion: { _ in })
    }
    
    internal func dismiss(_ view : UIView) {
        view.removeFromSuperview()
    }
    
    internal func buttonClicked(_ text: String, sender: UIView) {
        if addQuestion != nil, sender == addQuestion {
            if let selectedIndex = selectedIndex {
                let newIndexPath = IndexPath(row: selectedIndex, section: 0)

                allQuestions[selectedIndex] = text
                tableView.reloadRows(at: [newIndexPath], with: .fade)
                self.selectedIndex = nil
                
            } else {
                let newIndexPath = IndexPath(row: 0, section: 0)

                allQuestions.insert(text, at: 0)
                tableView.insertRows(at: [newIndexPath], with: .left)
            }
            checkEnableButton()
        } else if addEmail != nil, sender == addEmail {
            GlobalFunctions.validateEmail(text, completion: {[weak self] (success, error) in
                guard let `self` = self else { return }
                if !success {
                    self.showAddEmail(bodyText: "invalid email - try again")
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
    
    internal func userClickedMenu() {
        userClickedMenu(bodyText: "")
    }
    
    internal func userClickedMenu(bodyText: String, defaultBodyText: String = "type question") {
        addQuestion = AddText(frame: view.bounds, buttonText: "Add", bodyText: bodyText, defaultBodyText: defaultBodyText)
        addQuestion.delegate = self
        view.addSubview(addQuestion)
    }
    
    internal func userSelected(item : Any) {
        if let user = item as? PulseUser {
            selectedUser = user
            iNameDescription.text = "Pulse user! Invite will be sent in-app"
            iName.text = user.name?.capitalized
            iImage.setImage(selectedUser?.thumbPicImage, for: .normal)
            iImage.clipsToBounds = true
            checkEnableButton()
        }
    }
    
    internal func showAddEmail(bodyText: String) {
        addEmail = AddText(frame: view.bounds, buttonText: "Send",
                           bodyText: bodyText, keyboardType: .emailAddress)
        
        addEmail.delegate = self
        view.addSubview(addEmail)
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
            self.showAddEmail(bodyText: "enter interviewee email")
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
}


extension NewInterviewVC : UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allQuestions.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerReuseIdentifier)
        
        if !headerSetup, let cell = cell {
            addButton.frame.origin = CGPoint(x: 0, y: cell.contentView.bounds.height / 2 - addButton.frame.height / 2)
            
            cell.contentView.addSubview(addButton)
            cell.contentView.backgroundColor = UIColor.white
            addButton.addTarget(self, action: #selector(userClickedMenu as () -> Void), for: .touchUpInside)

            cell.textLabel?.text = "add interview questions"
            cell.textLabel?.setFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: UIColor.black, alignment: .center)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        cell?.accessoryType = .disclosureIndicator
        cell?.textLabel?.text = allQuestions[indexPath.row]
        cell?.textLabel?.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .black, alignment: .left)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedText = allQuestions[indexPath.row]
        selectedIndex = indexPath.row
        userClickedMenu(bodyText: selectedText)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.medium.rawValue
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return IconSizes.medium.rawValue * 1.2
    }
}


//UI Elements
extension NewInterviewVC {
    func setupLayout() {
        view.addSubview(iImage)
        view.addSubview(iName)
        view.addSubview(iNameDescription)
        view.addSubview(iTopic)
        view.addSubview(searchButton)
        view.addSubview(submitButton)
        
        iName.translatesAutoresizingMaskIntoConstraints = false
        iName.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: Spacing.xl.rawValue).isActive = true
        iName.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: Spacing.s.rawValue).isActive = true
        iName.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.65).isActive = true
        iName.layoutIfNeeded()
        
        iNameDescription.translatesAutoresizingMaskIntoConstraints = false
        iNameDescription.topAnchor.constraint(equalTo: iName.bottomAnchor, constant: Spacing.xxs.rawValue).isActive = true
        iNameDescription.leadingAnchor.constraint(equalTo: iName.leadingAnchor).isActive = true
        iNameDescription.trailingAnchor.constraint(equalTo: iName.trailingAnchor).isActive = true
        iNameDescription.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .lightGray, alignment: .left)
        
        iImage.translatesAutoresizingMaskIntoConstraints = false
        iImage.trailingAnchor.constraint(equalTo: iName.leadingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        iImage.centerYAnchor.constraint(equalTo: iName.centerYAnchor).isActive = true
        iImage.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        iImage.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        iImage.layoutIfNeeded()
        
        iImage.removeShadow()
        
        iTopic.translatesAutoresizingMaskIntoConstraints = false
        iTopic.topAnchor.constraint(equalTo: iName.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        iTopic.leadingAnchor.constraint(equalTo: iName.leadingAnchor).isActive = true
        iTopic.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.65).isActive = true
        iTopic.layoutIfNeeded()
        
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.trailingAnchor.constraint(equalTo: iName.trailingAnchor).isActive = true
        searchButton.bottomAnchor.constraint(equalTo: iName.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        searchButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        searchButton.heightAnchor.constraint(equalTo: searchButton.widthAnchor).isActive = true
        searchButton.layoutIfNeeded()
        searchButton.removeShadow()
        
        searchButton.addTarget(self, action: #selector(userClickedSearchUsers), for: .touchUpInside)
        
        iName.delegate = self
        iName.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        iName.addBottomBorder()
        iName.attributedPlaceholder = NSAttributedString(string: placeholderName,
                                                          attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        
        iTopic.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        iTopic.addBottomBorder()
        iTopic.attributedPlaceholder = NSAttributedString(string: placeholderDescription,
                                                         attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        
        addTableView()
        addSubmitButton()
        
    }
    
    internal func addTableView() {
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        view.addSubview(tableView)
        view.addSubview(sTypeDescription)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: iTopic.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        tableView.heightAnchor.constraint(equalToConstant: 275).isActive = true
        tableView.layoutIfNeeded()
        
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView?.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: headerReuseIdentifier)

        tableView?.backgroundView = nil
        tableView?.backgroundColor = UIColor.clear
        tableView?.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        tableView?.separatorColor = UIColor.pulseGrey.withAlphaComponent(0.7)
        
        tableView?.showsVerticalScrollIndicator = false
        tableView?.layoutIfNeeded()
        tableView?.tableFooterView = UIView()
        
        sTypeDescription.translatesAutoresizingMaskIntoConstraints = false
        sTypeDescription.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        sTypeDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sTypeDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        sTypeDescription.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        sTypeDescription.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        
        sTypeDescription.numberOfLines = 3
        sTypeDescription.text = "the interviewee can answer any or all suggested questions. Requests are sent directly in-app to Pulse users or send via email or text message on the next screen."
        
        updateDataSource()
    }
    
    internal func addSubmitButton() {
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.topAnchor.constraint(equalTo: sTypeDescription.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        
        submitButton.layer.cornerRadius = buttonCornerRadius.radius(.regular)
        submitButton.setTitle("Send Interview Request", for: UIControlState())
        submitButton.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
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
