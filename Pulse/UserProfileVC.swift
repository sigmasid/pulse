//
//  UserProfileVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class UserProfileVC: PulseVC, UserProfileDelegate, PreviewDelegate, ModalDelegate {
    
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
                //For current user
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
    public var watchedFullPreview: Bool = false     //Delegate PreviewVC var - if user watches full preview then go to index 1 vs. index 0 in full screen
    /** End Delegate Vars **/
    
    /** Data Source Vars **/
    public var allItems = [Item]() {
        didSet {
            itemStack.removeAll()
            itemStack = [ItemMetaData](repeating: ItemMetaData(), count: allItems.count)
        }
    }
    
    struct ItemMetaData {
        var itemCollection = [Item]()
        
        var gettingImageForPreview : Bool = false
        var gettingInfoForPreview : Bool = false
    }
    internal var itemStack = [ItemMetaData]()
    /** End Data Source Vars **/
    
    fileprivate var isLayoutSetup = false
    
    /** Collection View Vars **/
    internal var collectionView : UICollectionView!
    fileprivate let minCellHeight : CGFloat = 225
    fileprivate let headerHeight : CGFloat = 220
    
    fileprivate var selectedIndex : IndexPath? {
        didSet {
            if selectedIndex != nil {
                collectionView?.reloadItems(at: [selectedIndex!])
                if deselectedIndex != nil && deselectedIndex != selectedIndex {
                    collectionView?.reloadItems(at: [deselectedIndex!])
                }
            }
        }
        willSet {
            if selectedIndex != nil {
                deselectedIndex = selectedIndex
            }
            
            if newValue == nil, let selectedIndex = selectedIndex {
                let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: selectedIndex) as! BrowseContentCell
                cell.removePreview()
            }
        }
    }
    fileprivate var deselectedIndex : IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLayoutSetup {
            toggleLoading(show: true, message: "Loading Profile...", showIcon: true)

            updateHeader()
            setupLayout()
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
            itemStack.removeAll()
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
        print("user updated fired")
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
        
        collectionView?.register(EmptyCell.self,
                                 forCellWithReuseIdentifier: emptyReuseIdentifier)
        collectionView?.register(BrowseContentCell.self,
                                 forCellWithReuseIdentifier: reuseIdentifier)
        collectionView?.register(UserProfileHeader.self,
                                 forSupplementaryViewOfKind: UICollectionElementKindSectionHeader ,
                                 withReuseIdentifier: headerReuseIdentifier)
        
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
        PulseDatabase.getDetailedUserProfile(user: selectedUser, completion: {[weak self] updatedUser in
            guard let `self` = self else { return }
            let userImage = self.selectedUser.thumbPicImage
            
            self.selectedUser = updatedUser
            self.selectedUser.thumbPicImage = userImage
        })
    }
    
    internal func updateUserInfo() {
        if let collectionView = collectionView {
            for view in collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionHeader) {
                if let view = view as? UserProfileHeader {
                    view.updateUserDetails(selectedUser: selectedUser, isModal: isModal)

                    selectedUser.getUserImage(completion: { [weak self] profileImage in
                        guard let `self` = self else { return }
                        self.selectedUser.thumbPicImage = profileImage
                        view.updateUserImage(image: self.selectedUser.thumbPicImage)
                        view.setNeedsDisplay()
                    })
                }
            }
        }
    }
    
    //once allItems var is set reload the data
    func updateDataSource() {
        if !isLayoutSetup  {
            setupLayout()
        }
        
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
    
    /** Start Delegate Functions **/
    internal func askQuestion() {
        let questionVC = AskQuestionVC()
        questionVC.selectedUser = selectedUser
        questionVC.modalDelegate = self
        navigationController?.pushViewController(questionVC, animated: true)
    }
    
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
        
        if let selectedUserImage = selectedUser.thumbPicImage {
            messageVC.toUserImage = selectedUserImage
        }
        
        navigationController?.pushViewController(messageVC, animated: true)
    }
    /** End Delegate Functions **/
    
    internal func showItemDetail(selectedItem : Item?, allItems: [Item]) {
        contentVC = ContentManagerVC()
        
        if let selectedItem = selectedItem {
            contentVC.selectedItem = selectedItem
            contentVC.allItems = allItems
            contentVC.selectedChannel = Channel(cID: selectedItem.cID)
        } else {
            contentVC.allItems = allItems
            contentVC.selectedChannel = Channel(cID: allItems.first!.cID)
        }
        
        contentVC.openingScreen = .item
        
        contentVC.transitioningDelegate = self
        present(contentVC, animated: true, completion: nil)
    }
    
    internal func showItemDetail(selectedItem : Item) {
        //need to be set first
        showItemDetail(selectedItem: nil, allItems: [selectedItem])
    }
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateCurrentCell(_ cell: BrowseContentCell, atIndexPath indexPath: IndexPath) {
        if allItems[indexPath.row].itemCreated  {
            cell.updateLabel(nil, _subtitle: allItems[indexPath.row].itemTitle)
        }
        
        if let image = allItems[indexPath.row].content  {
            cell.updateImage(image: image)
        }
    }
    
    func updateOnscreenRows() {
        if let visiblePaths = collectionView?.indexPathsForVisibleItems {
            for indexPath in visiblePaths {
                let cell = collectionView?.cellForItem(at: indexPath) as! BrowseContentCell
                updateCurrentCell(cell, atIndexPath: indexPath)
            }
        }
    }
    
    //Delegate Function - Used for Mini Search, Ask Question
    internal func userClosedModal(_ viewController: UIViewController) {
        dismiss(animated: true, completion: { _ in })
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
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BrowseContentCell
        
        cell.contentView.backgroundColor = .white
        cell.setNumberOfLines(titleNum: 0, subTitleNum: 2)
        
        let currentItem = allItems[indexPath.row]
        
        /* GET PREVIEW IMAGE FROM STORAGE */
        if currentItem.content != nil && !itemStack[indexPath.row].gettingImageForPreview {
            
            cell.updateImage(image: currentItem.content)
            
        } else if itemStack[indexPath.row].gettingImageForPreview {
            
            //ignore if already fetching the image, so don't refetch if already getting
            
        } else if currentItem.itemCreated {
            itemStack[indexPath.row].gettingImageForPreview = true
            
            PulseDatabase.getImage(channelID: currentItem.cID, itemID: currentItem.itemID, fileType: .thumb, maxImgSize: MAX_IMAGE_FILESIZE, completion: {[weak self] (_data, error) in
                guard let `self` = self else { return }
                if error == nil {
                    let _previewImage = GlobalFunctions.createImageFromData(_data!)
                    self.allItems[indexPath.row].content = _previewImage
                    
                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                        DispatchQueue.main.async {
                            cell.updateImage(image: self.allItems[indexPath.row].content)
                        }
                    }
                } else {
                    cell.updateImage(image: nil)
                }
            })
        }
        
        if currentItem.itemCreated, itemStack[indexPath.row].gettingInfoForPreview {
            
            cell.updateLabel(nil, _subtitle: currentItem.itemTitle)
            
        } else if itemStack[indexPath.row].gettingInfoForPreview {
            
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            cell.updateLabel(nil, _subtitle: nil, _image : nil)

            itemStack[indexPath.row].gettingInfoForPreview = true
            
            // Get the user details
            PulseDatabase.getItem(currentItem.itemID, completion: {[weak self] (item, error) in
                guard let `self` = self else { return }
                if let item = item, indexPath.row < self.allItems.count {
                    let tempImage = self.allItems[indexPath.row].content
                    self.allItems[indexPath.row] = item
                    self.allItems[indexPath.row].content = tempImage
                    
                    DispatchQueue.main.async {
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            cell.updateLabel(nil, _subtitle: self.allItems[indexPath.row].itemTitle)
                        }
                    }

                    PulseDatabase.getImage(channelID: item.cID, itemID: item.itemID, fileType: .thumb, maxImgSize: MAX_IMAGE_FILESIZE, completion: {[weak self] (_data, error) in
                        guard let `self` = self else { return }
                        if error == nil, indexPath.row < self.allItems.count {
                            let _previewImage = GlobalFunctions.createImageFromData(_data!)
                            self.allItems[indexPath.row].content = _previewImage
                            
                            if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                DispatchQueue.main.async {
                                    cell.updateImage(image: self.allItems[indexPath.row].content)
                                }
                            }
                        } else {
                            cell.updateImage(image: self.allItems[indexPath.row].defaultImage())
                        }
                    })
                }
            })
        }
        
        if indexPath == selectedIndex && indexPath == deselectedIndex {
            
            showItemDetail(selectedItem: currentItem)
            
        } else if indexPath == selectedIndex {
            
            //if interview just go directly to full screen
            if currentItem.type != .interview {
                PulseDatabase.getItemCollection(currentItem.itemID, completion: {[weak self] (hasDetail, itemCollection) in
                    guard let `self` = self else { return }
                    if hasDetail {
                        cell.showTapForMore = true
                        self.itemStack[indexPath.row].itemCollection = itemCollection
                    } else {
                        cell.showTapForMore = false
                    }
                })
                
                cell.delegate = self
                cell.showItemPreview(item: currentItem)
            } else {
                toggleLoading(show: true, message: "Loading Interview...")
                PulseDatabase.getItemCollection(currentItem.itemID, completion: {[weak self] (hasDetail, itemCollection) in
                    guard let `self` = self else { return }
                    self.toggleLoading(show: false, message: nil)
                    self.showItemDetail(selectedItem : currentItem, allItems: itemCollection)
                    self.selectedIndex = nil
                    self.deselectedIndex = nil

                })
            }
            
        } else if indexPath == deselectedIndex {
            cell.removePreview()
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
        if allItems.count > 0, let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
            let cellRect = attributes.frame
            initialFrame = collectionView.convert(cellRect, to: collectionView.superview)
            
            selectedIndex = indexPath
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
}

extension UserProfileVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if allItems.count == 0 {
            return CGSize(width: view.frame.width, height: view.frame.height - headerHeight)
        }
        return CGSize(width: (view.frame.width - 30) / 2, height: minCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: headerHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if allItems.count == 0 {
            return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0, right: 0.0)
        }
        return UIEdgeInsets(top: 10.0, left: 10.0, bottom: (tabBarController?.tabBar.frame.height ?? 0) + Spacing.xs.rawValue, right: 10.0)
    }
}
