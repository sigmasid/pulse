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
    var allUsers = [PulseUser]() //to keep user data cached
    
    fileprivate var isLayoutSetup = false
    
    fileprivate var notificationsSetup : Bool = false
    fileprivate var initialLoadComplete = false
    fileprivate var minItemsInFeed = 4
    fileprivate var hasReachedEnd = false
    fileprivate var updateIncrement = -7 //get one week's worth of data on first load
    fileprivate var emptyMessage = "Discover & add new channels to your feed"
    fileprivate var footerMessage = "Fetching More..."
    fileprivate var shouldShowHeader = true //used for the "subscriptions" header - hide it if logged out or no subscriptions
    
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
            
            if PulseUser.isLoggedIn(), !initialLoadComplete {
                
                toggleLoading(show: true, message: "Loading feed...", showIcon: true)
                
            } else if !PulseUser.isLoggedIn(), !initialLoadComplete {
                
                emptyMessage = "Please login to see your feed"
                createFeed()
                toggleLoading(show: false, message: nil)
                
            }
            
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
        //let logoButton = PulseButton(size: .small, type: .logo, isRound : true, background: .white, tint: .black)
        //navigationItem.leftBarButtonItem = UIBarButtonItem(customView: logoButton)
        
        headerNav?.showNavbar(animated: true)
        headerNav?.setLogo()
        headerNav?.updateBackgroundImage(image: nil)
        headerNav?.setBackgroundColor(color: UIColor.pulseGrey.withAlphaComponent(0.4))
        headerNav?.followScrollView(collectionView, delay: 25.0)
    }
    
    internal func createFeed() {
        if PulseUser.isLoggedIn(), PulseUser.currentUser.subscriptions.count > 0 {
            
            allChannels = PulseUser.currentUser.subscriptions
            updateFeed()
            updateDataSource()
            
            shouldShowHeader = true
            collectionView?.reloadSections(IndexSet(integer: 0))
            initialLoadComplete = true
            
        } else if PulseUser.currentUser.subscriptions.count == 0 {
            
            toggleLoading(show: false, message: nil)
            updateDataSource()
            
            emptyMessage = "Discover & add new channels to your feed"
            shouldShowHeader = false
            collectionView?.reloadSections(IndexSet(integer: 0))
            initialLoadComplete = true
            
        } else if !PulseUser.isLoggedIn() {
            
            emptyMessage = "Please login to see your feed"
            shouldShowHeader = false
            
            updateFeed()
            updateDataSource()
            
            collectionView?.reloadSections(IndexSet(integer: 0))
        
        }
    }
    
    internal func updateFeed() {

        if PulseUser.isLoggedIn() {
            PulseDatabase.createFeed(startingAt: startUpdateAt, endingAt: endUpdateAt, completion: {[weak self] items in
                guard let `self` = self else {
                    return
                }
                
                var indexPaths = [IndexPath]()
                for (index, _) in items.enumerated() {
                    let newIndexPath = IndexPath(row: index , section: 1)
                    indexPaths.append(newIndexPath)
                }
                
                if !items.isEmpty {
                    self.shouldShowHeader = true

                    self.collectionView.performBatchUpdates({
                        self.collectionView?.insertItems(at: indexPaths)
                        self.allItems.append(contentsOf: items)
                        self.collectionView?.reloadData()
                        self.collectionView?.collectionViewLayout.invalidateLayout()
                        self.collectionView?.reloadSections(IndexSet(integer: 0))

                    })
                }
                
                if self.collectionView == nil {
                    self.setupScreenLayout()
                }
                
                if self.collectionView.contentSize.height < self.view.frame.height { //content fits the screen so fetch more
                    self.getMoreItems(completion: { _ in
                        self.collectionView?.reloadData()
                        self.collectionView?.reloadSections(IndexSet(integer: 0))
                    })
                }
                
                self.toggleLoading(show: false, message: nil)
            })
            
            startUpdateAt = endUpdateAt
            endUpdateAt = Calendar.current.date(byAdding: .day, value: updateIncrement, to: startUpdateAt)!
            
        } else {
            allChannels = []
            allItems = []
            emptyMessage = "Please login to see your feed"

            collectionView.reloadData()
            
            shouldShowHeader = false
            collectionView?.collectionViewLayout.invalidateLayout()
            initialLoadComplete = false
            
            startUpdateAt = Date()
            endUpdateAt = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            
            toggleLoading(show: false, message: nil)
        }
    }
    
    //get more items if scrolled to end
    internal func getMoreItems(completion: @escaping (Bool) -> Void) {
        
        PulseDatabase.fetchMoreItems(startingAt: startUpdateAt, endingAt: endUpdateAt, completion: {[weak self] items in
            guard let `self` = self else {
                return
            }
            
            if items.isEmpty, self.updateIncrement > -365 { //max lookback is one year
                self.updateIncrement = self.updateIncrement * 2
                self.endUpdateAt = Calendar.current.date(byAdding: .day, value: self.updateIncrement, to: self.startUpdateAt)!
                self.getMoreItems(completion: { _ in })
            } else if items.isEmpty, self.updateIncrement < -365 { //reached max increment
                self.shouldShowHeader = false
                self.footerMessage = "that's the end!"
                self.emptyMessage = "Discover & add new channels to your feed"
                self.hasReachedEnd = true
            } else {
                var indexPaths = [IndexPath]()
                for (index, _) in items.enumerated() {
                    let newIndexPath = IndexPath(row: self.allItems.count + index, section: 1)
                    indexPaths.append(newIndexPath)
                }
                
                self.collectionView.performBatchUpdates({
                    self.collectionView?.insertItems(at: indexPaths)
                    self.allItems.append(contentsOf: items)
                    
                    if items.count < 4 {
                        self.getMoreItems(completion: { _ in })
                    } else {
                        self.updateIncrement = -7
                        completion(true)
                    }
                })
            }
        })
        
        startUpdateAt = endUpdateAt
        endUpdateAt = Calendar.current.date(byAdding: .day, value: updateIncrement, to: startUpdateAt)!
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
            collectionView?.register(ItemHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: footerReuseIdentifier)
            
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
                cell.setMessage(message: emptyMessage, color: .black)
                return cell
            }
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: sectionReuseIdentifier, for: indexPath) as! HeaderChannelsCell
            cell.channels = allChannels
            cell.delegate = self
            return cell
            
        case 1:
            //if near the end then get more items
            if indexPath.row == allItems.count - 3 {
                self.getMoreItems(completion: { _ in })
            }
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ItemCell
            let currentItem = allItems[indexPath.row]
            cell.itemType = currentItem.type
            cell.tag = indexPath.row
            cell.delegate = self
            
            //clear the cells and set the item type first
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: currentItem.cTitle, _createdAt: currentItem.createdAt, _image: self.allItems[indexPath.row].content as? UIImage ?? nil)
            cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)
            
            //Get the image if content type is a post
            if currentItem.content == nil, currentItem.shouldGetImage(), !currentItem.fetchedContent {
                PulseDatabase.getImage(channelID: currentItem.cID, itemID: currentItem.itemID, fileType: .thumb, maxImgSize: maxImgSize, completion: {[weak self] (data, error) in
                    guard let `self` = self else {
                        return
                    }
                    
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
                if let user = self.checkUserDownloaded(user: PulseUser(uID: currentItem.itemUserID)) {
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
                    PulseDatabase.getUser(currentItem.itemUserID, completion: {[weak self] (user, error) in
                        if let user = user, let `self` = self {
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
    
    internal func checkUserDownloaded(user: PulseUser) -> PulseUser? {
        if let index = allUsers.index(of: user) {
            return allUsers[index]
        }
        return nil
    }
    
    internal func updateUserImageDownloaded(user: PulseUser, thumbPicImage : UIImage?) {
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
            if indexPath.section == 0, allChannels.count > 0, let cell = collectionView.cellForItem(at: indexPath) as? HeaderChannelsCell {
                cell.channels = allChannels
                
            } else if indexPath.section == 0, allChannels.count > 0 {

                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: sectionReuseIdentifier, for: indexPath) as! HeaderChannelsCell
                cell.channels = allChannels
                
            } else if indexPath.section == 1, allItems.count > 0 {
                
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
        case UICollectionElementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: footerReuseIdentifier, for: indexPath) as! ItemHeader
            switch indexPath.section {
            case 1:
                footerView.backgroundColor = UIColor.white
                footerView.updateLabel(footerMessage)
            default:
                break
            }
            return footerView
        default: assert(false, "Unexpected element kind")
        }
        return UICollectionReusableView()
    }
}

extension HomeVC {
    
    /** Delegate Functions **/
    func userSelected(item : Any) {
        tabBarHidden = false

        if let item = item as? Item {
            switch item.type {
            case .answer:
                
                showItemDetail(allItems: [item], index: 0, itemCollection: [], selectedItem: item, watchedPreview: false)
                
            case .post, .perspective, .showcase:
                
                showItemDetail(allItems: [item], index: 0, itemCollection: [], selectedItem: item, watchedPreview: false)
                
            case .posts, .feedback:
                
                showTag(selectedItem: item)
                
            case .interview, .question, .thread:
                
                toggleLoading(show: true, message: "loading \(item.type.rawValue)...", showIcon: true)
                
                PulseDatabase.getItemCollection(item.itemID, completion: {[weak self] (success, items) in
                    guard let `self` = self else { return }
                    self.toggleLoading(show: false, message: nil)
                    success ? self.showItemDetail(allItems: items, index: 0, itemCollection: [], selectedItem: item, watchedPreview: false) : self.showNoItemsMenu(selectedItem : item)
                })
            
            case .session:
                
                PulseDatabase.getItemCollection(item.itemID, completion: {[weak self] (success, items) in
                    guard let `self` = self else { return }

                    if success, items.count > 1 {
                        //since ordering is cron based - move the first 'question' item to front
                        if let lastItem = items.last {
                            let sessionSlice = items.dropLast()
                            var sessionItems = Array(sessionSlice)
                            sessionItems.insert(lastItem, at: 0)
                            self.showItemDetail(allItems: sessionItems, index: 0, itemCollection: [], selectedItem: item, watchedPreview: false)
                        }
                    } else if success {
                        self.showItemDetail(allItems: [item], index: 0, itemCollection: [], selectedItem: item, watchedPreview: false)
                    } else {
                        //show no items menu
                        self.showNoItemsMenu(selectedItem : item)
                    }
                })
                
            default: break
            }
        } else if let user = item as? PulseUser {
            
            userSelectedUser(toUser: user)
            
        } else if let channel = item as? Channel {
            let channelVC = ChannelVC()
            channelVC.selectedChannel = channel
            
            navigationController?.pushViewController(channelVC, animated: true)
        }
    }
    
    //checks to make sure we are not in mini search case
    internal func userSelectedUser(toUser: PulseUser) {
        
        if let selectedShareItem = selectedShareItem {
            
            let selectedChannel = Channel(cID: selectedShareItem.cID, title: selectedShareItem.cTitle)
            self.createShareRequest(selectedShareItem: selectedShareItem, shareType: selectedShareItem.inviteType(), selectedChannel: selectedChannel, toUser: toUser, completion: {[weak self] _ , _ in
                guard let `self` = self else { return }

                self.selectedShareItem = nil
            })
            
        } else {
            
            //if not mini search then just go to the user profile
            let userProfileVC = UserProfileVC()
            navigationController?.pushViewController(userProfileVC, animated: true)
            userProfileVC.selectedUser = toUser
            
        }
    }
    
    //no items yet - so prompt user if accepts input and requires verifiecation
    internal func showNoItemsMenu(selectedItem : Item) {
        let menu = UIAlertController(title: "Sorry! No\(selectedItem.childType(plural: true)) yet", message: nil, preferredStyle: .actionSheet)
        
        selectedItem.checkVerifiedInput(completion: {[weak self] success, error in
            guard let `self` = self else { return }

            if success {
                menu.message = "No\(selectedItem.childType())s yet - want to be the first?"
                
                menu.addAction(UIAlertAction(title: "\(selectedItem.childActionType())\(selectedItem.childType().capitalized)", style: .default, handler: { (action: UIAlertAction!) in
                    self.addNewItem(selectedItem: selectedItem)
                }))
            } else {
                menu.message = "We are still waiting for \(selectedItem.childType())!"
            }
            
            menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                menu.dismiss(animated: true, completion: nil)
            }))
            
            DispatchQueue.main.async {
                self.present(menu, animated: true, completion: nil)
            }
        })
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
        
        contentVC.transitioningDelegate = self
        
        present(contentVC, animated: true, completion: nil)
    }
    
    internal func addNewItem(selectedItem: Item) {
        contentVC = ContentManagerVC()
        contentVC.selectedChannel = Channel(cID: selectedItem.cID)
        contentVC.selectedItem = selectedItem
        contentVC.openingScreen = .camera
        
        contentVC.transitioningDelegate = self
        
        present(contentVC, animated: true, completion: nil)
    }
    
    /** End Browse Content Delegate **/
    
    /** ParentTextItem - Delegate Function **/
    internal func dismiss(_ view : UIView) {
        tabBarHidden = false
        view.removeFromSuperview()
    }
    
    //close modal - e.g. mini search
    internal func userClosedModal(_ viewController: UIViewController) {
        tabBarHidden = false
        dismiss(animated: true, completion: { _ in })
    }
    
    //after email - user submitted the text
    internal func buttonClicked(_ text: String, sender: UIView) {
        tabBarHidden = false
        GlobalFunctions.validateEmail(text, completion: {(success, error) in
            if !success {
                self.showAddEmail(bodyText: "invalid email - try again")
            } else {
                if let selectedShareItem = selectedShareItem {
                    let selectedChannel = Channel(cID: selectedShareItem.cID, title: selectedShareItem.cTitle)
                    createShareRequest(selectedShareItem: selectedShareItem, shareType: selectedShareItem.inviteType(), selectedChannel: selectedChannel, toUser: nil, toEmail: text, completion: { _ , _ in
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
        let seriesVC = SeriesVC()
        
        navigationController?.pushViewController(seriesVC, animated: true)
        seriesVC.selectedItem = selectedItem
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
        
        currentItem.checkVerifiedInput(completion: {[weak self] success, error in
            guard let `self` = self else { return }

            if success {
                menu.addAction(UIAlertAction(title: "\(currentItem.childActionType())\(currentItem.childType().capitalized)", style: .default, handler: { (action: UIAlertAction!) in
                    self.addNewItem(selectedItem: currentItem)
                }))
                
                menu.addAction(UIAlertAction(title: "invite Contributors", style: .default, handler: { (action: UIAlertAction!) in
                    self.showInviteMenu(currentItem: currentItem)
                }))
            }
        })
        
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
    
    //NOT BEING USED >> PROB WANT TO PUT IN SEPARATE BUCKET TO BE APPROVED PRIOR TO POSTING
    internal func showNonContributorMenu(selectedItem : Item) {
        let menu = UIAlertController(title: "Become a Contributor?",
                                     message: "looks like you are not yet a verified contributor. To ensure quality, we recommend getting verified. You can continue with your submission (might be reviewed for quality).",
                                     preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "continue Submission", style: .default, handler: { (action: UIAlertAction!) in
            self.addNewItem(selectedItem: selectedItem)
        }))
        
        menu.addAction(UIAlertAction(title: "become a Contributor", style: .default, handler: { (action: UIAlertAction!) in
            let becomeContributorVC = BecomeContributorVC()
            becomeContributorVC.selectedChannel = Channel(cID: selectedItem.cID, title: selectedItem.cTitle)
            
            self.navigationController?.pushViewController(becomeContributorVC, animated: true)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    /** Menu Options **/
    internal func showInviteMenu(currentItem : Item) {
        tabBarHidden = true
        
        let menu = UIAlertController(title: "invite Contributors",
                                     message: "know someone who can add to the conversation? invite them to be a contributor!",
                                     preferredStyle: .actionSheet)
        
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
            self.toggleLoading(show: true, message: "loading invite options", showIcon: true)
            let selectedChannel = Channel(cID: currentItem.cID, title: currentItem.cTitle)
            self.createShareRequest(selectedShareItem: currentItem, shareType: currentItem.inviteType(), selectedChannel: selectedChannel, toUser: nil, showAlert: false, completion: {[weak self] selectedShareItem , error in
                guard let `self` = self else { return }

                if error == nil, let selectedShareItem = selectedShareItem {
                    let shareText = "Can you add \(currentItem.childActionType())\(currentItem.childType()) on '\(currentItem.itemTitle)'"
                    self.showShare(selectedItem: selectedShareItem, type: "invite", fullShareText: shareText)
                }
            })
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            self.tabBarHidden = false
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showAddEmail(bodyText: String) {
        addText = AddText(frame: view.bounds, buttonText: "Send",
                          bodyText: bodyText, keyboardType: .emailAddress, tabBarHeightAdjustment: tabBarController?.tabBar.frame.height ?? 0)
        
        addText.delegate = self
        view.addSubview(addText)
    }
}


extension HomeVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        switch section {
        case 1:
            return CGSize(width: collectionView.frame.width, height: skinnyHeaderHeight)
        default:
            return CGSize(width: collectionView.frame.width, height: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case 0:
            return CGSize(width: collectionView.frame.width, height: shouldShowHeader ? skinnyHeaderHeight : 0)
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
            return allItems.count > 0 ? CGSize(width: collectionView.frame.width, height: headerSectionHeight) : CGSize(width: collectionView.frame.width, height: headerSectionHeight)
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

extension HomeVC: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if presented is ContentManagerVC {
            let animator = ExpandAnimationController()
            animator.initialFrame = initialFrame
            animator.exitFrame = getRectToLeft()
            
            return animator
        } else {
            return nil
        }
    }
}
