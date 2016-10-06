//
//  SearchResultsTableVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SearchVC: UIViewController {
    fileprivate var reuseIdentifier = "tableViewCell"
    fileprivate var searchController : UISearchController!
    fileprivate var tableView = UITableView()
    
    fileprivate var searchScope : SearchTypes? = .tags
    fileprivate enum SearchTypes { case tags, questions, users }
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
        
        setupTableView()
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    fileprivate func setupTableView() {
        searchController = UISearchController(searchResultsController: nil) //needs to be here as tableview uses it
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)

        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tableView.layoutIfNeeded()
        
        tableView.backgroundColor = UIColor.white
        tableView.showsVerticalScrollIndicator = false
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()

        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.isTranslucent = false
        searchController.searchBar.backgroundImage = GlobalFunctions.imageWithColor(UIColor.white)
        searchController.searchBar.scopeBarBackgroundImage = GlobalFunctions.imageWithColor(UIColor.white)
        searchController.searchBar.scopeButtonTitles = ["Tags","Questions","People"]
        
        let searchTextAttributes = [ NSForegroundColorAttributeName: UIColor.black ]
        searchController.searchBar.setScopeBarButtonTitleTextAttributes(searchTextAttributes, for: .normal)
        searchController.searchBar.setScopeBarButtonDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal)
        
        tableView.tableHeaderView?.backgroundColor = UIColor.white
        tableView.tableHeaderView = searchController.searchBar
        
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.isActive = true
        searchController.searchBar.becomeFirstResponder()

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
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cell.textLabel?.text = searchScope == .tags ? results[indexPath.row].key : results[indexPath.row].value
        return cell
    }
}

extension SearchVC: UISearchBarDelegate, UISearchResultsUpdating {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        switch selectedScope {
        case 0: searchScope = .tags
        case 1: searchScope = .questions
        case 2: searchScope = .users
        default: searchScope = nil
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let _searchText = searchController.searchBar.text!
        
        if _searchText != "" && _searchText.characters.count > 1 {
            switch searchScope! {
            case .tags:
                Database.search(type: .tag, searchText: _searchText.lowercased(), completion:  { searchResults in
                        self.results = searchResults
                })
            case .questions:
                Database.search(type: .question, searchText: _searchText.lowercased(), completion:  { searchResults in
                    self.results = searchResults
                })
            default: break
            }
        }
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        GlobalFunctions.dismissVC(self)
    }
}
