//
//  TagQABrowserVCViewController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/19/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class SeriesVC: PulseVC, HeaderDelegate, ItemCellDelegate, ModalDelegate, BrowseContentDelegate, SelectionDelegate, ParentTextViewDelegate, ItemPreviewDelegate, CompletedRecordingDelegate {
    
    public var selectedChannel: Channel!
    
    //set by delegate - is of type questions / posts / perspectives etc. since its a series
    public var selectedItem : Item! {
        didSet {
            toggleLoading(show: true, message: "Loading Series...", showIcon: true)
            PulseDatabase.getItemCollection(selectedItem.itemID, completion: {(success, items) in
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
    fileprivate var allUsers = [PulseUser]() //caches user image / user for reuse
    fileprivate var hasReachedEnd = false
    
    /** Card to show the mini info of item **/
    fileprivate var miniPreview : MiniPreview?
    
    /** Collection View Vars **/
    internal var collectionView : UICollectionView!
    
    fileprivate var isLayoutSetup = false
    fileprivate var selectedShareItem : Item?

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
        headerNav?.setNav(title: selectedItem.itemTitle, subtitle: selectedChannel.cTitle)
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
        dismiss(animated: true, completion: { _ in })
    }
    
    internal func doneRecording(success: Bool) {
        success ?
            GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Feedback Request Submitted", erMessage: "Stay tuned for updates & responses from experts!", buttonTitle: "done") :
            GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Error Sending Feedback Request", erMessage: "Sorry there was an error adding the feedback request. Please try again")
    }
    

    
    internal func askQuestion() {
        let questionVC = AskQuestionVC()
        questionVC.selectedTag = selectedItem
        questionVC.modalDelegate = self
        
        questionVC.modalPresentationStyle = .overCurrentContext
        questionVC.modalTransitionStyle = .crossDissolve
        
        self.navigationController?.present(questionVC, animated: true, completion: nil)
    }
    
    internal func addInterview() {
        let interviewVC = NewInterviewVC()
        interviewVC.selectedItem = selectedItem
        interviewVC.selectedChannel = selectedChannel
        navigationController?.pushViewController(interviewVC, animated: true)
    }
    
    internal func startThread() {
        let newThread = NewThreadVC()
        newThread.selectedChannel = selectedChannel
        newThread.selectedItem = selectedItem
        navigationController?.pushViewController(newThread, animated: true)
    }
    
    internal func startShowcase() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "create Showcase", style: .default, handler: { (action: UIAlertAction!) in
            self.addNewItem(selectedItem: self.selectedItem)
        }))
        
        menu.addAction(UIAlertAction(title: "invite Guests", style: .default, handler: { (action: UIAlertAction!) in
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
        let contentVC = ContentManagerVC()
        
        //NEEDED TO TO COPY BY VALUE VS REFERENCE
        contentVC.selectedChannel = selectedChannel
        contentVC.selectedItem = selectedItem
        contentVC.openingScreen = .camera
        contentVC.completedRecordingDelegate = self
        present(contentVC, animated: true, completion: nil)
    }
    
    internal func addNewItem(selectedItem: Item) {
        contentVC = ContentManagerVC()
        contentVC.selectedChannel = selectedChannel
        contentVC.selectedItem = selectedItem
        contentVC.openingScreen = .camera
        
        contentVC.transitioningDelegate = self
        present(contentVC, animated: true, completion: nil)
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

            PulseDatabase.getItemCollection(selectedItem.itemID, lastItem: lastItemID, completion: { success, items in
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
    
    internal func showAddEmail(bodyText: String) {
        addText = AddText(frame: view.bounds, buttonText: "Send",
                           bodyText: bodyText, keyboardType: .emailAddress)
        
        addText.delegate = self
        view.addSubview(addText)
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
        cell.updateLabel(currentItem.itemTitle != "" ? currentItem.itemTitle : "",
                         _subtitle: currentItem.user?.name, _createdAt: currentItem.createdAt, _tag: nil)
        cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)

        //Already fetched this item
        if allItems[indexPath.row].itemCreated {
            cell.itemType = currentItem.type
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: nil, _createdAt: currentItem.createdAt, _image: self.allItems[indexPath.row].content as? UIImage ?? nil)
            cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)
            
        } else {
            PulseDatabase.getItem(allItems[indexPath.row].itemID, completion: { (item, error) in
                if let item = item {
                    
                    cell.itemType = item.type

                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                        DispatchQueue.main.async {
                            cell.itemType = item.type
                            cell.updateLabel(item.itemTitle, _subtitle: self.allItems[indexPath.row].user?.name ?? nil,  _createdAt: item.createdAt, _tag: nil)
                        }
                    }
                    
                    item.tag = self.allItems[indexPath.row].tag
                    self.allItems[indexPath.row] = item
                    
                    //Get the image if content type is a post or perspectives thread
                    if item.content == nil, item.shouldGetImage(), !item.fetchedContent {
                        PulseDatabase.getImage(channelID: self.selectedChannel.cID, itemID: currentItem.itemID, fileType: .thumb, maxImgSize: maxImgSize, completion: { (data, error) in
                            if let data = data {
                                self.allItems[indexPath.row].content = UIImage(data: data)
                                
                                DispatchQueue.main.async {
                                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                        cell.updateImage(image : self.allItems[indexPath.row].content as? UIImage)
                                    }
                                }
                            }
                            
                            self.allItems[indexPath.row].fetchedContent = true
                        })
                    }
                    
                    // Get the user details
                    if let user = self.checkUserDownloaded(user: PulseUser(uID: item.itemUserID)) {
                        self.allItems[indexPath.row].user = user
                        cell.updateLabel(currentItem.itemTitle, _subtitle: user.name, _createdAt: currentItem.createdAt, _tag: nil)
                        
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
                        PulseDatabase.getUser(item.itemUserID, completion: {(user, error) in
                            if let user = user {
                                self.allItems[indexPath.row].user = user
                                self.allUsers.append(user)
                                
                                DispatchQueue.main.async {
                                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                        cell.updateLabel(item.itemTitle, _subtitle: user.name,  _createdAt: item.createdAt, _tag: nil)
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
            headerView.updateLabel("# \(selectedItem.itemTitle.lowercased())")
            
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
        return UICollectionReusableView()
    }
    
    //Find the index of downloaded user and return that user
    func checkUserDownloaded(user: PulseUser) -> PulseUser? {
        if let index = allUsers.index(of: user) {
            return allUsers[index]
        }
        return nil
    }
    
    //Add user downloaded image for a newly downloaded user
    func updateUserImageDownloaded(user: PulseUser, thumbPicImage : UIImage?) {
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
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: nil, _createdAt: currentItem.createdAt, _image: allItems[indexPath.row].content as? UIImage ?? nil)
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
    
    //parent text view delegate
    internal func dismiss(_ view : UIView) {
        view.removeFromSuperview()
    }
    
    internal func buttonClicked(_ text: String, sender: UIView) {
        GlobalFunctions.validateEmail(text, completion: {(success, error) in
            if !success {
                self.showAddEmail(bodyText: "invalid email - try again")
            } else {
                if let selectedShareItem = selectedShareItem {
                    let itemKey = databaseRef.child("items").childByAutoId().key
                    let parentItemID = selectedShareItem.itemID
                    
                    selectedShareItem.itemID = itemKey
                    selectedShareItem.cID = selectedChannel.cID
                    selectedShareItem.cTitle = selectedChannel.cTitle
                    selectedShareItem.tag = selectedItem
                    
                    toggleLoading(show: true, message: "sending invite...", showIcon: true)
                    PulseDatabase.createInviteRequest(item: selectedShareItem, type: selectedShareItem.inviteType()!, toUser: nil, toName: nil, toEmail: text,
                                                 childItems: [], parentItemID: parentItemID, completion: {(success, error) in
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
    internal func userSelected(item: Any) {
        guard let toUser = item as? PulseUser else {
            GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Invalid User Selected", erMessage: "Sorry! The user you selected is not valid")
            return
        }
        
        if let selectedShareItem = selectedShareItem {
            let itemKey = databaseRef.child("items").childByAutoId().key
            let parentItemID = selectedShareItem.itemID
            
            selectedShareItem.itemID = itemKey
            selectedShareItem.cID = selectedChannel.cID
            selectedShareItem.cTitle = selectedChannel.cTitle
            selectedShareItem.tag = selectedItem
            
            toggleLoading(show: true, message: "sending invite...", showIcon: true)
            PulseDatabase.createInviteRequest(item: selectedShareItem, type: selectedShareItem.inviteType()!, toUser: toUser, toName: toUser.name, childItems: [], parentItemID: parentItemID, completion: {(success, error) in
                success ?
                    GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Invite Sent", erMessage: "Thanks for your recommendation!", buttonTitle: "okay") :
                    GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Error Sending Request", erMessage: "Sorry there was an error sending the invite")
                self.toggleLoading(show: false, message: nil)
            })
        }
    }
    
    //for collection view items
    internal func userSelected(item : Item, index : Int) {
        
        item.tag = selectedItem //since we are in tagVC
        
        //can only be a question or a post that user selects since it's in a tag already
        switch item.type {
        case .post, .showcase:
            showItemDetail(allItems: self.allItems, index: index, itemCollection: [], selectedItem: selectedItem, watchedPreview: false)
        case .question, .thread, .interview:
            toggleLoading(show: true, message: "loading \(item.type.rawValue)...")
            PulseDatabase.getItemCollection(item.itemID, completion: {(success, items) in
                success ? self.showItemDetail(allItems: items, index: 0, itemCollection: [], selectedItem: item, watchedPreview: false) : self.showNoItemsMenu(selectedItem : item)
                self.toggleLoading(show: false, message: nil)
            })
        case .session:
            toggleLoading(show: true, message: "loading \(item.type.rawValue)...")
            PulseDatabase.getItemCollection(item.itemID, completion: {(success, items) in
                self.toggleLoading(show: false, message: nil)
                if success, items.count > 1 {
                    //since ordering is cron based - move the first 'question' item to front
                    if let lastItem = items.last {
                        let sessionSlice = items.dropLast()
                        var sessionItems = Array(sessionSlice)
                        sessionItems.insert(lastItem, at: 0)
                        self.showItemDetail(allItems: sessionItems, index: 0, itemCollection: [], selectedItem: item, watchedPreview: false)
                    }
                } else if success {
                    self.showItemDetail(allItems: [item], index: 0, itemCollection: [], selectedItem: item, watchedPreview: false)
                } else {
                    //show no items menu
                    self.showNoItemsMenu(selectedItem : item)
                }
            })
        default: break
        }
    }
    
    
    internal func showBrowse(selectedItem: Item) {
        selectedItem.cID = selectedChannel.cID
        
        let itemCollection = BrowseContentVC()
        itemCollection.selectedChannel = selectedChannel
        itemCollection.selectedItem = selectedItem
        itemCollection.contentDelegate = self
        itemCollection.forSingleUser = selectedItem.type == .interview ? true : false
        navigationController?.pushViewController(itemCollection, animated: true)
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
    
    internal func userClosedBrowse(_ viewController : UIViewController) {
        dismiss(animated: true, completion: { _ in })
    }
    
    internal func aboutSeries() {
        let _profileFrame = CGRect(x: view.bounds.width * (1/5), y: view.bounds.height * (1/4), width: view.bounds.width * (3/5), height: view.bounds.height * (1/2))
        
        /* BLUR BACKGROUND & DISABLE TAP WHEN MINI PROFILE IS SHOWING */
        blurViewBackground()
    
        miniPreview = MiniPreview(frame: _profileFrame, buttonTitle: "Become Contributor")
        miniPreview!.delegate = self

        PulseDatabase.getItem(selectedItem.itemID, completion: { (item, error) in
            if let item = item {
                self.miniPreview!.setTitleLabel(item.itemTitle)
                self.miniPreview!.setMiniDescriptionLabel(item.itemDescription)
                self.miniPreview!.setBackgroundImage(self.selectedItem.content as? UIImage ?? GlobalFunctions.imageWithColor(UIColor.black))
                
                self.selectedItem.itemDescription = item.itemDescription
            
                DispatchQueue.main.async {
                    self.view.addSubview(self.miniPreview!)
                }
            }
        })
    }
    
    /** Item Preview Delegate **/
    internal func userClosedPreview(_ preview : UIView) {
        preview.removeFromSuperview()
        removeBlurBackground()
    }
    
    internal func userClickedButton() {
        miniPreview!.removeFromSuperview()
        removeBlurBackground()
        
        let becomeContributorVC = BecomeContributorVC()
        becomeContributorVC.selectedChannel = self.selectedChannel
        
        self.navigationController?.pushViewController(becomeContributorVC, animated: true)
    }

    
    /** ItemCellDelegate Methods **/
    internal func clickedUserButton(itemRow : Int) {
        if let user = allItems[itemRow].user {
            let userProfileVC = UserProfileVC()
            navigationController?.pushViewController(userProfileVC, animated: true)
            userProfileVC.selectedUser = user
        }
    }
    
    //menu for each individual item
    internal func clickedMenuButton(itemRow: Int) {
        let currentItem = allItems[itemRow]
        currentItem.tag = selectedItem
        
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        currentItem.checkVerifiedInput(completion: { success, error in
            if success {
                menu.addAction(UIAlertAction(title: "\(currentItem.childActionType())\(currentItem.childType().capitalized)", style: .default, handler: { (action: UIAlertAction!) in
                    self.addNewItem(selectedItem: currentItem)
                }))
            
                menu.addAction(UIAlertAction(title: "invite Guests", style: .default, handler: { (action: UIAlertAction!) in
                    self.showInviteMenu(currentItem: currentItem)
                }))
            }
        })
        
        if currentItem.childItemType() != .unknown {
            menu.addAction(UIAlertAction(title: " browse\(currentItem.childType(plural: true).capitalized)", style: .default, handler: { (action: UIAlertAction!) in
                self.showBrowse(selectedItem: currentItem)
            }))
        }
        
        menu.addAction(UIAlertAction(title: "share \(currentItem.type.rawValue.capitalized)", style: .default, handler: { (action: UIAlertAction!) in
            self.showShare(selectedItem: currentItem, type: currentItem.type.rawValue)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }

    //user clicked header menu - for series
    func clickedHeaderMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "about Series", style: .default, handler: { (action: UIAlertAction!) in
            self.aboutSeries()
        }))
        
        selectedItem.checkVerifiedInput(completion: { success, error in
            if success {
                menu.addAction(UIAlertAction(title: "\(self.selectedItem.childActionType())\(self.selectedItem.childType().capitalized)", style: .default, handler: { (action: UIAlertAction!) in
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
                    case .showcases:
                        menu.dismiss(animated: false, completion: nil)
                        self.startShowcase()
                    default: break
                    }
                }))
            }
        })
        
        menu.addAction(UIAlertAction(title: "share Series", style: .default, handler: { (action: UIAlertAction!) in
            self.showShare(selectedItem: self.selectedItem, type: "series", fullShareText: self.selectedItem.itemTitle)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    //no items yet - so prompt user if accepts input and requires verifiecation
    internal func showNoItemsMenu(selectedItem : Item) {
        let menu = UIAlertController(title: "Sorry! No\(selectedItem.childType(plural: true)) yet", message: nil, preferredStyle: .actionSheet)

        selectedItem.checkVerifiedInput(completion: { success, error in
            if success {
                menu.message = "No\(selectedItem.childType())s yet - want to be the first?"
                
                menu.addAction(UIAlertAction(title: "\(self.selectedItem.childActionType())\(self.selectedItem.childType().capitalized)", style: .default, handler: { (action: UIAlertAction!) in
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
                    case .showcases:
                        self.startShowcase()
                    default: break
                    }
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
        
        menu.addAction(UIAlertAction(title: "continue Submission", style: .default, handler: { (action: UIAlertAction!) in
            self.addNewItem(selectedItem: selectedItem)
        }))
        
        menu.addAction(UIAlertAction(title: "become a Contributor", style: .default, handler: { (action: UIAlertAction!) in
            let becomeContributorVC = BecomeContributorVC()
            becomeContributorVC.selectedChannel = self.selectedChannel
            
            self.navigationController?.pushViewController(becomeContributorVC, animated: true)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showInviteMenu(currentItem : Item) {
        let menu = UIAlertController(title: "Invite Guests", message: "know someone who is an expert? Invite them below", preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "invite Pulse Users", style: .default, handler: { (action: UIAlertAction!) in
            self.selectedShareItem = currentItem
            
            let browseUsers = MiniUserSearchVC()
            browseUsers.modalPresentationStyle = .overCurrentContext
            browseUsers.modalTransitionStyle = .crossDissolve
            
            browseUsers.modalDelegate = self
            browseUsers.selectionDelegate = self
            browseUsers.selectedChannel = self.selectedChannel
            self.navigationController?.present(browseUsers, animated: true, completion: nil)
        }))
        
        menu.addAction(UIAlertAction(title: "invite via Email", style: .default, handler: { (action: UIAlertAction!) in
            self.selectedShareItem = currentItem
            self.showAddEmail(bodyText: "enter email")
        }))
        
        menu.addAction(UIAlertAction(title: "more invite Options", style: .default, handler: { (action: UIAlertAction!) in
            self.createShareRequest(selectedShareItem: currentItem, shareType: currentItem.inviteType(), selectedChannel: self.selectedChannel, toUser: nil, showAlert: false,
                                    completion: { selectedShareItem , error in
                if error == nil, let selectedShareItem = selectedShareItem {
                    let shareText = "Can you \(currentItem.childActionType())\(currentItem.childType()) - \(currentItem.itemTitle)"
                    self.showShare(selectedItem: selectedShareItem, type: "invite", fullShareText: shareText)
                }
            })
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
}

extension SeriesVC: UIViewControllerTransitioningDelegate {
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
