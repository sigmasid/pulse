//
//  HomeVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class HomeVC: PulseVC {
    
    //Main data source vars
    var allItems = [Item]()
    var allChannels = [Channel]()
    
    fileprivate var isLoaded = false
    fileprivate var isLayoutSetup = false
    fileprivate var loadingView : LoadingView?
    
    //fileprivate var feed : Tag!
    fileprivate var notificationsSetup : Bool = false
    fileprivate var initialLoadComplete = false
    fileprivate var minItemsInFeed = 4
    
    fileprivate var collectionView : UICollectionView!
    fileprivate let headerHeight : CGFloat = 20

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            statusBarHidden = true
            tabBarHidden = false
            
            toggleLoading(show: true, message: "Loading feed...")
            setupScreenLayout()
            setupNotifications()
            
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
    
    func createFeed() {
        
        if !initialLoadComplete  {
            
            allChannels = User.currentUser!.subscriptions
            updateFeed()
            updateDataSource()
            
            toggleLoading(show: false, message: nil)

            initialLoadComplete = true
        }
    }
    
    func updateFeed() {
        if User.isLoggedIn() {
            
            Database.createFeed { item in
                
                self.allItems.append(item)
                
                //set data source once
                if self.allItems.count > self.minItemsInFeed {
                    self.collectionView.reloadData()
                    self.initialLoadComplete = true
                }
            }
        } else {
            allChannels = []
            allItems = []
            collectionView.reloadData()
        }
    }
    
    func updateDataSource() {
        if !isLayoutSetup {
            setupScreenLayout()
        }
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.reloadData()
    }
    
    func setupNotifications() {
        if !notificationsSetup {

            NotificationCenter.default.addObserver(self, selector: #selector(createFeed), name: NSNotification.Name(rawValue: "SubscriptionsUpdated"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(updateFeed), name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
            
            notificationsSetup = true
        }
    }
    
    fileprivate func toggleLoading(show: Bool, message: String?) {
        if loadingView == nil {
            loadingView = LoadingView(frame: view.frame, backgroundColor: UIColor.white)
            loadingView?.addIcon(IconSizes.medium, _iconColor: UIColor.black, _iconBackgroundColor: nil)
            toggleLoading(show: true, message: nil)
            view.addSubview(loadingView!)
        }
        
        loadingView?.isHidden = show ? false : true
        loadingView?.addMessage(message)
    }
    
    fileprivate func setupScreenLayout() {
        if !isLayoutSetup {
            collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
            let _ = PulseFlowLayout.configureLayout(collectionView: collectionView, minimumLineSpacing: 10, itemSpacing: 10, stickyHeader: true)
            
            collectionView?.register(ItemCell.self, forCellWithReuseIdentifier: reuseIdentifier)
            collectionView?.register(HeaderChannelsCell.self, forCellWithReuseIdentifier: sectionReuseIdentifier)
            collectionView?.register(HeaderTitle.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
            
            view.addSubview(collectionView)
            
            isLayoutSetup = true
        }
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
        case 1: return self.allItems.count
        default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: sectionReuseIdentifier, for: indexPath) as! HeaderChannelsCell
            cell.channels = allChannels
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ItemCell
            let currentItem = allItems[indexPath.row]
            cell.tag = indexPath.row
            
            //clear the cells and set the item type first
            cell.updateLabel(nil, _subtitle: nil, _tag: nil)
            
            //Already fetched this item
            if currentItem.itemCreated {
                
                cell.itemType = currentItem.type
                cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: currentItem.tag?.itemTitle, _image: self.allItems[indexPath.row].content as? UIImage ?? nil)
                cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)
                
            } else {
                Database.getItem(currentItem.itemID, completion: { (item, error) in
                    
                    if let item = item {
                        
                        cell.itemType = currentItem.type
                        
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            DispatchQueue.main.async {
                                cell.updateLabel(item.itemTitle, _subtitle: self.allItems[indexPath.row].user?.name ?? nil, _tag: currentItem.tag?.itemTitle)
                            }
                        }
                        
                        item.tag = self.allItems[indexPath.row].tag
                        item.cID = self.allItems[indexPath.row].cID
                        self.allItems[indexPath.row] = item
                        
                        //Get the cover image
                        if let imageURL = item.contentURL, item.contentType == .recordedImage || item.contentType == .albumImage {
                            DispatchQueue.global(qos: .background).async {
                                if let data = try? Data(contentsOf: imageURL) {
                                    self.allItems[indexPath.row].content = UIImage(data: data)
                                    
                                    DispatchQueue.main.async {
                                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                            cell.updateImage(image : self.allItems[indexPath.row].content as? UIImage)
                                        }
                                    }
                                }
                            }
                        } else if item.contentType == .recordedVideo || item.contentType == .albumVideo {
                            Database.getImage(channelID: item.cID, itemID: item.itemID, fileType: .thumb, maxImgSize: maxImgSize, completion: { (data, error) in
                                if let data = data {
                                    self.allItems[indexPath.row].content = UIImage(data: data)
                                    
                                    DispatchQueue.main.async {
                                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                            cell.updateImage(image : self.allItems[indexPath.row].content as? UIImage)
                                        }
                                    }
                                }
                            })
                        }
                        
                        // Get the user details
                        Database.getUser(item.itemUserID, completion: {(user, error) in
                            if let user = user {
                                self.allItems[indexPath.row].user = user
                                DispatchQueue.main.async {
                                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                        cell.updateLabel(item.itemTitle, _subtitle: user.name, _tag: currentItem.tag?.itemTitle)
                                    }
                                }
                                
                                
                                DispatchQueue.global(qos: .background).async {
                                    if let imageString = user.thumbPic, let imageURL = URL(string: imageString), let _imageData = try? Data(contentsOf: imageURL) {
                                        self.allItems[indexPath.row].user?.thumbPicImage = UIImage(data: _imageData)
                                        
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
                })
            }
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
            return cell
        }
    }
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateCell(_ cell: ItemCell, inCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
        if allItems[indexPath.row].itemCreated {
            let currentItem = allItems[indexPath.row]
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: currentItem.tag?.itemTitle, _image: allItems[indexPath.row].content as? UIImage ?? nil)
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
        let selectedItem = allItems[indexPath.row]
        userSelected(item: selectedItem)
    }
    
    /** Delegate Functions **/
    internal func userSelected(user: User) {
        let userProfileVC = UserProfileVC()
        navigationController?.pushViewController(userProfileVC, animated: true)
        userProfileVC.selectedUser = user
    }
    
    fileprivate func updateHeader() {
        let logoButton = PulseButton(size: .small, type: .logo, isRound : true, background: .white, tint: .black)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: logoButton)
        
        headerNav?.showNavbar(animated: true)
        headerNav?.setNav(title: "PULSE")
        headerNav?.followScrollView(collectionView, delay: 25.0)
    }
    
    func userSelected(item : Item) {
        
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
    }
    
    internal func showItemDetail(allItems: [Item], index: Int, itemCollection: [Item], selectedItem : Item, watchedPreview : Bool) {
        contentVC = ContentManagerVC()
        contentVC.watchedFullPreview = watchedPreview
        //contentVC.selectedChannel = selectedChannel
        contentVC.selectedItem = selectedItem
        contentVC.itemCollection = itemCollection
        contentVC.itemIndex = index
        contentVC.allItems = allItems
        contentVC.openingScreen = .item
        
        //contentVC.transitioningDelegate = self
        present(contentVC, animated: true, completion: nil)
    }
    
    internal func showBrowse(selectedItem: Item) {
        let itemCollection = BrowseContentVC()
        //itemCollection.selectedChannel = selectedChannel
        itemCollection.selectedItem = selectedItem
        //itemCollection.contentDelegate = self
        
        navigationController?.pushViewController(itemCollection, animated: true)
    }
    
    func userClosedBrowse(_ viewController : UIViewController) {
        dismiss(animated: true, completion: { _ in
            print("should dismiss browse collection vc")
        })
    }
    
    internal func showTag(selectedItem : Item) {
        let tagDetailVC = TagCollectionVC()
        //tagDetailVC.selectedChannel = selectedChannel
        
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
                headerView.setTitle(title: "subscriptions")
            case 1:
                headerView.backgroundColor = .clear
                headerView.setTitle(title: "")
            default:
                break
            }
            
            //headerView.delegate = self
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
    }
}


extension HomeVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case 0:
            return CGSize(width: collectionView.frame.width, height: headerHeight)
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
        var cellHeight : CGFloat = 125
        switch indexPath.section {
        case 0:
            return CGSize(width: collectionView.frame.width, height: 100)
        case 1:
            cellHeight = GlobalFunctions.getCellHeight(type: allItems[indexPath.row].type)
            return CGSize(width: collectionView.frame.width, height: cellHeight)
        default:
            return CGSize(width: collectionView.frame.width, height: cellHeight)
        }
    }
    
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

