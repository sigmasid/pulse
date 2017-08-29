//
//  ForumVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/2/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ForumVC: PulseVC, HeaderDelegate {

    //set by delegate - selected item is a collection - type questions / posts / perspectives etc. since its a series
    public var selectedChannel: Channel!
    public var selectedItem : Item! {
        didSet {
            guard selectedItem != nil else { return }
            toggleLoading(show: true, message: "loading series...", showIcon: true)
            PulseDatabase.getItemCollection(selectedItem.itemID, completion: {[weak self] (success, items) in
                guard let `self` = self else { return }
                
                self.allItems = items
                self.updateDataSource()
                self.updateHeader()
                self.toggleLoading(show: false, message: nil)
            })
        }
    }
    //end set by delegate
    
    /** main datasource var **/
    fileprivate var allItems = [Item]()
    fileprivate var hasReachedEnd = false
    
    /** Collection View Vars **/
    internal var tableView : UITableView!
    
    fileprivate var isLayoutSetup = false
    fileprivate var seriesImageButton : PulseButton?
    
    private var cleanupComplete = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLayoutSetup {
            setupLayout()
            
            tabBarHidden = true
            isLayoutSetup = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        tabBarHidden = true
        updateHeader()
    }
    
    deinit {
        performCleanup()
    }
    
    private func performCleanup() {
        if !cleanupComplete {
            allItems = []
            selectedChannel = nil
            selectedItem = nil
            tableView = nil
            isLayoutSetup = false
            isLoaded = false
            cleanupComplete = true
        }
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        addBackButton()
        updateChannelImage(channel: selectedChannel)
        headerNav?.followScrollView(tableView, delay: 25.0)
        headerNav?.setNav(title: selectedItem.itemTitle, subtitle: selectedChannel.cTitle)
    }
    
    internal func setupLayout() {
        tableView = UITableView(frame: view.bounds)
        tableView.register(ForumListCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: emptyReuseIdentifier)
        tableView?.register(ItemTableHeader.self, forHeaderFooterViewReuseIdentifier: headerReuseIdentifier)
        
        tableView.backgroundView = nil
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .pulseGrey
        tableView.tableFooterView = UIView() //removes extra rows at bottom
        tableView.showsVerticalScrollIndicator = false
        tableView.estimatedSectionHeaderHeight = skinnyHeaderHeight
        
        view.addSubview(tableView)
    }
    
    internal func updateDataSource() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
        tableView.layoutIfNeeded()
    }
    
    //get more items if scrolled to end
    internal func getMoreItems() {
        
        if let lastItemID = allItems.last?.itemID, !hasReachedEnd {
            
            PulseDatabase.getItemCollection(selectedItem.itemID, lastItem: lastItemID, completion: {[weak self] success, items in
                guard let `self` = self else { return }
                
                if items.count > 0 {
                    
                    var indexPaths = [IndexPath]()
                    for (index, _) in items.enumerated() {
                        let newIndexPath = IndexPath(row: self.allItems.count + index - 1, section: 0)
                        indexPaths.append(newIndexPath)
                    }
                    self.allItems.append(contentsOf: items)
                    self.tableView?.insertRows(at: indexPaths, with: UITableViewRowAnimation.none)
                    
                } else {
                    self.hasReachedEnd = true
                }
            })
        }
    }
    
    internal func clickedHeaderMenu() {
        let menu = UIAlertController(title: "Welcome to \(selectedItem.itemTitle)", message: "\(selectedItem.itemDescription)", preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "start Thread", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.addNewItem()
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func addNewItem() {
        let newThreadVC = NewForumThreadVC()
        newThreadVC.selectedItem = selectedItem
        newThreadVC.selectedChannel = selectedChannel

        navigationController?.pushViewController(newThreadVC, animated: true)
    }
}


extension ForumVC: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! ForumListCell
        let currentItem = allItems[indexPath.row]
        
        cell.accessoryType = .disclosureIndicator
        cell.tintColor = .black

        //if near the end then get more items
        if indexPath.row == allItems.count - 1 {
            getMoreItems()
        }
        
        if currentItem.content == nil, !currentItem.fetchedContent {
            PulseDatabase.getImage(channelID: selectedChannel.cID, itemID: currentItem.itemID,
                                   fileType: .thumb, maxImgSize: MAX_IMAGE_FILESIZE, completion: {[weak self] data, error in
                guard let `self` = self else { return }
                if let data = data, let image = UIImage(data: data), tableView.indexPath(for: cell)?.row == indexPath.row  {
                    self.allItems[indexPath.row].content = image
                    DispatchQueue.main.async {
                        cell.updateImage(image: image)
                    }
                }
            })
        } else if let image = currentItem.content {
            cell.updateImage(image: image)
        }
        
        //Already fetched this item
        if allItems[indexPath.row].itemCreated {
            
            cell.item = allItems[indexPath.row]
            cell.updateName(name: allItems[indexPath.row].user?.name)
            
        } else {
            PulseDatabase.getItem(currentItem.itemID, completion: {[weak self] (item, error) in
                guard let `self` = self else { return }
                
                if let item = item {
                    
                    let itemImage = self.allItems[indexPath.row].content //copy image in case it's already downloaded
                    self.allItems[indexPath.row] = item
                    self.allItems[indexPath.row].content = itemImage
                    
                    if tableView.indexPath(for: cell)?.row == indexPath.row {
                        DispatchQueue.main.async {
                            cell.item = item
                            cell.layoutIfNeeded()
                        }
                    }
                    
                    // Get the user details
                    PulseDatabase.getUser(item.itemUserID, completion: {(user, error) in
                        
                        if let user = user {
                            
                            DispatchQueue.main.async {
                                if tableView.indexPath(for: cell)?.row == indexPath.row {
                                    cell.updateName(name: user.name)
                                }
                            }
                        }
                    })
                }
            })
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        return skinnyHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return FORUM_CELL_HEIGHT
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedThread = allItems[indexPath.row]
        let forumDetailVC = ForumDetailVC()
        selectedThread.tag = selectedItem
        forumDetailVC.selectedItem = selectedThread
        forumDetailVC.selectedChannel = selectedChannel
        navigationController?.pushViewController(forumDetailVC, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerReuseIdentifier) as? ItemTableHeader
        
        if let cell = cell {
            cell.updateLabel("Recent Threads")
            cell.delegate = self
        }
        
        return cell
    }
}

