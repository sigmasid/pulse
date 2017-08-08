//
//  ForumDetailVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/2/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import SafariServices

class ForumDetailVC: PulseVC, UITextViewDelegate {
    
    public var selectedItem : Item!
    public var selectedChannel : Channel!
    
    //model elements
    fileprivate var items = [Item]()
    
    //Layout elements
    fileprivate var tableView = UITableView()
    fileprivate var postBody = PaddingTextView()
    fileprivate var postContainer = UIView()
    fileprivate var postButton = UIButton()
    
    fileprivate var sendBottomConstraint : NSLayoutConstraint!
    fileprivate var textViewHeightConstraint : NSLayoutConstraint!
    fileprivate var placeholderText = "Join the discussion"
    
    //Bools for logic checks
    fileprivate var observersAdded = false
    fileprivate var cleanupComplete = false
    fileprivate var hasForumObserver = false
    fileprivate var canEdit : Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !observersAdded {
            tabBarHidden = true
            hideKeyboardWhenTappedAround()
            
            setupLayout()
            setupForumDetail()
            
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
            
            canEdit = PulseUser.isLoggedIn() && PulseUser.currentUser.isEditor(for: selectedChannel)
            
            observersAdded = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isLoaded {
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
            PulseDatabase.removeForumObserver(forumID: selectedItem.itemID )
            items = []
            selectedItem = nil
            
            NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
            
            cleanupComplete = true
        }
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        addBackButton()
        
        headerNav?.setNav(title: selectedItem.tag?.itemTitle,
                          subtitle: selectedChannel.cTitle)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            sendBottomConstraint.constant = -keyboardHeight
            
            if items.count > 0, tableView.contentSize.height > view.frame.height -  keyboardHeight {
                let indexPath : IndexPath = IndexPath(row:(items.count - 1), section:0)
                tableView.layoutIfNeeded()
                tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        sendBottomConstraint.constant = 0
    }
    
    fileprivate func setupForumDetail() {
        PulseDatabase.getForumItems(threadID: selectedItem.itemID, completion: {[weak self] (items, error) in
            guard let `self` = self else { return }
            if error == nil {
                self.items = items
                self.updateDataSource()
                
                if items.count > 0 {
                    let indexPath : IndexPath = IndexPath(row:(self.items.count - 1), section:0)
                    self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: false)
                }
                self.keepForumUpdated()
            }
        })
    }
    
    fileprivate func keepForumUpdated() {
        if !hasForumObserver {
            hasForumObserver = true
            
            PulseDatabase.keepForumUpdated(forumID: selectedItem.itemID, lastMessage: items.last?.itemID ?? nil, completion: {[weak self] newItem in
                guard let `self` = self else { return }
                self.items.append(newItem)
                let indexPath : IndexPath = IndexPath(row:(self.items.count - 1), section:0)
                self.tableView.insertRows(at:[indexPath], with: .fade)
            })
        }
    }
    
    internal func handleLink() {
        //handle link from selectedItem.linkedurl
        
        if let url = selectedItem.linkedURL {
            let svc = SFSafariViewController(url: url)
            present(svc, animated: true, completion: nil)
        }
    }
    
    //once allItems var is set reload the data
    internal func updateDataSource() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
        tableView.layoutIfNeeded()
    }
    
    internal func post() {
        guard PulseUser.isLoggedIn() else {
            GlobalFunctions.showAlertBlock("Error Posting",
                                           erMessage: "You have to be logged in to post")
            return
        }
        
        guard PulseUser.currentUser.isSubscribedToChannel(cID: selectedChannel.cID) else {
            GlobalFunctions.showAlertBlock("Error Posting",
                                           erMessage: "Only subscribers are allowed to post")
            return
        }
        
        guard postBody.text != "", postBody.text != placeholderText else {
            GlobalFunctions.showAlertBlock("Say Something First",
                                           erMessage: "Posts can't be empty!")
            return
        }
        
        PulseDatabase.postToForum(threadID: selectedItem.itemID, text: postBody.text, channelID: selectedChannel.cID, completion: {[weak self] success, error in
            guard let `self` = self else { return }
            self.textViewHeightConstraint.constant = IconSizes.medium.rawValue

            if success {
                self.postBody.text = self.placeholderText
                self.postBody.textColor = UIColor.lightGray
                self.postButton.setDisabled()
            } else {
                GlobalFunctions.showAlertBlock("Error Posting",
                                               erMessage: "Sorry we had a problem posting your comments. Please try again!")
            }
        })
    }
    
    fileprivate func setupLayout() {
        view.addSubview(postContainer)
        view.addSubview(tableView)
        
        postContainer.translatesAutoresizingMaskIntoConstraints = false
        sendBottomConstraint = postContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        sendBottomConstraint.isActive = true
        postContainer.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        textViewHeightConstraint = postContainer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue)
        textViewHeightConstraint.isActive = true
        postContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: postContainer.topAnchor).isActive = true
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tableView.layoutIfNeeded()
        
        tableView.register(ForumDetailCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.register(ForumItemHeader.self, forHeaderFooterViewReuseIdentifier: headerReuseIdentifier)

        tableView.tableFooterView = UIView() //empty footer to hide extra empty rows
        tableView.estimatedRowHeight = 125
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorColor = .pulseGrey
        tableView.separatorStyle = .singleLine

        postContainer.addSubview(postBody)
        postContainer.addSubview(postButton)
        
        postButton.translatesAutoresizingMaskIntoConstraints = false
        postButton.trailingAnchor.constraint(equalTo: postContainer.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        postButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        postButton.widthAnchor.constraint(equalTo: postButton.heightAnchor).isActive = true
        postButton.centerYAnchor.constraint(equalTo: postContainer.centerYAnchor).isActive = true
        postButton.layoutIfNeeded()
        
        postBody.translatesAutoresizingMaskIntoConstraints = false
        postBody.centerYAnchor.constraint(equalTo: postContainer.centerYAnchor).isActive = true
        postBody.leadingAnchor.constraint(equalTo: postContainer.leadingAnchor).isActive = true
        postBody.trailingAnchor.constraint(equalTo: postButton.leadingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        postBody.heightAnchor.constraint(equalTo:postContainer.heightAnchor).isActive = true
        postBody.layoutIfNeeded()
        postBody.setFont(FontSizes.body.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .left)
        postBody.delegate = self
        
        postBody.text = placeholderText
        postBody.isScrollEnabled = false
        
        postButton.makeRound()
        postButton.setTitle("Post", for: UIControlState())
        postButton.setButtonFont(FontSizes.caption2.rawValue, weight: UIFontWeightBold, color: .white, alignment: .center)
        postButton.setDisabled()
        postButton.addTarget(self, action: #selector(post), for: .touchUpInside)
        
        postContainer.layoutIfNeeded()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            self.postButton.setEnabled()
            
            let sizeThatFitsTextView = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
            textViewHeightConstraint.constant = max(IconSizes.medium.rawValue, sizeThatFitsTextView.height)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = placeholderText
            textView.textColor = UIColor.lightGray
        }
    }
}

extension ForumDetailVC: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! ForumDetailCell
        let currentItem = items[indexPath.row]
        
        PulseDatabase.getCachedUserPic(uid: currentItem.itemUserID, completion: { image in
            DispatchQueue.main.async {
                cell.updateImage(image: image)
            }
        })
        
        PulseDatabase.getUser(currentItem.itemUserID, completion: { user, error in
            if let user = user {
                DispatchQueue.main.async {
                    cell.updateName(name: user.name)
                }
            }
        })
        
        cell.item = currentItem

        return cell
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerReuseIdentifier) as? ForumItemHeader
        
        if let cell = cell {
            PulseDatabase.getUser(selectedItem.itemUserID, completion: {[weak self] user, error in
                guard let `self` = self else { return }
                if let user = user, let name = user.name {
                    let subtitle = "\(name) \u{2022}  \(self.selectedItem.getCreatedAt()!)"
                    cell.updateLabels(title: self.selectedItem.itemTitle, subtitle: subtitle)
                } else {
                    cell.updateLabels(title: self.selectedItem.itemTitle, subtitle: self.selectedItem.getCreatedAt())
                }
                
                if self.selectedItem.linkedURL != nil {
                    let linkButton = cell.addLink()
                    linkButton.addTarget(self, action: #selector(self.handleLink), for: .touchUpInside)
                }
            })
            
            DispatchQueue.main.async {
                cell.updateImage(image: self.selectedItem.content)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        return headerSectionHeight
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return canEdit
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let remove = UITableViewRowAction(style: .destructive, title: "Flag") {[unowned self] action, index in
            PulseDatabase.removeForumItem(itemID: self.items[index.row].itemID, forumID: self.selectedItem.itemID, completion: { success in
                if success {
                    self.items.remove(at: index.row)
                    tableView.deleteRows(at: [index], with: .fade)
                    DispatchQueue.main.async {
                        GlobalFunctions.showAlertBlock("Comment removed", erMessage: "This comment will no longer be visible in the forum. Thanks for actively monitoring the quality of the discussion & comments!")
                    }
                }
            })
        }
        remove.backgroundColor = UIColor.pulseRed
        
        return [remove]
    }
}
