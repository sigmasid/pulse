//
//  TagQABrowserVCViewController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/19/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import Firebase

class SeriesVC: PulseVC, HeaderDelegate, ItemCellDelegate, BrowseContentDelegate, CompletedRecordingDelegate {
    
    //set by delegate - selected item is a collection - type questions / posts / perspectives etc. since its a series
    public var selectedChannel: Channel!
    public var selectedItem : Item! {
        didSet {
            guard selectedItem != nil else { return }
            toggleLoading(show: true, message: "loading series...", showIcon: true)
            PulseDatabase.getItemCollection(selectedItem.itemID, completion: {[weak self] (success, items) in
                guard let `self` = self else { return }
                
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
    fileprivate var hasReachedEnd = false
    
    /** Collection View Vars **/
    internal var collectionView : UICollectionView!
    
    fileprivate var isLayoutSetup = false
    fileprivate var seriesImageButton : PulseButton?
    
    private var cleanupComplete = false
    
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
        tabBarHidden = true
        updateHeader()
    }
    
    deinit {
        performCleanup()
    }
    
    private func performCleanup() {
        if !cleanupComplete {
            allItems = []
            selectedChannel = nil
            selectedItem = nil
            collectionView = nil
            isLayoutSetup = false
            isLoaded = false
            cleanupComplete = true
        }
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        addBackButton()
        updateChannelImage(channel: selectedChannel)
        headerNav?.followScrollView(collectionView, delay: 25.0)
        headerNav?.setNav(title: selectedItem.itemTitle, subtitle: selectedChannel.cTitle)
    }
    
    fileprivate func setupLayout() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        let _ = PulseFlowLayout.configureLayout(collectionView: collectionView, minimumLineSpacing: 10, itemSpacing: 10, stickyHeader: true)
        
        collectionView.register(ItemHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        collectionView.register(ItemCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        view.addSubview(collectionView)
    }
    
    /** DELEGATE FUNCTIONS **/
    override func userClosedModal(_ viewController: UIViewController) {
        dismiss(animated: true, completion: {[weak self] _ in
            guard let `self` = self else { return }
            self.removeBlurBackground()
        })
    }
    
    internal func doneRecording(success: Bool) {
        success ?
            GlobalFunctions.showAlertBlock(viewController: self,
                                           erTitle: "Feedback Request Submitted",
                                           erMessage: "Stay tuned for updates & responses from experts!", buttonTitle: "done") :
            GlobalFunctions.showAlertBlock(viewController: self,
                                           erTitle: "Error Sending Feedback Request",
                                           erMessage: "Sorry there was an error adding the feedback request. Please try again")
    }
    /** END DELEGATE FUNCTIONS **/
    
    internal func askQuestion() {
        let questionVC = AskQuestionVC()
        questionVC.selectedTag = selectedItem
        questionVC.modalDelegate = self
        
        questionVC.modalPresentationStyle = .overCurrentContext
        questionVC.modalTransitionStyle = .crossDissolve
        
        navigationController?.present(questionVC, animated: true, completion: nil)
    }
    
    internal func addInterview() {
        let interviewVC = NewInterviewVC()
        interviewVC.selectedItem = selectedItem
        interviewVC.selectedChannel = selectedChannel
        navigationController?.pushViewController(interviewVC, animated: true)
    }
    
    internal func startThread() {
        let newThread = NewThreadVC()
        newThread.delegate = self
        newThread.selectedChannel = selectedChannel
        newThread.selectedItem = selectedItem
        navigationController?.pushViewController(newThread, animated: true)
    }
    
    internal func startShowcase() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "create Showcase", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.addNewItem(selectedItem: self.selectedItem)
        }))
        
        menu.addAction(UIAlertAction(title: "invite Guests", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            let newShowcase = NewShowcaseVC()
            newShowcase.selectedChannel = self.selectedChannel
            newShowcase.selectedItem = self.selectedItem
            self.navigationController?.pushViewController(newShowcase, animated: true)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func getFeedback() {
        contentVC = ContentManagerVC()
        
        //NEEDED TO TO COPY BY VALUE VS REFERENCE
        contentVC.selectedChannel = selectedChannel
        contentVC.selectedItem = selectedItem
        contentVC.openingScreen = .camera
        contentVC.completedRecordingDelegate = self
        present(contentVC, animated: true, completion: nil)
    }
    
    internal func addNewCollection() {
        let newCollectionVC = NewCollectionVC()
        newCollectionVC.selectedChannel = selectedChannel
        newCollectionVC.selectedItem = selectedItem
        navigationController?.pushViewController(newCollectionVC, animated: true)
    }
    
    internal func addNewItem(selectedItem: Item) {
        switch selectedItem.type {
        case .collection:
            let editCollectionVC = EditCollectionVC()
            editCollectionVC.selectedChannel = selectedChannel
            editCollectionVC.selectedItem = selectedItem
            navigationController?.pushViewController(editCollectionVC, animated: true)
        default:
            contentVC = ContentManagerVC()
            contentVC.selectedChannel = selectedChannel
            contentVC.selectedItem = selectedItem
            contentVC.openingScreen = .camera
            
            contentVC.transitioningDelegate = self
            present(contentVC, animated: true, completion: nil)
        }
    }

    //once allItems var is set reload the data
    internal func updateDataSource() {
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

            PulseDatabase.getItemCollection(selectedItem.itemID, lastItem: lastItemID, completion: {[weak self] success, items in
                guard let `self` = self else { return }

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
    
    override func addTextDone(_ text: String, sender: UIView) {
        GlobalFunctions.validateEmail(text, completion: {[unowned self] (success, error) in
            if !success {
                self.showAddText(buttonText: "Send", bodyText: nil, defaultBodyText: "invalid email - try again")
            } else {
                if let selectedShareItem = self.selectedShareItem as? Item {
                    let itemKey = databaseRef.child("items").childByAutoId().key
                    let parentItemID = selectedShareItem.itemID
                    
                    selectedShareItem.itemID = itemKey
                    selectedShareItem.cID = self.selectedChannel.cID
                    selectedShareItem.cTitle = self.selectedChannel.cTitle
                    selectedShareItem.tag = self.selectedItem
                    
                    self.toggleLoading(show: true, message: "sending invite...", showIcon: true)
                    PulseDatabase.createInviteRequest(item: selectedShareItem, type: selectedShareItem.inviteType()!, toUser: nil, toName: nil, toEmail: text,
                                                      childItems: [], parentItemID: parentItemID, completion: {[weak self](success, error) in
                                                        guard let `self` = self else { return }
                                                        
                                                        success ?
                                                            GlobalFunctions.showAlertBlock(viewController: self,
                                                                                           erTitle: "Invite Sent", erMessage: "Thanks for your recommendation!", buttonTitle: "okay") :
                                                            GlobalFunctions.showAlertBlock(viewController: self,
                                                                                           erTitle: "Error Sending Request", erMessage: "Sorry there was an error sending the invite")
                                                        self.toggleLoading(show: false, message: nil)
                    })
                }
            }
        })
    }
    
    //delegate for mini user search - send the invite
    override func userSelected(item: Any) {
        guard let toUser = item as? PulseUser else {
            GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Invalid User Selected", erMessage: "Sorry! The user you selected is not valid")
            return
        }
        
        if let selectedShareItem = selectedShareItem as? Item {
            let itemKey = databaseRef.child("items").childByAutoId().key
            let parentItemID = selectedShareItem.itemID
            
            selectedShareItem.itemID = itemKey
            selectedShareItem.cID = selectedChannel.cID
            selectedShareItem.cTitle = selectedChannel.cTitle
            selectedShareItem.tag = selectedItem
            
            toggleLoading(show: true, message: "sending invite...", showIcon: true)
            PulseDatabase.createInviteRequest(item: selectedShareItem, type: selectedShareItem.inviteType()!, toUser: toUser, toName: toUser.name, childItems: [], parentItemID: parentItemID, completion: {[weak self] (success, error) in
                guard let `self` = self else { return }
                
                success ?
                    GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Invite Sent", erMessage: "Thanks for your recommendation!", buttonTitle: "okay") :
                    GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Error Sending Request", erMessage: "Sorry there was an error sending the invite")
                self.toggleLoading(show: false, message: nil)
            })
        }
    }
}

extension SeriesVC : UICollectionViewDelegate, UICollectionViewDataSource {
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
        let _title = currentItem.itemDescription != "" ? "\(currentItem.itemTitle) - \(currentItem.itemDescription)" : currentItem.itemTitle
        cell.updateLabel(_title, _subtitle: currentItem.user?.name, _createdAt: currentItem.createdAt, _tag: nil)
        
        //Already fetched this item
        if allItems[indexPath.row].itemCreated {
            let _title = currentItem.itemDescription != "" ? "\(currentItem.itemTitle) - \(currentItem.itemDescription)" : currentItem.itemTitle

            cell.itemType = currentItem.type
            cell.updateCell(_title, _subtitle: currentItem.user?.name, _tag: nil, _createdAt: currentItem.createdAt, _image: allItems[indexPath.row].content ?? nil)
            
            PulseDatabase.getCachedUserPic(uid: currentItem.itemUserID, completion: { image in
                DispatchQueue.main.async {
                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                        cell.updateButtonImage(image: image, itemTag : indexPath.row)
                    }
                }
            })
            
        } else {
            PulseDatabase.getItem(allItems[indexPath.row].itemID, completion: {[weak self] (item, error) in
                guard let `self` = self else { return }

                if let item = item {
                    let _title = item.itemDescription != "" ? "\(item.itemTitle) - \(item.itemDescription)" : item.itemTitle

                    cell.itemType = item.type

                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                        DispatchQueue.main.async {
                            let _title = item.itemDescription != "" ? "\(item.itemTitle) - \(item.itemDescription)" : item.itemTitle

                            cell.itemType = item.type
                            cell.updateLabel(_title, _subtitle: self.allItems[indexPath.row].user?.name ?? nil,  _createdAt: item.createdAt, _tag: nil)
                        }
                    }
                    
                    item.tag = self.allItems[indexPath.row].tag
                    self.allItems[indexPath.row] = item
                    
                    PulseDatabase.getCachedUserPic(uid: item.itemUserID, completion: { image in
                        DispatchQueue.main.async {
                            if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                cell.updateButtonImage(image: image, itemTag : indexPath.row)
                            }
                        }
                    })
                    
                    //Get the image if content type is a post or perspectives thread
                    if item.content == nil, item.shouldGetImage(), !item.fetchedContent {
                        PulseDatabase.getImage(channelID: self.selectedChannel.cID, itemID: currentItem.itemID, fileType: .content, maxImgSize: MAX_IMAGE_FILESIZE, completion: {[weak self] (data, error) in
                            guard let `self` = self else { return }
                            if let data = data {
                                self.allItems[indexPath.row].content = UIImage(data: data)
                                
                                DispatchQueue.main.async {
                                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                        cell.updateImage(image : self.allItems[indexPath.row].content)
                                    }
                                }
                            }
                            
                            self.allItems[indexPath.row].fetchedContent = true
                        })
                    }
                    
                    // Get the user details
                    PulseDatabase.getUser(item.itemUserID, completion: {[weak self] (user, error) in
                        guard let `self` = self else { return }

                        if let user = user {
                            self.allItems[indexPath.row].user = user
                            
                            DispatchQueue.main.async {
                                if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                    cell.updateLabel(_title, _subtitle: user.name,  _createdAt: item.createdAt, _tag: nil)
                                }
                            }
                        }
                    })
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
            headerView.updateLabel("# \(selectedItem.itemTitle.lowercased())")
            
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
        return UICollectionReusableView()
    }
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateCell(_ cell: ItemCell, atIndexPath indexPath: IndexPath) {
        if allItems[indexPath.row].itemCreated {
            let currentItem = allItems[indexPath.row]
            let _title = allItems[indexPath.row].itemDescription != "" ? "\(allItems[indexPath.row].itemTitle) - \(allItems[indexPath.row].itemDescription)" : allItems[indexPath.row].itemTitle

            cell.updateCell(_title, _subtitle: currentItem.user?.name, _tag: nil, _createdAt: currentItem.createdAt, _image: allItems[indexPath.row].content ?? nil)
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
}

extension SeriesVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: skinnyHeaderHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: Spacing.xs.rawValue, right: 0.0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellHeight = GlobalFunctions.getCellHeight(type: allItems[indexPath.row].type)

        return CGSize(width: collectionView.frame.width, height: cellHeight)
    }
}

//menus
extension SeriesVC {
    //for collection view items
    internal func userSelected(item : Item, index : Int) {
        
        item.tag = selectedItem //since we are in tagVC
        item.cID = selectedChannel.cID
        item.cTitle = selectedChannel.cTitle
        
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [AnalyticsParameterContentType: item.type.rawValue as NSObject,
                                                                     AnalyticsParameterItemID: "\(item.itemID)" as NSObject])
        
        //can only be a question or a post that user selects since it's in a tag already
        switch item.type {
        case .post, .showcase:
            showItemDetail(allItems: allItems, index: index, itemCollection: [], selectedItem: selectedItem)
            
        case .interview:
            toggleLoading(show: true, message: "loading \(item.type.rawValue)...")
            PulseDatabase.getItemCollection(item.itemID, completion: {[weak self](success, items) in
                guard let `self` = self else {
                    return
                }
                
                success ? self.showItemDetail(allItems: items.reversed(), index: 0, itemCollection: [], selectedItem: item) : self.showNoItemsMenu(selectedItem : item)
                self.toggleLoading(show: false, message: nil)
            })
            
        case .question, .thread:
            toggleLoading(show: true, message: "loading \(item.type.rawValue)...")
            PulseDatabase.getItemCollection(item.itemID, completion: {[weak self](success, items) in
                guard let `self` = self else {
                    return
                }
                
                success ? self.showItemDetail(allItems: items, index: 0, itemCollection: [], selectedItem: item) : self.showNoItemsMenu(selectedItem : item)
                self.toggleLoading(show: false, message: nil)
            })
            
        case .session:
            toggleLoading(show: true, message: "loading \(item.type.rawValue)...")
            PulseDatabase.getItemCollection(item.itemID, completion: {[weak self] (success, items) in
                guard let `self` = self else {
                    return
                }
                
                self.toggleLoading(show: false, message: nil)
                if success, items.count > 1 {
                    //since ordering is cron based - move the first 'question' item to front
                    if let lastItem = items.last {
                        let sessionSlice = items.dropLast()
                        var sessionItems = Array(sessionSlice)
                        sessionItems.insert(lastItem, at: 0)
                        self.showItemDetail(allItems: sessionItems, index: 0, itemCollection: [], selectedItem: item)
                    }
                } else if success {
                    self.showItemDetail(allItems: [item], index: 0, itemCollection: [], selectedItem: item)
                } else {
                    //show no items menu
                    self.showNoItemsMenu(selectedItem : item)
                }
            })
            
        case .collection:
            
            let browseCollectionVC = BrowseCollectionVC()
            browseCollectionVC.selectedChannel = selectedChannel
            
            navigationController?.pushViewController(browseCollectionVC, animated: true)
            browseCollectionVC.selectedItem = item
            
        default: break
        }
    }
    
    
    internal func showBrowse(selectedItem: Item) {
        selectedItem.cID = selectedChannel.cID
        selectedItem.cTitle = selectedChannel.cTitle
        
        switch selectedItem.type {
        case .collection:
            let browseCollectionVC = BrowseCollectionVC()
            browseCollectionVC.selectedChannel = Channel(cID: selectedItem.cID, title: selectedItem.cTitle)
            
            navigationController?.pushViewController(browseCollectionVC, animated: true)
            browseCollectionVC.selectedItem = selectedItem
            
        default:
            let itemCollection = BrowseContentVC()
            itemCollection.selectedChannel = selectedChannel
            itemCollection.selectedItem = selectedItem
            itemCollection.contentDelegate = self
            itemCollection.forSingleUser = selectedItem.type == .interview ? true : false
            
            navigationController?.pushViewController(itemCollection, animated: true)
        }
    }
    
    internal func showItemDetail(allItems: [Item], index: Int, itemCollection: [Item], selectedItem : Item) {
        contentVC = ContentManagerVC()
        
        contentVC.selectedChannel = selectedChannel
        contentVC.selectedItem = selectedItem
        contentVC.itemCollection = itemCollection
        contentVC.itemIndex = index
        contentVC.allItems = allItems
        contentVC.openingScreen = .item
        
        contentVC.transitioningDelegate = self
        present(contentVC, animated: true, completion: nil)
    }
    
    internal func userClosedBrowse(_ viewController : UIViewController) {
        dismiss(animated: true, completion: { _ in })
    }
    
    internal func aboutSeries() {
        /* BLUR BACKGROUND & DISABLE TAP WHEN MINI PROFILE IS SHOWING */
        blurViewBackground()
        
        PulseDatabase.getItem(selectedItem.itemID, completion: {[weak self] (item, error) in
            if let item = item, let `self` = self {
                
                PulseDatabase.getCachedSeriesImage(channelID: self.selectedChannel.cID, itemID: self.selectedItem.itemID,
                                                   fileType: .thumb, completion: {[weak self] image in
                                                    
                    guard let `self` = self else { return }
                    
                    let seriesPreview = PMAlertController(title: item.itemTitle, description: item.itemDescription, image: image, style: .alert)
                    
                    seriesPreview.dismissWithBackgroudTouch = true
                    seriesPreview.modalDelegate = self
                    
                    seriesPreview.addAction(PMAlertAction(title: "Become Contributor", style: .cancel, action: {[weak self] () -> Void in
                        guard let `self` = self else { return }
                        self.userClickedBecomeContributor()
                        self.removeBlurBackground()
                    }))
                    
                    DispatchQueue.main.async {
                        self.present(seriesPreview, animated: true, completion: nil)
                    }
                })
                
                
            }
        })
    }
    
    internal func userClickedBecomeContributor() {
        removeBlurBackground()
        
        let becomeContributorVC = BecomeContributorVC()
        becomeContributorVC.selectedChannel = selectedChannel
        
        navigationController?.pushViewController(becomeContributorVC, animated: true)
    }

    
    /** ItemCellDelegate Methods **/
    internal func clickedUserButton(itemRow : Int) {
        if let user = allItems[itemRow].user {
            let userProfileVC = UserProfileVC()
            navigationController?.pushViewController(userProfileVC, animated: true)
            userProfileVC.selectedUser = user
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [AnalyticsParameterContentType: "user_profile" as NSObject,
                                                                         AnalyticsParameterItemID: "\(user.uID!)" as NSObject])
        }
    }
    
    //menu for each individual item
    internal func clickedMenuButton(itemRow: Int) {
        let currentItem = allItems[itemRow]
        currentItem.tag = selectedItem
        currentItem.cID = selectedChannel.cID
        currentItem.cTitle = selectedChannel.cTitle
        
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        currentItem.checkVerifiedInput(completion: {[weak self] success, error in
            guard let `self` = self else { return }

            if success {
                menu.addAction(UIAlertAction(title: "\(currentItem.childActionType())\(currentItem.childType().capitalized)", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                    guard let `self` = self else { return }
                    self.addNewItem(selectedItem: currentItem)
                }))
                
                if let inviteType = currentItem.inviteType() {
                    menu.addAction(UIAlertAction(title: "invite Guests", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                        guard let `self` = self else { return }
                        
                        self.showInviteMenu(currentItem: currentItem,
                                            inviteTitle: "Invite Guests",
                                            inviteMessage: "know an expert who can \(currentItem.childActionType())\(currentItem.childType())?\nInvite them below!",
                                            inviteType: inviteType)
                    }))
                }
            }
        })
        
        if currentItem.childItemType() != .unknown {
            menu.addAction(UIAlertAction(title: " browse\(currentItem.childType(plural: true).capitalized)", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                guard let `self` = self else { return }
                self.showBrowse(selectedItem: currentItem)
            }))
        }
        
        menu.addAction(UIAlertAction(title: "share \(currentItem.type.rawValue.capitalized)", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.showShare(selectedItem: currentItem, type: currentItem.type.rawValue)
        }))
        
        menu.addAction(UIAlertAction(title: "report This", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            
            menu.dismiss(animated: true, completion: nil)
            self.reportContent(item: currentItem)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }

    //user clicked header menu - for series
    func clickedHeaderMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "about Series", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.aboutSeries()
        }))
        
        selectedItem.checkVerifiedInput(completion: {[weak self] success, error in
            guard let `self` = self else { return }
            if success {
                menu.addAction(UIAlertAction(title: "\(self.selectedItem.childActionType())\(self.selectedItem.childType().capitalized)", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                    guard let `self` = self else { return }
                    
                    switch self.selectedItem.type {
                    case .interviews:
                        self.addInterview()
                    case .perspectives:
                        self.startThread()
                    case .questions:
                        self.askQuestion()
                    case .feedback:
                        self.getFeedback()
                    case .posts:
                        self.addNewItem(selectedItem: self.selectedItem)
                    case .collections:
                        self.addNewCollection()
                    case .showcases:
                        menu.dismiss(animated: false, completion: nil)
                        self.startShowcase()
                    default: break
                    }
                }))
            }
        })
        
        menu.addAction(UIAlertAction(title: "share Series", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.toggleLoading(show: true, message: "loading share options...", showIcon: true)

            self.selectedItem.createShareLink(completion: {[unowned self] link in
                guard let link = link else { return }
                self.shareContent(shareType: "series", shareText: self.selectedItem.itemTitle.capitalized, shareLink: link)
            })            
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    //no items yet - so prompt user if accepts input and requires verifiecation
    internal func showNoItemsMenu(selectedItem : Item) {
        let menu = UIAlertController(title: "Sorry! No\(selectedItem.childType(plural: true)) yet", message: nil, preferredStyle: .actionSheet)

        selectedItem.checkVerifiedInput(completion: {[weak self] success, error in
            guard let `self` = self else { return }

            if success {
                menu.message = "No\(selectedItem.childType())s yet - want to add one?"
                
                menu.addAction(UIAlertAction(title: "\(selectedItem.childActionType())\(selectedItem.childType().capitalized)", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                    guard let `self` = self else { return }
                    self.addNewItem(selectedItem: selectedItem)
                }))

            } else {
                menu.message = "We are still waiting for \(selectedItem.childType())!"
            }
            
            menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                menu.dismiss(animated: true, completion: nil)
            }))
            
            DispatchQueue.main.async {
                self.present(menu, animated: true, completion: nil)
            }
        })
    }
    
    //NOT BEING USED - CAN USE LATER TO EXPAND WHO CAN ANSWER > PROB WANT TO PUT IN A SEPARATE BUCKET
    internal func showNonContributorMenu(selectedItem : Item) {
        let menu = UIAlertController(title: "Become a Contributor?", message: "looks like you are not yet a verified contributor. To ensure quality, we recommend getting verified. You can continue with your submission (might be reviewed for quality).", preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "continue Submission", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.addNewItem(selectedItem: selectedItem)
        }))
        
        menu.addAction(UIAlertAction(title: "become a Contributor", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            let becomeContributorVC = BecomeContributorVC()
            becomeContributorVC.selectedChannel = self.selectedChannel
            
            self.navigationController?.pushViewController(becomeContributorVC, animated: true)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
}
