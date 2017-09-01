//
//  MessageVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/3/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

class MessageVC: PulseVC, UITextViewDelegate{
    
    //model elements
    fileprivate var messages = [Message]()

    var toUser : PulseUser! {
        didSet {
            if !isUserLoaded {
                isUserLoaded = true
                updateHeader()
                updateRecipientImage()
                setupConversationHistory()
            }
        }
    }
    fileprivate var conversationID : String? { didSet { self.isExistingConversation = true } } //set during initial load or after first message is sent
    var lastMessageID : String! { didSet { keepConversationUpdated() }} //to sync listener for last updated element
    fileprivate var iImage : PulseButton?
    
    //Layout elements
    fileprivate var msgBody = PaddingTextView()
    fileprivate var conversationHistory = UITableView()
    fileprivate var sendContainer = UIView()
    fileprivate var msgSend = UIButton()
    
    fileprivate var sendBottomConstraint : NSLayoutConstraint!
    fileprivate var textViewHeightConstraint : NSLayoutConstraint!
    //Bools for logic checks
    fileprivate var isExistingConversation = false
    fileprivate var hasConversationObserver = false
    fileprivate var isUserLoaded = false
    
    fileprivate var observersAdded = false
    fileprivate var cleanupComplete = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !observersAdded {
            tabBarHidden = true
            hideKeyboardWhenTappedAround()

            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
            
            observersAdded = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isLoaded {
            setupLayout()
            updateHeader()
            
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarHidden = true
    }
    
    deinit {
        if !cleanupComplete {
            messages = []
            toUser = nil
            
            NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
            
            if let _conversationID = conversationID {
                PulseDatabase.removeConversationObserver(conversationID: _conversationID)
            }
            cleanupComplete = true
        }
    }

    //Update Nav Header
    fileprivate func updateHeader() {
        addBackButton()
        iImage = addRightButton(type: .profile)

        headerNav?.setNav(title: toUser.name != nil ? "Message \(toUser.name!.components(separatedBy: " ")[0])" : "New Message",
                          subtitle: toUser.shortBio)
    }
    
    fileprivate func updateRecipientImage() {
        PulseDatabase.getCachedUserPic(uid: toUser.uID!, completion: {[weak self] image in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.iImage?.setImage(image, for: .normal)
                self.iImage?.clipsToBounds = true
                self.iImage?.contentMode = .scaleAspectFill
                self.iImage?.imageView?.contentMode = .scaleAspectFill
            }
        })
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            sendBottomConstraint.constant = -keyboardHeight
            //conversationHistory.layoutIfNeeded()
            
            if messages.count > 0, conversationHistory.contentSize.height > view.frame.height -  keyboardHeight {
                let indexPath : IndexPath = IndexPath(row:(messages.count - 1), section:0)
                conversationHistory.layoutIfNeeded()
                conversationHistory.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        sendBottomConstraint.constant = 0

        //sendContainer.layoutIfNeeded()
        //conversationHistory.layoutIfNeeded()
    }
    
    fileprivate func setupConversationHistory() {
        PulseDatabase.checkExistingConversation(to: toUser, completion: {[weak self] (success, _conversationID) in
            guard let `self` = self else { return }
            if let conversationID = _conversationID {
                self.conversationID = conversationID
                PulseDatabase.getConversationMessages(user: self.toUser, conversationID: conversationID, completion: {[weak self] messages, lastMessageID, error in
                    guard let `self` = self else { return }
                    if error == nil {
                        self.messages = messages
                        self.lastMessageID = lastMessageID
                        let indexPath : IndexPath = IndexPath(row:(self.messages.count - 1), section:0)
                        self.conversationHistory.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: false)
                    }
                })
            }
        })
    }
    
    fileprivate func keepConversationUpdated() {
        if !hasConversationObserver {
            hasConversationObserver = true

            conversationHistory.dataSource = self
            conversationHistory.delegate = self
            conversationHistory.reloadData()

            PulseDatabase.keepConversationUpdated(conversationID: conversationID!, lastMessage: lastMessageID ?? nil, completion: {[weak self] message in
                guard let `self` = self else { return }
                self.messages.append(message)
                let indexPath : IndexPath = IndexPath(row:(self.messages.count - 1), section:0)
                self.conversationHistory.insertRows(at:[indexPath], with: .fade)
                self.conversationHistory.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
            })
        }
    }
    
    internal func sendMessage() {
        guard PulseUser.currentUser.uID != toUser.uID else {
            GlobalFunctions.showAlertBlock("Error Sending Message",
                                           erMessage: "You are trying to message yourself!")
            return
        }
        
        let message = Message(from: PulseUser.currentUser, to: toUser, body: msgBody.text)
        message.mID = isExistingConversation ? conversationID! : nil
        
        PulseDatabase.sendMessage(existing: isExistingConversation, message: message, completion: {[weak self](success, _conversationID) in
            guard let `self` = self else { return }
            if success {
                self.msgBody.text = "Type message here"
                
                self.msgBody.textColor = UIColor.lightGray
                self.msgSend.setDisabled()
                
                self.conversationID = _conversationID!
                self.keepConversationUpdated()
                
                self.textViewHeightConstraint.constant = IconSizes.medium.rawValue
            } else {
                self.textViewHeightConstraint.constant = IconSizes.medium.rawValue

                GlobalFunctions.showAlertBlock("Error Sending Message",
                                               erMessage: "Sorry we had a problem sending your message. Please try again!")
            }
        })
    }
    
    internal func showSubscribeMenu(selectedChannel: Channel, inviteID: String) {
        
        PulseDatabase.subscribeChannel(selectedChannel, completion: { success, error in
            if success {
                PulseDatabase.markInviteCompleted(inviteID: inviteID)
                GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Subsribed!",
                                               erMessage: "You will now see all the updates in your feed. Enjoy!",
                                               buttonTitle: "done")
                
            } else {
                GlobalFunctions.showAlertBlock("Uh Oh! Error Subscribing",
                                               erMessage: "Sorry we encountered an error. Please try again or send us a message so we get this fixed!")
            }


        })
    }
    
    internal func showConfirmationMenu(status: Bool, inviteID: String) {
        PulseDatabase.updateContributorInvite(status: status, inviteID: inviteID, completion: { success, error in
            success ?
                GlobalFunctions.showAlertBlock(viewController: self,
                                               erTitle: "You are in!",
                                               erMessage: "You have been confirmed as a contributor. Now you can start creating, sharing and showcasing!",
                                               buttonTitle: "okay") :
                GlobalFunctions.showAlertBlock("Uh Oh! Error Accepting Invite",
                                               erMessage: "Sorry we encountered an error. Please try again or send us a message so we get this corrected for you!")
        })
    }
    
    internal func showContributorMenu(messageID: String, messageText: String) {
        toggleLoading(show: true, message: "loading Invite...", showIcon: true)
        let menu = UIAlertController(title: "Congratulations!",
                                     message: "\(messageText) As a verified contributor, you can showcase your content, expertise & brand!", preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "accept Invite", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.showConfirmationMenu(status: true, inviteID: messageID)
            self.toggleLoading(show: false, message: nil)
        }))
        
        menu.addAction(UIAlertAction(title: "decline Invite", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.showConfirmationMenu(status: false, inviteID: messageID)
            self.toggleLoading(show: false, message: nil)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            menu.dismiss(animated: true, completion: nil)
            self.toggleLoading(show: false, message: nil)
        }))
        
        self.present(menu, animated: true, completion: nil)
    }
    
    fileprivate func setupLayout() {
        view.addSubview(sendContainer)
        view.addSubview(conversationHistory)
        
        sendContainer.translatesAutoresizingMaskIntoConstraints = false
        sendBottomConstraint = sendContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        sendBottomConstraint.isActive = true
        sendContainer.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        textViewHeightConstraint = sendContainer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue)
        textViewHeightConstraint.isActive = true
        sendContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        conversationHistory.translatesAutoresizingMaskIntoConstraints = false
        conversationHistory.topAnchor.constraint(equalTo: view.topAnchor, constant: Spacing.xs.rawValue).isActive = true
        conversationHistory.bottomAnchor.constraint(equalTo: sendContainer.topAnchor).isActive = true
        conversationHistory.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        conversationHistory.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        conversationHistory.layoutIfNeeded()
        
        conversationHistory.register(MessageTableCell.self, forCellReuseIdentifier: reuseIdentifier)
        conversationHistory.tableFooterView = UIView() //empty footer to hide extra empty rows
        conversationHistory.rowHeight = UITableViewAutomaticDimension
        conversationHistory.estimatedRowHeight = UIScreen.main.bounds.height / 7
        conversationHistory.separatorStyle = .none
        
        sendContainer.addSubview(msgBody)
        sendContainer.addSubview(msgSend)
        
        msgSend.translatesAutoresizingMaskIntoConstraints = false
        msgSend.trailingAnchor.constraint(equalTo: sendContainer.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        msgSend.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        msgSend.widthAnchor.constraint(equalTo: msgSend.heightAnchor).isActive = true
        msgSend.centerYAnchor.constraint(equalTo: sendContainer.centerYAnchor).isActive = true
        msgSend.layoutIfNeeded()

        msgBody.translatesAutoresizingMaskIntoConstraints = false
        msgBody.centerYAnchor.constraint(equalTo: sendContainer.centerYAnchor).isActive = true
        msgBody.leadingAnchor.constraint(equalTo: sendContainer.leadingAnchor).isActive = true
        msgBody.trailingAnchor.constraint(equalTo: msgSend.leadingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        msgBody.heightAnchor.constraint(equalTo:sendContainer.heightAnchor).isActive = true
        msgBody.layoutIfNeeded()
        msgBody.setFont(FontSizes.body.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .left)
        msgBody.delegate = self
        
        msgBody.text = "Type message here"
        msgBody.isScrollEnabled = false
        
        msgSend.makeRound()
        msgSend.setTitle("Send", for: UIControlState())
        msgSend.setButtonFont(FontSizes.caption2.rawValue, weight: UIFontWeightBold, color: .white, alignment: .center)
        msgSend.setDisabled()
        msgSend.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)

        sendContainer.layoutIfNeeded()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Type message here" {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            self.msgSend.setEnabled()
            
            let sizeThatFitsTextView = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
            textViewHeightConstraint.constant = max(IconSizes.medium.rawValue, sizeThatFitsTextView.height)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "Type message here"
            textView.textColor = UIColor.lightGray
        }
    }
}

extension MessageVC: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! MessageTableCell
        let _currentMessage = messages[indexPath.row]
        
        if _currentMessage.from.uID == PulseUser.currentUser.uID {
            cell.messageType = .sent
            PulseDatabase.getCachedUserPic(uid: PulseUser.currentUser.uID!, completion: { image in
                DispatchQueue.main.async {
                    cell.messageSenderImage.image = image
                }
            })
        } else {
            cell.messageType = .received
            PulseDatabase.getCachedUserPic(uid: toUser.uID!, completion: { image in
                DispatchQueue.main.async {
                    cell.messageSenderImage.image = image
                }
            })
        }
        
        if _currentMessage.mType != .message && cell.messageType == .received {
            cell.accessoryType = .disclosureIndicator
        }

        cell.message = messages[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let message = messages[indexPath.row]
        if message.mType != .message, message.from.uID != PulseUser.currentUser.uID {
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        switch message.mType {
        case .perspectiveInvite, .questionInvite, .showcaseInvite:
            contentVC = ContentManagerVC()
            toggleLoading(show: true, message: "loading Invite...", showIcon: true)
            PulseDatabase.getInviteItem(message.mID, completion: {[weak self] selectedItem, _, childItem, toUser, conversationID, error in
                guard let `self` = self else { return }
                if let selectedItem = selectedItem {
                    DispatchQueue.main.async {
                        let selectedChannel = Channel(cID: selectedItem.cID, title: selectedItem.cTitle)
                        self.contentVC.selectedChannel = selectedChannel
                        self.contentVC.selectedItem = selectedItem
                        self.contentVC.openingScreen = .camera
                        self.present(self.contentVC, animated: true, completion: nil)
                    }
                }
                self.toggleLoading(show: false, message: nil)
            })
            
        case .interviewInvite:
            let interviewVC = InterviewRequestVC()
            interviewVC.conversationID = conversationID
            interviewVC.interviewItemID = message.mID
            
            navigationController?.pushViewController(interviewVC, animated: true)
        
        case .contributorInvite:
            
            showContributorMenu(messageID: message.mID, messageText: message.body)
        
        case .channelInvite:
            
            toggleLoading(show: true, message: "loading Invite...", showIcon: true)
            PulseDatabase.getInviteItem(message.mID, completion: {[weak self] selectedItem, _, childItem, toUser, conversationID, error in
                guard let `self` = self else { return }
                if let selectedItem = selectedItem {
                    DispatchQueue.main.async {
                        let selectedChannel = Channel(cID: selectedItem.cID, title: selectedItem.cTitle)
                        self.showSubscribeMenu(selectedChannel: selectedChannel, inviteID: message.mID)
                    }
                }
                self.toggleLoading(show: false, message: nil)
            })
            
        case .collectionInvite:
            
            toggleLoading(show: true, message: "loading Invite...", showIcon: true)
            PulseDatabase.getInviteItem(message.mID, completion: {[weak self] selectedItem, _, childItem, toUser, conversationID, error in
                guard let `self` = self else { return }
                if let selectedItem = selectedItem {
                    DispatchQueue.main.async {
                        let editCollectionVC = EditCollectionVC()
                        let selectedChannel = Channel(cID: selectedItem.cID, title: selectedItem.cTitle)
                        editCollectionVC.selectedChannel = selectedChannel
                        editCollectionVC.selectedItem = selectedItem
                        self.navigationController?.pushViewController(editCollectionVC, animated: true)
                    }
                }
                self.toggleLoading(show: false, message: nil)
            })
            
            
        default: break
        }
    }
}
