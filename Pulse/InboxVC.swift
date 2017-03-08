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
    
    var conversations = [Conversation]() {
        didSet {
            updateDataSource()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLoaded {
            setupLayout()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader()
    }

    internal func setupLayout() {
        tableView = UITableView(frame: view.bounds)
        tableView.register(InboxTableCell.self, forCellReuseIdentifier: reuseIdentifier)
        view.addSubview(tableView)
        
        isLoaded = true
    }
    
    internal func updateDataSource() {
        if !isLoaded {
            setupLayout()
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
        
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
        addBackButton()
        headerNav?.setNav(title: "Conversations")
    }
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    //must be implemented for viewForFooterInSection to fire
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return Spacing.xs.rawValue
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
