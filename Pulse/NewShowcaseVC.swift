//
//  NewShowcaseVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 5/30/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class NewShowcaseVC: PulseVC, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ParentTextViewDelegate, ModalDelegate, SelectionDelegate {
    //Set by parent
    public var selectedChannel : Channel!
    public var selectedItem : Item!
    
    fileprivate var selectedUser : PulseUser?
    fileprivate var addEmail : AddText!
    
    fileprivate var iImage = PulseButton(size: .small, type: .profile, isRound: true, hasBackground: false, tint: .black)
    fileprivate var iName = UITextField()
    fileprivate var iNameDescription = UILabel()
    
    fileprivate var iTopic = UITextView()
        fileprivate let searchButton = PulseButton(size: .small, type: .search, isRound: true, hasBackground: false, tint: .black)
    fileprivate var sTypeDescription = PaddingLabel()
    fileprivate var submitButton = UIButton()
    
    fileprivate var placeholderName = "enter name or tap search"
    fileprivate var placeholderDescription = "description for what you want the recipient to showcase"
    
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
    
    deinit {
        performCleanup()
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            selectedUser = nil
            selectedChannel = nil
            selectedItem = nil
            
            iImage.removeFromSuperview()
            sTypeDescription.removeFromSuperview()
            searchButton.removeFromSuperview()

            if addEmail != nil {
                addEmail.removeFromSuperview()
                addEmail = nil
            }
            
            cleanupComplete = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /** HEADER FUNCTIONS **/
    internal func updateHeader() {
        addBackButton()
        
        headerNav?.setNav(title: "Invite to Showcase", subtitle: selectedItem.itemTitle != "" ? selectedItem.itemTitle : selectedChannel.cTitle)
        headerNav?.updateBackgroundImage(image: GlobalFunctions.processImage(selectedChannel.cPreviewImage))
        headerNav?.showNavbar(animated: true)
    }
    
    func addChannelContributors() {
        if selectedChannel.contributors.isEmpty {
            PulseDatabase.getChannelContributors(channelID: selectedChannel.cID, completion: {success, contributors in
                self.selectedChannel.contributors = contributors
            })
        }
    }
    
    internal func handleSubmit() {
        if selectedUser != nil {
            createInvite(completion: { success, item in
                if success {
                    GlobalFunctions.showAlertBlock(viewController: self,
                            erTitle: "Invite Sent",
                            erMessage: "You will get a notification when the user adds the showcase!", buttonTitle: "okay")
                    self.selectedUser = nil
                    self.iTopic.text = self.placeholderDescription
                } else {
                    GlobalFunctions.showAlertBlock(viewController: self,
                                                   erTitle: "Error Sending Invite", erMessage: "Sorry there was an error sending the invite")
                }
            })
        } else {
            showNewUserInviteMenu()
        }
    }
    
    internal func createInvite(email: String? = nil, completion: @escaping (_ success : Bool, _ item : Item?) -> Void) {
        guard  PulseUser.isLoggedIn() else {
            GlobalFunctions.showAlertBlock("Please Login", erMessage: "You need to be logged in to send invites")
            return
        }
        toggleLoading(show: true, message: "creating invite...", showIcon: true)

        let loading = submitButton.addLoadingIndicator()
        submitButton.setDisabled()
        
        let itemKey = databaseRef.child("items").childByAutoId().key
        let item = Item(itemID: itemKey, type: "showcases")
        
        item.itemTitle = iTopic.text ?? ""
        item.itemUserID = PulseUser.currentUser.uID
        item.cID = selectedChannel.cID
        item.cTitle = selectedChannel.cTitle
        item.tag = selectedItem
        
        PulseDatabase.createInviteRequest(item: item, type: item.inviteType()!, toUser: selectedUser,
                                          toName: selectedUser?.name ?? iName.text, toEmail: email, childItems: [],  parentItemID: selectedItem.itemID,
                                          completion: {(success, error) in
            success ? completion(true, item) : completion(false, nil)
            loading.removeFromSuperview()
        })
    }
    
    /** Delegate Functions **/
    internal func userClosedModal(_ viewController : UIViewController) {
        dismiss(animated: true, completion: { _ in })
    }
    
    internal func dismiss(_ view : UIView) {
        view.removeFromSuperview()
    }
    
    internal func userSelected(item : Any) {
        if let user = item as? PulseUser {
            iNameDescription.text = "Pulse user! Invite will be sent in-app"
            selectedUser = user
            iName.text = user.name?.capitalized
            iImage.setImage(selectedUser?.thumbPicImage ?? UIImage(named: "default-profile"), for: .normal)
            iImage.clipsToBounds = true
            submitButton.setEnabled()
        }
    }
    
    //Button clicked delegate for after adding in email
    internal func buttonClicked(_ text: String, sender: UIView) {
        if addEmail != nil, sender == addEmail {
            GlobalFunctions.validateEmail(text, completion: {(success, error) in
                if !success {
                    self.showAddEmail(bodyText: "invalid email - try again")
                } else {
                    self.createInvite(email: text, completion: { success, item in
                        if success {
                            GlobalFunctions.showAlertBlock(viewController: self,
                                                           erTitle: "Invite Sent",
                                                           erMessage: "You will get a notification when the user adds the showcase!", buttonTitle: "okay")
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
    /** END DELEGATE FUNCTIONS **/
    
    internal func userClickedSearchUsers() {
        let browseUsers = MiniUserSearchVC()
        browseUsers.modalPresentationStyle = .overCurrentContext
        browseUsers.modalTransitionStyle = .crossDissolve
        browseUsers.modalDelegate = self
        browseUsers.selectionDelegate = self
        browseUsers.selectedChannel = selectedChannel
        navigationController?.present(browseUsers, animated: true, completion: nil)
    }
    
    internal func showNewUserInviteMenu() {
        let menu = UIAlertController(title: "Send Options",
                                     message: "How would you like to send it to the recipient?",
                                     preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "send Invite Email", style: .default, handler: { (action: UIAlertAction!) in
            self.showAddEmail(bodyText: "enter recipient email")
        }))
        
        menu.addAction(UIAlertAction(title: "more Share Options", style: .default, handler: { (action: UIAlertAction!) in
            self.toggleLoading(show: true, message: "creating invite link...", showIcon: true)
            self.createInvite(completion: { success, item in
                let shareText = "Would you like to \(self.selectedItem.childActionType())\(self.selectedItem.childType()) for the series \(self.selectedItem.itemTitle)?"
                success ?
                    self.showShare(selectedItem: item!, type: "invite", fullShareText: shareText, inviteItemID: self.selectedItem.itemID) :
                    GlobalFunctions.showAlertBlock(viewController: self,
                                                   erTitle: "Error Sending Invite", erMessage: "Sorry there was an error sending the invite")
            })
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
            DispatchQueue.main.async {
                self.submitButton.setTitle("Send Invite", for: .normal)
                self.submitButton.setEnabled()
            }
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showAddEmail(bodyText: String) {
        addEmail = AddText(frame: view.bounds, buttonText: "Send",
                           bodyText: bodyText, keyboardType: .emailAddress)
        
        addEmail.delegate = self
        view.addSubview(addEmail)
    }
    
    internal func showSuccessMenu(message: String) {
        let menu = UIAlertController(title: message,
                                     message: "Tap done to return to the series page!",
                                     preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "done", style: .default, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
            self.submitButton.setEnabled()
            self.goBack()
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showErrorMenu(error : Error) {
        let menu = UIAlertController(title: "Error Creating Invite", message: error.localizedDescription, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "cancel", style: .default, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
            self.submitButton.setEnabled()
        }))
        
        present(menu, animated: true, completion: nil)
    }
}

//UI Elements
extension NewShowcaseVC {
    func setupLayout() {
        view.addSubview(iImage)
        view.addSubview(iName)
        view.addSubview(iNameDescription)
        view.addSubview(iTopic)
        view.addSubview(sTypeDescription)

        view.addSubview(searchButton)
        view.addSubview(submitButton)
        
        iName.translatesAutoresizingMaskIntoConstraints = false
        iName.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: Spacing.xxl.rawValue).isActive = true
        iName.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: Spacing.s.rawValue).isActive = true
        iName.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.65).isActive = true
        iName.layoutIfNeeded()
        
        iName.delegate = self
        iName.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        iName.addBottomBorder()
        iName.attributedPlaceholder = NSAttributedString(string: placeholderName,
                                                         attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        
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
        iTopic.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        iTopic.layoutIfNeeded()
        
        iTopic.backgroundColor = UIColor.clear
        iTopic.layer.borderColor = UIColor.black.cgColor
        iTopic.layer.borderWidth = 1.0
        iTopic.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        iTopic.attributedText = NSAttributedString(string: placeholderDescription,
                                                   attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        iTopic.delegate = self
        
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.trailingAnchor.constraint(equalTo: iName.trailingAnchor).isActive = true
        searchButton.bottomAnchor.constraint(equalTo: iName.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        searchButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        searchButton.heightAnchor.constraint(equalTo: searchButton.widthAnchor).isActive = true
        searchButton.layoutIfNeeded()
        searchButton.removeShadow()
        searchButton.addTarget(self, action: #selector(userClickedSearchUsers), for: .touchUpInside)
        
        sTypeDescription.translatesAutoresizingMaskIntoConstraints = false
        sTypeDescription.topAnchor.constraint(equalTo: iTopic.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        sTypeDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sTypeDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        sTypeDescription.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        sTypeDescription.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        
        sTypeDescription.numberOfLines = 3
        sTypeDescription.text = "add in a description. showcase invites are sent directly in-app to existing Pulse users or you can choose to send requests via email or text message on the next screen."
        
        addSubmitButton()
    }
    
    internal func addSubmitButton() {
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.topAnchor.constraint(equalTo: sTypeDescription.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        
        submitButton.layer.cornerRadius = buttonCornerRadius.radius(.regular)
        submitButton.setTitle("Send Invite", for: UIControlState())
        submitButton.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        submitButton.setDisabled()
        
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
    }
}


extension NewShowcaseVC: UITextFieldDelegate, UITextViewDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text != "", sTypeDescription.text != "", sTypeDescription.text != placeholderDescription {
            iNameDescription.text = "New user! Pick how to send invite next"
            selectedUser = nil
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
        
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text != "", textView.text != placeholderDescription, iName.text != "" {
            submitButton.setEnabled()
        } else if textView.text == "" {
            textView.text = placeholderDescription
            submitButton.setDisabled()
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderDescription {
            textView.text = ""
        }
    }
}

