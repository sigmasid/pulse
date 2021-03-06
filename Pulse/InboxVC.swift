//
//  InboxVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/13/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

class InboxVC: PulseVC, ModalDelegate, SelectionDelegate {
    public weak var tabDelegate : MasterTabDelegate!
    
    internal var tableView : UITableView!
    internal var addButton = PulseButton(size: .small, type: .add, isRound : true, background: .white, tint: .black)

    var conversations = [Conversation]()
    fileprivate var isShowingUserSearch = false
    fileprivate var selectedUser : PulseUser? //user selected by mini search
    fileprivate var cleanupComplete = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLoaded {
            NotificationCenter.default.addObserver(self, selector: #selector(userUpdated), name: NSNotification.Name(rawValue: "UserSummaryUpdated"), object: nil)

            tabBarHidden = false
            setupLayout()
            updateDataSource()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarHidden = false
        statusBarHidden = false
        updateHeader()
    }
    
    deinit {
        if !cleanupComplete {
            
            if tableView != nil {
                tableView.removeFromSuperview()
            }
            conversations = []
            selectedUser = nil
            tabDelegate = nil
            cleanupComplete = true
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UserSummaryUpdated"), object: nil)
            isLoaded = false
        }
    }

    internal func setupLayout() {
        tableView = UITableView(frame: view.bounds)
        tableView.register(InboxTableCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: emptyReuseIdentifier)

        tableView.backgroundView = nil
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .pulseGrey
        tableView.tableFooterView = UIView() //removes extra rows at bottom
        tableView.showsVerticalScrollIndicator = false
        
        view.addSubview(tableView)
        
        isLoaded = true
    }
    
    internal func userUpdated() {
        if PulseUser.isLoggedIn() {
            updateDataSource()
        } else {
            conversations = []
            tableView.reloadData()
        }
    }
    
    internal func updateDataSource() {
        if !isLoaded {
            setupLayout()
        }
        
        guard PulseUser.isLoggedIn() else {
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.reloadData()
            return
        }
        
        PulseDatabase.getConversations(completion: { conversations in
            self.conversations = conversations
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.reloadData()
            
            self.keepConversationUpdated()
        })

        tableView.layoutIfNeeded()
    }
    
    internal func keepConversationUpdated() {
        guard PulseUser.isLoggedIn() else { return }
        
        PulseDatabase.keepConversationsUpdated(completion: { conversation in
            if let index = self.conversations.index(of: conversation) {
                self.conversations[index] = conversation
                let indexPath = IndexPath(row: index, section: 0)
                self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            }
        })
    }
    
    internal func newConversation() {
        tabBarHidden = true

        let browseUsers = MiniUserSearchVC()
        browseUsers.modalPresentationStyle = .overCurrentContext
        browseUsers.modalTransitionStyle = .crossDissolve
        
        browseUsers.modalDelegate = self
        browseUsers.selectionDelegate = self
        browseUsers.users = conversations.map({ $0.cUser })
        
        isShowingUserSearch = true
        self.navigationController?.present(browseUsers, animated: true, completion: nil)
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        headerNav?.setNav(title: "Conversations")
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: addButton)
        addButton.addTarget(self, action: #selector(newConversation), for: UIControlEvents.touchUpInside)
        
        if !tabBarHidden, tableView != nil {
            tableView.contentInset = UIEdgeInsetsMake(0, 0, tabBarController!.tabBar.frame.height + Spacing.xxl.rawValue, 0)
        }
    }
    
    //close modal - e.g. mini search
    internal func userClosedModal(_ viewController: UIViewController) {
        tabBarHidden = false

        dismiss(animated: true, completion: { _ in
            if self.isShowingUserSearch, let selectedUser = self.selectedUser {
                self.isShowingUserSearch = false
                self.userSelected(item: selectedUser)
            }
        })
    }
    
    //delegate for mini user search - start new conversation with user
    internal func userSelected(item: Any) {
        //check if the modal is still showing - needed because need to fully dismiss first before pushing on nav stack
        //start new conversation with user
        if !isShowingUserSearch, let user = item as? PulseUser {
            let messageVC = MessageVC()
            messageVC.toUser = user
            
            navigationController?.pushViewController(messageVC, animated: true)
        } else if isShowingUserSearch {
            //just set the user - once modal is dismissed it will recall this method
            selectedUser = item as? PulseUser
        }
        else {
            GlobalFunctions.showAlertBlock("Error Starting Conversation", erMessage: "Sorry the user you selected is not valid")
        }
    }
}
extension InboxVC: UITableViewDelegate, UITableViewDataSource {

    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count == 0 ? 1 : conversations.count
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    //must be implemented for viewForFooterInSection to fire
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return Spacing.xs.rawValue
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard conversations.count > 0 else {
            let cell = tableView.dequeueReusableCell(withIdentifier: emptyReuseIdentifier)
            cell?.textLabel?.numberOfLines = 0
            cell?.textLabel?.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
            cell?.textLabel?.lineBreakMode = .byWordWrapping
            
            cell?.textLabel?.text = "No conversations yet! Your coversation history will show up here"
            return cell!
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! InboxTableCell
        let user = conversations[indexPath.row].cUser!
        
        PulseDatabase.getCachedUserPic(uid: user.uID!, completion: { image in
            DispatchQueue.main.async {
                cell.updateImage(image : image)
            }
        })
        
        if !user.uCreated {
            PulseDatabase.getUser(user.uID!, completion: { (user, error) in
                if let user = user {
                    self.conversations[indexPath.row].cUser = user
                    cell.updateName(name: user.name)
                }
            })
        } else {
            cell.updateName(name: user.name)
        }
        
        let sentByUser : Bool? = conversations[indexPath.row].cLastMessageSender != nil ? conversations[indexPath.row].cLastMessageSender == PulseUser.currentUser : nil
        
        cell.updateLastMessage(conversation: conversations[indexPath.row], sentByUser: sentByUser)
        cell.updateMessageTime(time: conversations[indexPath.row].getLastMessageTime())
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let conversation = conversations[indexPath.row]
        let messageVC = MessageVC()
        messageVC.toUser = conversation.cUser
        
        navigationController?.pushViewController(messageVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.medium.rawValue + Spacing.s.rawValue * 2
    }
}
