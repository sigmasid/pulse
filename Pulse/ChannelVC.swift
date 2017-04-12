//
//  ChannelVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ChannelVC: PulseVC, SelectionDelegate, ItemCellDelegate, BrowseContentDelegate, HeaderDelegate, ParentTextViewDelegate, ModalDelegate {
    //set by delegate
    public var selectedChannel : Channel! {
        didSet {
            isSubscribed = User.currentUser!.subscriptionIDs.contains(selectedChannel.cID) ? true : false

            if !selectedChannel.cCreated {
                Database.getChannel(cID: selectedChannel.cID!, completion: { channel, error in
                    channel.cPreviewImage = self.selectedChannel.cPreviewImage
                    self.selectedChannel = channel
                    self.updateHeader()
                })
            } else if !selectedChannel.cDetailedCreated {
                getChannelItems()
            } else {
                allItems = selectedChannel.items
                updateDataSource()
                updateHeader()
            }
        }
    }
    //end set by delegate
    
    //used to cache users downloaded
    fileprivate var allUsers = [User]()
    
    fileprivate var subscribeButton = PulseButton(size: .medium, type: .add, isRound : true, background: .white, tint: .black)
    fileprivate var isSubscribed : Bool = false {
        didSet {
            if !isSubscribed {
               setupSubscribe()
            }
        }
    }
    fileprivate var activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: IconSizes.medium.rawValue, height: IconSizes.medium.rawValue))
    
    /** Data Source Vars **/
    fileprivate var allItems = [Item]()
    fileprivate var hasReachedEnd = false
    
    fileprivate var isLayoutSetup = false
    
    /** Collection View Vars **/
    fileprivate var collectionView : UICollectionView!
    
    fileprivate var selectedShareItem : Any?
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            statusBarStyle = .lightContent
            tabBarHidden = true
            setupScreenLayout()
            
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader()
    }
    
    deinit {
        selectedChannel = nil
        headerNav = nil //the category item - might be the question / tag / post etc.
        
        allItems = []
    }
    
    internal func getChannelItems() {
        Database.getChannelItems(channel: selectedChannel, completion: { updatedChannel in
            if let updatedChannel = updatedChannel {
                updatedChannel.cPreviewImage = self.selectedChannel.cPreviewImage
                self.selectedChannel = updatedChannel
            }
        })
    }
    
    //get more items if scrolled to end
    func getMoreChannelItems() {
        
        if let lastItemID = allItems.last?.itemID, !hasReachedEnd {
            
            Database.getChannelItems(channelID: selectedChannel.cID, lastItem: lastItemID, completion: { success, items in
                if items.count > 0 {
                    
                    var indexPaths = [IndexPath]()
                    for (index, _) in items.enumerated() {
                        let newIndexPath = IndexPath(row: self.allItems.count + index - 1, section: 0)
                        indexPaths.append(newIndexPath)
                    }
                    self.selectedChannel.items.append(contentsOf: items)
                    self.allItems.append(contentsOf: items)
                    self.collectionView?.insertItems(at: indexPaths)
                } else {
                    self.hasReachedEnd = true
                }
            })
        }
    }
    
    //Once the channel is set and pulled from database -> reload the datasource for collection view
    func updateDataSource() {
        if !isLayoutSetup {
            setupScreenLayout()
        }
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }
    
    internal func subscribe() {
        subscribeButton.setImage(nil, for: .normal)
        let indicator = subscribeButton.addLoadingIndicator()
        
        subscribeChannel(channel: selectedChannel, completion: {( success, error ) in
            if !success {
                GlobalFunctions.showAlertBlock("Error Subscribing Tag", erMessage: error!.localizedDescription)
            } else {
                if let user = User.currentUser, user.isSubscribedToChannel(cID: self.selectedChannel.cID) {
                    indicator.removeFromSuperview()
                    self.subscribeButton.setImage(UIImage(named: "check")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
                    self.isSubscribed = true
                    
                    UIView.animate(withDuration: 1, animations: { self.subscribeButton.alpha = 0 } , completion: {(value: Bool) in
                        self.subscribeButton.removeFromSuperview()
                        self.subscribeButton = PulseButton(size: .medium, type: .add, isRound : true, hasBackground: true, tint: .white)
                    })
                }
            }
        })
    }
    
    internal func subscribeChannel(channel : Channel, completion: @escaping (Bool, NSError?) -> Void) {
        Database.subscribeChannel(selectedChannel, completion: {(success, error) in
            completion(success, error)
        })
    }
    
    /** HEADER FUNCTIONS **/
    fileprivate func updateHeader() {
        addBackButton()

        headerNav?.setNav(title: selectedChannel.cTitle ?? "Explore Channel")
        headerNav?.updateBackgroundImage(image: GlobalFunctions.processImage(selectedChannel.cPreviewImage))
        headerNav?.showNavbar(animated: true)
        headerNav?.followScrollView(collectionView, delay: 25.0)
    }
    
    internal func setupSubscribe() {
        addScreenButton(button: subscribeButton)
        subscribeButton.addTarget(self, action: #selector(subscribe), for: UIControlEvents.touchUpInside)
    }
    
    fileprivate func setupScreenLayout() {
        if !isLayoutSetup {
            collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
            let _ = PulseFlowLayout.configureLayout(collectionView: collectionView, minimumLineSpacing: 10, itemSpacing: 10, stickyHeader: true)
            
            collectionView?.register(ItemCell.self, forCellWithReuseIdentifier: reuseIdentifier)
            collectionView?.register(HeaderTagsCell.self, forCellWithReuseIdentifier: sectionReuseIdentifier)
            collectionView?.register(ItemHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
                        
            view.addSubview(collectionView!)
            
            isLayoutSetup = true
        }
    }
}

/** Protocols **/
extension ChannelVC {
    
    /** Delegate Function **/
    internal func dismiss(_ view : UIView) {
        view.removeFromSuperview()
    }
    
    //clicked the image button to go to a user profile
    internal func clickedUserButton(itemRow : Int) {
        if let user = allItems[itemRow].user {
            let userProfileVC = UserProfileVC()
            navigationController?.pushViewController(userProfileVC, animated: true)
            userProfileVC.selectedUser = user
        }
    }
    
    //main menu for each individual item
    internal func clickedMenuButton(itemRow: Int) {
        let currentItem = allItems[itemRow]
        
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if currentItem.acceptsInput() {
            menu.addAction(UIAlertAction(title: "add\(currentItem.childType().capitalized)", style: .default, handler: { (action: UIAlertAction!) in
                currentItem.checkVerifiedInput() ? self.addNewItem(selectedItem: currentItem): self.showNonExpertMenu(selectedItem: currentItem)
            }))
            
            menu.addAction(UIAlertAction(title: "invite Contributors", style: .default, handler: { (action: UIAlertAction!) in
                self.showInviteMenu(currentItem: currentItem, inviteTitle: "Invite Contributors",
                                    inviteMessage: "know someone who can add to the conversation? invite them below!")
            }))
        }
        
        if currentItem.childItemType() != .unknown {
            menu.addAction(UIAlertAction(title: " browse\(currentItem.childType(plural: true).capitalized)", style: .default, handler: { (action: UIAlertAction!) in
                self.showBrowse(selectedItem: currentItem)
            }))
        }
        
        menu.addAction(UIAlertAction(title: "share \(currentItem.type.rawValue.capitalized)", style: .default, handler: { (action: UIAlertAction!) in
            self.showShare(selectedItem: currentItem, type: currentItem.type.rawValue)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func clickedHeaderMenu() {
        guard let user = User.currentUser else {
            return
        }
        
        user.isVerified(for: selectedChannel) ? showExpertMenu() : showRegularMenu()
    }
    
    //close modal - e.g. mini search
    internal func userClosedModal(_ viewController: UIViewController) {
        dismiss(animated: true, completion: { _ in })
    }
    
    //after email - user submitted the text
    internal func buttonClicked(_ text: String, sender: UIView) {
        GlobalFunctions.validateEmail(text, completion: {(success, error) in
            if !success {
                self.showAddEmail(bodyText: "invalid email - try again")
            } else {
                if let selectedShareItem = selectedShareItem as? Item {
                    
                    createShareRequest(selectedShareItem: selectedShareItem, selectedChannel: selectedChannel, toUser: nil, toEmail: text, completion: { _ , _ in
                        self.selectedShareItem = nil
                    })
                    
                } else if let selectedShareItem = selectedShareItem as? Channel {
                    
                    createContributorInvite(selectedChannel: selectedShareItem, toUser: nil, toEmail: text, completion: { _ , _ in })
                    
                }
            }
        })
    }
    /** End Delegate Functions **/
    
    /** Menu Options **/
    internal func showInviteMenu(currentItem : Any?, inviteTitle: String, inviteMessage: String) {
        let menu = UIAlertController(title: inviteTitle, message: inviteMessage, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "invite Pulse Users", style: .default, handler: { (action: UIAlertAction!) in
            self.selectedShareItem = currentItem
            
            let browseUsers = MiniUserSearchVC()
            browseUsers.modalPresentationStyle = .overCurrentContext
            browseUsers.modalTransitionStyle = .crossDissolve
            
            browseUsers.modalDelegate = self
            browseUsers.selectionDelegate = self
            browseUsers.selectedChannel = self.selectedChannel
            self.navigationController?.present(browseUsers, animated: true, completion: nil)
        }))
        
        menu.addAction(UIAlertAction(title: "invite via Email", style: .default, handler: { (action: UIAlertAction!) in
            self.selectedShareItem = currentItem
            self.showAddEmail(bodyText: "enter email")
        }))
        
        menu.addAction(UIAlertAction(title: "more invite Options", style: .default, handler: { (action: UIAlertAction!) in
            if let currentItem = currentItem as? Item {
                self.createShareRequest(selectedShareItem: currentItem, selectedChannel: self.selectedChannel, toUser: nil, showAlert: false,
                                        completion: { selectedShareItem , error in
                    //using the share item returned from the request
                    if error == nil, let selectedShareItem = selectedShareItem {
                        let shareText = "Can you add a\(currentItem.childType()) on \(currentItem.itemTitle)"
                        self.showShare(selectedItem: selectedShareItem, type: "invite", fullShareText: shareText)
                    }
                })
                
            } else if let shareChannel = currentItem as? Channel {
                self.toggleLoading(show: true, message: "loading share options...", showIcon: true)

                self.createContributorInvite(selectedChannel: shareChannel, toUser: nil, toEmail: nil, showAlert: true, completion: { inviteID , error in
                    
                    if error == nil, let inviteID = inviteID {
                        let channelTitle = shareChannel.cTitle ?? "a Pulse channel"
                        let shareText = "You are invited to be a contributor on \(channelTitle)"
                        
                        Database.createShareLink(linkString: "invite/"+inviteID, completion: { link in
                            guard let link = link else {
                                self.toggleLoading(show: false, message: nil)
                                return
                            }
                            
                            self.toggleLoading(show: false, message: nil)
                            self.shareContent(shareType: "", shareText: "", shareLink: link, fullShareText: shareText)
                        })
                    }
                    
                })
            }
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showAddEmail(bodyText: String) {
        addText = AddText(frame: view.bounds, buttonText: "Send",
                           bodyText: bodyText, keyboardType: .emailAddress)
        
        addText.delegate = self
        view.addSubview(addText)
    }
    
    internal func showNonExpertMenu(selectedItem : Item) {
        let menu = UIAlertController(title: "Become a Contributor?", message: "looks like you are not yet a verified contributor. To ensure quality, we recommend getting verified. You can continue with your submission (might be reviewed for quality).", preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "continue Submission", style: .default, handler: { (action: UIAlertAction!) in
            self.addNewItem(selectedItem: selectedItem)
        }))
        
        menu.addAction(UIAlertAction(title: "become a Contributor", style: .default, handler: { (action: UIAlertAction!) in
            let applyExpertVC = ApplyExpertVC()
            applyExpertVC.selectedChannel = self.selectedChannel
            
            self.navigationController?.pushViewController(applyExpertVC, animated: true)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    //for header
    func showExpertMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "start New Series", style: .default, handler: { (action: UIAlertAction!) in
            self.startSeries()
        }))
        
        menu.addAction(UIAlertAction(title: "invite Contributors", style: .default, handler: { (action: UIAlertAction!) in
            self.showInviteMenu(currentItem: self.selectedChannel, inviteTitle: "invite Contributors",
                                inviteMessage: "contributors can add posts, answer questions and share their perspecives on discussions. To ensure quality, please only invite qualified contributors. All new contributor requests are reviewed.")
        }))
        
        menu.addAction(UIAlertAction(title: "share Channel", style: .default, handler: { (action: UIAlertAction!) in
            self.toggleLoading(show: true, message: "loading share options...", showIcon: true)
            self.selectedChannel.createShareLink(completion: { link in
                guard let link = link else { return }
                self.shareContent(shareType: "channel", shareText: self.selectedChannel.cTitle ?? "", shareLink: link)
            })
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
            self.toggleLoading(show: false, message: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    //for header
    func showRegularMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "featured Contributors", style: .default, handler: { (action: UIAlertAction!) in
            let browseContributorsVC = BrowseUsersVC()
            browseContributorsVC.selectedChannel = self.selectedChannel
            browseContributorsVC.delegate = self
            
            self.navigationController?.pushViewController(browseContributorsVC, animated: true)
        }))
        
        menu.addAction(UIAlertAction(title: "share Channel", style: .default, handler: { (action: UIAlertAction!) in
            self.toggleLoading(show: true, message: "loading share options...", showIcon: true)
            self.selectedChannel.createShareLink(completion: { link in
                guard let link = link else { return }
                self.activityController = GlobalFunctions.shareContent(shareType: "channel",
                                                                       shareText: self.selectedChannel.cTitle ?? "",
                                                                       shareLink: link, presenter: self)
            })
        }))
        
        menu.addAction(UIAlertAction(title: isSubscribed ? "unsubscribe" : "subscribe", style: .destructive, handler: { (action: UIAlertAction!) in
            self.subscribeChannel(channel: self.selectedChannel, completion: {(success, error) in
                menu.dismiss(animated: true, completion: nil)
            })
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    /** End Menu Options **/
    
    /** Menu Actions **/
    internal func startSeries() {
        let newSeries = NewSeriesVC()
        newSeries.selectedChannel = selectedChannel
        
        navigationController?.pushViewController(newSeries, animated: true)
    }
    
    internal func userSelected(item : Any) {
        if let item = item as? Item {
            switch item.type {
            case .answer:
                
                showItemDetail(allItems: [item], index: 0, itemCollection: [], selectedItem: item, watchedPreview: false)
                
            case .post, .perspective:
                
                showItemDetail(allItems: [item], index: 0, itemCollection: [], selectedItem: item, watchedPreview: false)
                
            case .question, .thread:
                
                showBrowse(selectedItem: item)
                
            case .posts, .feedback, .perspectives, .interviews, .questions:
                
                showTag(selectedItem: item)
            
            case .interview:
                
                toggleLoading(show: true, message: "loading interview...", showIcon: true)
                Database.getItemCollection(item.itemID, completion: {(success, items) in
                    self.toggleLoading(show: false, message: nil)
                    self.showItemDetail(allItems: items, index: 0, itemCollection: [], selectedItem: item, watchedPreview: false)
                })
                
            default: break
            }
            
        //user selected from mini user search for invite or clicked the user profile button
        } else if let user = item as? User {
    
            userSelectedUser(toUser: user)
        
        //user invalid selection
        } else {
            
            GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Invalid Selection", erMessage: "Sorry! That selection is not valid")
            
        }
    }
    
    //delegate for mini user search - send the invite
    internal func userSelectedUser(toUser: User) {
        
        if let selectedShareItem = selectedShareItem as? Item {
            //
            self.createShareRequest(selectedShareItem: selectedShareItem, selectedChannel: selectedChannel, toUser: toUser, completion: { _ , _ in
                self.selectedShareItem = nil
            })
        } else if let selectedShareItem = selectedShareItem as? Channel {
            
            //channel contributor invite
            createContributorInvite(selectedChannel: selectedShareItem, toUser: toUser, toEmail: nil, showAlert: true, completion: { _, _ in })
            
        } else {
            
            let userProfileVC = UserProfileVC()
            navigationController?.pushViewController(userProfileVC, animated: true)
            userProfileVC.selectedUser = toUser
            
        }
    }
    
    internal func showItemDetail(allItems: [Item], index: Int, itemCollection: [Item], selectedItem : Item, watchedPreview : Bool) {
        contentVC = ContentManagerVC()
        contentVC.watchedFullPreview = watchedPreview
        contentVC.selectedChannel = selectedChannel
        contentVC.selectedItem = selectedItem
        contentVC.itemCollection = itemCollection
        contentVC.itemIndex = index
        contentVC.allItems = allItems
        contentVC.openingScreen = .item
        
        contentVC.transitioningDelegate = self
        present(contentVC, animated: true, completion: nil)
    }
    
    internal func addNewItem(selectedItem: Item) {
        contentVC = ContentManagerVC()
        contentVC.selectedChannel = selectedChannel
        contentVC.selectedItem = selectedItem
        contentVC.openingScreen = .camera
        
        contentVC.transitioningDelegate = self
        present(contentVC, animated: true, completion: nil)
    }
    
    internal func showBrowse(selectedItem: Item) {
        let _selectedItem = selectedItem
        _selectedItem.cID = selectedChannel.cID
        
        let itemCollection = BrowseContentVC()
        itemCollection.selectedChannel = selectedChannel
        itemCollection.selectedItem = _selectedItem
        itemCollection.contentDelegate = self
        
        navigationController?.pushViewController(itemCollection, animated: true)
    }
    
    internal func showTag(selectedItem : Item) {
        let tagDetailVC = TagCollectionVC()
        tagDetailVC.selectedChannel = selectedChannel
        
        navigationController?.pushViewController(tagDetailVC, animated: true)
        tagDetailVC.selectedItem = selectedItem
        
    }
    
    internal func createContributorInvite(selectedChannel: Channel, toUser: User?, toEmail: String?  = nil, showAlert: Bool = true,
                                          completion: @escaping (String?, Error?) -> Void) {
        
        toggleLoading(show: true, message: "creating invite...", showIcon: true)
        Database.createContributorInvite(channel: selectedChannel, type: .contributorInvite, toUser: toUser, toName: nil,
                                         toEmail: toEmail, completion: {(inviteID, error) in
                                        
            self.toggleLoading(show: false, message: nil)

            if error == nil, showAlert {
                GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Invite Sent", erMessage: "Thanks for your recommendation!", buttonTitle: "okay")
                completion(inviteID, nil)
            } else if showAlert {
                GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Error Sending Request", erMessage: "Sorry there was an error sending the invite")
                completion(nil, error)
            }
        })
    }
}

/* COLLECTION VIEW */
extension ChannelVC : UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return self.allItems.count
        default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: sectionReuseIdentifier, for: indexPath) as! HeaderTagsCell
            cell.selectedChannel = selectedChannel
            cell.items = selectedChannel.tags
            cell.delegate = self
            
            return cell
        case 1:
            //if near the end then get more items
            if indexPath.row == allItems.count - 1 {
                getMoreChannelItems()
            }
            
            let currentItem = allItems[indexPath.row]
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ItemCell
            cell.itemType = currentItem.type
            
            cell.delegate = self
            cell.tag = indexPath.row
            
            //clear the cells and set the item type first
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: currentItem.tag?.itemTitle, _createdAt: currentItem.createdAt, _image: self.allItems[indexPath.row].content as? UIImage ?? nil)
            cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)

            //Add additional user details as needed
            if currentItem.user == nil || !currentItem.user!.uCreated {
                if let user = checkUserDownloaded(user: User(uID: currentItem.itemUserID)) {
                    allItems[indexPath.row].user = user
                    cell.updateLabel(currentItem.itemTitle, _subtitle: user.name, _createdAt: currentItem.createdAt, _tag: currentItem.tag?.itemTitle)
                    
                    if user.thumbPicImage == nil {
                        DispatchQueue.global(qos: .background).async {
                            if let imageString = user.thumbPic, let imageURL = URL(string: imageString), let _imageData = try? Data(contentsOf: imageURL) {
                                self.allItems[indexPath.row].user?.thumbPicImage = UIImage(data: _imageData)
                                self.updateUserImageDownloaded(user: user, thumbPicImage: UIImage(data: _imageData))

                                DispatchQueue.main.async {
                                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                        cell.updateButtonImage(image: self.allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Get the user details
                    Database.getUser(currentItem.itemUserID, completion: {(user, error) in
                    if let user = user {
                        self.allItems[indexPath.row].user = user
                        self.allUsers.append(user)
                        DispatchQueue.main.async {
                            if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                cell.updateLabel(currentItem.itemTitle, _subtitle: user.name, _createdAt: currentItem.createdAt, _tag: currentItem.tag?.itemTitle)
                            }
                        }
                        
                        DispatchQueue.global(qos: .background).async {
                            if let imageString = user.thumbPic, let imageURL = URL(string: imageString), let _imageData = try? Data(contentsOf: imageURL) {
                                self.allItems[indexPath.row].user?.thumbPicImage = UIImage(data: _imageData)
                                self.updateUserImageDownloaded(user: user, thumbPicImage: UIImage(data: _imageData))
                                
                                DispatchQueue.main.async {
                                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                        cell.updateButtonImage(image: self.allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)
                                    }
                                }
                            }
                        }
                        
                    }
                    })
                }
            }
            
            let shouldGetImage = currentItem.type == .post || currentItem.type == .thread || currentItem.type == .perspective
            
            //Get the image if content type is a post
            if currentItem.content == nil, shouldGetImage, !currentItem.fetchedContent {
                Database.getImage(channelID: self.selectedChannel.cID, itemID: currentItem.itemID, fileType: .thumb, maxImgSize: maxImgSize, completion: { (data, error) in
                    if let data = data {
                        self.allItems[indexPath.row].content = UIImage(data: data)
                        
                        DispatchQueue.main.async {
                            if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                cell.updateImage(image : self.allItems[indexPath.row].content as? UIImage)
                            }
                        }
                    }
                    
                    self.allItems[indexPath.row].fetchedContent = true
                })
            }
            
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
            return cell
        }
    }
    
    func checkUserDownloaded(user: User) -> User? {
        if let index = allUsers.index(of: user) {
            return allUsers[index]
        }
        return nil
    }

    func updateUserImageDownloaded(user: User, thumbPicImage : UIImage?) {
        if let image = thumbPicImage , let index = allUsers.index(of: user) {
            allUsers[index].thumbPicImage = image
        }
    }
    
    //Did select item at index path
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let selectedItem = allItems[indexPath.row]
            userSelected(item: selectedItem)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! ItemHeader
            switch indexPath.section {
            case 0:
                headerView.backgroundColor = UIColor.white
                headerView.delegate = self
                headerView.updateLabel("featured series")
            case 1:
                break
            default:
                break
            }
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
    }
}

extension ChannelVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case 0:
            return CGSize(width: collectionView.frame.width, height: skinnyHeaderHeight)
        case 1:
            return CGSize(width: collectionView.frame.width, height: 0)
        default:
            return CGSize(width: collectionView.frame.width, height: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: Spacing.xs.rawValue, right: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.section {
        case 0:
            return CGSize(width: collectionView.frame.width, height: headerSectionHeight)
        case 1:
            let cellHeight = GlobalFunctions.getCellHeight(type: allItems[indexPath.row].type)
            return CGSize(width: collectionView.frame.width, height: cellHeight)
        default:
            return CGSize(width: collectionView.frame.width, height: 0)
        }
    }
    
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

extension ChannelVC: UIScrollViewDelegate {
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateCell(_ cell: ItemCell, inCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
        if allItems[indexPath.row].itemCreated {
            let currentItem = allItems[indexPath.row]
            cell.itemType = currentItem.type
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: currentItem.tag?.itemTitle, _createdAt: currentItem.createdAt, _image: allItems[indexPath.row].content as? UIImage ?? nil)
            cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)
        }
    }
    
    func updateOnscreenRows() {
        let visiblePaths = collectionView.indexPathsForVisibleItems
        for indexPath in visiblePaths {
            if indexPath.section == 1 {
                let cell = collectionView.cellForItem(at: indexPath) as! ItemCell
                updateCell(cell, inCollectionView: collectionView, atIndexPath: indexPath)
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateOnscreenRows()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { updateOnscreenRows() }
    }
}

extension ChannelVC: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if presented is ContentManagerVC {
            panDismissInteractionController.wireToViewController(contentVC, toViewController: nil, edge: UIRectEdge.left)
            
            let animator = ExpandAnimationController()
            animator.initialFrame = initialFrame
            animator.exitFrame = getRectToLeft()
            
            return animator
        } else {
            return nil
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is ContentManagerVC {
            let animator = PanAnimationController()
            
            animator.initialFrame = getRectToLeft()
            animator.exitFrame = getRectToRight()
            animator.transitionType = .dismiss
            return animator
        } else {
            return nil
        }
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return panPresentInteractionController.interactionInProgress ? panPresentInteractionController : nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return panDismissInteractionController.interactionInProgress ? panDismissInteractionController : nil
    }
}
