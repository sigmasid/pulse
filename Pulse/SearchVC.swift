//
//  SearchResultsTableVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/28/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

enum SearchTypes {
    case channels
    case users
    case items
}


class SearchVC: PulseVC, XMSegmentedControlDelegate {
    public weak var modalDelegate : ModalDelegate!
    public weak var selectionDelegate : SelectionDelegate!

    fileprivate var searchController = UISearchController(searchResultsController: nil)
    fileprivate var scopeBar : XMSegmentedControl!
    fileprivate var tableView = UITableView()
    fileprivate var headerText = ""
    fileprivate var isSetupComplete = false
    fileprivate var isSearchingPulse = false
    fileprivate var searchScope : SearchTypes! = .channels
    
    var results = [Any]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isSetupComplete {

            definesPresentationContext = false
            
            setupSearch()
            setupScope()
            setupTableView()
            
            isSetupComplete = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //addBackButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    internal func closeSearch() {
        if modalDelegate != nil {
            modalDelegate.userClosedModal(self)
        }
    }
    
    func activateSearch() {
        DispatchQueue.main.async { [] in
            self.searchController.searchBar.becomeFirstResponder()
            self.searchController.isActive = true
        }
    }
    
    //Initial setup for search - controller is set to active when user clicks search
    fileprivate func setupSearch() {
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        searchController.searchBar.barTintColor = UIColor.pulseGrey
        
        headerNav?.getSearchContainer()?.addSubview(searchController.searchBar)
        headerNav?.toggleSearch(show: true)

        searchController.searchBar.sizeToFit()
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.delegate = self
        
        activateSearch()
    }
    
    fileprivate func setupScope() {
        let scopeFrame = CGRect(x: 0, y: 0, width: view.bounds.width, height: SCOPE_HEIGHT)
        scopeBar = XMSegmentedControl(frame: scopeFrame, segmentTitle: ["Channels", "Series", "People"] , selectedItemHighlightStyle: .bottomEdge)
        scopeBar.delegate = self
        scopeBar.addBottomBorder(color: .pulseGrey)
        
        scopeBar.backgroundColor = .clear
        scopeBar.highlightColor = .pulseBlue
        scopeBar.highlightTint = .black
        scopeBar.tint = .gray
        
        view.addSubview(scopeBar)
    }
    
    fileprivate func setupTableView() {
        
        tableView.register(SearchTableCell.self, forCellReuseIdentifier: reuseIdentifier)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: scopeBar.bottomAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tableView.layoutIfNeeded()
        
        tableView.backgroundColor = UIColor.white
        tableView.showsVerticalScrollIndicator = false
        
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .pulseGrey
        tableView.tableFooterView = UIView() //removes extra rows at bottom
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    func xmSegmentedControl(_ xmSegmentedControl: XMSegmentedControl, selectedSegment: Int) {
        switch selectedSegment {
        case 0: searchScope = .channels
        case 1: searchScope = .items
        case 2: searchScope = .users
        default: searchScope = nil
        }
        
        results = []
        tableView.reloadData()
        
        DispatchQueue.main.async { [] in
            self.searchController.searchBar.becomeFirstResponder()
            self.searchController.isActive = true
        }
    }
}

extension SearchVC: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive && searchController.searchBar.text != "" ? (results.count == 0 ? 1 : results.count) : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! SearchTableCell
        
        if results.count == 0  {
            cell.subtitleLabel.text = isSearchingPulse ? "" : "Try another search!"

            switch searchScope! {
                case .channels:
                    cell.titleLabel.text = isSearchingPulse ? "Searching..." : "No channels found"
                    cell.iconButton.setImage(UIImage(named: "channels"), for: UIControlState())
                    cell.iconButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)

                case .items:
                    cell.titleLabel.text = isSearchingPulse ? "Searching..." : "No series found"
                    cell.iconButton.setImage(UIImage(named: "browse-circle"), for: UIControlState())
                    cell.iconButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)

                case .users:
                    cell.titleLabel.text = isSearchingPulse ? "Searching..." : "No user found"
                    cell.iconButton.setImage(UIImage(named: "default-profile"), for: UIControlState())
                    cell.iconButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)

            }
            cell.iconButton.imageView?.contentMode = .scaleAspectFill
            cell.iconButton.imageView?.tintColor = .black
            cell.iconButton.makeRound()

            return cell
        }
        
        switch searchScope! {
        case .channels:
            if let channel = results[indexPath.row] as? Channel {
                cell.titleLabel.text = channel.cTitle?.capitalized
                cell.subtitleLabel.text = channel.cDescription
                cell.iconButton.setImage(UIImage(named: "channels"), for: UIControlState())
                cell.iconButton.imageView?.tintColor = .black
                cell.iconButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
                PulseDatabase.getCachedChannelImage(channelID: channel.cID, fileType: .thumb, completion: { image in
                    if let image = image {
                        DispatchQueue.main.async {
                            cell.iconButton.setImage(image, for: UIControlState())
                            cell.iconButton.imageView?.contentMode = .scaleAspectFill
                            cell.iconButton.makeRound()
                        }
                    }
                })
            }
        case .items:
            if let item = results[indexPath.row] as? Item {
                cell.titleLabel.text = item.itemTitle.capitalized
                cell.subtitleLabel.text = item.itemDescription
                cell.iconButton.setImage(UIImage(named: "browse-circle"), for: UIControlState())
                cell.iconButton.imageView?.tintColor = .black
                cell.iconButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
                PulseDatabase.getCachedSeriesImage(channelID: item.cID, itemID: item.itemID, fileType: .thumb, completion: { image in
                    if let image = image {
                        DispatchQueue.main.async {
                            cell.iconButton.setImage(image, for: UIControlState())
                            cell.iconButton.imageView?.contentMode = .scaleAspectFill
                            cell.iconButton.makeRound()
                        }
                    }
                })
            }
        case .users:
            if let user = results[indexPath.row] as? PulseUser {
                cell.titleLabel.text = user.name?.capitalized
                cell.subtitleLabel.text = user.shortBio?.capitalized
                cell.iconButton.setImage(UIImage(named: "default-profile"), for: UIControlState())
                cell.iconButton.imageView?.tintColor = .black
                cell.iconButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
                PulseDatabase.getCachedUserPic(uid: user.uID!, completion: { image in
                    if let image = image {
                        DispatchQueue.main.async {
                            cell.iconButton.setImage(image, for: UIControlState())
                            cell.iconButton.imageView?.contentMode = .scaleAspectFill
                            cell.iconButton.makeRound()
                        }
                    }
                })
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.medium.rawValue
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = results[indexPath.row]
        if selectionDelegate != nil {
            selectionDelegate.userSelected(item: item)
            closeSearch()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.backgroundView?.backgroundColor = .white
            header.textLabel!.setFont(FontSizes.body2.rawValue, weight: UIFontWeightRegular, color: .black, alignment: .left)
        }
    }
    
    func tableView(_ tableView: UITableView,
                   heightForHeaderInSection section: Int) -> CGFloat{
        return Spacing.xs.rawValue
    }
}

extension SearchVC: UISearchBarDelegate, UISearchResultsUpdating, UISearchControllerDelegate {
    // MARK: - Search controller delegate methods
    
    func updateSearchResults(for searchController: UISearchController) {
        if !results.isEmpty  {
            results = []
            tableView.reloadData()
        }
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchController.searchBar.resignFirstResponder()
        searchBar.endEditing(true)
        
        let _searchText = searchController.searchBar.text!
        
        if _searchText != "" && _searchText.characters.count > 1 {
            isSearchingPulse = true
            results = []

            switch searchScope! {
            case .channels:
                PulseDatabase.searchChannels(searchText: _searchText.lowercased(), completion: {[weak self] searchResults in
                    guard let `self` = self else { return }
                    self.results = searchResults
                    self.isSearchingPulse = false
                })
            case .users:
                PulseDatabase.searchUsers(searchText: _searchText.lowercased(), completion:  {[weak self] searchResults in
                    guard let `self` = self else { return }
                    self.results = searchResults
                    self.isSearchingPulse = false
                })
            case .items:
                PulseDatabase.searchItem(searchText: _searchText.lowercased(), completion:  {[weak self] searchResults in
                    guard let `self` = self else { return }
                    self.results = searchResults
                    self.isSearchingPulse = false
                })
            }
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
        searchController.searchBar.placeholder = "enter search text"
    }
}
