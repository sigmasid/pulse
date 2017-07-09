//
//  BrowseContentVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/17/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class BrowseContentVC: PulseVC, PreviewDelegate, HeaderDelegate {
    //Delegate PreviewVC var - if user watches full preview then go to index 1 vs. index 0 in full screen
    public var watchedFullPreview: Bool = false
    public weak var contentDelegate : BrowseContentDelegate!
    public weak var modalDelegate : ModalDelegate!
    /** End Delegate Vars **/
    
    //Main data source var
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
            guard !cleanupComplete else { return }
            
            if selectedItem != nil, allItems.isEmpty {
                PulseDatabase.getItemCollection(selectedItem.itemID, completion: {[weak self](success, items) in
                    guard let `self` = self else { return }
                    if success {
                        let type = self.selectedItem.type == .question ? "answer" : "post"
                        self.allItems = items.map{ item -> Item in
                            Item(itemID: item.itemID, type: type)
                        }
                        self.updateDataSource()
                    } else {
                        self.allItems = items
                        self.updateDataSource()
                    }
                    self.toggleLoading(show: false, message: nil)
                })
            } else {
                updateDataSource()
                toggleLoading(show: false, message: nil)
            }
        }
    }
    public var forSingleUser = false //if true then shows titles in caption vs. user info
    //end set by delegate
    
    /** Collection View Vars **/
    internal var collectionView : UICollectionView!
    fileprivate let minCellHeight : CGFloat = 225
    
    fileprivate var selectedIndex : IndexPath? {
        didSet {
            guard !cleanupComplete else { return }
            
            if selectedIndex != nil {
                collectionView?.reloadItems(at: [selectedIndex!])
                if deselectedIndex != nil && deselectedIndex != selectedIndex {
                    collectionView?.reloadItems(at: [deselectedIndex!])
                }
            }
        }
        willSet {
            guard !cleanupComplete else { return }
            
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
    /** End Collection View **/
    
    private var cleanupComplete = false

    //once allItems var is set reload the data
    func updateDataSource() {
        if !isLayoutSetup {
            setupLayout()
            
            tabBarHidden = true
            isLayoutSetup = true
        }
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.reloadData()
        collectionView?.layoutIfNeeded()
    }
    
    fileprivate var isLayoutSetup = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLayoutSetup {
            toggleLoading(show: true, message: "Loading...", showIcon: true)
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
    
    public func performCleanup() {
        if !cleanupComplete {
            cleanupComplete = true
            allItems = []
            itemStack = []
            selectedChannel = nil
            selectedItem = nil
        }
    }
    
    fileprivate func setupLayout() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        let _ = PulseFlowLayout.configureLayout(collectionView: collectionView, minimumLineSpacing: 10, itemSpacing: 10, stickyHeader: true)
        
        collectionView?.register(EmptyCell.self, forCellWithReuseIdentifier: emptyReuseIdentifier)
        collectionView?.register(ItemHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        collectionView?.register(BrowseContentCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        view.addSubview(collectionView)
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        if navigationController != nil {
            //is in nav controller
            addBackButton()
            headerNav?.followScrollView(collectionView, delay: 25.0)
            headerNav?.setNav(title: selectedItem.tag?.itemTitle, subtitle: selectedItem.cTitle)
            headerNav?.updateBackgroundImage(image: selectedChannel.getNavImage())
        } else {
            //was shown modally
            statusBarHidden = true
            setupClose()
            closeButton.addTarget(self, action: #selector(closeBrowse), for: UIControlEvents.touchUpInside)
        }
    }
    
    internal func setupClose() {
        addScreenButton(button: closeButton)
        closeButton.addTarget(self, action: #selector(closeBrowse), for: UIControlEvents.touchUpInside)
    }
    
    /** DELEGATE METHODS FOR CONTENT DETAIL **/
    internal func closeBrowse() {
        if modalDelegate != nil {
            modalDelegate.userClosedModal(self)
        }
    }
    
    internal func showItemDetail(item : Item, index : Int, itemCollection: [Item]) {
        if contentDelegate != nil {
            contentDelegate.showItemDetail(allItems: allItems, index: index, itemCollection: itemCollection, selectedItem : item, watchedPreview : watchedFullPreview)
        }
    }
    
    internal func clickedHeaderMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        selectedItem.checkVerifiedInput(completion: {[weak self] success, error in
            guard let `self` = self else { return }
            if success {
                menu.addAction(UIAlertAction(title: "\(self.selectedItem.childActionType())\(self.selectedItem.childType().capitalized)", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                    guard let `self` = self else { return }
                    self.clickedAddItem()
                }))
            }
        })
        
        menu.addAction(UIAlertAction(title: "share \(selectedItem.type.rawValue.capitalized)", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.showShare(selectedItem: self.selectedItem, type: self.selectedItem.type.rawValue)

        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func clickedAddItem() {
        if contentDelegate != nil {
            contentDelegate.addNewItem(selectedItem: selectedItem)
        }
    }
}

extension BrowseContentVC : UICollectionViewDelegate, UICollectionViewDataSource {

    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allItems.count == 0 ? 1 : allItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if allItems.count > 0, let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
            let cellRect = attributes.frame
            initialFrame = collectionView.convert(cellRect, to: collectionView.superview)
        
            selectedIndex = indexPath
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard allItems.count > 0 else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emptyReuseIdentifier, for: indexPath) as! EmptyCell
            cell.setMessage(message: "nothing to see yet!", color: .black)
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BrowseContentCell
        
        cell.contentView.backgroundColor = .white
        cell.updateLabel(nil, _subtitle: nil, _image : nil)
        
        let currentItem = allItems[indexPath.row]
        
        /* GET PREVIEW IMAGE FROM STORAGE */
        if selectedItem.shouldGetBrowseImage() {
            
            if currentItem.content != nil && !itemStack[indexPath.row].gettingImageForPreview {
                
                cell.updateImage(image: currentItem.content)
                
            } else if itemStack[indexPath.row].gettingImageForPreview {
                
                //ignore if already fetching the image, so don't refetch if already getting
                
            } else {
                itemStack[indexPath.row].gettingImageForPreview = true
                
                PulseDatabase.getImage(channelID: selectedItem.cID ?? selectedChannel.cID, itemID: currentItem.itemID, fileType: .thumb, maxImgSize: MAX_IMAGE_FILESIZE, completion: {[weak self] (_data, error) in
                    guard let `self` = self else { return }
                    if error == nil {
                        let _previewImage = GlobalFunctions.createImageFromData(_data!)
                        self.allItems[indexPath.row].content = _previewImage
                        
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            DispatchQueue.main.async {
                                cell.updateImage(image: self.allItems[indexPath.row].content)
                            }
                        }
                    } else {
                        cell.updateImage(image: nil)
                    }
                })
            }
        }
        
        let hasUserImage = !selectedItem.shouldGetBrowseImage() && allItems[indexPath.row].user?.thumbPicImage != nil
        
        //Already fetched this item
        if allItems[indexPath.row].itemCreated, let user = allItems[indexPath.row].user, hasUserImage  {
            
            cell.updateLabel(user.name?.capitalized, _subtitle: user.shortBio?.capitalized)
            cell.updateImage(image: user.thumbPicImage)


        } else if itemStack[indexPath.row].gettingInfoForPreview {
            
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            itemStack[indexPath.row].gettingInfoForPreview = true

            PulseDatabase.getItem(allItems[indexPath.row].itemID, completion: {[weak self] (item, error) in
                guard let `self` = self else { return }
                
                if let item = item {
                    
                    item.tag = self.allItems[indexPath.row].tag
                    self.allItems[indexPath.row] = item
                    
                    if self.forSingleUser {
                        cell.updateLabel(nil, _subtitle: item.itemTitle)
                    } else {
                    // Get the user details
                        PulseDatabase.getUser(item.itemUserID, completion: {[weak self] (user, error) in
                            guard let `self` = self else { return }
                            if let user = user {
                                self.allItems[indexPath.row].user = user
                                DispatchQueue.main.async {
                                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                        
                                        cell.updateLabel(user.name?.capitalized, _subtitle: user.shortBio?.capitalized)

                                    }
                                }
                                
                                if !self.selectedItem.shouldGetBrowseImage() {
                                    DispatchQueue.global(qos: .background).async {
                                        if let imageString = user.profilePic ?? user.thumbPic, let imageURL = URL(string: imageString),
                                            let _imageData = try? Data(contentsOf: imageURL) {
                                            if indexPath.row < self.allItems.count { //prevent crash if user navigates away
                                                self.allItems[indexPath.row].user?.thumbPicImage = UIImage(data: _imageData)
                                                
                                                DispatchQueue.main.async {
                                                    cell.updateImage(image: self.allItems[indexPath.row].user?.thumbPicImage)
                                                }
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
        
        if indexPath == selectedIndex && indexPath == deselectedIndex {
            showItemDetail(item: selectedItem, index: indexPath.row, itemCollection: itemStack[indexPath.row].itemCollection )
        } else if indexPath == selectedIndex {
            //if item has more than initial clip, show 'see more at the end'
            watchedFullPreview = false
            
            //if interview just go directly to full screen
            if currentItem.type != .interview {
                PulseDatabase.getItemCollection(currentItem.itemID, completion: {[weak self] (hasDetail, itemCollection) in
                    guard let `self` = self else { return }
                    if hasDetail {
                        cell.showTapForMore = true
                        self.itemStack[indexPath.row].itemCollection = itemCollection.reversed()
                    } else {
                        cell.showTapForMore = false
                    }
                })
                
                cell.delegate = self
                cell.showItemPreview(item: currentItem)
            } else {
                toggleLoading(show: true, message: "loading interview...")
                PulseDatabase.getItemCollection(currentItem.itemID, completion: {[weak self] (hasDetail, itemCollection) in
                    guard let `self` = self else { return }
                    self.toggleLoading(show: false, message: nil)
                    self.showItemDetail(item: self.selectedItem, index: 0, itemCollection: itemCollection)
                    self.selectedIndex = nil
                    self.deselectedIndex = nil
                    
                })
            }
            
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
            headerView.delegate = self
            
            if forSingleUser, let name = selectedItem.user?.name {
                let headerTitle = name + " - " + selectedItem.itemTitle
                headerView.updateLabel(headerTitle)
            } else {
                headerView.updateLabel(selectedItem != nil ? selectedItem.itemTitle : "")
            }
            
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
        return UICollectionReusableView()
    }
}

extension BrowseContentVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if allItems.count == 0 {
            return CGSize(width: view.frame.width, height: view.frame.height - skinnyHeaderHeight)
        }
        return CGSize(width: (view.frame.width - 30) / 2, height: minCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: selectedItem != nil ? skinnyHeaderHeight : 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if allItems.count == 0 {
            return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0, right: 0.0)
        }
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
        
        if  selectedItem.shouldGetBrowseImage(), let image = allItems[indexPath.row].content  {
            cell.updateImage(image: image)
        } else if !selectedItem.shouldGetBrowseImage(), let image = allItems[indexPath.row].user?.thumbPicImage {
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
