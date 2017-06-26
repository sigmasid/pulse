//
//  ChannelVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ChannelVC: PulseVC, SelectionDelegate, ItemCellDelegate, BrowseContentDelegate, HeaderDelegate, ParentTextViewDelegate, ModalDelegate {
    //set by delegate
    public var selectedChannel : Channel! {
        didSet {
            isSubscribed = PulseUser.currentUser.subscriptionIDs.contains(selectedChannel.cID) ? true : false
            if !selectedChannel.cCreated {
                PulseDatabase.getChannel(cID: selectedChannel.cID!, completion: {[weak self] channel, error in
                    guard let `self` = self, let channel = channel else { return }
                    
                    channel.cPreviewImage = self.selectedChannel.cPreviewImage
                    self.selectedChannel = channel
                    self.updateHeader()
                })
            } else if !selectedChannel.cDetailedCreated {
                getChannelItems()
            } else {
                allItems = selectedChannel.items
                updateHeader()
                updateDataSource()
                toggleLoading(show: false, message: nil)
            }
        }
    }
    //end set by delegate
    
    //used to cache users downloaded
    fileprivate var allUsers = [PulseUser]()
    
    fileprivate var subscribeButton = PulseButton(size: .medium, type: .add, isRound : true, background: .white, tint: .black)
    fileprivate var isSubscribed : Bool = false {
        didSet {
            if !isSubscribed {
               setupSubscribe()
            }
        }
    }
    fileprivate var activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: IconSizes.medium.rawValue, height: IconSizes.medium.rawValue))
    
    /** Data Source Vars **/
    fileprivate var allItems = [Item]()
    fileprivate var hasReachedEnd = false
    
    fileprivate var isLayoutSetup = false
    
    /** Sync Vars **/
    fileprivate var startUpdateAt : Date = Date()
    fileprivate var endUpdateAt : Date = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    fileprivate var updateIncrement = -7 //get one week's worth of data on first load

    /** Collection View Vars **/
    fileprivate var collectionView : UICollectionView!
    fileprivate var footerMessage = "Fetching More..."
    fileprivate var selectedShareItem : Any?
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLoaded, allItems.isEmpty {
            
            toggleLoading(show: true, message: "Loading Channel...", showIcon: true)
            statusBarStyle = .lightContent
            setupScreenLayout()
            tabBarHidden = true

            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarHidden = true
        updateHeader()
    }
    
    deinit {
        selectedChannel = nil
        allItems = []
        allUsers = []
        collectionView = nil
    }
    
    internal func getChannelItems() {
        PulseDatabase.getChannelItems(channel: selectedChannel, startingAt: startUpdateAt, endingAt: endUpdateAt, completion: {[weak self] updatedChannel in
            
            if let updatedChannel = updatedChannel,  let `self` = self {
                updatedChannel.cPreviewImage = self.selectedChannel.cPreviewImage
                self.selectedChannel = updatedChannel
                
                if self.collectionView == nil {
                    self.setupScreenLayout()
                }
                
                if !updatedChannel.items.isEmpty {
                    var indexPaths = [IndexPath]()
                    for (index, _) in updatedChannel.items.enumerated() {
                        let newIndexPath = IndexPath(row: index , section: 1)
                        indexPaths.append(newIndexPath)
                    }
                    
                    self.collectionView.performBatchUpdates({
                        self.collectionView?.insertItems(at: indexPaths)
                        //self.collectionView?.reloadData()
                        self.collectionView?.collectionViewLayout.invalidateLayout()
                        self.collectionView?.reloadSections(IndexSet(integer: 1))
                        
                    })
                } else {
                    self.getMoreChannelItems(completion: {[weak self] success in
                        guard let `self` = self else { return}
                        //self.collectionView?.reloadData()
                        if success {
                            self.collectionView?.reloadSections(IndexSet(integer: 1))
                        } else {
                            self.collectionView?.reloadData()
                        }
                    })
                }
                
                
                if self.collectionView.contentSize.height < self.view.frame.height || updatedChannel.items.count < 4 {
                    //content fits the screen so fetch more
                    self.getMoreChannelItems(completion: {[weak self] success in
                        guard let `self` = self else { return }
                        if success {
                            self.collectionView?.reloadSections(IndexSet(integer: 1))
                        } else {
                            self.collectionView?.reloadData()
                        }
                    })
                }
            }
        })
        startUpdateAt = endUpdateAt
        endUpdateAt = Calendar.current.date(byAdding: .day, value: updateIncrement, to: startUpdateAt)!
    }
    
    //get more items if scrolled to end
    func getMoreChannelItems(completion: @escaping (Bool) -> Void)  {

        PulseDatabase.getChannelItems(channelID: selectedChannel.cID, startingAt: startUpdateAt, endingAt: endUpdateAt, completion: {[weak self] success, items in

            guard let `self` = self else {
                return
            }

            if items.isEmpty, self.updateIncrement > -365 { //max lookback is one year
                self.updateIncrement = self.updateIncrement * 2
                self.endUpdateAt = Calendar.current.date(byAdding: .day, value: self.updateIncrement, to: self.startUpdateAt)!
                self.getMoreChannelItems(completion: { success in completion(success) })
            } else if items.isEmpty, self.updateIncrement < -365 { //reached max increment
                if self.allItems.isEmpty {
                    self.footerMessage = "check back soon for new content!"
                } else {
                    self.footerMessage = "that's the end!"
                }
                self.hasReachedEnd = true
                completion(false)
            } else {
                var indexPaths = [IndexPath]()
                for (index, _) in items.enumerated() {
                    let newIndexPath = IndexPath(row: self.allItems.count + index, section: 1)
                    indexPaths.append(newIndexPath)
                }
                
                self.collectionView.performBatchUpdates({
                    self.collectionView?.insertItems(at: indexPaths)
                    self.selectedChannel.items.append(contentsOf: items)
                    self.allItems.append(contentsOf: items)
                    
                    if items.count < 4 {
                        self.getMoreChannelItems(completion: { success in completion(success)})
                    } else {
                        self.updateIncrement = -7
                        completion(true)
                    }
                })
            }
        })
        self.startUpdateAt = self.endUpdateAt
        self.endUpdateAt = Calendar.current.date(byAdding: .day, value: self.updateIncrement, to: self.startUpdateAt)!        
    }
    
    //Once the channel is set and pulled from database -> reload the datasource for collection view
    func updateDataSource() {
        if !isLayoutSetup {
            setupScreenLayout()
        }
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }
    
    internal func subscribe() {
        subscribeButton.setImage(nil, for: .normal)
        let indicator = subscribeButton.addLoadingIndicator()
        
        subscribeChannel(channel: selectedChannel, completion: {[weak self]( success, error ) in
            guard let `self` = self else { return }
            
            if !success {
                GlobalFunctions.showAlertBlock("Error Subscribing", erMessage: error!.localizedDescription)
                self.subscribeButton.setImage(UIImage(named: "add")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
                indicator.removeFromSuperview()
            } else {
                if PulseUser.currentUser.isSubscribedToChannel(cID: self.selectedChannel.cID) {
                    indicator.removeFromSuperview()
                    self.subscribeButton.setImage(UIImage(named: "check")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
                    self.isSubscribed = true
                    
                    UIView.animate(withDuration: 1, animations: { self.subscribeButton.alpha = 0 } , completion: {(value: Bool) in
                        self.subscribeButton.removeFromSuperview()
                        self.subscribeButton = PulseButton(size: .medium, type: .add, isRound : true, hasBackground: true, tint: .white)
                    })
                }
            }
        })
    }
    
    internal func subscribeChannel(channel : Channel, completion: @escaping (Bool, NSError?) -> Void) {
        PulseDatabase.subscribeChannel(selectedChannel, completion: {(success, error) in
            completion(success, error)
        })
    }
    
    /** HEADER FUNCTIONS **/
    fileprivate func updateHeader() {
        addBackButton()
        updateChannelImage()

        headerNav?.setNav(title: selectedChannel.cTitle ?? "Explore Channel")
        headerNav?.showNavbar(animated: true)
        headerNav?.followScrollView(collectionView, delay: 25.0)
    }
    
    fileprivate func updateChannelImage() {
        if selectedChannel.cPreviewImage != nil {
            headerNav?.updateBackgroundImage(image: selectedChannel.getNavImage())
        } else if let stringURL = selectedChannel.cImageURL, let url = URL(string: stringURL) {
            DispatchQueue.global().async {
                if let channelImage = try? Data(contentsOf: url) {
                    self.selectedChannel.cPreviewImage = UIImage(data: channelImage)
                    DispatchQueue.main.async {
                        self.headerNav?.updateBackgroundImage(image: self.selectedChannel.getNavImage())
                    }
                } else {
                    DispatchQueue.main.async {
                        self.headerNav?.updateBackgroundImage(image: nil)
                    }
                }
            }
        }
    }
    
    internal func setupSubscribe() {
        addScreenButton(button: subscribeButton)
        subscribeButton.addTarget(self, action: #selector(subscribe), for: UIControlEvents.touchUpInside)
    }
    
    fileprivate func setupScreenLayout() {
        if !isLayoutSetup {
            collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
            let _ = PulseFlowLayout.configureLayout(collectionView: collectionView, minimumLineSpacing: 10, itemSpacing: 10, stickyHeader: true)
            
            collectionView?.register(ItemCell.self, forCellWithReuseIdentifier: reuseIdentifier)
            collectionView?.register(HeaderTagsCell.self, forCellWithReuseIdentifier: sectionReuseIdentifier)
            collectionView?.register(ItemHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
            collectionView?.register(ItemHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: footerReuseIdentifier)
            
            view.addSubview(collectionView!)
            
            isLayoutSetup = true
        }
    }
}

/** Protocols **/
extension ChannelVC {
    
    /** Delegate Function **/
    internal func dismiss(_ view : UIView) {
        view.removeFromSuperview()
    }
    
    //clicked the image button to go to a user profile
    internal func clickedUserButton(itemRow : Int) {
        if let user = allItems[itemRow].user {
            let userProfileVC = UserProfileVC()
            navigationController?.pushViewController(userProfileVC, animated: true)
            userProfileVC.selectedUser = user
        }
    }
    
    //main menu for each individual item
    internal func clickedMenuButton(itemRow: Int) {
        let currentItem = allItems[itemRow]
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
                menu.message = "No\(selectedItem.childType())s yet - want to be the first?"
                
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
    
    //user clicked menu in the header section
    internal func clickedHeaderMenu() {
        guard PulseUser.isLoggedIn() else {
            showSubscriberHeaderMenu()
            return
        }
        
        PulseUser.currentUser.isVerified(for: selectedChannel) ? showContributorHeaderMenu() : showSubscriberHeaderMenu()
    }
    
    //close modal - e.g. mini search
    internal func userClosedModal(_ viewController: UIViewController) {
        dismiss(animated: true, completion: { _ in })
    }
    
    //after email - user submitted the text
    internal func buttonClicked(_ text: String, sender: UIView) {
        GlobalFunctions.validateEmail(text, completion: {[weak self] (success, error) in
            guard let `self` = self else { return }
            
            if !success {
                self.showAddEmail(bodyText: "invalid email - try again")
            } else {
                if let selectedShareItem = self.selectedShareItem as? Item {
                    
                    self.createShareRequest(selectedShareItem: selectedShareItem, shareType: selectedShareItem.inviteType(), selectedChannel: self.selectedChannel, toUser: nil, toEmail: text, completion: {[weak self] _ , _ in
                        guard let `self` = self else { return }
                        self.selectedShareItem = nil
                    })
                    
                } else if let selectedShareItem = self.selectedShareItem as? Channel {
                    self.createContributorInvite(selectedChannel: selectedShareItem, toUser: nil, toEmail: text, completion: {[weak self] _ , _ in
                        guard let `self` = self else { return }
                        self.selectedShareItem = nil
                    })
                    
                }
            }
        })
    }
    /** End Delegate Functions **/
    
    /** Menu Options **/
    internal func showInviteMenu(currentItem : Any?, inviteTitle: String, inviteMessage: String, inviteType: MessageType) {
        let menu = UIAlertController(title: inviteTitle, message: inviteMessage, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "invite Pulse Users", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.selectedShareItem = currentItem
            
            let browseUsers = MiniUserSearchVC()
            browseUsers.modalPresentationStyle = .overCurrentContext
            browseUsers.modalTransitionStyle = .crossDissolve
            
            browseUsers.modalDelegate = self
            browseUsers.selectionDelegate = self
            browseUsers.selectedChannel = self.selectedChannel
            self.navigationController?.present(browseUsers, animated: true, completion: nil)
        }))
        
        menu.addAction(UIAlertAction(title: "invite via Email", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.selectedShareItem = currentItem
            self.showAddEmail(bodyText: "enter email")
        }))
        
        menu.addAction(UIAlertAction(title: "more invite Options", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            switch inviteType {
            case .perspectiveInvite, .questionInvite, .showcaseInvite, .feedbackInvite:
                if let currentItem = currentItem as? Item {
                    self.createShareRequest(selectedShareItem: currentItem, shareType: inviteType, selectedChannel: self.selectedChannel, toUser: nil, showAlert: false, completion: {[unowned self] selectedShareItem , error in
                        //using the share item returned from the request
                        if error == nil, let selectedShareItem = selectedShareItem {
                            let shareText = "Can you \(currentItem.childActionType())\(currentItem.childType()) on \(currentItem.itemTitle)"
                            self.showShare(selectedItem: selectedShareItem, type: "invite", fullShareText: shareText, inviteItemID: currentItem.itemID)
                        }
                    })
                    
                }
            case .contributorInvite:
                if let shareChannel = currentItem as? Channel {
                    self.toggleLoading(show: true, message: "loading share options...", showIcon: true)
                    
                    self.createContributorInvite(selectedChannel: shareChannel, toUser: nil, toEmail: nil, showAlert: true, completion: {[unowned self] inviteID , error in
                        
                        if error == nil, let inviteID = inviteID {
                            let channelTitle = shareChannel.cTitle ?? "a Pulse channel"
                            let shareText = "You are invited to be a contributor on \(channelTitle)"
                            
                            PulseDatabase.createShareLink(item: shareChannel, linkString: "invites/"+inviteID, completion: {[unowned self] link in
                                guard let link = link else {
                                    self.toggleLoading(show: false, message: nil)
                                    return
                                }
                                
                                self.toggleLoading(show: false, message: nil)
                                self.shareContent(shareType: "", shareText: "", shareLink: link, fullShareText: shareText)
                            })
                        }
                        
                    })
                }
            case .channelInvite:
                if let shareChannel = currentItem as? Channel {
                    self.toggleLoading(show: true, message: "loading share options...", showIcon: true)
                    
                    let shareItem = Item(itemID: "")
                    shareItem.itemTitle = "Check out \(shareChannel.cTitle ?? " this channel")" //send blank item since we are inviting users to come to channel
                    
                    self.createShareRequest(selectedShareItem: shareItem, shareType: .channelInvite, selectedChannel: shareChannel, toUser: nil, completion: { [unowned self] item, error in
                        
                        if error == nil, let inviteID = item?.itemID {
                            let channelTitle = shareChannel.cTitle ?? "a Pulse channel"
                            let shareText = "\(PulseUser.currentUser.name ?? "Your friend") invited you to \(channelTitle)"
                            
                            PulseDatabase.createShareLink(item: shareChannel, linkString: "invites/"+inviteID, completion: {[unowned self] link in
                                guard let link = link else {
                                    self.toggleLoading(show: false, message: nil)
                                    return
                                }
                                
                                self.toggleLoading(show: false, message: nil)
                                self.shareContent(shareType: "", shareText: "", shareLink: link, fullShareText: shareText)
                            })
                        }
                    })
                }
            default: break
            }
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showAddEmail(bodyText: String) {
        addText = AddText(frame: view.bounds, buttonText: "Send",
                           bodyText: bodyText, keyboardType: .emailAddress)
        
        addText.delegate = self
        view.addSubview(addText)
    }
    
    /*** HEADER MENUS ***/
    //when user clicks menu in the header
    func showContributorHeaderMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        //only editors can start series
        if PulseUser.isLoggedIn(), PulseUser.currentUser.isEditor(for: selectedChannel) {
            menu.addAction(UIAlertAction(title: "start New Series", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                guard let `self` = self else { return }
                self.startSeries()
            }))
        }
        
        //contributors & editors can invite contributors
        menu.addAction(UIAlertAction(title: "invite Contributors", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.showInviteMenu(currentItem: self.selectedChannel,
                                inviteTitle: "invite Contributors",
                                inviteMessage: "contributors can add posts, answer questions and share their perspecives. To ensure quality, please only invite qualified contributors. All new contributor requests are reviewed.", inviteType: .contributorInvite)
        }))
        
        //anyone can share
        menu.addAction(UIAlertAction(title: "share Channel", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.toggleLoading(show: true, message: "loading share options...", showIcon: true)
            self.selectedChannel.createShareLink(completion: {[unowned self] link in
                guard let link = link else { return }
                self.shareContent(shareType: "channel", shareText: self.selectedChannel.cTitle?.capitalized ?? "", shareLink: link)
            })
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            menu.dismiss(animated: true, completion: nil)
            self.toggleLoading(show: false, message: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    //for header
    func showSubscriberHeaderMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        //all users can browse the featured contributors
        menu.addAction(UIAlertAction(title: "meet Contributors", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            let browseContributorsVC = BrowseUsersVC()
            browseContributorsVC.selectedChannel = self.selectedChannel
            browseContributorsVC.delegate = self
            
            self.navigationController?.pushViewController(browseContributorsVC, animated: true)
        }))
        
        menu.addAction(UIAlertAction(title: "become Contributor", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            let becomeContributorVC = BecomeContributorVC()
            becomeContributorVC.selectedChannel = self.selectedChannel
            
            self.navigationController?.pushViewController(becomeContributorVC, animated: true)
        }))
        
        menu.addAction(UIAlertAction(title: "share Channel", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.toggleLoading(show: true, message: "loading share options...", showIcon: true)
            self.selectedChannel.createShareLink(completion: {[unowned self] link in
                guard let link = link else { return }
                self.shareContent(shareType: "channel", shareText: self.selectedChannel.cTitle?.capitalized ?? "", shareLink: link)
            })
        }))
        
        menu.addAction(UIAlertAction(title: isSubscribed ? "unsubscribe" : "subscribe", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.subscribeChannel(channel: self.selectedChannel, completion: {(success, error) in
                menu.dismiss(animated: true, completion: nil)
            })
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    /** End Menu Options **/
    
    /** Menu Actions **/
    internal func startSeries() {
        let newSeries = NewSeriesVC()
        newSeries.selectedChannel = selectedChannel
        navigationController?.pushViewController(newSeries, animated: true)
    }
    
    internal func userSelected(item : Any) {
        if let item = item as? Item {
            switch item.type {
                
            case .post, .perspective, .answer, .showcase:
                
                showItemDetail(allItems: [item], index: 0, itemCollection: [], selectedItem: item, watchedPreview: false)
                
            case .posts, .feedback, .perspectives, .interviews, .questions, .showcases:
                
                showTag(selectedItem: item)
            
            case .session:
                
                toggleLoading(show: true, message: "loading session...", showIcon: true)
                
                PulseDatabase.getItemCollection(item.itemID, completion: {[weak self] (success, items) in
                    guard let `self` = self else { return }
                    
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
                        GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Error Loading session", erMessage: "Sorry! There was an error getting the session!")
                    }
                })
            
            case .interview, .question, .thread:
                
                toggleLoading(show: true, message: "loading \(item.type.rawValue)...", showIcon: true)
                
                PulseDatabase.getItemCollection(item.itemID, completion: {[weak self] (success, items) in
                    guard let `self` = self else { return }
                    
                    self.toggleLoading(show: false, message: nil)
                    success ?
                        self.showItemDetail(allItems: items, index: 0, itemCollection: [], selectedItem: item, watchedPreview: false) :
                        self.showNoItemsMenu(selectedItem : item)
                })
                
            default: break
            }
            
        //user selected from mini user search for invite or clicked the user profile button
        } else if let user = item as? PulseUser {
    
            userSelectedUser(toUser: user)
        
        //user invalid selection
        } else {
            
            GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Invalid Selection", erMessage: "Sorry! That selection is not valid")
            
        }
    }
    
    //checks to make sure we are not in mini search case
    internal func userSelectedUser(toUser: PulseUser) {
        
        if let selectedShareItem = selectedShareItem as? Item {
            //
            self.createShareRequest(selectedShareItem: selectedShareItem, shareType: selectedShareItem.inviteType(), selectedChannel: selectedChannel, toUser: toUser, completion: {[unowned self] _ , _ in
                self.selectedShareItem = nil
            })
        } else if let selectedShareItem = selectedShareItem as? Channel {
            
            //channel contributor invite
            createContributorInvite(selectedChannel: selectedShareItem, toUser: toUser, toEmail: nil, showAlert: true, completion: { _, _ in })
            
        } else {
            
            //if not mini search then just go to the user profile
            let userProfileVC = UserProfileVC()
            navigationController?.pushViewController(userProfileVC, animated: true)
            userProfileVC.selectedUser = toUser
            
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
    
    internal func addNewItem(selectedItem: Item) {
        contentVC = ContentManagerVC()
        contentVC.selectedChannel = selectedChannel
        contentVC.selectedItem = selectedItem
        contentVC.openingScreen = .camera
        
        contentVC.transitioningDelegate = self
        present(contentVC, animated: true, completion: nil)
    }
    
    internal func showBrowse(selectedItem: Item) {
        selectedItem.cID = selectedChannel.cID
        
        let itemCollection = BrowseContentVC()
        itemCollection.selectedChannel = selectedChannel
        itemCollection.selectedItem = selectedItem
        itemCollection.contentDelegate = self
        
        navigationController?.pushViewController(itemCollection, animated: true)
    }
    
    internal func showTag(selectedItem : Item) {
        let seriesVC = SeriesVC()
        seriesVC.selectedChannel = selectedChannel
        
        navigationController?.pushViewController(seriesVC, animated: true)
        seriesVC.selectedItem = selectedItem
        
    }
    
    internal func createContributorInvite(selectedChannel: Channel, toUser: PulseUser?, toEmail: String?  = nil, showAlert: Bool = true,
                                          completion: @escaping (String?, Error?) -> Void) {
        
        toggleLoading(show: true, message: "creating invite...", showIcon: true)
        PulseDatabase.createContributorInvite(channel: selectedChannel, type: .contributorInvite, toUser: toUser, toName: toUser?.name,
                                         toEmail: toEmail, completion: {[unowned self] (inviteID, error) in
                                        
            self.toggleLoading(show: false, message: nil)

            if error == nil, showAlert {
                GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Invite Sent", erMessage: "Thanks for your recommendation!", buttonTitle: "okay")
                completion(inviteID, nil)
            } else if showAlert {
                GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Error Sending Request", erMessage: "Sorry there was an error sending the invite")
                completion(nil, error)
            }
        })
    }
}

/* COLLECTION VIEW */
extension ChannelVC : UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return self.allItems.count
        default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: sectionReuseIdentifier, for: indexPath) as! HeaderTagsCell
            cell.selectedChannel = selectedChannel
            cell.items = selectedChannel.tags
            cell.delegate = self
            
            return cell
        case 1:
            //if near the end then get more items
            if indexPath.row == allItems.count - 3, !hasReachedEnd {
                getMoreChannelItems(completion: { _ in })
            }
            
            let currentItem = allItems[indexPath.row]
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ItemCell
            cell.itemType = currentItem.type
            
            cell.delegate = self
            cell.tag = indexPath.row
            
            //clear the cells and set the item type first
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: currentItem.tag?.itemTitle, _createdAt: currentItem.createdAt, _image: self.allItems[indexPath.row].content as? UIImage ?? nil)
            cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)

            //Add additional user details as needed
            if currentItem.user == nil || !currentItem.user!.uCreated {
                if let user = checkUserDownloaded(user: PulseUser(uID: currentItem.itemUserID)) {
                    allItems[indexPath.row].user = user
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
                    // Get the user details
                    PulseDatabase.getUser(currentItem.itemUserID, completion: {[weak self] (user, error) in
                    guard let `self` = self else { return }
                        
                    if let user = user {
                        self.allItems[indexPath.row].user = user
                        self.allUsers.append(user)
                        DispatchQueue.main.async {
                            if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                cell.updateLabel(currentItem.itemTitle, _subtitle: user.name, _createdAt: currentItem.createdAt, _tag: currentItem.tag?.itemTitle)
                            }
                        }
                        
                        DispatchQueue.global(qos: .background).async {
                            if let imageString = user.thumbPic, let imageURL = URL(string: imageString), let _imageData = try? Data(contentsOf: imageURL), let image = UIImage(data: _imageData) {
                                self.allItems[indexPath.row].user?.thumbPicImage = image
                                self.updateUserImageDownloaded(user: user, thumbPicImage: image)
                                
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
            
            //Get the image if content type is a post
            if currentItem.content == nil, currentItem.shouldGetImage(), !currentItem.fetchedContent {
                PulseDatabase.getImage(channelID: self.selectedChannel.cID, itemID: currentItem.itemID, fileType: .thumb, maxImgSize: maxImgSize, completion: {[weak self] (data, error) in
                    guard let `self` = self else { return }
                    
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
            
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
            return cell
        }
    }
    
    func checkUserDownloaded(user: PulseUser) -> PulseUser? {
        if let index = allUsers.index(of: user) {
            return allUsers[index]
        }
        return nil
    }

    func updateUserImageDownloaded(user: PulseUser, thumbPicImage : UIImage?) {
        if let image = thumbPicImage , let index = allUsers.index(of: user) {
            allUsers[index].thumbPicImage = image
        }
    }
    
    //Did select item at index path
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let selectedItem = allItems[indexPath.row]
            userSelected(item: selectedItem)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! ItemHeader
            switch indexPath.section {
            case 0:
                headerView.backgroundColor = UIColor.white
                headerView.delegate = self
                headerView.updateLabel("featured series")
            case 1:
                break
            default:
                break
            }
            return headerView
        case UICollectionElementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: footerReuseIdentifier, for: indexPath) as! ItemHeader
            switch indexPath.section {
            case 1:
                footerView.backgroundColor = UIColor.white
                footerView.updateLabel(footerMessage)
                footerView.addLoadingIndicator(hide: false)
            default:
                break
            }
            return footerView
        default: assert(false, "Unexpected element kind")
        }
        return UICollectionReusableView()
    }
}

extension ChannelVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case 0:
            return CGSize(width: collectionView.frame.width, height: selectedChannel.tags.count > 0 ? skinnyHeaderHeight : 0)
        case 1:
            return CGSize(width: collectionView.frame.width, height: 0)
        default:
            return CGSize(width: collectionView.frame.width, height: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        switch section {
        case 1:
            return CGSize(width: collectionView.frame.width, height: skinnyHeaderHeight)
        default:
            return CGSize(width: collectionView.frame.width, height: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: selectedChannel.tags.count > 0 ? Spacing.xs.rawValue : 0, right: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.section {
        case 0:
            return CGSize(width: collectionView.frame.width, height: selectedChannel.tags.count > 0 ? headerSectionHeight : 0)
        case 1:
            let cellHeight = GlobalFunctions.getCellHeight(type: allItems[indexPath.row].type)
            return CGSize(width: collectionView.frame.width, height: selectedChannel.tags.count > 0 ? cellHeight : 0)
        default:
            return CGSize(width: collectionView.frame.width, height: 0)
        }
    }
    
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

extension ChannelVC: UIScrollViewDelegate {
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateCell(_ cell: ItemCell, inCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
        if allItems[indexPath.row].itemCreated {
            let currentItem = allItems[indexPath.row]
            cell.itemType = currentItem.type
            cell.updateCell(currentItem.itemTitle, _subtitle: currentItem.user?.name, _tag: currentItem.tag?.itemTitle, _createdAt: currentItem.createdAt, _image: allItems[indexPath.row].content as? UIImage ?? nil)
            cell.updateButtonImage(image: allItems[indexPath.row].user?.thumbPicImage, itemTag : indexPath.row)
        }
    }
    
    func updateOnscreenRows() {
        let visiblePaths = collectionView.indexPathsForVisibleItems
        for indexPath in visiblePaths {
            if indexPath.section == 1 {
                let cell = collectionView.cellForItem(at: indexPath) as! ItemCell
                updateCell(cell, inCollectionView: collectionView, atIndexPath: indexPath)
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

extension ChannelVC: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if presented is ContentManagerVC {            
            let animator = ExpandAnimationController()
            animator.initialFrame = initialFrame
            animator.exitFrame = getRectToLeft()
            
            return animator
        } else {
            return nil
        }
    }
    
    /**
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
    } **/
    
    /**
    internal func showNonContributorMenu(selectedItem : Item) {
        let menu = UIAlertController(title: "Want to be a Contributor?",
                                     message: "looks like you are not yet a verified contributor. To ensure quality, we recommend applying to be verified. You can still continue with your submission (will be reviewed for quality).",
                                     preferredStyle: .actionSheet)
        
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
    } **/
}
