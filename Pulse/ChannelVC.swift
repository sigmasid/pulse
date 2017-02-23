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
    func userSelected(tag : Tag)
}

class ChannelVC: UIViewController, ChannelDelegate {
    //set by delegate
    public var selectedChannel : Channel! {
        didSet {
            isFollowingSelectedChannel = User.currentUser?.savedTags != nil && User.currentUser!.savedTagIDs.contains(selectedChannel.cID!) ? true : false

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

    fileprivate var toggleFollowButton = PulseButton(size: .medium, type: .addCircle, isRound : true, hasBackground: false, tint: .black)
    fileprivate var isFollowingSelectedChannel : Bool = false {
        didSet {
            isFollowingSelectedChannel ?
                toggleFollowButton.setImage(UIImage(named: "remove-circle")?.withRenderingMode(.alwaysTemplate), for: UIControlState()) :
                toggleFollowButton.setImage(UIImage(named: "add-circle")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        }
    }
    
    fileprivate var allItems = [Item]()
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
    
    //Update Nav Header
    fileprivate func updateHeader() {
        let backButton = PulseButton(size: .small, type: .back, isRound : true, hasBackground: true)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: toggleFollowButton)

        if let nav = headerNav {
            nav.setNav(title: selectedChannel.cTitle ?? "Explore Channel")
            nav.updateBackgroundImage(image: selectedChannel.cPreviewImage)
            backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
            //toggleFollowButton.addTarget(self, action: #selector(), for: UIControlEvents.touchUpInside)
        } else {
            title = selectedChannel.cTitle ?? "Explore Channel"
        }
    }
    
    /**
    internal func follow() {
        Database.pinTagForUser(selectedTag, completion: {(success, error) in
            if !success {
                GlobalFunctions.showErrorBlock("Error Saving Tag", erMessage: error!.localizedDescription)
            } else {
                self.isFollowingSelectedTag = self.isFollowingSelectedTag ? false : true
            }
        })
    }**/
    
    internal func userSelected(user: User) {
        let userProfileVC = UserProfileVC()
        navigationController?.pushViewController(userProfileVC, animated: true)
        userProfileVC.selectedUser = user
    }
    
    internal func userSelected(tag: Tag) {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionHeadersPinToVisibleBounds = true
        
        let tagDetailVC = TagCollectionVC(collectionViewLayout: layout)
        tagDetailVC.selectedChannel = selectedChannel
        tagDetailVC.selectedTag = tag
        navigationController?.pushViewController(tagDetailVC, animated: true)
    }
    
    fileprivate func setupScreenLayout() {
        if !isLayoutSetup {
            let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
            layout.scrollDirection = UICollectionViewScrollDirection.vertical
            layout.minimumLineSpacing = 10
            layout.minimumInteritemSpacing = 10

            channel = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
            channel?.register(ItemCell.self, forCellWithReuseIdentifier: reuseIdentifier)
            channel?.register(ChannelHeaderTags.self,
                                            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader ,
                                            withReuseIdentifier: headerReuseIdentifier)
            //channel?.register(ChannelHeader.self,
            //                  forSupplementaryViewOfKind: UICollectionElementKindSectionHeader ,
            //                  withReuseIdentifier: headerReuseIdentifier)
            
            view.addSubview(channel!)
            
            channel.translatesAutoresizingMaskIntoConstraints = false
            channel.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            channel.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            channel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            channel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            channel.layoutIfNeeded()
            
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
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateCell(_ cell: ItemCell, inCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
        if allItems.count > indexPath.row, allItems[indexPath.row].itemCreated {
            let currentItem = allItems[indexPath.row]
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: currentItem.tag?.tagTitle, _image: allItems[indexPath.row].content as? UIImage ?? nil)
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
        showItem(selectedItem)
    }
    
    func showItem(_ item : Item) {
        contentVC = ContentManagerVC()
        
        switch item.type! {
        case .answer:
            showItemDetail(allItems: [item], itemCollection: [], selectedItem: item, watchedPreview: false)

        case .post:
            Database.getItemCollection(item.itemID, completion: {(success, items) in
                if success, let _items = items {
                    self.showItemDetail(allItems: [item], itemCollection: _items, selectedItem: item, watchedPreview: true)
                } else {
                    print("no posts found")
                }
            })
            
        case .question:
            
            Database.getItemCollection(item.itemID, completion: {(success, items) in
                if success, let _items = items {
                    self.showItemDetail(allItems: [item], itemCollection: [], selectedItem: item, watchedPreview: true)
                } else {
                    print("no posts found")
                }
            })
            // new question was added so go to question browser
            
            let selectedQuestion = Question(qID: item.itemID)
            selectedQuestion.qTitle = item.itemTitle
            selectedQuestion.uID = item.itemUserID
            
            showQuestion(selectedQuestion: selectedQuestion)
            
        default: break
        }
    }
    
    internal func showItemDetail(allItems: [Item], itemCollection: [String], selectedItem : Item, watchedPreview : Bool) {
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
    
    internal func showQuestion(selectedQuestion: Question) {

        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionHeadersPinToVisibleBounds = true
        
        let answersCollection = AnswersCollectionVC(collectionViewLayout: layout)
        answersCollection.selectedQuestion = selectedQuestion
        
        if selectedQuestion.qCreated {
            answersCollection.allItems = selectedQuestion.qItems
        }
        
        navigationController?.pushViewController(answersCollection, animated: true)
    }
    
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    

    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! ChannelHeaderTags
            headerView.backgroundColor = .white
            headerView.tags = selectedChannel.tags
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
        let cellHeight = allItems[indexPath.row].type == .question || allItems[indexPath.row].type == .answer ? questionCellHeight : postCellHeight
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
