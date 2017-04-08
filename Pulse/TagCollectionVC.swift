//
//  TagQABrowserVCViewController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/19/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class TagCollectionVC: PulseVC, HeaderDelegate, ItemCellDelegate, ModalDelegate, BrowseContentDelegate, SelectionDelegate, ParentTextViewDelegate {
    
    public var selectedChannel: Channel!
    
    //set by delegate - is of type questions / posts / perspectives etc. since its a series
    public var selectedItem : Item! {
        didSet {
            toggleLoading(show: true, message: "Loading Series...", showIcon: true)
            Database.getItemCollection(selectedItem.itemID, completion: {(success, items) in
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
    fileprivate var allUsers = [User]() //caches user image / user for reuse
    fileprivate var hasReachedEnd = false
    
    /** Collection View Vars **/
    internal var collectionView : UICollectionView!
    
    fileprivate var isLayoutSetup = false
    
    fileprivate var selectedShareItem : Item?
    fileprivate var addEmail : AddText!

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
        updateHeader()
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        addBackButton()
        headerNav?.followScrollView(collectionView, delay: 25.0)
        headerNav?.setNav(title: selectedChannel.cTitle ?? selectedItem.itemTitle)
        headerNav?.updateBackgroundImage(image: GlobalFunctions.processImage(selectedChannel.cPreviewImage))
    }
    
    func setupLayout() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        let _ = PulseFlowLayout.configureLayout(collectionView: collectionView, minimumLineSpacing: 10, itemSpacing: 10, stickyHeader: true)
        
        collectionView.register(ItemHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        collectionView.register(ItemCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        view.addSubview(collectionView)
    }
    
    func userClosedModal(_ viewController: UIViewController) {
        dismiss(animated: true, completion: { _ in })
    }
    
    internal func askQuestion() {
        let questionVC = AskQuestionVC()
        questionVC.selectedTag = selectedItem
        questionVC.delegate = self
        
        GlobalFunctions.addNewVC(questionVC, parentVC: self)
    }
    
    internal func addInterview() {
        let interviewVC = NewInterviewVC()
        interviewVC.selectedItem = selectedItem
        interviewVC.selectedChannel = selectedChannel
        navigationController?.pushViewController(interviewVC, animated: true)
    }
    
    internal func startThread() {
        let newThread = NewThreadVC()
        newThread.selectedChannel = selectedChannel
        newThread.selectedItem = selectedItem
        navigationController?.pushViewController(newThread, animated: true)
    }
    
    internal func addNewItem(selectedItem: Item) {
        contentVC = ContentManagerVC()
        contentVC.selectedChannel = selectedChannel
        contentVC.selectedItem = selectedItem
        contentVC.openingScreen = .camera
        
        contentVC.transitioningDelegate = self
        present(contentVC, animated: true, completion: nil)
    }

    //once allItems var is set reload the data
    internal func updateDataSource() {
        if !isLayoutSetup {
            setupLayout()
        }
        
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.reloadData()
        collectionView?.layoutIfNeeded()
    }
    
    //get more items if scrolled to end
    internal func getMoreItems() {
        
        if let lastItemID = allItems.last?.itemID, !hasReachedEnd {

            Database.getItemCollection(selectedItem.itemID, lastItem: lastItemID, completion: { success, items in
                if items.count > 0 {
                    
                    var indexPaths = [IndexPath]()
                    for (index, _) in items.enumerated() {
                        let newIndexPath = IndexPath(row: self.allItems.count + index - 1, section: 0)
                        indexPaths.append(newIndexPath)
                    }
                    self.allItems.append(contentsOf: items)
                    self.collectionView?.insertItems(at: indexPaths)
                } else {
                    self.hasReachedEnd = true
                }
            })
        }
    }
    
    internal func showAddEmail(bodyText: String) {
        addEmail = AddText(frame: view.bounds, buttonText: "Send",
                           bodyText: bodyText, keyboardType: .emailAddress)
        
        addEmail.delegate = self
        view.addSubview(addEmail)
    }
}

extension TagCollectionVC : UICollectionViewDelegate, UICollectionViewDataSource {
    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
            let cellRect = attributes.frame
            initialFrame = collectionView.convert(cellRect, to: collectionView.superview)
        }
        
        userSelected(item : allItems[indexPath.row], index: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        //if near the end then get more items
        if indexPath.row == allItems.count - 1 {
            getMoreItems()
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ItemCell
        cell.delegate = self
        cell.tag = indexPath.row
        
        let currentItem = allItems[indexPath.row]

        //clear the cells and set the item type first
        cell.updateLabel(currentItem.itemTitle != "" ? currentItem.itemTitle : "",
                         _subtitle: currentItem.user?.name, _createdAt: currentItem.createdAt, _tag: nil)
        cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)

        //Already fetched this item
        if allItems[indexPath.row].itemCreated {
            cell.itemType = currentItem.type
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: nil, _createdAt: currentItem.createdAt, _image: self.allItems[indexPath.row].content as? UIImage ?? nil)
            cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)
            
        } else {
            Database.getItem(allItems[indexPath.row].itemID, completion: { (item, error) in
                if let item = item {
                    
                    cell.itemType = item.type

                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                        DispatchQueue.main.async {
                            cell.itemType = item.type
                            cell.updateLabel(item.itemTitle, _subtitle: self.allItems[indexPath.row].user?.name ?? nil,  _createdAt: item.createdAt, _tag: nil)
                        }
                    }
                    
                    item.tag = self.allItems[indexPath.row].tag
                    self.allItems[indexPath.row] = item
                    
                    //Get the image if content type is a post or perspectives thread
                    if item.content == nil, item.type == .post || item.type == .thread, !item.fetchedContent {
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
                    
                    // Get the user details
                    if let user = self.checkUserDownloaded(user: User(uID: item.itemUserID)) {
                        self.allItems[indexPath.row].user = user
                        cell.updateLabel(currentItem.itemTitle, _subtitle: user.name, _createdAt: currentItem.createdAt, _tag: nil)
                        
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
                        Database.getUser(item.itemUserID, completion: {(user, error) in
                            if let user = user {
                                self.allItems[indexPath.row].user = user
                                self.allUsers.append(user)
                                
                                DispatchQueue.main.async {
                                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                        cell.updateLabel(item.itemTitle, _subtitle: user.name,  _createdAt: item.createdAt, _tag: nil)
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
            })
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! ItemHeader
            headerView.backgroundColor = .white
            headerView.delegate = self
            headerView.updateLabel("# \(selectedItem.itemTitle.lowercased())")
            
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
    }
    
    //Find the index of downloaded user and return that user
    func checkUserDownloaded(user: User) -> User? {
        if let index = allUsers.index(of: user) {
            return allUsers[index]
        }
        return nil
    }
    
    //Add user downloaded image for a newly downloaded user
    func updateUserImageDownloaded(user: User, thumbPicImage : UIImage?) {
        if let image = thumbPicImage , let index = allUsers.index(of: user) {
            allUsers[index].thumbPicImage = image
        }
    }
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateCell(_ cell: ItemCell, atIndexPath indexPath: IndexPath) {
        
        if let image = allItems[indexPath.row].user?.thumbPicImage  {
            cell.updateButtonImage(image: image, itemTag : indexPath.row)
        }
        
        if allItems[indexPath.row].itemCreated {
            let currentItem = allItems[indexPath.row]
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: nil, _createdAt: currentItem.createdAt, _image: allItems[indexPath.row].content as? UIImage ?? nil)
        }
    }
    
    func updateOnscreenRows() {
        if let visiblePaths = collectionView?.indexPathsForVisibleItems {
            for indexPath in visiblePaths {
                let cell = collectionView?.cellForItem(at: indexPath) as! ItemCell
                updateCell(cell, atIndexPath: indexPath)
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

extension TagCollectionVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: skinnyHeaderHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: Spacing.xs.rawValue, right: 0.0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellHeight = GlobalFunctions.getCellHeight(type: allItems[indexPath.row].type)

        return CGSize(width: collectionView.frame.width, height: cellHeight)
    }
}

//menus
extension TagCollectionVC {
    
    //parent text view delegate
    internal func dismiss(_ view : UIView) {
        view.removeFromSuperview()
    }
    
    internal func buttonClicked(_ text: String, sender: UIView) {
        GlobalFunctions.validateEmail(text, completion: {(success, error) in
            if !success {
                self.showAddEmail(bodyText: "invalid email - try again")
            } else {
                if let selectedShareItem = selectedShareItem {
                    let itemKey = databaseRef.child("items").childByAutoId().key
                    let parentItemID = selectedShareItem.itemID
                    
                    selectedShareItem.itemID = itemKey
                    selectedShareItem.cID = selectedChannel.cID
                    selectedShareItem.cTitle = selectedChannel.cTitle
                    selectedShareItem.tag = selectedItem
                    
                    toggleLoading(show: true, message: "sending invite...", showIcon: true)
                    let type : MessageType = selectedShareItem.type == .thread ? .perspectiveInvite : .questionInvite
                    Database.createInviteRequest(item: selectedShareItem, type: type, toUser: nil, toName: nil, toEmail: text,
                                                 childItems: [], parentItemID: parentItemID, completion: {(success, error) in
                            success ?
                            GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Invite Sent", erMessage: "Thanks for your recommendation!", buttonTitle: "okay") :
                            GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Error Sending Request", erMessage: "Sorry there was an error sending the invite")
                        self.toggleLoading(show: false, message: nil)
                    })
                }
            }
        })
    }
    
    //delegate for mini user search - send the invite
    internal func userSelected(item: Any) {
        guard let toUser = item as? User else {
            GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Invalid User Selected", erMessage: "Sorry! The user you selected is not valid")
            return
        }
        
        if let selectedShareItem = selectedShareItem {
            let itemKey = databaseRef.child("items").childByAutoId().key
            let parentItemID = selectedShareItem.itemID
            
            selectedShareItem.itemID = itemKey
            selectedShareItem.cID = selectedChannel.cID
            selectedShareItem.cTitle = selectedChannel.cTitle
            selectedShareItem.tag = selectedItem
            
            toggleLoading(show: true, message: "sending invite...", showIcon: true)
            let type : MessageType = selectedShareItem.type == .thread ? .perspectiveInvite : .questionInvite
            Database.createInviteRequest(item: selectedShareItem, type: type, toUser: toUser, toName: toUser.name, childItems: [], parentItemID: parentItemID, completion: {(success, error) in
                success ?
                    GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Invite Sent", erMessage: "Thanks for your recommendation!", buttonTitle: "okay") :
                    GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Error Sending Request", erMessage: "Sorry there was an error sending the invite")
                self.toggleLoading(show: false, message: nil)
            })
        }
    }
    
    //for collection view items
    internal func userSelected(item : Item, index : Int) {
        
        item.tag = selectedItem //since we are in tagVC
        
        //can only be a question or a post that user selects since it's in a tag already
        switch item.type {
        case .post:
            showItemDetail(allItems: self.allItems, index: index, itemCollection: [], selectedItem: selectedItem, watchedPreview: false)
        case .question, .thread, .interview:
            Database.getItemCollection(item.itemID, completion: {(success, items) in
                success ? self.showItemDetail(allItems: items, index: 0, itemCollection: [], selectedItem: item, watchedPreview: false) : self.showNoItemsMenu(selectedItem : item)
            })
        default: break
        }
    }
    
    
    internal func showBrowse(selectedItem: Item) {
        selectedItem.cID = selectedChannel.cID
        
        let itemCollection = BrowseContentVC()
        itemCollection.selectedChannel = selectedChannel
        itemCollection.selectedItem = selectedItem
        itemCollection.contentDelegate = self
        itemCollection.forSingleUser = selectedItem.type == .interview ? true : false
        navigationController?.pushViewController(itemCollection, animated: true)
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
    
    internal func userClosedBrowse(_ viewController : UIViewController) {
        dismiss(animated: true, completion: { _ in })
    }
    
    /** ItemCellDelegate Methods **/
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
        currentItem.tag = selectedItem
        
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

    //user clicked header menu - for series
    func clickedHeaderMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let newItemTitle = "new\(selectedItem.childType().capitalized)"
        
        if let user = User.currentUser, user.isVerified(for: selectedChannel) {
            menu.addAction(UIAlertAction(title: newItemTitle, style: .default, handler: { (action: UIAlertAction!) in
                switch self.selectedItem.type {
                case .interviews:
                    self.addInterview()
                case .perspectives:
                    self.startThread()
                case .questions, .feedback:
                    self.askQuestion()
                case .posts:
                    self.addNewItem(selectedItem: self.selectedItem)
                default: break
                }
            }))
        }
        
        menu.addAction(UIAlertAction(title: "share Series", style: .default, handler: { (action: UIAlertAction!) in
            self.showShare(type: "series")
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    //
    internal func showNoItemsMenu(selectedItem : Item) {
        var isExpert = false
        
        if User.isLoggedIn(), User.currentUser!.isVerified(for: selectedChannel) {
            isExpert = true
        }
        let message = isExpert ? "No\(selectedItem.childType())s yet - want to add one?" : "We are still waiting for the first\(selectedItem.childType())!"
        
        let menu = UIAlertController(title: "Sorry! No\(selectedItem.childType())s yet", message: message, preferredStyle: .actionSheet)
        
        if isExpert {
            menu.addAction(UIAlertAction(title: "add\(selectedItem.childType())", style: .default, handler: { (action: UIAlertAction!) in
                self.addNewItem(selectedItem: selectedItem)
            }))
        }
        
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
            applyExpertVC.selectedChannel = self.selectedChannel
            
            self.navigationController?.pushViewController(applyExpertVC, animated: true)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showInviteMenu(currentItem : Item) {
        let menu = UIAlertController(title: "Invite Experts", message: "know someone who can add to the discussion?", preferredStyle: .actionSheet)
        
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
            self.createShareRequest(selectedShareItem: currentItem, showAlert: false, completion: { selectedShareItem , error in
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
    
    internal func createShareRequest(selectedShareItem : Item, toEmail : String? = nil, showAlert : Bool = true, completion: @escaping (_ item : Item?, _ error : Error?) -> Void) {
        let itemKey = databaseRef.child("items").childByAutoId().key
        let parentItemID = selectedShareItem.itemID
        
        selectedShareItem.itemID = itemKey
        selectedShareItem.cID = selectedChannel.cID
        selectedShareItem.cTitle = selectedChannel.cTitle
        
        toggleLoading(show: true, message: "creating invite...", showIcon: true)
        let type : MessageType = selectedShareItem.type == .thread ? .perspectiveInvite : .questionInvite
        Database.createInviteRequest(item: selectedShareItem, type: type, toUser: nil, toName: nil, toEmail: toEmail,
                                     childItems: [], parentItemID: parentItemID, completion: {(success, error) in
            if success, showAlert {
                GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Invite Sent", erMessage: "Thanks for your recommendation!", buttonTitle: "okay")
            } else if showAlert {
                GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Error Sending Request", erMessage: "Sorry there was an error sending the invite")
            }
            
            completion(selectedShareItem, error)
            self.selectedShareItem = nil
        })
    }
    
    internal func showShare(selectedItem: Item, type: String, fullShareText: String = "") {
        toggleLoading(show: true, message: "loading share options...", showIcon: true)
        let isInvite = type == "invite" ? true : false

        selectedItem.createShareLink(invite: isInvite, completion: { link in
            guard let link = link else { return }
            self.shareContent(shareType: type, shareText: self.selectedItem.itemTitle, shareLink: link, fullShareText: fullShareText)
        })
    }
    
    internal func showShare(type: String) {
        showShare(selectedItem: self.selectedItem, type: type, fullShareText: self.selectedItem.itemTitle)
    }
}

extension TagCollectionVC: UIViewControllerTransitioningDelegate {
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
