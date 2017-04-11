//
//  HomeVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class HomeVC: PulseVC, BrowseContentDelegate, SelectionDelegate, HeaderDelegate, ItemCellDelegate, ModalDelegate, ParentTextViewDelegate {
    
    //Main data source vars
    var allItems = [Item]()
    var allChannels = [Channel]()
    var allUsers = [User]() //to keep user data cached
    
    fileprivate var isLayoutSetup = false
    
    //fileprivate var feed : Tag!
    fileprivate var notificationsSetup : Bool = false
    fileprivate var initialLoadComplete = false
    fileprivate var minItemsInFeed = 4
    fileprivate var hasReachedEnd = false
    
    /** Collection View Vars **/
    fileprivate var collectionView : UICollectionView!
    
    /** Sync Vars **/
    fileprivate var startUpdateAt : Date = Date()
    fileprivate var endUpdateAt : Date = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

    /** Set which var user has selected to share **/
    fileprivate var selectedShareItem : Item?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            statusBarHidden = true
            tabBarHidden = false
            
            toggleLoading(show: true, message: "Loading feed...", showIcon: true)
            setupScreenLayout()
            
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        statusBarHidden = false
        tabBarHidden = false
        updateHeader()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override init() {
        super.init()
        setupNotifications()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func updateHeader() {
        let logoButton = PulseButton(size: .small, type: .logo, isRound : true, background: .white, tint: .black)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: logoButton)
        
        headerNav?.showNavbar(animated: true)
        headerNav?.setNav(title: "PULSE")
        headerNav?.updateBackgroundImage(image: nil)
        headerNav?.followScrollView(collectionView, delay: 25.0)
    }
    
    internal func createFeed() {
        
        if !initialLoadComplete  {
            
            allChannels = User.currentUser!.subscriptions
            updateFeed()
            updateDataSource()

            toggleLoading(show: false, message: nil)
            
            initialLoadComplete = true
        }
    }
    
    internal func updateFeed() {
        if User.isLoggedIn() {
            Database.createFeed(startingAt: startUpdateAt, endingAt: endUpdateAt, completion: { items in
                var indexPaths = [IndexPath]()
                for (index, _) in items.enumerated() {
                    let newIndexPath = IndexPath(row: index , section: 1)
                    indexPaths.append(newIndexPath)
                }
                if self.allItems.isEmpty {
                    self.collectionView?.reloadData()
                }
                
                self.collectionView.performBatchUpdates({
                    self.collectionView?.insertItems(at: indexPaths)
                    self.allItems.append(contentsOf: items)
                })
            })
            
            startUpdateAt = endUpdateAt
            endUpdateAt = Calendar.current.date(byAdding: .day, value: -7, to: startUpdateAt)!

        } else {
            allChannels = []
            allItems = []
            collectionView.reloadData()
        }
    }
    
    //get more items if scrolled to end
    internal func getMoreItems() {
        
        Database.fetchMoreItems(startingAt: startUpdateAt, endingAt: endUpdateAt, completion: { items in
            var indexPaths = [IndexPath]()
            for (_, item) in items.enumerated() {
                self.allItems.append(item)
                let newIndexPath = IndexPath(row: self.allItems.count - 1, section: 1)
                indexPaths.append(newIndexPath)
            }
            self.collectionView?.insertItems(at: indexPaths)
        })
        
        startUpdateAt = endUpdateAt
        endUpdateAt = Calendar.current.date(byAdding: .day, value: -7, to: startUpdateAt)!
    }
    
    fileprivate func updateDataSource() {
        if !isLayoutSetup {
            setupScreenLayout()
        }
        
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    fileprivate func setupNotifications() {
        if !notificationsSetup {

            NotificationCenter.default.addObserver(self, selector: #selector(createFeed), name: NSNotification.Name(rawValue: "SubscriptionsUpdated"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(updateFeed), name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
            
            notificationsSetup = true
        }
    }
    
    fileprivate func setupScreenLayout() {
        if !isLayoutSetup {
            collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
            let _ = PulseFlowLayout.configureLayout(collectionView: collectionView, minimumLineSpacing: 10, itemSpacing: 10, stickyHeader: true)
            
            collectionView?.register(EmptyCell.self, forCellWithReuseIdentifier: emptyReuseIdentifier)
            collectionView?.register(ItemCell.self, forCellWithReuseIdentifier: reuseIdentifier)
            collectionView?.register(HeaderChannelsCell.self, forCellWithReuseIdentifier: sectionReuseIdentifier)
            collectionView?.register(ItemHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
            
            view.addSubview(collectionView)
            
            isLayoutSetup = true
        }
    }
    
    internal func showSubscriptions() {
        let subscriptionVC = ExploreChannelsVC()
        subscriptionVC.forUser = true

        navigationController?.pushViewController(subscriptionVC, animated: true)
        
        subscriptionVC.allChannels = self.allChannels
    }
}


/* COLLECTION VIEW */
extension HomeVC : UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return allItems.count
        default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.section {
        case 0:
            guard allChannels.count > 0 else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emptyReuseIdentifier, for: indexPath) as! EmptyCell
                cell.setMessage(message: "discover & add new channels to your feed", color: .black)
                return cell
            }
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: sectionReuseIdentifier, for: indexPath) as! HeaderChannelsCell
            cell.channels = allChannels
            cell.delegate = self
            return cell

        case 1:
            //if near the end then get more items
            if indexPath.row == allItems.count - 3 {
                getMoreItems()
            }
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ItemCell
            let currentItem = allItems[indexPath.row]
            cell.itemType = currentItem.type
            cell.tag = indexPath.row
            cell.delegate = self
            
            //clear the cells and set the item type first
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: currentItem.cTitle, _createdAt: currentItem.createdAt, _image: self.allItems[indexPath.row].content as? UIImage ?? nil)
            cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)

            let shouldGetImage = currentItem.type == .post || currentItem.type == .thread || currentItem.type == .perspective
            //Get the image if content type is a post
            if currentItem.content == nil, shouldGetImage, !currentItem.fetchedContent {
                Database.getImage(channelID: currentItem.cID, itemID: currentItem.itemID, fileType: .thumb, maxImgSize: maxImgSize, completion: { (data, error) in
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
            
            //Add additional user details as needed
            if currentItem.user == nil || !currentItem.user!.uCreated {
                if let user = self.checkUserDownloaded(user: User(uID: currentItem.itemUserID)) {
                    self.allItems[indexPath.row].user = user
                    cell.updateLabel(currentItem.itemTitle, _subtitle: user.name, _createdAt: currentItem.createdAt, _tag: currentItem.cTitle)
                    
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
                                    cell.updateLabel(currentItem.itemTitle, _subtitle: user.name, _createdAt: currentItem.createdAt, _tag: currentItem.cTitle)
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
            
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
            return cell
        }
    }
    
    internal func checkUserDownloaded(user: User) -> User? {
        if let index = allUsers.index(of: user) {
            return allUsers[index]
        }
        return nil
    }
    
    internal func updateUserImageDownloaded(user: User, thumbPicImage : UIImage?) {
        if let image = thumbPicImage , let index = allUsers.index(of: user) {
            allUsers[index].thumbPicImage = image
        }
    }
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    internal func updateCell(_ cell: ItemCell, inCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
        if allItems[indexPath.row].itemCreated {
            let currentItem = allItems[indexPath.row]
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: currentItem.cTitle,
                            _createdAt: currentItem.createdAt, _image: allItems[indexPath.row].content as? UIImage ?? nil)
            cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)
        }
    }
    
    internal func updateOnscreenRows() {
        let visiblePaths = collectionView.indexPathsForVisibleItems
        for indexPath in visiblePaths {
            if indexPath.section == 0, allChannels.count > 0 {
                let cell = collectionView.cellForItem(at: indexPath) as! HeaderChannelsCell
                cell.channels = allChannels
            } else if indexPath.section == 1 {
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
            
            headerView.backgroundColor = .white
            
            switch indexPath.section {
            case 0:
                headerView.delegate = self
                headerView.updateLabel("subscriptions")
            case 1:
                break
            default:
                break
            }
            
            //headerView.delegate = self
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
    }
}

extension HomeVC {

    /** Delegate Functions **/
    func userSelected(item : Any) {
        
        if let item = item as? Item {
            switch item.type {
            case .answer:
                
                showItemDetail(allItems: [item], index: 0, itemCollection: [], selectedItem: item, watchedPreview: false)
                
            case .post, .perspective:
                
                showItemDetail(allItems: [item], index: 0, itemCollection: [], selectedItem: item, watchedPreview: false)

            case .question, .thread:
                
                showBrowse(selectedItem: item)
                
            case .posts, .feedback:
                
                showTag(selectedItem: item)
                
            default: break
            }
        } else if let user = item as? User {
            
            let userProfileVC = UserProfileVC()
            navigationController?.pushViewController(userProfileVC, animated: true)
            userProfileVC.selectedUser = user
            
        } else if let channel = item as? Channel {
            let channelVC = ChannelVC()
            channelVC.selectedChannel = channel

            navigationController?.pushViewController(channelVC, animated: true)
        }
    }
    
    /** Browse Content Delegate **/
    internal func showItemDetail(allItems: [Item], index: Int, itemCollection: [Item], selectedItem : Item, watchedPreview : Bool) {
        contentVC = ContentManagerVC()
        contentVC.watchedFullPreview = watchedPreview
        contentVC.selectedChannel = Channel(cID: selectedItem.cID)
        contentVC.selectedItem = selectedItem
        contentVC.itemCollection = itemCollection
        contentVC.itemIndex = index
        contentVC.allItems = allItems
        contentVC.openingScreen = .item
        
        //contentVC.transitioningDelegate = self
        present(contentVC, animated: true, completion: nil)
    }
    
    internal func addNewItem(selectedItem: Item) {
        contentVC = ContentManagerVC()
        contentVC.selectedChannel = Channel(cID: selectedItem.cID)
        contentVC.selectedItem = selectedItem
        contentVC.openingScreen = .camera
        
        present(contentVC, animated: true, completion: nil)
    }
    
    /** End Browse Content Delegate **/
    
    /** Delegate Function **/
    internal func dismiss(_ view : UIView) {
        view.removeFromSuperview()
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
                if let selectedShareItem = selectedShareItem {
                    let selectedChannel = Channel(cID: selectedShareItem.cID, title: selectedShareItem.cTitle)
                    createShareRequest(selectedShareItem: selectedShareItem, selectedChannel: selectedChannel, toUser: nil, toEmail: text, completion: { _ , _ in
                        self.selectedShareItem = nil
                    })
                    
                }
            }
        })
    }
    /** End Delegate Functions **/
    
    internal func showBrowse(selectedItem: Item) {
        let itemCollection = BrowseContentVC()
        itemCollection.selectedChannel = Channel(cID: selectedItem.cID)
        itemCollection.selectedItem = selectedItem
        itemCollection.contentDelegate = self
        
        navigationController?.pushViewController(itemCollection, animated: true)
    }
    
    func userClosedBrowse(_ viewController : UIViewController) {
        dismiss(animated: true, completion: { _ in })
    }
    
    internal func showTag(selectedItem : Item) {
        let tagDetailVC = TagCollectionVC()
        
        navigationController?.pushViewController(tagDetailVC, animated: true)
        tagDetailVC.selectedItem = selectedItem
    }
    
    //for the header
    internal func clickedHeaderMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "browse Subscriptions", style: .default, handler: { (action: UIAlertAction!) in
            self.showSubscriptions()
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    //shows the user profile
    internal func clickedUserButton(itemRow : Int) {
        if let user = allItems[itemRow].user {
            let userProfileVC = UserProfileVC()
            navigationController?.pushViewController(userProfileVC, animated: true)
            userProfileVC.selectedUser = user
        }
    }
    
    //menu for each individual item
    internal func clickedMenuButton(itemRow: Int) {
        let currentItem = allItems[itemRow]
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if currentItem.acceptsInput() {
            menu.addAction(UIAlertAction(title: "add\(currentItem.childType().capitalized)", style: .default, handler: { (action: UIAlertAction!) in
                currentItem.checkVerifiedInput() ? self.addNewItem(selectedItem: currentItem): self.showNonExpertMenu(selectedItem: currentItem)
            }))
            
            menu.addAction(UIAlertAction(title: "invite Experts", style: .default, handler: { (action: UIAlertAction!) in
                self.showInviteMenu(currentItem: currentItem)
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
    
    internal func showNonExpertMenu(selectedItem : Item) {
        let menu = UIAlertController(title: "Become a Contributor?", message: "looks like you are not yet a verified contributor. To ensure quality, we recommend getting verified. You can continue with your submission (might be reviewed for quality).", preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "continue Submission", style: .default, handler: { (action: UIAlertAction!) in
            self.addNewItem(selectedItem: selectedItem)
        }))
        
        menu.addAction(UIAlertAction(title: "become a Contributor", style: .default, handler: { (action: UIAlertAction!) in
            let applyExpertVC = ApplyExpertVC()
            applyExpertVC.selectedChannel = Channel(cID: selectedItem.cID, title: selectedItem.cTitle)
            
            self.navigationController?.pushViewController(applyExpertVC, animated: true)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    /** Menu Options **/
    internal func showInviteMenu(currentItem : Item) {
        let menu = UIAlertController(title: "invite Experts", message: "know someone who can add to the conversation? invite them below!", preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "invite Pulse Users", style: .default, handler: { (action: UIAlertAction!) in
            self.selectedShareItem = currentItem
            
            let browseUsers = MiniUserSearchVC()
            browseUsers.modalPresentationStyle = .overCurrentContext
            browseUsers.modalTransitionStyle = .crossDissolve
            
            browseUsers.modalDelegate = self
            browseUsers.selectionDelegate = self
            browseUsers.selectedChannel = Channel(cID: currentItem.cID, title: currentItem.cTitle)
            self.navigationController?.present(browseUsers, animated: true, completion: nil)
        }))
        
        menu.addAction(UIAlertAction(title: "invite via Email", style: .default, handler: { (action: UIAlertAction!) in
            self.selectedShareItem = currentItem
            self.showAddEmail(bodyText: "enter email")
        }))
        
        menu.addAction(UIAlertAction(title: "more invite Options", style: .default, handler: { (action: UIAlertAction!) in
            let selectedChannel = Channel(cID: currentItem.cID, title: currentItem.cTitle)
            self.createShareRequest(selectedShareItem: currentItem, selectedChannel: selectedChannel, toUser: nil, showAlert: false, completion: { selectedShareItem , error in
                if error == nil, let selectedShareItem = selectedShareItem {
                    let shareText = "Can you add a\(currentItem.childType()) on \(currentItem.itemTitle)"
                    self.showShare(selectedItem: selectedShareItem, type: "invite", fullShareText: shareText)
                }
            })
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
}


extension HomeVC: UICollectionViewDelegateFlowLayout {
    
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
        switch section {
        case 0:
            return UIEdgeInsets(top: 0.0, left: 0.0, bottom: Spacing.xs.rawValue, right: 0.0)
        case 1:
            return UIEdgeInsets(top: 0.0, left: 0.0, bottom: (tabBarController?.tabBar.frame.height ?? 0) + Spacing.xs.rawValue, right: 0.0)
        default:
            return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellHeight : CGFloat = 125
        switch indexPath.section {
        case 0:
            return allItems.count > 0 ? CGSize(width: collectionView.frame.width, height: headerSectionHeight) : CGSize(width: collectionView.frame.width, height: 0)
        case 1:
            return allItems.count > 0 ? CGSize(width: collectionView.frame.width, height: GlobalFunctions.getCellHeight(type: allItems[indexPath.row].type)) :
                                        CGSize(width: collectionView.frame.width, height: 0)
        default:
            return CGSize(width: collectionView.frame.width, height: cellHeight)
        }
    }
    
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

