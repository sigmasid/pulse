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
            print("should be reloading data with conversation count \(conversations.count)")
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view did load fired")
        tableView.register(InboxTableCell.self, forCellReuseIdentifier: reuseIdentifier)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func addImage(cell : InboxTableCell, url : String) {
        DispatchQueue.global(qos: .background).async {
            if let _userImageData = try? Data(contentsOf: URL(string: url)!) {
                DispatchQueue.main.async {
                    cell.updateImage(image : UIImage(data: _userImageData))
                }
            }
        }
    }
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("returned conversation count of \(conversations.count)")
        return conversations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! InboxTableCell
        let user = conversations[indexPath.row].cUser!
        
        if !user.uCreated {
            print("going to get user from database")
            Database.getUser(user.uID!, completion: { (user, error) in
                if error == nil {
                    self.conversations[indexPath.row].cUser = user
                    cell.updateName(name: user.name)
                    if let _uPic = user.thumbPic {
                        print("going to try and add pic")
                        self.addImage(cell: cell, url: _uPic)
                    }
                }
            })
        } else {
            cell.updateName(name: user.name)
            if let _uPic = user.thumbPic {
                addImage(cell: cell, url: _uPic)
            }
        }
        
        cell.updateLastMessage(message: conversations[indexPath.row].cLastMessage)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let conversation = conversations[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.medium.rawValue + Spacing.s.rawValue * 2
    }
}
