//
//  BrowseContentVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/17/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

private let headerReuseIdentifier = "ItemHeaderCell"
private let reuseIdentifier = "BrowseContentCell"


class BrowseContentVC: PulseVC, PreviewDelegate {
    //Delegate PreviewVC var - if user watches full preview then go to index 1 vs. index 0 in full screen
    var watchedFullPreview: Bool = false
    var contentDelegate : BrowseContentDelegate!
    /** End Delegate Vars **/
    
    /** Transition Animation Vars **/
    fileprivate var panPresentInteractionController = PanEdgeInteractionController()
    fileprivate var panDismissInteractionController = PanEdgeInteractionController()
    fileprivate var initialFrame = CGRect.zero
    
    //Main data source var -
    public var allItems = [Item]() {
        didSet {
            itemStack.removeAll()
            itemStack = [ItemMetaData](repeating: ItemMetaData(), count: allItems.count)
        }
    }
    internal var itemStack = [ItemMetaData]()
    
    //set by delegate
    public var selectedChannel : Channel!
    public var selectedItem : Item! {
        didSet {
            if allItems.isEmpty {
                Database.getItemCollection(selectedItem.itemID, completion: {(success, items) in
                    if success {
                        let type = self.selectedItem.type == .question ? "answer" : "post"
                        self.allItems = items.map{ item -> Item in
                            Item(itemID: item.itemID, type: type)
                        }
                        self.updateDataSource()
                    }
                })
            } else {
                updateDataSource()
            }
        }
    }
    //end set by delegate
    
    /** Collection View Vars **/
    internal var collectionView : UICollectionView!
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
                let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: selectedIndex) as! BrowseContentCell
                cell.removePreview()
            }
        }
    }
    fileprivate var deselectedIndex : IndexPath?
    /** End Declarations **/
    
    //once allItems var is set reload the data
    func updateDataSource() {
        if !isLayoutSetup {
            setupLayout()
            
            tabBarHidden = true
            isLayoutSetup = true
        }
        print("should update data source")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.reloadData()
        collectionView?.layoutIfNeeded()
    }
    
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
    
    func setupLayout() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        let _ = PulseFlowLayout.configureLayout(collectionView: collectionView, minimumLineSpacing: 10, itemSpacing: 10, stickyHeader: true)
        
        collectionView?.register(ItemHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        collectionView?.register(BrowseContentCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        view.addSubview(collectionView)
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        let backButton = PulseButton(size: .small, type: .back, isRound : true, background: .white, tint: .black)
        backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        headerNav?.followScrollView(collectionView, delay: 25.0)
    }

    
    internal func showItemDetail(item : Item, index : Int, itemCollection: [Item]) {
        if contentDelegate != nil {
            contentDelegate.showItemDetail(allItems: allItems, index: index, itemCollection: itemCollection, selectedItem : item, watchedPreview : watchedFullPreview)
        }
    }
}

extension BrowseContentVC : UICollectionViewDelegate, UICollectionViewDataSource {

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
        
        selectedIndex = indexPath
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BrowseContentCell
        
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
            showItemDetail(item: selectedItem, index: indexPath.row, itemCollection: itemStack[indexPath.row].itemCollection )
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
    
    func collectionView(_ collectionView: UICollectionView,
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

extension BrowseContentVC: UICollectionViewDelegateFlowLayout {
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

/* UPDATE ON SCREEN ROWS WHEN SCROLL STOPS */
extension BrowseContentVC  {
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateBrowseContentCell(_ cell: BrowseContentCell, atIndexPath indexPath: IndexPath) {
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
                let cell = collectionView?.cellForItem(at: indexPath) as! BrowseContentCell
                updateBrowseContentCell(cell, atIndexPath: indexPath)
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

extension BrowseContentVC: UIViewControllerTransitioningDelegate {
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

