//
//  UserProfileVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import Firebase

class UserProfileVC: PulseVC, UserProfileDelegate, ItemCellDelegate {
    
    public weak var modalDelegate : ModalDelegate!
    public var isModal = false
    
    fileprivate var observerAdded = false
    fileprivate var isCurrentUser = false
    private var cleanupComplete = false
    fileprivate lazy var menuButton : PulseButton = PulseButton(size: .small, type: .ellipsis, isRound : true, background: .white, tint: .black)
    
    /** Delegate Vars **/
    public var selectedUser : PulseUser! {
        didSet {
            guard !cleanupComplete else { return }
            
            if (selectedUser == nil || selectedUser.uID == nil) {
                allItems = []
                headerNav?.setNav(title: "Profile")
                updateDataSource()
            } else if PulseUser.isLoggedIn(), selectedUser.uID == PulseUser.currentUser.uID! {
                //For current user - if is modal - transfer values from current user
                guard !isModal else {
                    updateUserInfo()
                    allItems = PulseUser.currentUser.items
                    updateDataSource()
                    return
                }
                
                if  oldValue != nil {
                    guard selectedUser.uID != oldValue.uID else { return }
                }
                addObservers()

                PulseDatabase.getUserItems(uID: PulseUser.currentUser.uID!, completion: {[weak self] items in
                    guard let `self` = self else { return }
                    self.allItems = items
                    self.updateDataSource()
                })
                isCurrentUser = true
            } else if selectedUser != nil, !selectedUser.uCreated {
                PulseDatabase.getUser(selectedUser.uID!, completion: {[weak self] (user, error) in
                    guard let `self` = self else { return }
                    
                    if error == nil {
                        self.selectedUser = user
                        self.updateHeader()
                        self.headerNav?.setNav(title: user?.name ?? "User Profile")
                    }
                })
            } else if selectedUser != nil, !selectedUser.uDetailedCreated {
                getDetailUserProfile()
            } else if selectedUser != nil {
                allItems = selectedUser.items
                updateDataSource()
            }
        }
    }
    /** End Delegate Vars **/
    
    /** Data Source Vars **/
    public var allItems = [Item]()
    fileprivate var selectedUserPic : UIImage?
    /** End Data Source Vars **/
    
    fileprivate var isLayoutSetup = false
    
    /** Collection View Vars **/
    internal var collectionView : UICollectionView!
    fileprivate let headerHeight : CGFloat = 220
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLayoutSetup {
            toggleLoading(show: true, message: "loading profile...", showIcon: true)
            
            updateHeader()
            setupLayout()
            updateDataSource()
            isLayoutSetup = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)        
        updateHeader()

        guard selectedUser != nil else {
            headerNav?.setNav(title: "Profile")
            return
        }
        headerNav?.setNav(title: selectedUser.name)
    }
    
    deinit {
        performCleanup()
    }
    
    internal func performCleanup() {
        if !cleanupComplete {
            cleanupComplete = true
            selectedUser = nil
            collectionView = nil
            allItems.removeAll()
            modalDelegate = nil
            
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UserSummaryUpdated"), object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UserDetailsUpdated"), object: nil)
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    internal func userUpdated() {
        if PulseUser.isLoggedIn() {
            selectedUser = PulseUser.currentUser
            updateUserInfo()
            headerNav?.setNav(title: PulseUser.currentUser.name ?? "Your Profile")
        } else {
            headerNav?.setNav(title: "Profile")
        }
    }
    
    internal func userDetailsUpdated() {
        if PulseUser.isLoggedIn() {
            selectedUser = PulseUser.currentUser
        }
    }
    
    internal func addObservers() {
        if !observerAdded {
            NotificationCenter.default.addObserver(self, selector: #selector(userUpdated), name: NSNotification.Name(rawValue: "UserSummaryUpdated"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(userDetailsUpdated), name: NSNotification.Name(rawValue: "UserDetailsUpdated"), object: nil)
            observerAdded = true
        }
    }
    
    fileprivate func setupLayout() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        let _ = PulseFlowLayout.configureLayout(collectionView: collectionView, minimumLineSpacing: 10, itemSpacing: 10, stickyHeader: false)
        
        collectionView?.register(EmptyCell.self, forCellWithReuseIdentifier: emptyReuseIdentifier)
        collectionView?.register(ItemCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView?.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        
        view.addSubview(collectionView)
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        
        headerNav?.updateBackgroundImage(image: nil)
        
        if isCurrentUser && isRootController() {
            tabBarHidden = false
        } else {
            tabBarHidden = true

            if navigationController != nil {
                isModal = false
                addBackButton()
                
                menuButton.removeShadow()
                
                menuButton.addTarget(self, action: #selector(showMenu), for: .touchUpInside)
                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: menuButton)
                
            } else {
                
                isModal = true
                statusBarHidden = true
                setupClose()
                closeButton.addTarget(self, action: #selector(closeModal), for: UIControlEvents.touchUpInside)
                
            }
        }
        
        if !tabBarHidden, collectionView != nil {
            collectionView.contentInset = UIEdgeInsetsMake(0, 0, tabBarController!.tabBar.frame.height + Spacing.m.rawValue, 0)
        }
    }
    
    //Setup close button
    internal func setupClose() {
        addScreenButton(button: closeButton)
        closeButton.addTarget(self, action: #selector(closeModal), for: UIControlEvents.touchUpInside)
    }
    
    //If we want to go to a right menu button - currently using button in header
    internal func addMenuButton() {
        let menuButton = PulseButton(size: .small, type: .ellipsis, isRound: true, hasBackground: false, tint: .black)
        menuButton.removeShadow()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: menuButton)
        menuButton.addTarget(self, action: #selector(showMenu), for: .touchUpInside)
    }
    
    internal func closeModal() {
        if modalDelegate != nil {
            modalDelegate.userClosedModal(self)
        }
    }
    
    internal func getDetailUserProfile() {
        guard let selectedUser = selectedUser else { return }
        
        PulseDatabase.getDetailedUserProfile(user: selectedUser, completion: {[weak self] updatedUser in
            guard let `self` = self else { return }
            self.selectedUser = updatedUser
        })
    }
    
    internal func updateUserInfo() {
        if let collectionView = collectionView {
            for view in collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionHeader) {
                if let view = view as? UserProfileHeader {
                    view.updateUserDetails(selectedUser: selectedUser, isModal: isModal)
                    
                    if selectedUser.uID! == PulseUser.currentUser.uID {
                        PulseDatabase.getCachedCurrentUserPic(completion: { image in
                            DispatchQueue.main.async {
                                view.updateUserImage(image: image)
                                view.setNeedsDisplay()
                            }
                        })
                    } else {
                        PulseDatabase.getCachedUserPic(uid: selectedUser.uID!, completion: { image in
                            DispatchQueue.main.async {
                                view.updateUserImage(image: image)
                                view.setNeedsDisplay()
                            }
                        })
                    }
                }
            }
        }
    }
    
    //once allItems var is set reload the data
    func updateDataSource() {
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.reloadData()
        collectionView?.collectionViewLayout.invalidateLayout()
        
        toggleLoading(show: false, message: nil)
    }
    
    /** Show Menu **/
    func showMenu() {
        isCurrentUser ? showCurrentUserMenu() : showUserMenu()
    }
    
    func editProfile() {
        navigationController?.pushViewController(SettingsTableVC(), animated: true)
    }
    
    func showUserMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "send Message", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.sendMessage()
        }))
        
        menu.addAction(UIAlertAction(title: "share Profile", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.shareProfile()
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showCurrentUserMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if isRootController() {
            menu.addAction(UIAlertAction(title: "edit Profile", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                guard let `self` = self else { return }
                menu.dismiss(animated: true, completion: nil)
                self.navigationController?.pushViewController(SettingsTableVC(), animated: true)
            }))
            
            menu.addAction(UIAlertAction(title: "get Support", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                guard let `self` = self else { return }
                menu.dismiss(animated: true, completion: nil)
                let messageVC = MessageVC()
                messageVC.toUser = PULSE_SUPPORT_USER
                DispatchQueue.main.async {
                    self.navigationController?.pushViewController(messageVC, animated: true)
                }
            }))
            
            menu.addAction(UIAlertAction(title: "logout", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
                guard let `self` = self else { return }
                menu.dismiss(animated: true, completion: nil)
                self.clickedLogout()
            }))
        } else {
            menu.addAction(UIAlertAction(title: "share Profile", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                guard let `self` = self else { return }
                self.shareProfile()
            }))
        }
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    //shows the user profile
    internal func clickedUserButton(itemRow : Int) {
        //ignore as we are already in user profile
    }
    
    //menu for each individual item
    internal func clickedMenuButton(itemRow: Int) {
        let currentItem = allItems[itemRow]
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "share \(currentItem.type.rawValue.capitalized)", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.showShare(selectedItem: currentItem, type: currentItem.type.rawValue)
        }))
        
        menu.addAction(UIAlertAction(title: "report This", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            
            menu.dismiss(animated: true, completion: nil)
            self.reportContent(item: currentItem)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func clickedLogout() {
        let confirmLogout = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .actionSheet)
        
        confirmLogout.addAction(UIAlertAction(title: "logout", style: .destructive, handler: {(action: UIAlertAction!) in
            PulseDatabase.signOut({[weak self] success in
                guard let `self` = self else { return }
                if !success {
                    GlobalFunctions.showAlertBlock("Error Logging Out", erMessage: "Sorry there was an error logging out, please try again!")
                } else {
                    self.selectedUser = nil
                }
            })
        }))
        
        confirmLogout.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            confirmLogout.dismiss(animated: true, completion: nil)
        }))
        
        present(confirmLogout, animated: true, completion: nil)
    }
    
    override func userSelected(item : Any) {
        
        if let item = item as? Item {
            
            item.user = selectedUser
            
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [AnalyticsParameterContentType: item.type.rawValue as NSObject,
                                                                         AnalyticsParameterItemID: "\(item.itemID)" as NSObject])
            
            switch item.type {
            case .answer:
                
                showItemDetail(allItems: [item], index: 0, itemCollection: [], selectedItem: item)
                
            case .post, .perspective, .showcase:
                
                showItemDetail(allItems: [item], index: 0, itemCollection: [], selectedItem: item)
                
            case .interview:
                
                //showing chron (earliest first) vs. question / thread where show newest first
                toggleLoading(show: true, message: "loading \(item.type.rawValue)...", showIcon: true)
                
                PulseDatabase.getItemCollection(item.itemID, completion: {[weak self] (success, items) in
                    guard let `self` = self else { return }
                    self.toggleLoading(show: false, message: nil)
                    success ?
                        self.showItemDetail(allItems: items.reversed(), index: 0, itemCollection: [], selectedItem: item) :
                        GlobalFunctions.showAlertBlock("Error Fetching Interview", erMessage: "Sorry there was an error - please try another item")
                })
                
            case .question, .thread:
                
                toggleLoading(show: true, message: "loading \(item.type.rawValue)...", showIcon: true)
                
                PulseDatabase.getItemCollection(item.itemID, completion: {[weak self] (success, items) in
                    guard let `self` = self else { return }
                    self.toggleLoading(show: false, message: nil)
                    success ?
                        self.showItemDetail(allItems: items, index: 0, itemCollection: [], selectedItem: item) :
                        GlobalFunctions.showAlertBlock("Error Fetching Interview", erMessage: "Sorry there was an error - please try another item")
                })
                
            case .session:
                
                toggleLoading(show: true, message: "loading \(item.type.rawValue)...", showIcon: true)
                
                PulseDatabase.getItemCollection(item.itemID, completion: {[weak self] (success, items) in
                    guard let `self` = self else { return }
                    
                    self.toggleLoading(show: false, message: nil)
                    
                    if success, items.count > 1 {
                        //since ordering is cron based - move the first 'question' item to front
                        if let lastItem = items.last {
                            let sessionSlice = items.dropLast()
                            var sessionItems = Array(sessionSlice)
                            sessionItems.insert(lastItem, at: 0)
                            self.showItemDetail(allItems: sessionItems, index: 0, itemCollection: [], selectedItem: item)
                        }
                    } else if success {
                        self.showItemDetail(allItems: [item], index: 0, itemCollection: [], selectedItem: item)
                    } else {
                        //show no items menu
                        GlobalFunctions.showAlertBlock("Error Fetching Interview", erMessage: "Sorry there was an error - please try another item")
                    }
                })
                
            case .collection:
                
                let browseCollectionVC = BrowseCollectionVC()
                browseCollectionVC.selectedChannel = Channel(cID: item.cID, title: item.cTitle)
                
                navigationController?.pushViewController(browseCollectionVC, animated: true)
                browseCollectionVC.selectedItem = item
                
            default: break
            }
        }
    }
    /** End Delegate Functions **/
    
    /** Start Delegate Functions **/
    internal func shareProfile() {
        self.toggleLoading(show: true, message: "loading share options...", showIcon: true)

        selectedUser.createShareLink(completion: {[unowned self] link in
            guard let link = link else { return }
            self.shareContent(shareType: "user", shareText: self.selectedUser.name ?? "", shareLink: link)
        })
    }
    
    internal func sendMessage() {
        let messageVC = MessageVC()
        messageVC.toUser = selectedUser
        
        navigationController?.pushViewController(messageVC, animated: true)
    }
    /** End Delegate Functions **/
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateCurrentCell(_ cell: ItemCell, atIndexPath indexPath: IndexPath) {
        if allItems[indexPath.row].itemCreated  {
            cell.updateLabel(getTitleForItem(item: allItems[indexPath.row]), _subtitle: selectedUser.name, _createdAt: allItems[indexPath.row].createdAt, _tag: nil)
        }
        
        if let image = allItems[indexPath.row].content  {
            cell.updateImage(image: image)
        }
    }
    
    func updateOnscreenRows() {
        if let visiblePaths = collectionView?.indexPathsForVisibleItems {
            for indexPath in visiblePaths {
                let cell = collectionView?.cellForItem(at: indexPath) as! ItemCell
                updateCurrentCell(cell, atIndexPath: indexPath)
            }
        }
    }
}

extension UserProfileVC : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allItems.count == 0 ? 1 : allItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard allItems.count > 0 else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emptyReuseIdentifier, for: indexPath) as! EmptyCell
            cell.setMessage(message: "nothing to see yet!", color: .black)
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ItemCell
        cell.delegate = self
        cell.tag = indexPath.row
        
        let currentItem = allItems[indexPath.row]
        
        //clear the cells and set the item type first
        cell.updateLabel(nil, _subtitle: selectedUser.name, _createdAt: currentItem.createdAt, _tag: nil)
        
        if let selectedUserImage = selectedUserPic {
            cell.updateButtonImage(image: selectedUserImage, itemTag : indexPath.row)
        } else {
            PulseDatabase.getCachedUserPic(uid: selectedUser.uID!, completion: { image in
                DispatchQueue.main.async {
                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                        cell.updateButtonImage(image: image, itemTag : indexPath.row)
                        self.selectedUserPic = image
                    }
                }
            })
        }
        
        //Already fetched this item
        if allItems[indexPath.row].itemCreated {
            
            cell.itemType = currentItem.type
            cell.updateCell(getTitleForItem(item: allItems[indexPath.row]), _subtitle: selectedUser.name, _tag: nil, _createdAt: currentItem.createdAt, _image: allItems[indexPath.row].content ?? nil)
            
        } else {
            PulseDatabase.getItem(allItems[indexPath.row].itemID, completion: {[weak self] (item, error) in
                guard let `self` = self else { return }
                
                if let item = item {
                    cell.itemType = item.type
                    
                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                        DispatchQueue.main.async {
                            
                            cell.itemType = item.type
                            cell.updateLabel(self.getTitleForItem(item: item), _subtitle: self.selectedUser.name,  _createdAt: item.createdAt, _tag: nil)
                        }
                    }
                    
                    self.allItems[indexPath.row] = item
                    
                    //Get the image if content type is a post or perspectives thread
                    if item.content == nil, item.shouldGetImage(), !item.fetchedContent, let imageID = self.filePathForImage(item: item) {
                        PulseDatabase.getImage(channelID: item.cID, itemID: imageID, fileType: .content, maxImgSize: MAX_IMAGE_FILESIZE, completion: {[weak self] (data, error) in
                            guard let `self` = self else { return }
                            if let data = data {
                                self.allItems[indexPath.row].content = UIImage(data: data)
                                
                                DispatchQueue.main.async {
                                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                        cell.updateImage(image : self.allItems[indexPath.row].content)
                                    }
                                }
                            }
                            
                            self.allItems[indexPath.row].fetchedContent = true
                        })
                    }
                }
            })
        }
        
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateOnscreenRows()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { updateOnscreenRows() }
    }
    
    //Did select item at index path
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if allItems.count > 0, indexPath.row < allItems.count {
            userSelected(item: allItems[indexPath.row])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! UserProfileHeader
            headerView.isModal = isModal
            headerView.backgroundColor = .white
            headerView.updateUserDetails(selectedUser: selectedUser, isModal : isModal)
            headerView.profileDelegate = self
            
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
        return UICollectionReusableView()
    }
    
    //Individual items like perspective / collection are saved so need to get the parent itemID to grab the image
    func filePathForImage(item: Item) -> String? {
        switch item.type {
        case .collection, .perspective, .feedback:
            return item.tag?.itemID
        default:
            return item.itemID
        }
    }
    
    //Individual items like perspective / collection are saved so need to get the parent itemID to grab the title
    func getTitleForItem(item: Item) -> String {
        switch item.type {
        case .collection, .perspective, .feedback:
            let _title = item.tag?.itemTitle != nil ? "\(item.tag!.itemTitle)" : item.itemTitle
            return _title
        default:
            let _title = item.itemDescription != "" ? "\(item.itemTitle) - \(item.itemDescription)" : item.itemTitle
            return _title
        }
    }
}

extension UserProfileVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: allItems.count > 0 ? (tabBarController?.tabBar.frame.height ?? 0) + Spacing.xs.rawValue : 0, right: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if allItems.count == 0 {
            return CGSize(width: view.frame.width, height: view.frame.height - headerHeight)
        }
        
        let cellHeight = GlobalFunctions.getCellHeight(type: allItems[indexPath.row].type)
        return CGSize(width: collectionView.frame.width, height: allItems.count > 0 ? cellHeight : 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: headerHeight)
    }
    
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
