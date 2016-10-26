//
//  InboxVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/13/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class InboxVC: UITableViewController {
    let reuseIdentifier = "InboxTableCell"
    var conversations = [Conversation]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(InboxTableCell.self, forCellReuseIdentifier: reuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
        updateHeader()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    fileprivate func addListenerForSelected(conversationID : String) {
        
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        let backButton = NavVC.getButton(type: .back)
        backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        if let nav = navigationController as? NavVC {
            nav.setNav(title: "Conversations", subtitle: nil, statusImage: nil)
            nav.toggleLogo(mode: .full)
        } else {
            title = "Conversations"
        }
    }
    
    ///Pop self from stack
    func goBack() {
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! InboxTableCell
        let user = conversations[indexPath.row].cUser!
        
        if !user.uCreated {
            Database.getUser(user.uID!, completion: { (user, error) in
                if error == nil {
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
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let conversation = conversations[indexPath.row]
        
        let messageVC = MessageVC()
        messageVC.toUser = conversation.cUser
        
        if let currentUserImage = conversation.cUser.thumbPicImage {
            messageVC.toUserImage = currentUserImage
        }
        
        self.navigationController?.pushViewController(messageVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.medium.rawValue + Spacing.s.rawValue * 2
    }
}
