//
//  ExploreChannelsVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/18/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

protocol ExploreChannelsDelegate: class {
    func userClickedSubscribe(senderTag: Int)
}

class ExploreChannelsVC: PulseVC, ExploreChannelsDelegate, ModalDelegate, SelectionDelegate, BrowseContentDelegate {
    
    // Set by MasterTabVC
    public var universalLink : URL? {
        didSet {
            if isLayoutSetup, let _ = universalLink {
                handleLink()
            }
        }
    }
    public var forUser = false //in case we are browsing channels for a specific user

    public var allChannels = [Channel]() {
        didSet {
            updateDataSource()
        }
    }

    fileprivate var channelCollection : UICollectionView!
    fileprivate var isLayoutSetup = false
    fileprivate var searchButton : PulseButton = PulseButton(size: .small, type: .search, isRound : true, background: .white, tint: .black)
    fileprivate lazy var menuButton : PulseButton = PulseButton(size: .small, type: .ellipsis, isRound : true, hasBackground: false, tint: .black)

    override func viewDidLayoutSubviews() {
        if !isLayoutSetup {
            toggleLoading(show: true, message: "Loading...", showIcon: true)
            setupScreenLayout()
            updateRootScopeSelection()
            isLayoutSetup = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateOnscreenRows()
        updateHeader()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func setupScreenLayout() {
        if !isLayoutSetup {
            
            channelCollection = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
            let _ = PulseFlowLayout.configureLayout(collectionView: channelCollection, minimumLineSpacing: 10, itemSpacing: 10, stickyHeader: true)
            channelCollection.register(ExploreChannelsCell.self, forCellWithReuseIdentifier: reuseIdentifier)
            
            view.addSubview(channelCollection)

            searchButton.addTarget(self, action: #selector(userClickedSearch), for: UIControlEvents.touchUpInside)
            
            if universalLink != nil {
                handleLink()
            }
            
            isLayoutSetup = true
        }
    }
    
    fileprivate func updateHeader() {

        if !forUser {
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: searchButton)
            tabBarHidden = false
            
            menuButton.removeShadow()
            menuButton.addTarget(self, action: #selector(menuButtonClicked), for: .touchUpInside)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: menuButton)
            
            headerNav?.setNav(title: "Explore Channels")
            headerNav?.updateBackgroundImage(image: nil)
        } else {
            addBackButton()
            tabBarHidden = true
            
            headerNav?.setNav(title: "Your Subscriptions")
            headerNav?.updateBackgroundImage(image: nil)
        }
    }
    
    fileprivate func updateRootScopeSelection() {
        if allChannels.isEmpty {
            Database.getExploreChannels({ channels, error in
                if error == nil {
                    self.allChannels = channels
                    self.toggleLoading(show: false, message: nil)
                }
            })
        }
    }
    
    internal func menuButtonClicked() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "start a Channel", style: .default, handler: { (action: UIAlertAction!) in
            self.startChannel()
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func updateDataSource() {
        if !isLayoutSetup {
            setupScreenLayout()
        }
        
        channelCollection.delegate = self
        channelCollection.dataSource = self
        channelCollection.reloadData()
        channelCollection.layoutIfNeeded()
    }
    
    internal func userClickedSearch() {
        let searchNavVC = PulseNavVC(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
        let searchVC = SearchVC()
        searchNavVC.modalTransitionStyle = .crossDissolve

        searchVC.modalDelegate = self
        searchVC.selectionDelegate = self
        searchNavVC.viewControllers = [searchVC]
        
        navigationController?.present(searchNavVC, animated: true, completion: nil)
    }
    
    internal func userClosedModal(_ viewController : UIViewController) {
        dismiss(animated: true, completion: { _ in })
    }
    
    internal func userClickedSubscribe(senderTag: Int) {
        let selectedChannel = allChannels[senderTag]
        
        Database.subscribeChannel(selectedChannel, completion: {(success, error) in
            if !success {
                GlobalFunctions.showAlertBlock("Error Subscribing Tag", erMessage: error!.localizedDescription)
            } else {
                if let cell = self.channelCollection.cellForItem(at: IndexPath(item: senderTag, section: 0)) as? ExploreChannelsCell {
                    DispatchQueue.main.async {
                        if let user = User.currentUser, user.isSubscribedToChannel(cID: selectedChannel.cID) {
                            cell.updateSubscribe(type: .unfollow, tag: senderTag)
                        } else {
                            cell.updateSubscribe(type: .follow, tag: senderTag)
                        }
                    }
                }
            }
        })
    }
    
    internal func userSelected(item : Any) {
        if let item = item as? Item {
            switch item.type {
                
            case .posts, .feedback, .perspectives, .interviews:
                
                let tagDetailVC = TagCollectionVC()
                tagDetailVC.selectedChannel = Channel(cID: item.cID)
                navigationController?.pushViewController(tagDetailVC, animated: true)
                tagDetailVC.selectedItem = item
            
            case .perspective, .answer, .post:
                
                showItemDetail(item: item, allItems: [item])
            
            case .question, .thread, .interview:
                toggleLoading(show: true, message: "Loading Item...", showIcon: true)
                Database.getItemCollection(item.itemID, completion: {(success, items) in
                    success ?
                        self.showItemDetail(item: item, allItems: items) :
                        self.showBrowse(selectedItem: item)
                    self.toggleLoading(show: false, message: nil)
                })
            default: break
            }
        } else if let user = item as? User {
            
            let userProfileVC = UserProfileVC()
            navigationController?.pushViewController(userProfileVC, animated: true)
            userProfileVC.selectedUser = user
            
        } else if let channel = item as? Channel {
            
            showChannel(channel: channel)
            
        }
    }
    
    internal func addNewItem(selectedItem: Item) {
        contentVC = ContentManagerVC()
        contentVC.selectedChannel = Channel(cID: selectedItem.cID, title: selectedItem.cTitle)
        contentVC.selectedItem = selectedItem
        contentVC.openingScreen = .camera
        
        present(contentVC, animated: true, completion: nil)
    }
    
    //
    internal func showBrowse(selectedItem: Item) {
        let _selectedItem = selectedItem
        
        let itemCollection = BrowseContentVC()
        itemCollection.selectedChannel = Channel(cID: selectedItem.cID, title: selectedItem.cTitle)
        itemCollection.selectedItem = _selectedItem
        itemCollection.contentDelegate = self
        
        navigationController?.pushViewController(itemCollection, animated: true)
    }
    
    
    internal func showChannel(channel : Channel) {
        let channelVC = ChannelVC()
        navigationController?.pushViewController(channelVC, animated: true)
        channelVC.selectedChannel = channel
    }

    //used for handling links
    internal func showItemDetail(item : Item, allItems: [Item]) {
        showItemDetail(allItems: allItems, index: 0, itemCollection: [], selectedItem: item, watchedPreview: false)
    }
    
    internal func showItemDetail(allItems: [Item], index: Int, itemCollection: [Item], selectedItem : Item, watchedPreview : Bool) {
        contentVC = ContentManagerVC()
        contentVC.watchedFullPreview = watchedPreview
        contentVC.selectedChannel = Channel(cID: selectedItem.cID, title: selectedItem.cTitle)
        contentVC.selectedItem = selectedItem
        contentVC.itemCollection = itemCollection
        contentVC.itemIndex = index
        contentVC.allItems = allItems
        contentVC.openingScreen = .item
        
        present(contentVC, animated: true, completion: nil)
    }
    
    internal func startChannel() {
        let newChannelVC = NewChannelVC()
        navigationController?.pushViewController(newChannelVC, animated: true)
    }
}

extension ExploreChannelsVC : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allChannels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ExploreChannelsCell
        cell.delegate = self
        
        let channel = allChannels[indexPath.row]
        cell.updateCell(channel.cTitle, subtitle: channel.cDescription)
        
        if let user = User.currentUser {
            user.isSubscribedToChannel(cID: channel.cID) ? cell.updateSubscribe(type: .unfollow, tag: indexPath.row) : cell.updateSubscribe(type: .follow, tag: indexPath.row)
        }
        
        if !channel.cCreated {
            Database.getChannel(cID: channel.cID, completion: { (channel, error) in
                channel.cPreviewImage = self.allChannels[indexPath.row].cPreviewImage
                self.allChannels[indexPath.row] = channel
                cell.updateCell(channel.cTitle, subtitle: channel.cDescription)
            })
        }

        if channel.cPreviewImage != nil {
            cell.updateImage(image: channel.cPreviewImage)
        } else if let urlPath = channel.cImageURL, let url = URL(string: urlPath) {
            DispatchQueue.global().async {
                if let channelImage = try? Data(contentsOf: url) {
                    channel.cPreviewImage = UIImage(data: channelImage)
                    DispatchQueue.main.async(execute: {
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            cell.updateImage(image: channel.cPreviewImage)
                        }
                    })
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        showChannel(channel: allChannels[indexPath.row])
        
    }
    
    internal func updateOnscreenRows() {
        if channelCollection != nil {
            let visiblePaths = channelCollection.indexPathsForVisibleItems
            for indexPath in visiblePaths {
                if let cell = channelCollection.cellForItem(at: indexPath) as? ExploreChannelsCell, let user = User.currentUser{
                    user.isSubscribedToChannel(cID: allChannels[indexPath.row].cID) ? cell.updateSubscribe(type: .unfollow, tag: indexPath.row) : cell.updateSubscribe(type: .follow, tag: indexPath.row)
                }
            }
        }
    }
}

extension ExploreChannelsVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width - 20, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 10.0, bottom: 1.0, right: 10.0)
    }
}

/** HANDLE DYNAMIC LINKS **/
extension ExploreChannelsVC {
     func handleLink() {
        toggleLoading(show: true, message: "Loading Link...", showIcon: true)
        if let universalLink = universalLink, let link = URLComponents(url: universalLink, resolvingAgainstBaseURL: true) {
     
            let urlComponents = link.path.components(separatedBy: "/").dropFirst()
         
            guard let linkType = urlComponents.first else { return }
         
            switch linkType {
            case "u":
                let uID = urlComponents[2]
                userSelected(item: User(uID: uID))
                toggleLoading(show: false, message: nil)

            case "c":
                let selectedChannel = Channel(cID: urlComponents[2])
                showChannel(channel: selectedChannel)
                toggleLoading(show: false, message: nil)

            case "i":
                let itemID = urlComponents[2]
                Database.getItem(itemID, completion: {(item, error) in
                    self.toggleLoading(show: false, message: nil)

                    if let item = item {
                        self.userSelected(item: item)
                    } else {
                        GlobalFunctions.showAlertBlock("Error Locating Item",
                                                       erMessage: "Sorry we couldn't find this item. But there's plenty more interesting content behind this message!")
                    }
                })
            case "invite":
                let inviteID = urlComponents[2]
                Database.getInviteItem(inviteID, completion: { item, type, items, toUser, conversationID, error in
                    if error == nil, let item = item, let type = type {
                        switch type {
                        case .interviewInvite:
                            DispatchQueue.main.async {
                                let interviewVC = InterviewRequestVC()
                                //need to do in this order so all items are set before itemID
                                interviewVC.conversationID = conversationID
                                interviewVC.allQuestions = items
                                interviewVC.selectedUser = toUser
                                interviewVC.interviewItem = item
                                self.navigationController?.pushViewController(interviewVC, animated: true)

                                interviewVC.interviewItemID = item.itemID
                                
                            }
                        case .perspectiveInvite, .questionInvite:
                            DispatchQueue.main.async {
                                let selectedChannel = Channel(cID: item.cID, title: item.cTitle)
                                self.contentVC = ContentManagerVC()
                                self.contentVC.selectedChannel = selectedChannel
                                self.contentVC.selectedItem = item
                                self.contentVC.openingScreen = .camera
                                self.present(self.contentVC, animated: true, completion: nil)
                            }
                        case .contributorInvite:
                            self.showContributorMenu(inviteItem: item)
                        default: break
                        }
                    }
                    self.toggleLoading(show: false, message: nil)
                })
                
            default: break
            }
        
            if !isLayoutSetup {
                isLayoutSetup = true
                self.universalLink = nil
            }
        }
     }
    
    internal func showContributorMenu(inviteItem: Item) {
        let menu = UIAlertController(title: "Congratulations!",
                                     message: "You were recommended as a contributor for \(inviteItem.cTitle ?? " a channel"). Contributors are featured thought leaders who shape the content & experience for this channel. It's a great way to showcase your expertise and build your personal brand", preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "accept Invite", style: .default, handler: { (action: UIAlertAction!) in
            self.showConfirmationMenu(status: true, inviteID: inviteItem.itemID)
        }))
        
        menu.addAction(UIAlertAction(title: "decline Invite", style: .destructive, handler: { (action: UIAlertAction!) in
            self.showConfirmationMenu(status: false, inviteID: inviteItem.itemID)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .default, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    
    internal func showConfirmationMenu(status: Bool, inviteID: String) {
        Database.updateContributorInvite(status: status, inviteID: inviteID, completion: { success, error in
            success ?
                GlobalFunctions.showAlertBlock("All Set!", erMessage: "You have been confirmed as a contributor for the channel. Check out the channel and ") :
                GlobalFunctions.showAlertBlock("Uh Oh! Error Accepting Invite", erMessage: "Sorry we encountered an error. Please try again or send us a message so we get this corrected for you!")
        })
    }
}
