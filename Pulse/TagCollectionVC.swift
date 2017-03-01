//
//  TagQABrowserVCViewController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/19/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
private let headerReuseIdentifier = "PostsHeaderCell"
private let reuseIdentifier = "PostsCell"

class TagCollectionVC: UICollectionViewController {
    
    public var selectedChannel: Channel!
    //set by delegate
    public var selectedItem : Item! {
        didSet {
            Database.getItemCollection(selectedItem.itemID, completion: {(success, items) in
                self.setupButton()
                self.allItems = items
                self.updateDataSource()
                self.updateHeader()
            })
        }
    }
    //end set by delegate
    
    /** main datasource var **/
    fileprivate var allItems = [Item]()
    
    fileprivate var headerNav : PulseNavVC?
    fileprivate var contentVC : ContentManagerVC!
    
    /** Collection View Vars **/
    internal let headerHeight : CGFloat = 60
    
    fileprivate let headerReuseIdentifier = "ChannelHeader"
    fileprivate let reuseIdentifier = "ItemCell"
    
    /** Transition Vars **/
    fileprivate var initialFrame = CGRect.zero
    fileprivate var panPresentInteractionController = PanEdgeInteractionController()
    fileprivate var panDismissInteractionController = PanEdgeInteractionController()
    
    /** Main Button **/
    fileprivate var screenButton : PulseButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        collectionView?.backgroundColor = .white
        
        collectionView?.register(ItemHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        collectionView?.register(ItemCell.self, forCellWithReuseIdentifier: reuseIdentifier)        
    
        if let nav = navigationController as? PulseNavVC {
            headerNav = nav
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        let backButton = PulseButton(size: .small, type: .back, isRound : true, hasBackground: true)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
        
        extendedLayoutIncludesOpaqueBars = true
        collectionView?.backgroundColor = .white
        view.backgroundColor = .white
    }
    
    internal func setupButton() {
        if selectedItem.type == .question {
            screenButton = PulseButton(size: .medium, type: .question, isRound : true, hasBackground: true, tint: .white)
            view.addSubview(screenButton)

            screenButton.addTarget(self, action: #selector(askQuestion), for: UIControlEvents.touchUpInside)
            
            screenButton.translatesAutoresizingMaskIntoConstraints = false
            screenButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
            screenButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
            screenButton.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
            screenButton.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
            screenButton.layoutIfNeeded()
        }
    }
    
    func askQuestion() {
        let questionVC = AskQuestionVC()
        questionVC.selectedTag = selectedItem
        navigationController?.pushViewController(questionVC, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        let backButton = PulseButton(size: .small, type: .back, isRound : true, hasBackground: true)
        backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    //once allItems var is set reload the data
    func updateDataSource() {
        collectionView?.reloadData()
        collectionView?.layoutIfNeeded()
        
        if allItems.count > 0 {
            collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
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
        
        userSelected(item : allItems[indexPath.row], index: indexPath.row)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ItemCell
        
        let currentItem = allItems[indexPath.row]

        //clear the cells and set the item type first
        cell.updateLabel(nil, _subtitle: nil, _tag: nil)
        
        //Already fetched this item
        if allItems[indexPath.row].itemCreated {
            
            cell.itemType = currentItem.type
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: currentItem.tag?.itemTitle, _image: self.allItems[indexPath.row].content as? UIImage ?? nil)
            cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage)
            
        } else {
            Database.getItem(allItems[indexPath.row].itemID, completion: { (item, error) in
                if let item = item {
                    
                    cell.itemType = item.type


                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                        DispatchQueue.main.async {
                            cell.itemType = item.type
                            cell.updateLabel(item.itemTitle, _subtitle: self.allItems[indexPath.row].user?.name ?? nil, _tag: currentItem.tag?.itemTitle)
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
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! ItemHeader
            headerView.backgroundColor = .white
            
            if let title = selectedItem.itemTitle {
                headerView.updateLabel(title.lowercased(), count: allItems.count, image: selectedItem.content as? UIImage)
            }
            
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
    }
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateCell(_ cell: ItemCell, atIndexPath indexPath: IndexPath) {
        
        if let image = allItems[indexPath.row].user?.thumbPicImage  {
            cell.updateButtonImage(image: image)
        }
        
        if allItems[indexPath.row].itemCreated {
            let currentItem = allItems[indexPath.row]
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: currentItem.tag?.itemTitle, _image: allItems[indexPath.row].content as? UIImage ?? nil)
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
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateOnscreenRows()
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { updateOnscreenRows() }
    }
    
    
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

}

extension TagCollectionVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: headerHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 0.0, bottom: 1.0, right: 0.0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellHeight = GlobalFunctions.getCellHeight(type: allItems[indexPath.row].type)

        return CGSize(width: collectionView.frame.width - 20, height: cellHeight)
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
