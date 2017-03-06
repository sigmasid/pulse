//
//  UserProfileVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

protocol UserProfileDelegate: class {
    func showMenu()
}

class UserProfileVC: PulseVC, UserProfileDelegate, PreviewDelegate {
    
    /** Delegate Vars **/
    public var selectedUser : User! {
        didSet {
            if !selectedUser.uCreated {
                Database.getUser(selectedUser.uID!, completion: {(user, error) in
                    if error == nil {
                        self.selectedUser = user
                        self.setHeaderTitle(title: user?.name ?? "Explore User")
                    }
                })
            } else if !selectedUser.uDetailedCreated {
                getDetailUserProfile()
            } else {
                allItems = selectedUser.items
                updateDataSource()
            }
            
            if selectedUser.thumbPicImage == nil {
                getUserProfilePic()
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
    
    fileprivate var isLoaded = false
    
    /** Collection View Vars **/
    internal var collectionView : UICollectionView!
    fileprivate let minCellHeight : CGFloat = 225
    fileprivate let headerHeight : CGFloat = 200
    fileprivate let headerReuseIdentifier = "UserProfileHeader"
    fileprivate let reuseIdentifier = "FeedAnswerCell"
    
    /** Transition Vars **/
    fileprivate var initialFrame = CGRect.zero
    fileprivate var panPresentInteractionController = PanEdgeInteractionController()
    fileprivate var panDismissInteractionController = PanEdgeInteractionController()
    
    fileprivate var activityController: UIActivityViewController? //Used for share screen
    
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
                let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: selectedIndex) as! ItemFullWidthCell
                cell.removePreview()
            }
        }
    }
    fileprivate var deselectedIndex : IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            updateHeader()
            setupLayout()
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader()

        guard selectedUser != nil else { return }
        setHeaderTitle(title: selectedUser.name ?? "Explore User")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupLayout() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        let _ = PulseFlowLayout.configureLayout(collectionView: collectionView, minimumLineSpacing: 10, itemSpacing: 10, stickyHeader: false)
        
        collectionView?.register(BrowseContentCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView?.register(UserProfileHeader.self,
                                 forSupplementaryViewOfKind: UICollectionElementKindSectionHeader ,
                                 withReuseIdentifier: headerReuseIdentifier)
        
        view.addSubview(collectionView)
    }
    
    internal func getDetailUserProfile() {
        Database.getDetailedUserProfile(user: selectedUser, completion: { updatedUser in
            let userImage = self.selectedUser.thumbPicImage
            
            self.selectedUser = updatedUser
            self.selectedUser.thumbPicImage = userImage
        })
    }
    
    internal func getUserProfilePic() {
        Database.getProfilePicForUser(user: selectedUser, completion: { profileImage in
            self.selectedUser.thumbPicImage = profileImage
            if let collectionView = self.collectionView {
                for view in collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionHeader) {
                    view.setNeedsDisplay()
                }
            }
        })
    }
    
    //once allItems var is set reload the data
    func updateDataSource() {
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.reloadData()
        collectionView?.layoutIfNeeded()
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        let backButton = PulseButton(size: .small, type: .back, isRound : true, background: .white, tint: .black)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
    }
    
    fileprivate func setHeaderTitle(title: String) {
        headerNav?.setNav(title: title)
    }
    
    /** Show Menu **/
    func showMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "Send Message", style: .default, handler: { (action: UIAlertAction!) in
            self.sendMessage()
        }))
        
        menu.addAction(UIAlertAction(title: "Share Profile", style: .default, handler: { (action: UIAlertAction!) in
            self.shareProfile()
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    /** Start Delegate Functions **/
    func askQuestion() {
        let questionVC = AskQuestionVC()
        questionVC.selectedUser = selectedUser
        navigationController?.pushViewController(questionVC, animated: true)
    }
    
    func shareProfile() {
        selectedUser.createShareLink(completion: { link in
            guard let link = link else { return }
            self.activityController = GlobalFunctions.shareContent(shareType: "person",
                                                                   shareText: self.selectedUser.name ?? "",
                                                                   shareLink: link, presenter: self)
        })
    }
    
    func sendMessage() {
        let messageVC = MessageVC()
        messageVC.toUser = selectedUser
        
        if let selectedUserImage = selectedUser.thumbPicImage {
            messageVC.toUserImage = selectedUserImage
        }
        
        navigationController?.pushViewController(messageVC, animated: true)
    }
    /** End Delegate Functions **/
    
    internal func showItemDetail(selectedItem : Item) {
        //need to be set first
        
        contentVC = ContentManagerVC()
        contentVC.watchedFullPreview = false
        contentVC.allItems = [selectedItem]
        contentVC.openingScreen = .item
        contentVC.selectedChannel = Channel(cID: selectedItem.cID)
        
        contentVC.transitioningDelegate = self
        present(contentVC, animated: true, completion: nil)
    }
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateCurrentCell(_ cell: BrowseContentCell, atIndexPath indexPath: IndexPath) {
        if allItems[indexPath.row].itemCreated  {
            cell.updateLabel(nil, _subtitle: allItems[indexPath.row].itemTitle)
        }
        
        if let image = allItems[indexPath.row].content as? UIImage  {
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
}

extension UserProfileVC : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BrowseContentCell
        
        cell.contentView.backgroundColor = .white
        cell.setNumberOfLines(titleNum: 0, subTitleNum: 2)
        
        let currentItem = allItems[indexPath.row]
        
        /* GET PREVIEW IMAGE FROM STORAGE */
        if currentItem.content != nil && !itemStack[indexPath.row].gettingImageForPreview {
            
            cell.updateImage(image: currentItem.content as? UIImage)
            
        } else if itemStack[indexPath.row].gettingImageForPreview {
            
            //ignore if already fetching the image, so don't refetch if already getting
        } else if currentItem.itemCreated {
            itemStack[indexPath.row].gettingImageForPreview = true
            
            Database.getImage(channelID: currentItem.cID, itemID: currentItem.itemID, fileType: .thumb, maxImgSize: maxImgSize, completion: {(_data, error) in
                if error == nil {
                    let _previewImage = GlobalFunctions.createImageFromData(_data!)
                    self.allItems[indexPath.row].content = _previewImage
                    
                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                        DispatchQueue.main.async {
                            cell.updateImage(image: self.allItems[indexPath.row].content as? UIImage)
                        }
                    }
                } else {
                    cell.updateImage(image: nil)
                }
            })
        }
        
        /** GET NAME & BIO FROM DATABASE - SHOWING MANY ITEMS FROM MANY USERS CASE **/
        if currentItem.itemCreated, itemStack[indexPath.row].gettingInfoForPreview {
            
            cell.updateLabel(nil, _subtitle: currentItem.itemTitle)
            
        } else if itemStack[indexPath.row].gettingInfoForPreview {
            
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            cell.updateLabel(nil, _subtitle: nil, _image : nil)

            itemStack[indexPath.row].gettingInfoForPreview = true
            
            // Get the user details
            Database.getItem(currentItem.itemID, completion: {(item, error) in
                if let item = item {
                    let tempImage = self.allItems[indexPath.row].content
                    self.allItems[indexPath.row] = item
                    self.allItems[indexPath.row].content = tempImage
                    
                    DispatchQueue.main.async {
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            cell.updateLabel(nil, _subtitle: self.allItems[indexPath.row].itemTitle)
                        }
                    }

                    Database.getImage(channelID: item.cID, itemID: item.itemID, fileType: .thumb, maxImgSize: maxImgSize, completion: {(_data, error) in
                        if error == nil {
                            let _previewImage = GlobalFunctions.createImageFromData(_data!)
                            self.allItems[indexPath.row].content = _previewImage
                            
                            if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                DispatchQueue.main.async {
                                    cell.updateImage(image: self.allItems[indexPath.row].content as? UIImage)
                                }
                            }
                        } else {
                            cell.updateImage(image: nil)
                        }
                    })
                
                }
            })
        }
        
        if indexPath == selectedIndex && indexPath == deselectedIndex {
            showItemDetail(selectedItem: currentItem)
        } else if indexPath == selectedIndex {
            //if item has more than initial clip, show 'see more at the end'
            watchedFullPreview = false
            
            Database.getItemCollection(currentItem.itemID, completion: {(hasDetail, itemCollection) in
                if hasDetail {
                    cell.showTapForMore = true
                    self.itemStack[indexPath.row].itemCollection = itemCollection
                } else {
                    cell.showTapForMore = false
                }
            })
            
            cell.delegate = self
            cell.showItemPreview(item: currentItem)
            
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
        if let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
            let cellRect = attributes.frame
            initialFrame = collectionView.convert(cellRect, to: collectionView.superview)
        }
        
        selectedIndex = indexPath
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! UserProfileHeader
            headerView.backgroundColor = .white
            headerView.updateUserDetails(selectedUser: selectedUser)
            headerView.profileDelegate = self
            
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
    }
}

extension UserProfileVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (view.frame.width - 30) / 2, height: minCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: headerHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 10.0, bottom: 0.0, right: 10.0)
    }
}

extension UserProfileVC: UIViewControllerTransitioningDelegate {
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
