//
//  SearchResultsTableVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

protocol searchVCDelegate: class {
    func userCancelledSearch()
    func userSelectedSearchResult(type : ItemTypes?, id : String)
}


class SearchVC: UIViewController, XMSegmentedControlDelegate {
    fileprivate var reuseIdentifier = "tableViewCell"
    fileprivate var searchController = UISearchController(searchResultsController: nil)
    fileprivate var searchBarContainer = UIView()
    fileprivate var scopeBarContainer = UIView()
    fileprivate var tableView = UITableView()
    
    fileprivate var isSetupComplete = false
    
    fileprivate var searchScope : ItemTypes? = .tag
    var searchDelegate : searchVCDelegate!

    var results = [(key:String , value:String)]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isSetupComplete {
            isSetupComplete = true
            
            addSearchBar()
            setupTableView()
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    fileprivate func addSearchBar() {
        view.addSubview(searchBarContainer)
        searchBarContainer.translatesAutoresizingMaskIntoConstraints = false
        searchBarContainer.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        searchBarContainer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        searchBarContainer.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        searchBarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        searchBarContainer.layoutIfNeeded()
        
        searchController.searchBar.sizeToFit()
        searchBarContainer.addSubview(searchController.searchBar)
        definesPresentationContext = true
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.backgroundImage = GlobalFunctions.imageWithColor(UIColor.white)

        searchController.dimsBackgroundDuringPresentation = false
        searchController.isActive = true
        searchController.searchBar.becomeFirstResponder()

    }
    
    fileprivate func setupTableView() {
        
        tableView.register(SearchTableCell.self, forCellReuseIdentifier: reuseIdentifier)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: scopeBarContainer.bottomAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tableView.layoutIfNeeded()
        
        tableView.backgroundColor = UIColor.white
        tableView.showsVerticalScrollIndicator = false
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    func xmSegmentedControl(_ xmSegmentedControl: XMSegmentedControl, selectedSegment: Int) {
        switch selectedSegment {
        case 0: searchScope = .tag
        case 1: searchScope = .question
        case 2: searchScope = .user
        default: searchScope = nil
        }
    }
}

extension SearchVC: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive && searchController.searchBar.text != "" ? results.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! SearchTableCell
        cell.titleLabel.text = searchScope == .tag ? results[indexPath.row].key : results[indexPath.row].value
        cell.subtitleLabel.text = searchScope == .tag ? results[indexPath.row].value : ""
        
        cell.iconButton.setImage(searchScope == .tag ? UIImage(named: "tag") : UIImage(named: "question"), for: UIControlState())
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.large.rawValue
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = results[indexPath.row].key
        searchDelegate.userSelectedSearchResult(type: searchScope, id: id)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection: Int) -> UIView? {
        let headerView = UIView()
        let activityIndicatorView = UIActivityIndicatorView()
        let activityLabel = UILabel()
        
        headerView.addSubview(activityIndicatorView)
        headerView.addSubview(activityLabel)

        activityLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightMedium, color: .black, alignment: .center)
        activityLabel.text = "Searching..."
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView,
                   heightForHeaderInSection section: Int) -> CGFloat{
        return IconSizes.medium.rawValue
    }
}

extension SearchVC: UISearchBarDelegate, UISearchResultsUpdating {
    // MARK: - Search controller delegate methods
    
    func updateSearchResults(for searchController: UISearchController) {
        let _searchText = searchController.searchBar.text!
        
        if _searchText != "" && _searchText.characters.count > 1 {
            //implement
        } else if _searchText == "" {
            //empty the dictionary
        }
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        GlobalFunctions.dismissVC(self)
    }
}
