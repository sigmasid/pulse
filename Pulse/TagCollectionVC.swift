//
//  TagQABrowserVCViewController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/19/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class TagCollectionVC: PulseVC, HeaderDelegate, ItemCellDelegate, ModalDelegate {
    
    public var selectedChannel: Channel!
    
    //set by delegate - is of type feedback / posts since its a tag
    public var selectedItem : Item! {
        didSet {
            toggleLoading(show: true, message: "Loading Tag...", showIcon: true)
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
    internal let headerHeight : CGFloat = 50
    
    fileprivate var isLayoutSetup = false
    
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
        GlobalFunctions.dismissVC(viewController)
    }
        
    func userClickedMenu() {
        switch selectedItem.type {
        case .posts:
            showPostMenu()
        case .feedback:
            showFeedbackMenu()
        default: return
        }
    }
    
    //is showing answers
    func showFeedbackMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "Ask", style: .default, handler: { (action: UIAlertAction!) in
            self.askQuestion()
        }))
        
        menu.addAction(UIAlertAction(title: "Share Tag", style: .default, handler: { (action: UIAlertAction!) in
            self.askQuestion()
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    func showPostMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "New Post", style: .default, handler: { (action: UIAlertAction!) in
            self.askQuestion()
        }))
        
        menu.addAction(UIAlertAction(title: "Share Tag", style: .default, handler: { (action: UIAlertAction!) in
            self.askQuestion()
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    func askQuestion() {
        let questionVC = AskQuestionVC()
        questionVC.selectedTag = selectedItem
        questionVC.delegate = self
        
        GlobalFunctions.addNewVC(questionVC, parentVC: self)
    }

    //once allItems var is set reload the data
    func updateDataSource() {
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
    
    /** ItemCellDelegate Methods **/
    internal func clickedItemButton(itemRow : Int) {
        if let user = allItems[itemRow].user {
            let userProfileVC = UserProfileVC()
            navigationController?.pushViewController(userProfileVC, animated: true)
            userProfileVC.selectedUser = user
        }
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
        cell.updateLabel(currentItem.itemTitle, _subtitle: currentItem.user?.name, _createdAt: currentItem.createdAt, _tag: selectedItem.itemTitle)
        cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)

        //Already fetched this item
        if allItems[indexPath.row].itemCreated {
            
            cell.itemType = currentItem.type
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: selectedItem.itemTitle, _createdAt: currentItem.createdAt, _image: self.allItems[indexPath.row].content as? UIImage ?? nil)
            cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)
            
        } else {
            Database.getItem(allItems[indexPath.row].itemID, completion: { (item, error) in
                if let item = item {
                    
                    cell.itemType = item.type


                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                        DispatchQueue.main.async {
                            cell.itemType = item.type
                            cell.updateLabel(item.itemTitle, _subtitle: self.allItems[indexPath.row].user?.name ?? nil,  _createdAt: self.allItems[indexPath.row].createdAt,
                                             _tag: self.allItems[indexPath.row].tag?.itemTitle)
                        }
                    }
                    
                    item.tag = self.allItems[indexPath.row].tag
                    self.allItems[indexPath.row] = item
                    
                    //Get the cover image
                    if let imageURL = item.contentURL, item.contentType == .recordedImage || item.contentType == .albumImage, let _imageData = try? Data(contentsOf: imageURL) {
                        DispatchQueue.global(qos: .background).async {
                            
                            self.allItems[indexPath.row].content = UIImage(data: _imageData)
                            
                            DispatchQueue.main.async {
                                if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                    cell.updateImage(image : self.allItems[indexPath.row].content as? UIImage)
                                }
                            }
                        }
                    } else if item.contentType == .recordedVideo || item.contentType == .albumVideo {
                        Database.getImage(channelID: self.selectedChannel.cID, itemID: item.itemID, fileType: .thumb, maxImgSize: maxImgSize, completion: { (data, error) in
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
                    if let user = self.checkUserDownloaded(user: User(uID: item.itemUserID)) {
                        self.allItems[indexPath.row].user = user
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
                        Database.getUser(item.itemUserID, completion: {(user, error) in
                            if let user = user {
                                self.allItems[indexPath.row].user = user
                                self.allUsers.append(user)
                                
                                DispatchQueue.main.async {
                                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                        cell.updateLabel(item.itemTitle, _subtitle: user.name,  _createdAt: item.createdAt, _tag: currentItem.tag?.itemTitle)
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
            
            if let title = selectedItem.itemTitle {
                headerView.updateLabel("# \(title.lowercased())")
            }
            
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
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: selectedItem.itemTitle, _createdAt: currentItem.createdAt, _image: allItems[indexPath.row].content as? UIImage ?? nil)
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
    
    /**
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
        let bottomInset = scrollView.contentInset.bottom
        
        if bottomEdge >= scrollView.contentSize.height - bottomInset {
            print("reached end of scroll view")
            getMoreItems()
        }
    } **/
    
    func userSelected(item : Item, index : Int) {
        
        item.tag = selectedItem //since we are in tagVC
        
        //can only be a question or a post that user selects since it's in a tag already
        switch item.type {
        case .post:
            Database.getItemCollection(item.itemID, completion: {(success, items) in
                success ?
                    self.showItemDetail(allItems: self.allItems, index: index, itemCollection: items, selectedItem: self.selectedItem, watchedPreview: true) :
                    self.showItemDetail(allItems: self.allItems, index: index, itemCollection: [item], selectedItem: self.selectedItem, watchedPreview: false)
            })
        case .question:
            Database.getItemCollection(item.itemID, completion: {(success, items) in
                success ?
                    self.showItemDetail(allItems: items, index: 0, itemCollection: [], selectedItem: item, watchedPreview: false) :
                    GlobalFunctions.showErrorBlock("Sorry! No answers yet", erMessage: "We are still waiting to get an answer - want to add one?")
            })
        default: break
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
    
    func userClosedBrowse(_ viewController : UIViewController) {
        dismiss(animated: true, completion: { _ in
            print("should dismiss browse collection vc")
        })
    }
}

extension TagCollectionVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: headerHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: Spacing.xs.rawValue, right: 0.0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellHeight = GlobalFunctions.getCellHeight(type: allItems[indexPath.row].type)

        return CGSize(width: collectionView.frame.width, height: cellHeight)
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
