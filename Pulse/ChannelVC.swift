//
//  ChannelVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ChannelVC: PulseVC, SelectionDelegate, UIScrollViewDelegate, ItemCellDelegate, BrowseContentDelegate {
    //set by delegate
    public var selectedChannel : Channel! {
        didSet {
            isSubscribed = User.currentUser!.subscriptionIDs.contains(selectedChannel.cID) ? true : false

            if !selectedChannel.cCreated {
                Database.getChannel(cID: selectedChannel.cID!, completion: { channel, error in
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
    
    fileprivate var isLoaded = false
    fileprivate var isLayoutSetup = false
    
    /** Collection View Vars **/
    fileprivate var collectionView : UICollectionView!
        
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
        
        Database.subscribeChannel(selectedChannel, completion: {(success, error) in
            if !success {
                GlobalFunctions.showErrorBlock("Error Subscribing Tag", erMessage: error!.localizedDescription)
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
    
    func clickedItemButton(itemRow : Int) {
        if let user = allItems[itemRow].user {
            let userProfileVC = UserProfileVC()
            navigationController?.pushViewController(userProfileVC, animated: true)
            userProfileVC.selectedUser = user
        }
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
            collectionView?.register(HeaderTitle.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
            
            //channel?.register(ChannelHeaderExperts.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
            
            view.addSubview(collectionView!)
            
            isLayoutSetup = true
        }
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
            
            //Get the image if content type is a post
            if currentItem.content == nil, currentItem.type == .post, !currentItem.fetchedContent {
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

    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateCell(_ cell: ItemCell, inCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
        if allItems[indexPath.row].itemCreated {
            let currentItem = allItems[indexPath.row]
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
    
    //Did select item at index path
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let selectedItem = allItems[indexPath.row]
            userSelected(item: selectedItem)
        }
    }
    
    /** Delegate Functions **/
    func userSelected(item : Any) {
        if let item = item as? Item {
            switch item.type {
            case .answer:
                showItemDetail(allItems: [item], index: 0, itemCollection: [], selectedItem: item, watchedPreview: false)
            case .post:
                Database.getItemCollection(item.itemID, completion: {(success, items) in
                    if success {
                        self.showItemDetail(allItems: [item], index: 0, itemCollection: items, selectedItem: item, watchedPreview: true)
                    } else {
                        self.showItemDetail(allItems: [item], index: 0, itemCollection: [item], selectedItem: item, watchedPreview: false)
                    }
                })
            case .question:
                
                showBrowse(selectedItem: item)
                
            case .posts, .feedback:
                
                showTag(selectedItem: item)
                
            default: break
            }
        } else if let user = item as? User {
            let userProfileVC = UserProfileVC()
            navigationController?.pushViewController(userProfileVC, animated: true)
            userProfileVC.selectedUser = user
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
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! HeaderTitle
            switch indexPath.section {
            case 0:
                headerView.backgroundColor = UIColor.white.withAlphaComponent(0.8)
                headerView.setTitle(title: "featured series")
            case 1:
                headerView.backgroundColor = UIColor.white.withAlphaComponent(0.8)
                headerView.setTitle(title: "recent updates")
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
            return CGSize(width: collectionView.frame.width, height: skinnyHeaderHeight)
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
