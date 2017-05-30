//
//  MiniUserSearch.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/23/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class MiniUserSearchVC: PulseVC, UIGestureRecognizerDelegate, SelectionDelegate {
    
    public var selectedChannel : Channel! {
        didSet {
            if selectedChannel != nil, selectedChannel.contributors.isEmpty {
                Database.getChannelContributors(channelID: selectedChannel.cID, completion: {success, users in
                    self.users = users
                })
            } else {
                users = selectedChannel.contributors
            }
        }
    }
    public var modalDelegate : ModalDelegate!
    public var selectionDelegate : SelectionDelegate!
    
    fileprivate var searchController = UISearchController(searchResultsController: nil)
    fileprivate var searchContainer = UIView()
    fileprivate var collectionView : UICollectionView!
    fileprivate let collectionViewHeight =  IconSizes.xLarge.rawValue

    fileprivate var headerText = ""
    
    fileprivate var isSetupComplete = false
    fileprivate var observersAdded = false
    fileprivate var tap: UITapGestureRecognizer!

    var users = [User]() {
        didSet {
            if collectionView != nil {
                collectionView.reloadData()
            }
        }
    }
    fileprivate var defaultUsers = [User]() //store the initial expert list
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isSetupComplete {
            
            definesPresentationContext = false
            
            addObservers()
            setupCollectionView()
            setupSearch()
            
            isSetupComplete = true
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addBackButton()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        if tap != nil {
            view.removeGestureRecognizer(tap)
        }
    }
    
    internal func closeSearch() {
        if modalDelegate != nil {
            UIView.animate(withDuration: 0.2, animations: {
                self.collectionView.frame.origin.y = self.view.bounds.maxY + searchBarHeight
                self.searchContainer.frame.origin.y = self.view.bounds.maxY
                
                self.collectionView.alpha = 0
                self.searchContainer.alpha = 0

            }, completion: {(value: Bool) in
                self.collectionView.layoutIfNeeded()
                self.searchContainer.layoutIfNeeded()
                
                self.collectionView.alpha = 1
                self.searchContainer.alpha = 1
                
                self.modalDelegate.userClosedModal(self)
            })
        }
    }
    
    internal func activateSearch() {
        DispatchQueue.main.async { [] in
            self.searchController.searchBar.becomeFirstResponder()
            self.searchController.isActive = true
        }
    }
    
    func addObservers() {
        if !observersAdded {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
            view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            
            tap = UITapGestureRecognizer(target: self, action: #selector(closeSearch))
            tap.cancelsTouchesInView = false
            tap.isEnabled = true
            tap.delegate = self
            view.addGestureRecognizer(tap)
            
            observersAdded = true
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        tap.isEnabled = false
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            
            UIView.animate(withDuration: 0.2, animations: {
                self.collectionView.frame.origin.y = self.view.bounds.maxY - self.collectionViewHeight - keyboardHeight
                self.searchContainer.frame.origin.y = self.view.bounds.maxY - self.collectionViewHeight - searchBarHeight - keyboardHeight
            }, completion: {(value: Bool) in
                self.collectionView.layoutIfNeeded()
                self.searchContainer.layoutIfNeeded()
            })
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        tap.isEnabled = true

        UIView.animate(withDuration: 0.2, animations: {
            self.collectionView.frame.origin.y = self.view.bounds.maxY - self.collectionViewHeight
            self.searchContainer.frame.origin.y = self.view.bounds.maxY - self.collectionViewHeight - searchBarHeight
        }, completion: {(value: Bool) in
            self.collectionView.layoutIfNeeded()
            self.searchContainer.layoutIfNeeded()
        })
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: view)

        if collectionView.frame.contains(point) {
            return false
        }
        
        return true
    }
    
    
    //Initial setup for search - controller is set to active when user clicks search
    fileprivate func setupSearch() {
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        searchController.searchBar.barTintColor = UIColor.pulseGrey
        
        view.addSubview(searchContainer)
        searchContainer.frame = CGRect(x: 0, y: view.bounds.maxY - collectionViewHeight - searchBarHeight, width: self.view.frame.width, height: searchBarHeight)
        searchContainer.backgroundColor = .white
        searchController.searchBar.frame = searchContainer.bounds
        
        searchContainer.addSubview(searchController.searchBar)
        searchController.searchBar.sizeToFit()
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.delegate = self
        
        searchContainer.addBottomBorder()
    }
    
    fileprivate func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 5
        
        
        
        let collectionViewFrame = CGRect(x: 0, y: view.bounds.maxY - collectionViewHeight,
                                         width: view.frame.width, height: collectionViewHeight)
        collectionView = UICollectionView(frame: collectionViewFrame, collectionViewLayout: layout)
        collectionView.register(HeaderCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        view.addSubview(collectionView)
        
        collectionView.backgroundColor = .white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    internal func userSelected(item : Any) {
        if selectionDelegate != nil, let index = item as? Int {
            selectionDelegate.userSelected(item: users[index])
            closeSearch()
        }
    }
}

extension MiniUserSearchVC: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! HeaderCell
        cell.delegate = self
        cell.tag = indexPath.row
        
        let _user = users[indexPath.row]
        
        if !_user.uCreated {
            cell.updateImage(image : UIImage(named: "default-profile"))

            Database.getUser(_user.uID!, completion: { (user, error) in
                if let user = user {
                    cell.updateCell(user.name?.capitalized, _image: nil)
                    
                    self.users[indexPath.row] = user
                    
                    if let _uPic = user.profilePic {
                        DispatchQueue.global(qos: .background).async {
                            if let _userImageData = try? Data(contentsOf: URL(string: _uPic)!) {
                                
                                DispatchQueue.main.async {
                                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                        self.users[indexPath.row].thumbPicImage = UIImage(data: _userImageData)
                                        cell.updateImage(image : UIImage(data: _userImageData))
                                    }
                                }
                            }
                        }
                    }
                }
            })
        } else {
            if _user.thumbPicImage != nil {
                cell.updateCell(_user.name?.capitalized, _image : _user.thumbPicImage)
            } else if let _uPic = _user.thumbPic {
                cell.updateCell(_user.name?.capitalized, _image: UIImage(named: "default-profile"))
                
                DispatchQueue.global(qos: .background).async {
                    if let _userImageData = try? Data(contentsOf: URL(string: _uPic)!) {
                        if self.users.count > indexPath.row {
                            self.users[indexPath.row].thumbPicImage = UIImage(data: _userImageData)
                        }
                        
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            DispatchQueue.main.async {
                                cell.updateCell(_user.name?.capitalized, _image : UIImage(data: _userImageData))
                            }
                        }
                    }
                }
            } else {
                cell.updateCell(_user.name?.capitalized, _image: UIImage(named: "default-profile"))
            }
        }
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width / 4.5, height: collectionViewHeight - Spacing.s.rawValue)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        userSelected(item: users[indexPath.row])
    }
}

extension MiniUserSearchVC: UISearchBarDelegate, UISearchResultsUpdating, UISearchControllerDelegate {
    // MARK: - Search controller delegate methods
    
    func updateSearchResults(for searchController: UISearchController) {
        headerText = "Searching..."
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        if searchBar.text != "" {
            return false
        }
        return true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if searchBar.text == "", !defaultUsers.isEmpty {
            users = defaultUsers
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchController.isActive = true
        searchBar.endEditing(false)
        
        if defaultUsers.isEmpty {
            defaultUsers = users
        }
        
        users = [] //empty the collection
        let _searchText = searchController.searchBar.text!
        
        if _searchText != "" && _searchText.characters.count > 1 {
            Database.searchUsers(searchText: _searchText.lowercased(), completion:  { searchResults in
                self.users = searchResults
            })
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        closeSearch()
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async { [] in
            searchController.searchBar.showsCancelButton = true
            searchController.searchBar.tintColor = .black
            searchController.searchBar.becomeFirstResponder()
        }
        searchController.searchBar.placeholder = "search pulse - enter name"
    }
}
