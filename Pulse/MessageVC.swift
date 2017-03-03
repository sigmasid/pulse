//
//  MessageVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/3/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class MessageVC: UIViewController, UITextViewDelegate{
    
    //model elements
    fileprivate var messages = [Message]()

    var toUser : User! {
        didSet {
            if !isUserLoaded {
                isUserLoaded = true
                setupToUserLayout()
                updateToUserData()
                setupConversationHistory()
            }
        }
    }
    fileprivate var conversationID : String? { didSet { self.isExistingConversation = true } } //set during initial load or after first message is sent
    var toUserImage : UIImage? //set by delegate
    var lastMessageID : String! { didSet { keepConversationUpdated() }} //to sync listener for last updated element
    
    //Layout elements
    fileprivate var msgTo = UIView()
    fileprivate var msgToUserName = UILabel()
    fileprivate var msgToUserBio = UILabel()
    fileprivate var msgBody = UITextView()
    fileprivate var conversationHistory = UITableView()
    fileprivate var sendContainer = UIView()
    fileprivate var msgSend = UIButton()
    
    fileprivate var sendBottomConstraint : NSLayoutConstraint!
    fileprivate var textViewHeightConstraint : NSLayoutConstraint!
    //Bools for logic checks
    fileprivate var isExistingConversation = false
    fileprivate var hasConversationObserver = false
    fileprivate var isUserLoaded = false
    
    fileprivate var reuseIdentifier = "messageCell"
    fileprivate var isLoaded = false
    fileprivate var observersAdded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !observersAdded {
            extendedLayoutIncludesOpaqueBars = true
            hideKeyboardWhenTappedAround()

            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
            observersAdded = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        if !isLoaded {
            
            view.backgroundColor = UIColor.white
            view.layoutIfNeeded()

            setupLayout()
            updateHeader()
            
            isLoaded = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        extendedLayoutIncludesOpaqueBars = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let _conversationID = conversationID {
            Database.removeConversationObserver(conversationID: _conversationID)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    //Update Nav Header
    fileprivate func updateHeader() {
        let backButton = PulseButton(size: .small, type: .back, isRound : true, hasBackground: true)
        backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        if let nav = navigationController as? PulseNavVC {
            nav.setNav(title: msgToUserName.text != nil ? "Message \(msgToUserName.text!.components(separatedBy: " ")[0])" : "New Message")
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            sendBottomConstraint.constant = -keyboardHeight
            conversationHistory.layoutIfNeeded()
            
            if messages.count > 0 {
                let indexPath : IndexPath = IndexPath(row:(messages.count - 1), section:0)
                conversationHistory.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: false)
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        sendBottomConstraint.constant = 0

        sendContainer.layoutIfNeeded()
        conversationHistory.layoutIfNeeded()
    }
    
    fileprivate func setupConversationHistory() {
        Database.checkExistingConversation(to: toUser, completion: {(success, _conversationID) in
            if success {
                self.conversationID = _conversationID!
                Database.getConversationMessages(conversationID: _conversationID!, completion: { messages, lastMessageID, error in
                    if error == nil {
                        self.messages = messages
                        self.lastMessageID = lastMessageID
                        let indexPath : IndexPath = IndexPath(row:(self.messages.count - 1), section:0)
                        self.conversationHistory.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
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

            Database.keepConversationUpdated(conversationID: conversationID!, lastMessage: lastMessageID ?? nil, completion: { message in
                self.messages.append(message)
                let indexPath : IndexPath = IndexPath(row:(self.messages.count - 1), section:0)
                self.conversationHistory.insertRows(at:[indexPath], with: .fade)
                self.conversationHistory.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
            })
        }
    }
    
    func sendMessage() {
        guard User.currentUser!.uID != toUser.uID else { return }
        
        let message = Message(from: User.currentUser!, to: toUser, body: msgBody.text)
        message.mID = isExistingConversation ? conversationID! : nil
        
        Database.sendMessage(existing: isExistingConversation, message: message, completion: {(success, _conversationID) in
            if success {
                self.msgBody.text = "Type message here"
                self.msgBody.textColor = UIColor.lightGray
                self.msgSend.setDisabled()
                
                self.conversationID = _conversationID!
                self.keepConversationUpdated()
            } else {
                GlobalFunctions.showErrorBlock("Error Sending Message", erMessage: "Sorry we had a problem sending your message. Please try again!")
            }
        })
    }
    
    fileprivate func setupLayout() {
        view.addSubview(msgTo)
        view.addSubview(sendContainer)
        view.addSubview(conversationHistory)

        msgTo.translatesAutoresizingMaskIntoConstraints = false
        msgTo.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        msgTo.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        msgTo.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        msgTo.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        sendContainer.translatesAutoresizingMaskIntoConstraints = false
        sendBottomConstraint = sendContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        sendBottomConstraint.isActive = true
        sendContainer.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        textViewHeightConstraint = sendContainer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue)
        textViewHeightConstraint.isActive = true
        sendContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        conversationHistory.translatesAutoresizingMaskIntoConstraints = false
        conversationHistory.topAnchor.constraint(equalTo: msgTo.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        conversationHistory.bottomAnchor.constraint(equalTo: sendContainer.topAnchor, constant: -Spacing.s.rawValue).isActive = true
        conversationHistory.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        conversationHistory.centerXAnchor.constraint(equalTo: msgTo.centerXAnchor).isActive = true
        conversationHistory.layoutIfNeeded()
        
        conversationHistory.register(MessageTableCell.self, forCellReuseIdentifier: reuseIdentifier)
        conversationHistory.tableFooterView = UIView() //empty footer to hide extra empty rows
        conversationHistory.rowHeight = UITableViewAutomaticDimension
        conversationHistory.estimatedRowHeight = UIScreen.main.bounds.height / 7
        
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
        
        textViewHeightConstraint = msgBody.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue)
        textViewHeightConstraint.isActive = true
        msgBody.layoutIfNeeded()
        
        msgBody.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        msgBody.layer.borderColor = UIColor.lightGray.cgColor
        msgBody.layer.borderWidth = 1.0
        msgBody.delegate = self
        
        msgBody.text = "Type message here"
        msgBody.textColor = UIColor.lightGray
        msgBody.isScrollEnabled = false
        
        msgSend.makeRound()
        msgSend.setTitle("Send", for: UIControlState())
        msgSend.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)
        msgSend.setDisabled()
        msgSend.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)

        sendContainer.layoutIfNeeded()
        tabBarController?.tabBar.isHidden = true
    }
    
    fileprivate func setupToUserLayout() {
        msgTo.addSubview(msgToUserName)
        msgTo.addSubview(msgToUserBio)

        msgToUserName.translatesAutoresizingMaskIntoConstraints = false
        msgToUserName.centerXAnchor.constraint(equalTo: msgTo.centerXAnchor).isActive = true
        msgToUserName.topAnchor.constraint(equalTo: msgTo.topAnchor).isActive = true
        
        msgToUserName.setFont(FontSizes.body.rawValue, weight: UIFontWeightBold, color: UIColor.black, alignment: .center)
        
        msgToUserBio.translatesAutoresizingMaskIntoConstraints = false
        msgToUserBio.centerXAnchor.constraint(equalTo: msgTo.centerXAnchor).isActive = true
        msgToUserBio.topAnchor.constraint(equalTo: msgToUserName.bottomAnchor).isActive = true
        
        msgToUserBio.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: UIColor.gray, alignment: .center)
    }
    
    fileprivate func updateToUserData() {
        if let _uName = toUser.name {
            msgToUserName.text = _uName
        }
        
        if let _uBio = toUser.shortBio {
            msgToUserBio.text = _uBio
        }
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
            textViewHeightConstraint.constant = sizeThatFitsTextView.height
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
        
        if _currentMessage.from.uID == User.currentUser?.uID {
            cell.messageType = .sent
            cell.messageSenderImage.image = User.currentUser?.thumbPicImage
        } else {
            cell.messageType = .received
            cell.messageSenderImage.image = toUserImage
        }

        cell.message = messages[indexPath.row]
        return cell
    }
}
