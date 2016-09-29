//
//  SearchHeaderCellView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SearchHeaderCell: UICollectionReusableView {
    var searchField = UISearchController(searchResultsController: nil)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        print("header view fired")
        
        addSubview(searchField.searchBar)
        searchField.searchBar.sizeToFit()
        searchField.dimsBackgroundDuringPresentation = true
        searchField.searchBar.scopeButtonTitles = ["Tags", "Questions", "People"]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
