//
//  NewInterviewVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/23/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import CoreLocation
import MobileCoreServices

class NewInterviewVC: PulseVC, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ParentTextViewDelegate, ModalDelegate, SelectionDelegate  {
    //Set by parent
    public var selectedChannel : Channel!
    public var selectedItem : Item!
    
    fileprivate var selectedUser : User!
    
    fileprivate var iImage = PulseButton(size: .small, type: .profile, isRound: true, hasBackground: false, tint: .black)
    fileprivate var iName = UITextField()
    fileprivate var iTopic = UITextField()
    fileprivate var submitButton = UIButton()
    
    fileprivate var sType = PaddingLabel()
    fileprivate var sTypeDescription = PaddingLabel()
    fileprivate var addQuestion : AddText!
    
    //Table View Vars
    fileprivate var tableView : UITableView!
    fileprivate var allQuestions = [String]()
    
    fileprivate var isLoaded = false
    fileprivate var headerSetup = false
    fileprivate let addButton = PulseButton(size: .small, type: .add, isRound: true, background: .white, tint: .black)
    fileprivate let searchButton = PulseButton(size: .small, type: .search, isRound: true, hasBackground: false, tint: .black)

    fileprivate var selectedIndex : Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            tabBarHidden = true
            
            updateHeader()
            setupLayout()
            addChannelExperts()
            hideKeyboardWhenTappedAround()
            
            isLoaded = true
        }
    }
    
    deinit {
        allQuestions = []
    }
    
    /** HEADER FUNCTIONS **/
    internal func updateHeader() {
        addBackButton()
        
        headerNav?.setNav(title: "Start a New Interview", subtitle: selectedChannel.cTitle)
        headerNav?.updateBackgroundImage(image: GlobalFunctions.processImage(selectedChannel.cPreviewImage))
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
    
    internal func handleSubmit() {
        let loading = submitButton.addLoadingIndicator()
        submitButton.setDisabled()
        
        let itemKey = databaseRef.child("items").childByAutoId().key
        let item = Item(itemID: itemKey, type: "interview")
        
        item.itemTitle = iName.text
        item.itemUserID = User.currentUser!.uID
        //item.itemDescription = sMessage.text
        item.cID = selectedChannel.cID
    }

    internal func showSuccessMenu() {
        let menu = UIAlertController(title: "Successfully Added Interview",
                                     message: "Tap okay to return to the series page!",
                                     preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "done", style: .default, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
            self.goBack()
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showErrorMenu(error : Error) {
        let menu = UIAlertController(title: "Error Starting Interview", message: error.localizedDescription, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "cancel", style: .default, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    func userClickedSearchUsers() {
        let browseUsers = MiniUserSearchVC()
        browseUsers.modalPresentationStyle = .overCurrentContext
        browseUsers.modalTransitionStyle = .crossDissolve
        browseUsers.modalDelegate = self
        browseUsers.selectionDelegate = self
        browseUsers.selectedChannel = selectedChannel
        navigationController?.present(browseUsers, animated: true, completion: nil)
    }
    
    func addChannelExperts() {
        if selectedChannel.experts.isEmpty {
            Database.getChannelExperts(channelID: selectedChannel.cID, completion: {success, experts in
                self.selectedChannel.experts = experts
            })
        }
    }
    
    /** Delegate Functions **/
    func userClosedModal(_ viewController : UIViewController) {
        dismiss(animated: true, completion: { _ in })
    }
    
    func dismiss(_ view : UIView) {
        view.removeFromSuperview()
    }
    
    func buttonClicked(_ text: String) {
        if let selectedIndex = selectedIndex {
            let newIndexPath = IndexPath(row: selectedIndex, section: 0)

            allQuestions[selectedIndex] = text
            tableView.reloadRows(at: [newIndexPath], with: .fade)
            self.selectedIndex = nil
            
        } else {
            let newIndexPath = IndexPath(row: 0, section: 0)

            allQuestions.insert(text, at: 0)
            tableView.insertRows(at: [newIndexPath], with: .left)
        }
    }
    
    func userClickedMenu() {
        userClickedMenu(bodyText: "")
    }
    
    func userClickedMenu(bodyText: String, defaultBodyText: String = "type question") {
        addQuestion = AddText(frame: view.bounds, buttonText: "Add", bodyText: bodyText, defaultBodyText: defaultBodyText)
        addQuestion.delegate = self
        view.addSubview(addQuestion)
    }
    
    func userSelected(item : Any) {
        if let user = item as? User {
            selectedUser = user
            iName.text = user.name
            iImage.setImage(selectedUser.thumbPicImage, for: .normal)
            iImage.clipsToBounds = true
            submitButton.setEnabled()
        }
    }
}


extension NewInterviewVC : UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allQuestions.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerReuseIdentifier)
        
        if !headerSetup, let cell = cell {
            addButton.frame.origin = CGPoint(x: 0, y: cell.contentView.bounds.height / 2 - addButton.frame.height / 2)
            
            cell.contentView.addSubview(addButton)
            cell.contentView.backgroundColor = UIColor.white
            addButton.addTarget(self, action: #selector(userClickedMenu as (Void) -> Void), for: .touchUpInside)

            cell.textLabel?.text = "add interview questions"
            cell.textLabel?.setFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: UIColor.black, alignment: .center)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        cell?.accessoryType = .disclosureIndicator
        cell?.textLabel?.text = allQuestions[indexPath.row]
        cell?.textLabel?.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .black, alignment: .left)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedText = allQuestions[indexPath.row]
        selectedIndex = indexPath.row
        userClickedMenu(bodyText: selectedText)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.medium.rawValue
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return IconSizes.medium.rawValue * 1.2
    }
}


//UI Elements
extension NewInterviewVC {
    func setupLayout() {
        view.addSubview(iImage)
        view.addSubview(iName)
        view.addSubview(iTopic)
        view.addSubview(searchButton)
        view.addSubview(submitButton)
        
        iName.translatesAutoresizingMaskIntoConstraints = false
        iName.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: Spacing.xxl.rawValue).isActive = true
        iName.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: Spacing.s.rawValue).isActive = true
        iName.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.65).isActive = true
        iName.layoutIfNeeded()
        
        iImage.translatesAutoresizingMaskIntoConstraints = false
        iImage.trailingAnchor.constraint(equalTo: iName.leadingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        iImage.centerYAnchor.constraint(equalTo: iName.centerYAnchor).isActive = true
        iImage.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        iImage.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        iImage.layoutIfNeeded()
        
        iImage.removeShadow()
        
        iTopic.translatesAutoresizingMaskIntoConstraints = false
        iTopic.topAnchor.constraint(equalTo: iName.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        iTopic.leadingAnchor.constraint(equalTo: iName.leadingAnchor).isActive = true
        iTopic.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.65).isActive = true
        iTopic.layoutIfNeeded()
        
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.trailingAnchor.constraint(equalTo: iName.trailingAnchor).isActive = true
        searchButton.bottomAnchor.constraint(equalTo: iName.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        searchButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        searchButton.heightAnchor.constraint(equalTo: searchButton.widthAnchor).isActive = true
        searchButton.layoutIfNeeded()
        searchButton.removeShadow()
        
        searchButton.addTarget(self, action: #selector(userClickedSearchUsers), for: .touchUpInside)
        
        iName.delegate = self
        iName.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        iName.layer.addSublayer(GlobalFunctions.addBorders(self.iName, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        iName.attributedPlaceholder = NSAttributedString(string: "enter name or tap search",
                                                          attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        
        iTopic.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        iTopic.layer.addSublayer(GlobalFunctions.addBorders(self.iName, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        iTopic.attributedPlaceholder = NSAttributedString(string: "brief description for interview",
                                                         attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        
        addTableView()
        addSubmitButton()
        
    }
    
    internal func addTableView() {
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        view.addSubview(tableView)
        view.addSubview(sTypeDescription)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: iTopic.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        tableView.heightAnchor.constraint(equalToConstant: 275).isActive = true
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
        
        sTypeDescription.translatesAutoresizingMaskIntoConstraints = false
        sTypeDescription.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        sTypeDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sTypeDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        sTypeDescription.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        sTypeDescription.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        
        sTypeDescription.numberOfLines = 3
        sTypeDescription.text = "the interviewee can answer any or all of your suggested questions. interview requests are sent directly to Pulse users or you can choose to send requests via email or text message next."
        
        updateDataSource()
    }
    
    internal func addSubmitButton() {
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.topAnchor.constraint(equalTo: sTypeDescription.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        
        submitButton.layer.cornerRadius = buttonCornerRadius.radius(.regular)
        submitButton.setTitle("Send Interview Request", for: UIControlState())
        submitButton.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        submitButton.setDisabled()
        
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
    }
}

extension NewInterviewVC: UITextFieldDelegate, UITextViewDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == iName, textField.text != "" {
            submitButton.setEnabled()
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string == "\n" {
            textField.resignFirstResponder()
            return false
        }
        
        let  char = string.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        
        if isBackSpace == -92, textField.text != "" {
            return true
        }
        
        return true
    }
}
