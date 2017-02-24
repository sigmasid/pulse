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
    public var selectedTag : Tag! {
        didSet {
            if !selectedTag.tagCreated {
                Database.getTag(selectedTag.tagID!, completion: { tag, error in
                    self.selectedTag = tag
                    self.updateHeader()
                })
            }
            else {
                allItems = selectedTag.items
                updateDataSource()
                updateHeader()
            }
        }
    }
    //end set by delegate
    
    /** main datasource var **/
    fileprivate var allItems = [Item]()
    
    fileprivate var headerNav : PulseNavVC?
    fileprivate var contentVC : ContentManagerVC!
    
    /** Collection View Vars **/
    internal let questionCellHeight : CGFloat = 125
    internal let postCellHeight : CGFloat = 300
    internal let headerHeight : CGFloat = 60
    
    fileprivate let headerReuseIdentifier = "ChannelHeader"
    fileprivate let reuseIdentifier = "ItemCell"
    
    /** Transition Vars **/
    fileprivate var initialFrame = CGRect.zero
    fileprivate var panPresentInteractionController = PanEdgeInteractionController()
    fileprivate var panDismissInteractionController = PanEdgeInteractionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
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
        
        collectionView?.backgroundColor = .white
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
        
        showItemDetail(selectedItem: allItems[indexPath.row])
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ItemCell
        
        if allItems[indexPath.row].type == nil {
            allItems[indexPath.row].type = selectedTag.type
        }
        
        let currentItem = allItems[indexPath.row]

        //clear the cells and set the item type first
        cell.updateLabel(nil, _subtitle: nil, _tag: nil)
        cell.itemType = currentItem.type
        
        //Already fetched this item
        if allItems.count > indexPath.row, allItems[indexPath.row].itemCreated {
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: currentItem.tag?.tagTitle, _image: self.allItems[indexPath.row].content as? UIImage ?? nil)
            cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage)
        } else {
            Database.getItem(allItems[indexPath.row].itemID, completion: { (item, error) in
                if let item = item {
                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                        DispatchQueue.main.async {
                            cell.updateLabel(item.itemTitle, _subtitle: self.allItems[indexPath.row].user?.name ?? nil, _tag: currentItem.tag?.tagTitle)
                        }
                    }
                    
                    item.tag = self.allItems[indexPath.row].tag
                    self.allItems[indexPath.row] = item
                    
                    //Get the cover image
                    DispatchQueue.global(qos: .background).async {
                        if let imageURL = item.contentURL, item.contentType == .recordedImage || item.contentType == .albumImage, let _imageData = try? Data(contentsOf: imageURL) {
                            self.allItems[indexPath.row].content = UIImage(data: _imageData)
                            
                            DispatchQueue.main.async {
                                if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                    cell.updateImage(image : self.allItems[indexPath.row].content as? UIImage)
                                }
                            }
                        }
                    }
                    
                    // Get the user details
                    Database.getUser(item.itemUserID, completion: {(user, error) in
                        if let user = user {
                            self.allItems[indexPath.row].user = user
                            DispatchQueue.main.async {
                                if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                    cell.updateLabel(item.itemTitle, _subtitle: user.name, _tag: currentItem.tag?.tagTitle)
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
            
            if let title = selectedTag.tagTitle {
                headerView.updateLabel("# \(title.capitalized)", count: selectedTag.items.count)
            }
            
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
    }
    
    
    internal func showItemDetail(selectedItem : Item) {
        
        Database.getItemCollection(selectedItem.itemID, completion: {(success, items) in
            if success {
                self.contentVC = ContentManagerVC()
                
                self.contentVC.selectedChannel = self.selectedChannel
                self.contentVC.selectedItem = selectedItem
                
                let type = selectedItem.type == .question ? "answer" : "post"
                self.contentVC.allItems = items.map{ val -> Item in Item(itemID: val, type: type) }
                
                self.contentVC.openingScreen = .item
                self.contentVC.transitioningDelegate = self

                DispatchQueue.main.async {
                    self.present(self.contentVC, animated: true, completion: nil)
                }
            }
        })
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
        let cellHeight = selectedTag.type == .question ? questionCellHeight : postCellHeight
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
