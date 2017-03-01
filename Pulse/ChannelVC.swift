//
//  ChannelVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

protocol ChannelDelegate: class {
    func userSelected(user : User)
    func userSelected(item : Item)
    func currentItems(items : [Item])
}

class ChannelVC: UIViewController, ChannelDelegate {
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
    
    fileprivate var headerNav : PulseNavVC?
    fileprivate var contentVC : ContentManagerVC!

    fileprivate var subscribeButton = PulseButton(size: .medium, type: .add, isRound : true, hasBackground: true, tint: .white)
    fileprivate var isSubscribed : Bool = false {
        didSet { setupSubscribe() }
    }
    fileprivate var activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: IconSizes.medium.rawValue, height: IconSizes.medium.rawValue))
    
    fileprivate var allItems = [Item]()
    fileprivate var headerItems = [Item]()
    
    fileprivate var isLoaded = false
    fileprivate var isLayoutSetup = false
    
    /** Collection View Vars **/
    fileprivate var channel : UICollectionView!
    fileprivate let questionCellHeight : CGFloat = 125
    fileprivate let postCellHeight : CGFloat = 300

    fileprivate let headerHeight : CGFloat = 125
    fileprivate let headerReuseIdentifier = "ChannelHeader"
    fileprivate let reuseIdentifier = "ItemCell"
    
    /** Transition Vars **/
    fileprivate var initialFrame = CGRect.zero
    fileprivate var panPresentInteractionController = PanEdgeInteractionController()
    fileprivate var panDismissInteractionController = PanEdgeInteractionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            if let nav = navigationController as? PulseNavVC {
                headerNav = nav
            }
            
            extendedLayoutIncludesOpaqueBars = true
            tabBarController?.tabBar.isHidden = true
            edgesForExtendedLayout = .bottom
            view.backgroundColor = .white
            
            setupScreenLayout()
            definesPresentationContext = true
            
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateHeader()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    internal func getChannelItems() {
        Database.getChannelItems(channel: selectedChannel, completion: { updatedChannel in
            if let updatedChannel = updatedChannel {
                self.selectedChannel = updatedChannel
            }
        })
    }
    
    //Once the channel is set and pulled from database -> reload the datasource for collection view
    func updateDataSource() {
        if !isLayoutSetup {
            setupScreenLayout()
        }
        
        channel.delegate = self
        channel.dataSource = self
        channel.reloadData()
        channel.layoutIfNeeded()
        
        if allItems.count > 0 {
            channel.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
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

                    UIView.animate(withDuration: 1, animations: { self.subscribeButton.alpha = 0 } , completion: {(value: Bool) in
                        self.subscribeButton.removeFromSuperview()
                        self.subscribeButton = PulseButton(size: .medium, type: .add, isRound : true, hasBackground: true, tint: .white)
                    })
                }
            }
        })
    }
    
    /** HEADER FUNCTIONS **/
    fileprivate func updateHeader() {
        let backButton = PulseButton(size: .small, type: .back, isRound : true, hasBackground: true)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        if let nav = headerNav {
            nav.setNav(title: selectedChannel.cTitle ?? "Explore Channel")
            nav.updateBackgroundImage(image: selectedChannel.cPreviewImage)
            backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
        } else {
            title = selectedChannel.cTitle ?? "Explore Channel"
        }
    }
    
    internal func userSelected(user: User) {
        let userProfileVC = UserProfileVC(collectionViewLayout: GlobalFunctions.getPulseCollectionLayout())
        navigationController?.pushViewController(userProfileVC, animated: true)
        userProfileVC.selectedUser = user
    }
    
    internal func currentItems(items : [Item]) {
        headerItems = items
    }
    
    internal func setupSubscribe() {
        if !isSubscribed {
            view.addSubview(subscribeButton)
            
            subscribeButton.addTarget(self, action: #selector(subscribe), for: UIControlEvents.touchUpInside)
            
            subscribeButton.translatesAutoresizingMaskIntoConstraints = false
            subscribeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
            subscribeButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
            subscribeButton.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
            subscribeButton.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
            subscribeButton.layoutIfNeeded()
        }
    }
    
    fileprivate func setupScreenLayout() {
        if !isLayoutSetup {
            
            channel = UICollectionView(frame: view.bounds, collectionViewLayout: GlobalFunctions.getPulseCollectionLayout())
            channel?.register(ItemCell.self, forCellWithReuseIdentifier: reuseIdentifier)
            channel?.register(ChannelHeaderTags.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
            //channel?.register(ChannelHeaderExperts.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
            
            view.addSubview(channel!)
            
            channel.backgroundColor = .clear
            channel.backgroundView = nil
            channel.showsVerticalScrollIndicator = false
            
            channel?.isMultipleTouchEnabled = true
            isLayoutSetup = true
        }
    }
}

/* COLLECTION VIEW */
extension ChannelVC : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ItemCell
        let currentItem = allItems[indexPath.row]
        
        //clear the cells and set the item type first
        cell.updateLabel(nil, _subtitle: nil, _tag: nil)
        
        //Already fetched this item
        if currentItem.itemCreated {

            cell.itemType = currentItem.type
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: currentItem.tag?.itemTitle, _image: self.allItems[indexPath.row].content as? UIImage ?? nil)
            cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage)
            
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
                        Database.getImage(channelID: self.selectedChannel.cID, itemID: item.itemID, fileType: .cover, maxImgSize: maxImgSize, completion: { (data, error) in
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
                                            cell.updateButtonImage(image: self.allItems[indexPath.row].user?.thumbPicImage)
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
    }
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateCell(_ cell: ItemCell, inCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
        if allItems[indexPath.row].itemCreated {
            let currentItem = allItems[indexPath.row]
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: currentItem.tag?.itemTitle, _image: allItems[indexPath.row].content as? UIImage ?? nil)
            cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage)
        }
    }
    
    func updateOnscreenRows() {
        let visiblePaths = channel.indexPathsForVisibleItems
        for indexPath in visiblePaths {
            let cell = channel.cellForItem(at: indexPath) as! ItemCell
            updateCell(cell, inCollectionView: channel, atIndexPath: indexPath)
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
    
    func userSelected(item : Item) {
        
        switch item.type {
            
        case .answer:
            
            showItemDetail(allItems: [item], itemCollection: [], selectedItem: item, watchedPreview: false)

        case .post:
            Database.getItemCollection(item.itemID, completion: {(success, items) in
                if success {
                    self.showItemDetail(allItems: [item], itemCollection: items, selectedItem: item, watchedPreview: true)
                } else {
                    self.showItemDetail(allItems: [item], itemCollection: [item], selectedItem: item, watchedPreview: false)
                }
            })
        case .question:
            
            showBrowse(selectedItem: item)
            
        case .tag:

            showTag(selectedItem: item)
            
        default: break
        }
    }
    
    internal func showItemDetail(allItems: [Item], itemCollection: [Item], selectedItem : Item, watchedPreview : Bool) {
        contentVC = ContentManagerVC()
        contentVC.watchedFullPreview = watchedPreview
        contentVC.selectedChannel = selectedChannel
        contentVC.selectedItem = selectedItem
        contentVC.itemCollection = itemCollection
        contentVC.allItems = allItems
        contentVC.openingScreen = .item
        
        contentVC.transitioningDelegate = self
        present(contentVC, animated: true, completion: nil)
    }
    
    internal func showBrowse(selectedItem: Item) {
        let layout = GlobalFunctions.getPulseCollectionLayout()
        layout.sectionHeadersPinToVisibleBounds = true
        
        let itemCollection = BrowseCollectionVC(collectionViewLayout: layout)
        itemCollection.selectedChannel = selectedChannel
        itemCollection.selectedItem = selectedItem
        
        navigationController?.pushViewController(itemCollection, animated: true)
    }
    
    internal func showTag(selectedItem : Item) {
        let layout = GlobalFunctions.getPulseCollectionLayout()
        layout.sectionHeadersPinToVisibleBounds = true
        
        let tagDetailVC = TagCollectionVC(collectionViewLayout: layout)
        tagDetailVC.selectedChannel = selectedChannel
        tagDetailVC.selectedItem = selectedItem
        
        navigationController?.pushViewController(tagDetailVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! ChannelHeaderTags
            
            headerView.backgroundColor = .white
            headerView.selectedChannel = selectedChannel
            headerView.items = headerItems.isEmpty ? selectedChannel.tags : headerItems
            
            //headerView.experts = selectedChannel.experts
            headerView.delegate = self
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
    }
}

extension ChannelVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: channel.frame.width, height: headerHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 0.0, bottom: 1.0, right: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellHeight = GlobalFunctions.getCellHeight(type: allItems[indexPath.row].type)
        return CGSize(width: channel.frame.width - 20, height: cellHeight)
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
