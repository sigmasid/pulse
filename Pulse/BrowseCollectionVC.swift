//
//  BrowseCollectionVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/24/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class BrowseCollectionVC: PulseVC {

    /** Set by parent **/
    public var selectedChannel : Channel!
    
    //master list item - should have the tagItem in it
    public var selectedItem : Item! {
        didSet {
            //get the child lists
            guard selectedItem != nil else { return }
            PulseDatabase.getLists(parentListID: selectedItem.itemID, completion: {[weak self] lists in
                guard let `self` = self else { return }
                self.allLists = lists
                self.updateCollectionDataSource()
            })
        }
    }
    
    /** Table / Collection View Vars **/
    fileprivate var collectionView: UICollectionView!
    fileprivate var tableView : UITableView!
    fileprivate var collectionViewHeader : UIView!
    fileprivate var headerButton : PulseButton = PulseButton(size: .small, type: .ellipsis, isRound: true, hasBackground: false, tint: .black)
    
    //items for the current table view
    fileprivate var allItems = [Item]()
    
    //all the list IDs - when set pull all items for that list from database
    fileprivate var allLists = [List]() {
        didSet {
            if !allLists.isEmpty {
                //get the first item in the list
                userSelected(item: 0)
            }
        }
    }
    fileprivate var allListItems = [String : [Item]]() //after items pulled use this dictionary to store them
    fileprivate var selectedListIndex : Int? = nil {
        didSet {
            guard let oldValue = oldValue else { return }
            let oldIndexPath = IndexPath(row: oldValue, section: 0)
            collectionView.reloadItems(at: [oldIndexPath])
        }
    }
    
    fileprivate var headerSetup = false
    fileprivate var cleanupComplete = false
        
    //After user edits / adds description so we set the correct one
    private var selectedItemTag : Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            tabBarHidden = true
            
            updateHeader()
            setupCollectionHeader()
            setupCollectionView()
            setupTableView()
            hideKeyboardWhenTappedAround()
            
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarHidden = true
        updateHeader()
    }
    
    deinit {
        performCleanup()
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            allItems = []
            selectedChannel = nil
            selectedItem = nil
            
            if tableView != nil {
                tableView = nil
            }
            
            cleanupComplete = true
        }
    }
    
    /** HEADER FUNCTIONS **/
    internal func updateHeader() {
        addBackButton()
        updateChannelImage(channel: selectedChannel)
        headerNav?.setNav(title: selectedItem.itemTitle, subtitle: selectedItem.tag?.itemTitle ?? selectedChannel.cTitle)
        headerNav?.showNavbar(animated: true)
    }
    
    internal func updateDataSource() {
        if tableView != nil {
            tableView?.dataSource = self
            tableView?.delegate = self
            
            tableView?.layoutIfNeeded()
            tableView?.reloadData()
        }
    }
    
    internal func updateCollectionDataSource() {
        if collectionView != nil {
            collectionView?.dataSource = self
            collectionView?.delegate = self
            
            collectionView?.layoutIfNeeded()
            collectionView?.reloadData()
        }
    }
    
    //either from collection view or the button inside collection view
    override func userSelected(item : Any) {
        guard let itemIndex = item as? Int, selectedListIndex != itemIndex else {
            //either not a correct index or same as current so don't reload
            return
        }
        
        selectedListIndex = itemIndex
        
        let selectedList = allLists[itemIndex]
        if allListItems[selectedList.listID] != nil {
            //if already fetched just set it as the current allItems
            allItems = allListItems[selectedList.listID]!
            updateDataSource()
        } else {
            //fetch the items for tableview
            PulseDatabase.getListItems(listID: selectedList.listID, completion: {[weak self] items in
                guard let `self` = self else { return }
                self.allItems = items
                self.allListItems[selectedList.listID] = items
                self.updateDataSource()
            })
        }
    }
    
    internal func clickedHeaderMenu() {
        //show menu when user clicks header
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        selectedItem.checkVerifiedInput(completion: {[weak self] success, error in
            menu.addAction(UIAlertAction(title: "create Collection", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                guard let `self` = self else { return }
                let editCollectionVC = EditCollectionVC()
                editCollectionVC.selectedChannel = self.selectedChannel
                editCollectionVC.selectedItem = self.selectedItem
                self.navigationController?.pushViewController(editCollectionVC, animated: true)
            }))
            
            menu.addAction(UIAlertAction(title: "invite Guests", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                guard let `self` = self else { return }
                if let inviteType = self.selectedItem.inviteType() {
                    menu.addAction(UIAlertAction(title: "invite Guests", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                        guard let `self` = self else { return }
                        self.showInviteMenu(currentItem: self.selectedItem,
                                            inviteTitle: "Invite Guests",
                                            inviteMessage: "know an expert who can \(self.selectedItem.childActionType())\(self.selectedItem.childType())?\nInvite them below!",
                            inviteType: inviteType)
                    }))
                }
            }))
        })
        
        menu.addAction(UIAlertAction(title: "share Collection", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.showShare(selectedItem: self.selectedItem, type: self.selectedItem.type.rawValue)
        }))
        
        present(menu, animated: true, completion: nil)
    }
}

/** Table View Data Source **/
extension BrowseCollectionVC : UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? ListItemCell else {
            return UITableViewCell()
        }
        
        let currentItem = allItems[indexPath.row]
        cell.updateItemDetails(title: currentItem.itemTitle, subtitle: currentItem.itemDescription, countText: String(indexPath.row + 1))
        cell.showItemMenu(show: false)
        cell.showImageBorder(show: currentItem.linkedURL != nil ? true : false)
        
        PulseDatabase.getCachedListItemImage(itemID: currentItem.itemID, fileType: FileTypes.content, maxImgSize: MAX_IMAGE_FILESIZE, completion: { image in
            DispatchQueue.main.async {
                cell.updateImage(image: image)
            }
        })
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.large.rawValue * 1.05
    }
}

/** Collection View Data Source **/
extension BrowseCollectionVC: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allLists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! HeaderCell
        cell.delegate = self
        cell.tag = indexPath.row
        
        let currentList = allLists[indexPath.row]
        
        if selectedListIndex == indexPath.row {
            cell.showImageBorder(show: true)
        } else {
            cell.showImageBorder(show: false)
        }
        
        PulseDatabase.getUser(currentList.userID, completion: { user, error in
            cell.updateTitle(title: user?.name)
        })
        
        PulseDatabase.getCachedUserPic(uid: currentList.userID, completion: {image in
            DispatchQueue.main.async {
                cell.updateImage(image: image)
            }
        })
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        userSelected(item: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: allLists.count > 0 ? Spacing.xxs.rawValue : 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    }
}

//UI Elements
extension BrowseCollectionVC {
    fileprivate func setupCollectionHeader() {
        collectionViewHeader = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: skinnyHeaderHeight))
        view.addSubview(collectionViewHeader)
        collectionViewHeader.addBottomBorder(color: .pulseGrey, thickness: 1.0)
        
        let sectionLabel = UILabel(frame: CGRect(x: Spacing.s.rawValue, y: 0, width: collectionViewHeader.frame.width - IconSizes.small.rawValue - Spacing.xs.rawValue,
                                                      height: skinnyHeaderHeight))
        headerButton.frame = CGRect(x: view.bounds.width - headerButton.bounds.width - Spacing.xs.rawValue,
                                    y: sectionLabel.frame.midY - (headerButton.bounds.height / 2),
                                    width: headerButton.bounds.width,
                                    height: headerButton.bounds.height)
        
        collectionViewHeader.addSubview(sectionLabel)
        collectionViewHeader.addSubview(headerButton)
        
        headerButton.addTarget(self, action: #selector(clickedHeaderMenu), for: .touchUpInside)
        headerButton.removeShadow()
        
        sectionLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: UIColor.black, alignment: .left)
        sectionLabel.text = "featured collections"
    }
    
    fileprivate func setupTableView() {
        tableView = UITableView(frame: CGRect.zero, style: UITableViewStyle.plain)
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.layoutIfNeeded()
        
        tableView?.register(ListItemCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        tableView?.backgroundView = nil
        tableView?.backgroundColor = UIColor.clear
        tableView?.separatorStyle = UITableViewCellSeparatorStyle.none
        
        tableView?.showsVerticalScrollIndicator = false
        tableView?.tableFooterView = UIView()
        
        updateDataSource()
    }
    
    fileprivate func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 5
        layout.estimatedItemSize = CGSize(width: view.frame.width / 4, height: IconSizes.medium.rawValue + Spacing.m.rawValue)
        
        let collectionViewFrame = CGRect(x: 0, y: skinnyHeaderHeight, width: view.frame.width, height: IconSizes.medium.rawValue + Spacing.l.rawValue)
        collectionView = UICollectionView(frame: collectionViewFrame, collectionViewLayout: layout)
        collectionView.register(HeaderCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.register(ItemHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        view.addSubview(collectionView)
        
        collectionView.backgroundColor = .white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.addBottomBorder(color: .pulseGrey, thickness: 1.0)
        
        updateCollectionDataSource()
    }
}
