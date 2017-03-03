//
//  BrowseCollectionVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/17/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

private let headerReuseIdentifier = "ItemHeaderCell"
private let reuseIdentifier = "BrowseCell"

class BrowseCollectionVC: UICollectionViewController, previewDelegate {
    //Delegate PreviewVC var - if user watches full preview then go to index 1 vs. index 0 in full screen
    var watchedFullPreview: Bool = false
    /** End Delegate Vars **/
    
    /** Transition Animation Vars **/
    fileprivate var panPresentInteractionController = PanEdgeInteractionController()
    fileprivate var panDismissInteractionController = PanEdgeInteractionController()
    fileprivate var contentVC : ContentManagerVC!
    fileprivate var initialFrame = CGRect.zero
    
    //Main data source var -
    public var allItems = [Item]() {
        didSet {
            itemStack.removeAll()
            itemStack = [ItemMetaData](repeating: ItemMetaData(), count: allItems.count)
        }
    }
    private var itemStack = [ItemMetaData]()
    
    //set by delegate
    public var selectedChannel : Channel!
    public var selectedItem : Item! {
        didSet {
            Database.getItemCollection(selectedItem.itemID, completion: {(success, items) in
                if success {
                    let type = self.selectedItem.type == .question ? "answer" : "post"
                    self.allItems = items.map{ item -> Item in Item(itemID: item.itemID, type: type) }
                    self.updateDataSource()
                }
            })
        }
    }
    //end set by delegate
    
    /** Collection View Vars **/
    fileprivate let minCellHeight : CGFloat = 225
    fileprivate let headerHeight : CGFloat = 60
    
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
                let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: selectedIndex) as! BrowseCell
                cell.removePreview()
            }
        }
    }
    fileprivate var deselectedIndex : IndexPath?
    /** End Declarations **/
    
    //once allItems var is set reload the data
    func updateDataSource() {
        collectionView?.reloadData()
        collectionView?.layoutIfNeeded()
        
        if allItems.count > 0 {
            collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.register(ItemHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        collectionView?.register(BrowseCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let backButton = PulseButton(size: .small, type: .back, isRound : true, hasBackground: true)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
        
        extendedLayoutIncludesOpaqueBars = true
        view.backgroundColor = .white
        collectionView?.backgroundColor = .white
    }
    
    internal func showItemDetail(item : Item, index : Int) {
        //need to be set first
        
        contentVC = ContentManagerVC()
        contentVC.watchedFullPreview = false
        contentVC.selectedChannel = selectedChannel
        contentVC.selectedItem = selectedItem
        contentVC.allItems = allItems
        contentVC.itemIndex = index
        contentVC.openingScreen = .item
        
        contentVC.transitioningDelegate = self
        present(contentVC, animated: true, completion: nil)
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allItems.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
            let cellRect = attributes.frame
            initialFrame = collectionView.convert(cellRect, to: collectionView.superview)
        }
        
        selectedIndex = indexPath
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BrowseCell
        
        cell.contentView.backgroundColor = .white
        cell.updateLabel(nil, _subtitle: nil, _image : nil)
        
        let currentItem = allItems[indexPath.row]
        
        /* GET PREVIEW IMAGE FROM STORAGE */
        if currentItem.content != nil && !itemStack[indexPath.row].gettingImageForPreview {
            
            cell.updateImage(image: currentItem.content as? UIImage)
        } else if itemStack[indexPath.row].gettingImageForPreview {
            
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            itemStack[indexPath.row].gettingImageForPreview = true
            
            Database.getImage(channelID: selectedItem.cID, itemID: currentItem.itemID, fileType: .thumb, maxImgSize: maxImgSize, completion: {(_data, error) in
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
        
        //Already fetched this item
        if allItems[indexPath.row].itemCreated, let user = allItems[indexPath.row].user  {
            
            cell.updateLabel(user.name?.capitalized, _subtitle: user.shortBio?.capitalized)

        } else if itemStack[indexPath.row].gettingInfoForPreview {
            
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            itemStack[indexPath.row].gettingInfoForPreview = true

            Database.getItem(allItems[indexPath.row].itemID, completion: { (item, error) in
                
                if let item = item {
                    
                    item.tag = self.allItems[indexPath.row].tag
                    self.allItems[indexPath.row] = item
                    
                    // Get the user details
                    Database.getUser(item.itemUserID, completion: {(user, error) in
                        if let user = user {
                            self.allItems[indexPath.row].user = user
                            DispatchQueue.main.async {
                                if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                    
                                    cell.updateLabel(user.name?.capitalized, _subtitle: user.shortBio?.capitalized)

                                }
                            }
                        }
                    })
                }
            })
        }
        
        if indexPath == selectedIndex && indexPath == deselectedIndex {
            showItemDetail(item: selectedItem, index: indexPath.row)
        } else if indexPath == selectedIndex {
            //if item has more than initial clip, show 'see more at the end'
            watchedFullPreview = false
            
            Database.getItemCollection(selectedItem.itemID, completion: {(hasDetail, itemCollection) in
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
    
    override func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! ItemHeader
            headerView.backgroundColor = .white
            headerView.updateLabel(selectedItem != nil ? selectedItem.itemTitle : "")
            
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
    }
}

extension BrowseCollectionVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (view.frame.width - 30) / 2, height: minCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: selectedItem != nil ? headerHeight : 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 10.0, bottom: 0.0, right: 10.0)
    }
}

/* COLLECTION VIEW */
extension BrowseCollectionVC  {
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateBrowseCell(_ cell: BrowseCell, atIndexPath indexPath: IndexPath) {
        if let user = allItems[indexPath.row].user  {
            cell.updateLabel(user.name?.capitalized, _subtitle: user.shortBio?.capitalized)
        }
        
        if let image = allItems[indexPath.row].content as? UIImage  {
            cell.updateImage(image: image)
        }
    }
    
    func updateOnscreenRows() {
        if let visiblePaths = collectionView?.indexPathsForVisibleItems {
            for indexPath in visiblePaths {
                let cell = collectionView?.cellForItem(at: indexPath) as! BrowseCell
                updateBrowseCell(cell, atIndexPath: indexPath)
            }
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateOnscreenRows()
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { updateOnscreenRows() }
    }
}

extension BrowseCollectionVC: UIViewControllerTransitioningDelegate {
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

