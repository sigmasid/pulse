//  InterviewRequestReceivedVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/27/17.
//  Copyright © 2017 Think Apart. All rights reserved.


import UIKit

class InterviewRequestVC: PulseVC, CompletedRecordingDelegate, ListDelegate {
    public var selectedUser : PulseUser!
    public var interviewItem : Item!
    public var conversationID : String?
    
    public var interviewItemID : String! {
        didSet {
            if interviewItem == nil || allItems.isEmpty || selectedUser == nil {
                PulseDatabase.getInviteItem(interviewItemID, completion: {[weak self] interviewItem, _, questions, toUser, conversationID, error in
                    guard let `self` = self else { return }

                    self.selectedUser = toUser
                    self.interviewItem = interviewItem
                    self.allItems = questions
                    
                    if self.conversationID == nil, let cID = conversationID {
                        self.conversationID = cID
                    }
                    
                    self.checkPartialInterview()
                    self.updateDataSource()
                    self.updateScreen()
                    self.createInterviewImage()
                })
            } else {
                self.checkPartialInterview()
                self.updateDataSource()
                self.updateScreen()
                self.createInterviewImage()
            }
        }
    }
    
    //Table View Vars
    internal var tableView : UITableView!
    internal var allItems = [Item]()
    internal var selectedIndex : Int?
    internal var completedIndex = [Bool]()
    
    //UI Elements
    internal var iImage = PulseButton(size: .medium, type: .profile, isRound: true, hasBackground: false, tint: .black)
    internal var iDescription = PaddingLabel()
    internal var submitButton = PulseButton(title: "Finish Interview", isRound: true, hasShadow: false)
    internal var loading : UIView?

    fileprivate var fullImageData : Data?
    fileprivate var thumbImageData : Data?
    private var cleanupComplete = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLoaded {
            performInitialLoad()
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
    
    internal func performInitialLoad() {
        tabBarHidden = true
        
        updateHeader()
        setupLayout()
        hideKeyboardWhenTappedAround()
    }
    
    deinit {
        performCleanup()
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            selectedUser = nil
            interviewItem = nil
            allItems.removeAll()
            completedIndex.removeAll()
            cleanupComplete = true
        }
    }
    
    
    /** HEADER FUNCTIONS **/
    internal func updateHeader() {
        addBackButton()
        addMenuButton()
        
        headerNav?.setNav(title: "Interview Request", subtitle: interviewItem != nil ? interviewItem.tag?.itemTitle : nil)
        headerNav?.updateBackgroundImage(image: nil)
        headerNav?.showNavbar(animated: true)
    }
    
    //If we want to go to a right menu button - currently using button in header
    internal func addMenuButton() {
        let menuButton = PulseButton(size: .small, type: .ellipsis, isRound: true, hasBackground: false, tint: .black)
        menuButton.removeShadow()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: menuButton)
        menuButton.addTarget(self, action: #selector(showMenu), for: .touchUpInside)
    }
    
    internal func doneRecording(success: Bool) {
        if success, let selectedIndex = selectedIndex {
            allItems[selectedIndex].itemCreated = true
            tableView.reloadRows(at: [IndexPath(item: selectedIndex, section: 0)], with: .middle)
            submitButton.setEnabled()
        }
    }
    
    private func updateScreen() {
        let interviewRequest = interviewItem.itemTitle != "" ? ": \(interviewItem.itemTitle)" : ""
        let interviewerName = interviewItem.user?.name != nil ? " from \(interviewItem.user!.name!)" : ""
        let channelName = interviewItem.cTitle != nil ? " on \(interviewItem.cTitle!.capitalized) Channel" : ""
        let seriesName = interviewItem.tag?.itemTitle != nil ? " \(interviewItem.tag!.itemTitle)" : " interview"

        headerNav?.setNav(title: "Interview Request", subtitle: "Topic\(interviewRequest)")

        iDescription.text = "You got an interview request\(interviewerName.capitalized). Your interview will be featured in the\(seriesName) series\(channelName)! Completed Qs have a check mark & drafts are saved until you are ready to publish"
        iDescription.numberOfLines = 0
        iDescription.layoutIfNeeded()
    }
    
    private func createInterviewImage() {
        PulseDatabase.getProfilePicForUser(user: PulseUser.currentUser, completion: { image in
            guard let image = image else { return }
            let filteredImage = image.applyInterviewFilter(filteredFrame: CGRect(x: 0, y: 0, width: FULL_IMAGE_WIDTH, height: FULL_IMAGE_WIDTH))
            self.fullImageData = filteredImage?.mediumQualityJPEGNSData
            self.thumbImageData = filteredImage?.resizeImage(newWidth: ITEM_THUMB_WIDTH)?.mediumQualityJPEGNSData
        })
    }
    
    internal func checkPartialInterview() {
        PulseDatabase.getItemCollection(interviewItemID, completion: {[weak self] success, items in
            guard let `self` = self else { return }
            if success {
                for item in items {
                    if let itemIndex = self.allItems.index(of: item) {
                        self.allItems[itemIndex].itemCreated = true
                        self.tableView.reloadRows(at: [IndexPath(item: itemIndex, section: 0)], with: .middle)
                        self.submitButton.setEnabled()
                    }
                }
            }
        })
    }
    
    internal func confirmDecline() {
        let menu = UIAlertController(title: "Are you sure you want to decline the interview?", message: "Interviews are a great way to share your perspectives, build your brand and help improve community's understanding of key issues & topics.", preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "decline Interview", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.markInterviewDeclined()
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .default, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showShare() {
        toggleLoading(show: true, message: "loading share options...", showIcon: true)
        interviewItem.createShareLink(completion: {[weak self] link in
            guard let `self` = self, let link = link else { return }
            self.shareContent(shareType: "interview", shareText: self.interviewItem.itemTitle, shareLink: link)
        })
    }
    
    internal func showMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "decline Interview", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.confirmDecline()
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .default, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showIncompleteMenu() {
        let menu = UIAlertController(title: "Mark Interview Complete?", message: "There are a few questions remaining. Are you sure you want to leave?", preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "mark Complete", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.markInterviewCompleted()
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .default, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func confirmOverwriteAnswer(qItem : Item) {
        let confirmMenu = UIAlertController(title: "Already Answered", message: "Would you like to replace your answer?", preferredStyle: .actionSheet)
        
        confirmMenu.addAction(UIAlertAction(title: "replace Answer", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.askQuestion(qItem: qItem)
        }))
        
        confirmMenu.addAction(UIAlertAction(title: "cancel", style: .default, handler: { (action: UIAlertAction!) in
            confirmMenu.dismiss(animated: true, completion: nil)
        }))
        
        present(confirmMenu, animated: true, completion: nil)
    }
    
    internal func showSuccessMenu() {
        loading?.removeFromSuperview()
        submitButton.setEnabled()
        
        let menu = UIAlertController(title: "All Set! Interview Posted",
                                     message: "Share your interview or tap done to the go back!",
                                     preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "share Interview", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.showShare()
        }))
        
        menu.addAction(UIAlertAction(title: "done", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            menu.dismiss(animated: true, completion: nil)
            self.goBack()
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showErrorMenu(errorTitle : String, error : Error) {
        loading?.removeFromSuperview()
        submitButton.setEnabled()

        let menu = UIAlertController(title: errorTitle, message: error.localizedDescription, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "cancel", style: .default, handler: {(action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
}

//UI Elements
extension InterviewRequestVC {
    internal func setupLayout() {
        view.addSubview(iDescription)

        iDescription.translatesAutoresizingMaskIntoConstraints = false
        iDescription.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        iDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        iDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
        iDescription.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        
        iDescription.numberOfLines = 4
        iDescription.lineBreakMode = .byWordWrapping

        addTableView()
    }
    
    internal func addTableView() {
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        view.addSubview(tableView)
        view.addSubview(submitButton)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: iDescription.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        
        tableView?.register(ListItemCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView?.register(ListItemFooter.self, forHeaderFooterViewReuseIdentifier: headerReuseIdentifier)
        
        tableView?.backgroundView = nil
        tableView?.backgroundColor = UIColor.clear
        tableView?.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        tableView?.separatorColor = UIColor.pulseGrey.withAlphaComponent(0.7)
        
        tableView?.showsVerticalScrollIndicator = false
        tableView?.tableFooterView = UIView()
        
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalToConstant: PulseButton.regularButtonHeight).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true

        submitButton.setDisabled()
        submitButton.addTarget(self, action: #selector(checkInterviewCompleted), for: .touchUpInside)
    }
    
    internal func updateDataSource() {
        if !isLoaded {
            performInitialLoad()
            isLoaded = true
        }
        
        tableView?.dataSource = self
        tableView?.delegate = self
        
        tableView?.layoutIfNeeded()
        tableView?.reloadData()
    }
    
    internal func askQuestion(qItem : Item) {
        guard let userID = PulseUser.currentUser.uID else {
            let errorInfo = [ NSLocalizedDescriptionKey : "please login" ]
            let error = NSError.init(domain: "NotLoggedIn", code: 404, userInfo: errorInfo)
            showErrorMenu(errorTitle: "Please Login", error: error)
            return
        }
        
        contentVC = ContentManagerVC()
        contentVC.selectedChannel = Channel(cID: interviewItem.cID)
        
        //NEEDED TO TO COPY BY VALUE VS REFERENCE
        let newItem = Item(itemID: interviewItem.itemID,
                           itemUserID: userID,
                           itemTitle: qItem.itemTitle,
                           type: interviewItem.type,
                           tag: interviewItem.tag,
                           cID: interviewItem.cID)
        newItem.cTitle = interviewItem.cTitle
        
        contentVC.selectedItem = newItem
        contentVC.openingScreen = .camera
        contentVC.completedRecordingDelegate = self
        contentVC.createdItemKey = qItem.itemID
        present(contentVC, animated: true, completion: nil)
    }
    
    internal func checkInterviewCompleted() {
        submitButton.setDisabled()
        loading = submitButton.addLoadingIndicator()
        
        for item in allItems {
            if !item.itemCreated {
                showIncompleteMenu()
                submitButton.setEnabled()
                loading?.removeFromSuperview()
            } else if item.itemID == allItems.last?.itemID {
                markInterviewCompleted()
            }
        }
    }
    
    internal func markInterviewCompleted() {
        //upload image first so we can add in the URL
        PulseDatabase.uploadImageData(channelID: interviewItem.cID, itemID: interviewItem.itemID, imageData: fullImageData, fileType: .content, completion: {[weak self] (metadata, error) in
            guard let `self` = self else { return }
            
            self.interviewItem.contentURL = metadata?.downloadURL()
            self.addInterviewToDatabase(item: self.interviewItem)
            PulseDatabase.uploadImageData(channelID: self.interviewItem.cID, itemID: self.interviewItem.itemID, imageData: self.thumbImageData, fileType: .thumb, completion: {_ in })
        })
    }
    
    internal func addInterviewToDatabase(item: Item) {
        PulseDatabase.addInterviewToDatabase(interviewItemID: interviewItemID, interviewParentItem: item, completion: {[weak self] (success, error) in
            guard let `self` = self else { return }
            if success {
                self.showSuccessMenu()
            } else {
                self.showErrorMenu(errorTitle: "Error Saving Interview", error: error!)
            }
        })
    }
    
    internal func markInterviewDeclined() {
        toggleLoading(show: true, message: "Declining Interview Request...", showIcon: true)
        PulseDatabase.declineInterview(interviewItemID: interviewItemID, interviewParentItem: interviewItem, conversationID: conversationID, completion: {[weak self] (success, error) in
            guard let `self` = self else { return }

            self.toggleLoading(show: false, message: nil)
            if success {
                self.goBack()
            } else {
                self.showErrorMenu(errorTitle: "Error Declining Interview", error: error!)
            }
        })
    }
    
    internal func addListItem(title : String) {
        let newItem = Item(itemID: PulseDatabase.getKey(forPath: "items"))
        newItem.itemTitle = title
        
        let newIndexPath = IndexPath(row: allItems.count, section: 0)
        allItems.append(newItem)
        tableView.insertRows(at: [newIndexPath], with: .left)
        tableView.scrollToRow(at: newIndexPath, at: .bottom, animated: true)
    }
    
    func userClickedListItem(itemID: String) {
        //ignore - supposed to be for clicking the image link which we don't use
    }
    
    func showMenuFor(itemID: String) {
        //not showing menu
    }
}

extension InterviewRequestVC : UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allItems.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerReuseIdentifier) as? ListItemFooter else {
            return UITableViewHeaderFooterView()
        }
        
        cell.listDelegate = self
        cell.contentView.backgroundColor = UIColor.white
        cell.contentView.layer.cornerRadius = 5
        cell.updateLabels(title: "select / add Question", subtitle: "you can answer any / all questions or add new ones!")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? ListItemCell else {
            return UITableViewCell()
        }
        cell.showItemMenu(show: false)
        let currentItem = allItems[indexPath.row]
        
        if currentItem.itemCreated {
            cell.updateImage(image: UIImage(named: "check"), showBackground: false, showSmallPreview: true, addBorder: true, addInsets: true)
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: currentItem.itemTitle)
            attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, attributeString.length))
            attributeString.addAttribute(NSFontAttributeName, value: UIFont.pulseFont(ofWeight: UIFontWeightThin, size: FontSizes.body2.rawValue), range: NSMakeRange(0, attributeString.length))
            cell.updateAttributedItemDetails(title: nil, subtitle: attributeString, countText: String(indexPath.row + 1))

        } else {
            cell.updateItemDetails(title: nil, subtitle: allItems[indexPath.row].itemTitle, countText: String(indexPath.row + 1))
        }
        
        cell.itemID = String(indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < allItems.count {
            selectedIndex = indexPath.row
            
            if allItems[indexPath.row].itemCreated {
                confirmOverwriteAnswer(qItem: allItems[indexPath.row])
            } else {
                askQuestion(qItem: allItems[indexPath.row])
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.large.rawValue
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return IconSizes.medium.rawValue * 1.2
    }
}
