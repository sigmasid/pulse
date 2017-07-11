//  InterviewRequestReceivedVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/27/17.
//  Copyright © 2017 Think Apart. All rights reserved.


import UIKit

class InterviewRequestVC: PulseVC, CompletedRecordingDelegate {
    
    public var selectedUser : PulseUser!
    public var interviewItem : Item!
    public var conversationID : String?
    
    public var interviewItemID : String! {
        didSet {
            if interviewItem == nil || allQuestions.isEmpty || selectedUser == nil {
                PulseDatabase.getInviteItem(interviewItemID, completion: {[weak self] interviewItem, _, questions, toUser, conversationID, error in
                    guard let `self` = self else { return }

                    self.selectedUser = toUser
                    self.interviewItem = interviewItem
                    self.allQuestions = questions
                    
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
    internal var allQuestions = [Item]()
    internal var selectedIndex : Int?
    internal var completedIndex = [Bool]()

    //UI Elements
    internal var iImage = PulseButton(size: .medium, type: .profile, isRound: true, hasBackground: false, tint: .black)
    internal var iDescription = PaddingLabel()
    internal var submitButton = PulseButton(title: "Finish Interview", isRound: true, hasShadow: false)
    
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
            allQuestions.removeAll()
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
            allQuestions[selectedIndex].itemCreated = true
            tableView.reloadRows(at: [IndexPath(item: selectedIndex, section: 0)], with: .middle)
            submitButton.setEnabled()
        }
    }
    
    private func updateScreen() {
        let interviewRequest = interviewItem.itemTitle != "" ? ": \(interviewItem.itemTitle)" : ""
        let interviewerName = interviewItem.user?.name != nil ? " from \(interviewItem.user!.name!)" : ""
        let channelName = interviewItem.cTitle != nil ? " on Channel \(interviewItem.cTitle!.capitalized)" : ""
        let seriesName = interviewItem.tag?.itemTitle != nil ? " \(interviewItem.tag!.itemTitle)" : " interview"

        headerNav?.setNav(title: "Interview Request", subtitle: "Topic\(interviewRequest)")

        iDescription.text = "You receieved an interview request\(interviewerName.capitalized). Your interview will be featured in the\(seriesName) series\(channelName)!"
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
                    if let itemIndex = self.allQuestions.index(of: item) {
                        self.allQuestions[itemIndex].itemCreated = true
                        self.tableView.reloadRows(at: [IndexPath(item: itemIndex, section: 0)], with: .middle)
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
            self.submitButton.setEnabled()
            self.goBack()
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showErrorMenu(errorTitle : String, error : Error) {
        let menu = UIAlertController(title: errorTitle, message: error.localizedDescription, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "cancel", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            menu.dismiss(animated: true, completion: nil)
            self.submitButton.setEnabled()
        }))
        
        present(menu, animated: true, completion: nil)
    }
}

//UI Elements
extension InterviewRequestVC {
    internal func setupLayout() {
        view.addSubview(iDescription)

        iDescription.translatesAutoresizingMaskIntoConstraints = false
        iDescription.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: Spacing.xxl.rawValue).isActive = true
        iDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        iDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        iDescription.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        
        iDescription.numberOfLines = 4
        iDescription.lineBreakMode = .byWordWrapping

        addTableView()
    }
    
    internal func addTableView() {
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: iDescription.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -IconSizes.xLarge.rawValue).isActive = true
        tableView.layoutIfNeeded()
        
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView?.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: headerReuseIdentifier)
        
        tableView?.backgroundView = nil
        tableView?.backgroundColor = UIColor.clear
        tableView?.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        tableView?.separatorColor = UIColor.pulseGrey.withAlphaComponent(0.7)
        
        tableView?.showsVerticalScrollIndicator = false
        tableView?.layoutIfNeeded()
        tableView?.tableFooterView = UIView()
        
        addSubmitButton()
    }
    
    internal func addSubmitButton() {
        view.addSubview(submitButton)
        
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalToConstant: PulseButton.regularButtonHeight).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        submitButton.layoutIfNeeded()
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
        for item in allQuestions {
            if !item.itemCreated {
                showIncompleteMenu()
            } else if item.itemID == allQuestions.last?.itemID {
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
}

extension InterviewRequestVC : UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allQuestions.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerReuseIdentifier)
        
        if let cell = cell {
            cell.contentView.addBottomBorder()
            cell.contentView.backgroundColor = .clear
            cell.textLabel?.text = "Select a question to answer"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.backgroundView?.backgroundColor = .white
            header.textLabel!.setFont(FontSizes.body.rawValue, weight: UIFontWeightBold, color: .black, alignment: .left)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        cell?.textLabel?.numberOfLines = 3
        cell?.textLabel?.lineBreakMode = .byTruncatingTail
        
        if allQuestions[indexPath.row].itemCreated {
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: allQuestions[indexPath.row].itemTitle)
            attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, attributeString.length))
            attributeString.addAttribute(NSFontAttributeName, value: UIFont.pulseFont(ofWeight: UIFontWeightThin, size: FontSizes.body2.rawValue), range: NSMakeRange(0, attributeString.length))
            
            cell?.accessoryType = .checkmark
            cell?.textLabel?.attributedText = attributeString

        } else {
            cell?.accessoryType = .disclosureIndicator
            cell?.textLabel?.text = allQuestions[indexPath.row].itemTitle
            cell?.textLabel?.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .black, alignment: .left)
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < allQuestions.count {
            selectedIndex = indexPath.row
            
            if allQuestions[indexPath.row].itemCreated {
                confirmOverwriteAnswer(qItem: allQuestions[indexPath.row])
            } else {
                askQuestion(qItem: allQuestions[indexPath.row])
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.medium.rawValue
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return skinnyHeaderHeight
    }
}
