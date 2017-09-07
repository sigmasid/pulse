//
//  EditCollectionVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/23/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import SafariServices

class EditCollectionVC: PulseVC, ListDelegate {
    /** Set by parent **/
    public var selectedChannel : Channel!
    public var selectedItem : Item! {
        didSet {
            PulseDatabase.getListItems(listID: selectedItem.itemID, completion: {[weak self] allItems in
                guard let `self` = self else { return }
                self.allItems = allItems
                self.updateDataSource()
            })
        }
    }
    
    /** List UI Vars **/
    fileprivate var submitButton = PulseButton(title: "Post", isRound: false, hasShadow: false)
    fileprivate var listInstructions = PaddingLabel()
    
    /** Table View Vars **/
    fileprivate var tableView : UITableView!
    fileprivate var allItems = [Item]()
    fileprivate var newItems = [Item]()
    
    fileprivate var cleanupComplete = false
    fileprivate var addMode: AddMode! = .none

    //After user edits / adds description so we set the correct one
    private var selectedItemTag : Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            tabBarHidden = true
            
            updateHeader()
            setupLayout()
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
        headerNav?.setNav(title: selectedItem.itemTitle, subtitle: selectedChannel.cTitle)
        headerNav?.showNavbar(animated: true)
    }
    
    internal func updateDataSource() {
        if tableView != nil {
            tableView?.dataSource = self
            tableView?.delegate = self
            tableView?.isEditing = true
            
            tableView?.layoutIfNeeded()
            tableView?.reloadData()
        }
    }
    
    internal func handleSubmit() {
        guard PulseUser.isLoggedIn() else {
            GlobalFunctions.showAlertBlock("Please login", erMessage: "You must be logged in to create a list!")
            return
        }
        
        PulseDatabase.addNewList(cID: selectedChannel.cID, parentListItem: selectedItem, listItems: allItems, completion: {[weak self] success, error in
            guard let `self` = self else { return }
            if success {
                self.showSuccessMenu()
            } else {
                GlobalFunctions.showAlertBlock("Sorry! Error Creating List", erMessage: error?.localizedDescription)
            }
        })
    }
    
    internal func addListItem(title : String) {
        let newItem = Item(itemID: String(allItems.count))
        newItem.itemTitle = title
        
        let newIndexPath = IndexPath(row: allItems.count, section: 0)
        allItems.append(newItem)
        newItems.append(newItem)
        tableView.insertRows(at: [newIndexPath], with: .left)
        
        if allItems.count == 1 {
            //so it reloads the header
            tableView.reloadData()
        } else {
            tableView.scrollToRow(at: newIndexPath, at: .bottom, animated: true)
        }
    }
    
    internal func userClickedListItem(itemID: String) {
        //check the listID - if it has url - open the URL
        guard let _selectedItemTag = allItems.index(of: Item(itemID: itemID)) else {
            return
        }
        
        let currentItem = allItems[_selectedItemTag]
        
        guard let url = currentItem.linkedURL else {
            return
        }
        
        let svc = SFSafariViewController(url: url)
        present(svc, animated: true, completion: nil)
    }
    
    internal func showSuccessMenu() {
        //offer to go to editCollectionVC -> to rank items
        
        let menu = UIAlertController(title: "Thanks for posting!", message: "click done to go back", preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "done", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.goBack()
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    internal func showMenuFor(itemID: String) {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        guard let _selectedItemTag = allItems.index(of: Item(itemID: itemID)) else {
            return
        }
        
        selectedItemTag = _selectedItemTag
        let currentItem = allItems[_selectedItemTag]
        
        if newItems.index(of: currentItem) != nil {
            
            //edit title option only for items that a user adds
            menu.addAction(UIAlertAction(title: "edit Title", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                guard let `self` = self else { return }
                self.showAddText(buttonText: "Done", bodyText: currentItem.itemTitle, keyboardType: .alphabet)
                self.addMode = .title
                menu.dismiss(animated: true, completion: nil)
            }))
            
            //add link option only for items a user adds
            menu.addAction(UIAlertAction(title: currentItem.linkedURL != nil ? "edit Link" : "add Link", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                guard let `self` = self else { return }
                self.showAddText(buttonText: "Done", bodyText: currentItem.linkedURL != nil ? String(describing: currentItem.linkedURL!) : "http://", keyboardType: UIKeyboardType.URL)
                
                self.addMode = .link
                menu.dismiss(animated: true, completion: nil)
            }))
        }
        
        menu.addAction(UIAlertAction(title: currentItem.itemDescription != "" ? "edit Reason" : "add Reason", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            self.showAddText(buttonText: "Done", bodyText: currentItem.itemDescription != "" ? currentItem.itemDescription : nil, defaultBodyText: "enter reason", keyboardType: .alphabet)
            self.addMode = .description
            menu.dismiss(animated: true, completion: nil)
        }))
        
        //remove option
        menu.addAction(UIAlertAction(title: "remove Item", style: .destructive, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            let indexPath = IndexPath(row: _selectedItemTag, section: 0)
            self.allItems.remove(at: _selectedItemTag)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.selectedItemTag = nil
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
    
    override func addTextDone(_ text: String, sender: UIView) {
        guard let _selectedItemTag = selectedItemTag else {
            return
        }
        
        switch addMode! {
        case .title:
            allItems[_selectedItemTag].itemTitle = text
        case .link:
            guard GlobalFunctions.validateURL(urlString: text), text != "http://" else {
                DispatchQueue.main.async {
                    self.showAddText(buttonText: "Done", bodyText: "http://", keyboardType: .URL)
                }
                return
            }
            allItems[_selectedItemTag].linkedURL = URL(string: text)
        case .description:
            allItems[_selectedItemTag].itemDescription = text
        default: break
        }
        
        let reloadIndexPath = IndexPath(row: _selectedItemTag, section: 0)
        tableView.reloadRows(at: [reloadIndexPath], with: .fade)
        selectedItemTag = nil
        
        addMode = .none
    }
}

extension EditCollectionVC : UITableViewDelegate, UITableViewDataSource {
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
        cell.updateLabels(title: selectedItem.itemTitle, subtitle: selectedItem.itemDescription)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? ListItemCell else {
            return UITableViewCell()
        }
        
        let currentItem = allItems[indexPath.row]
        cell.updateItemDetails(title: currentItem.itemTitle, subtitle: currentItem.itemDescription)
        cell.showItemMenu()
        cell.itemID = currentItem.itemID
        cell.showImageBorder(show: currentItem.linkedURL != nil ? true : false)

        if let image = currentItem.content {
            cell.updateImage(image: image)
        } else if currentItem.contentURL != nil {
            PulseDatabase.getCachedListItemImage(itemID: currentItem.itemID, fileType: FileTypes.content, maxImgSize: MAX_IMAGE_FILESIZE, completion: {[weak self] image in
                guard let `self` = self else { return }
                self.allItems[indexPath.row].content = image
                DispatchQueue.main.async {
                    cell.updateImage(image: image)
                }
            })
        }
        
        cell.listDelegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.large.rawValue * 1.05
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return IconSizes.medium.rawValue * 1.2
    }
    
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        let itemToMove = allItems[fromIndexPath.row]
        allItems.remove(at: fromIndexPath.row)
        allItems.insert(itemToMove, at: toIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}


//UI Elements
extension EditCollectionVC {
    fileprivate func setupLayout() {
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        view.addSubview(tableView)
        view.addSubview(listInstructions)
        view.addSubview(submitButton)
        
        listInstructions.translatesAutoresizingMaskIntoConstraints = false
        listInstructions.topAnchor.constraint(equalTo: view.topAnchor, constant: Spacing.s.rawValue).isActive = true
        listInstructions.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        listInstructions.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
        listInstructions.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalToConstant: PulseButton.regularButtonHeight).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: listInstructions.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: submitButton.topAnchor).isActive = true
        
        tableView?.register(ListItemCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView?.register(ListItemFooter.self, forHeaderFooterViewReuseIdentifier: headerReuseIdentifier)
        
        tableView?.backgroundView = nil
        tableView?.backgroundColor = UIColor.clear
        tableView?.separatorStyle = UITableViewCellSeparatorStyle.none
        
        tableView?.showsVerticalScrollIndicator = false
        tableView?.tableFooterView = UIView()
        
        listInstructions.text = "You can rank / arrange items by dragging & dropping and add an explanation by clicking the menu button"
        
        updateDataSource()
    }
}
