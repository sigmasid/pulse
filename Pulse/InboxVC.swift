//
//  InboxVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/13/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class InboxVC: PulseVC, UITableViewDataSource, UITableViewDelegate {
    
    var tableView : UITableView!
    var isLoaded = false
    
    var conversations = [Conversation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLoaded {
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
    
    internal func updateDataSource() {
        if !isLoaded {
            setupLayout()
        }
        
        Database.getConversations(completion: { conversations in
            self.conversations = conversations
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.reloadData()
        })
        

        tableView.layoutIfNeeded()
    }
    
    fileprivate func addImage(cell : InboxTableCell, url : String, user : User) {
        DispatchQueue.global(qos: .background).async {
            if let _userImageData = try? Data(contentsOf: URL(string: url)!) {
                DispatchQueue.main.async {
                    let image = UIImage(data: _userImageData)
                    cell.updateImage(image : image)
                    user.thumbPicImage = image
                }
            }
        }
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        headerNav?.setNav(title: "Conversations")
    }
    
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
        
        if !user.uCreated {
            Database.getUser(user.uID!, completion: { (user, error) in
                if let user = user {
                    self.conversations[indexPath.row].cUser = user
                    cell.updateName(name: user.name)
                    if let _uPic = user.thumbPic {
                        self.addImage(cell: cell, url: _uPic, user: user)
                    }
                }
            })
        } else {
            cell.updateName(name: user.name)
            if let _uPic = user.thumbPic {
                addImage(cell: cell, url: _uPic, user: user)
            }
        }
        
        cell.updateLastMessage(message: conversations[indexPath.row].cLastMessage)
        cell.updateMessageTime(time: conversations[indexPath.row].getLastMessageTime())
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let conversation = conversations[indexPath.row]
        
        let messageVC = MessageVC()
        messageVC.toUser = conversation.cUser
        
        if let currentUserImage = conversation.cUser.thumbPicImage {
            messageVC.toUserImage = currentUserImage
        }
        
        navigationController?.pushViewController(messageVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.medium.rawValue + Spacing.s.rawValue * 2
    }
}
