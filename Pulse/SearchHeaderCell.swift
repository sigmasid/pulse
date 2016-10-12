//
//  SearchHeaderCellView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SearchHeaderCell: UICollectionReusableView {
//    var showSearchField = UIButton()
    fileprivate var searchBarContainer = UIView()
    fileprivate var scopeBarContainer : UIView!
    var searchController = UISearchController(searchResultsController: nil)
//    var segmentedControl : XMSegmentedControl!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        addSearchBar()
//        searchController.dimsBackgroundDuringPresentation = false
//        searchController.searchBar.sizeToFit()
//        addSubview(searchController.searchBar)
        
//        addSubview(showSearchField)
//        showSearchField.frame = frame.insetBy(dx: 5, dy: 5)
//        showSearchField.setButtonFont(FontSizes.body2.rawValue, weight: UIFontWeightRegular, color: UIColor.lightGray, alignment: .center)
//        showSearchField.backgroundColor = UIColor.white
//
//        let searchTintedImage = UIImage(named: "search")?.withRenderingMode(.alwaysTemplate)
//        showSearchField.setImage(searchTintedImage, for: UIControlState())
//        showSearchField.tintColor = UIColor.lightGray
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func addSearchBar() {
        addSubview(searchBarContainer)
        searchBarContainer.translatesAutoresizingMaskIntoConstraints = false
        searchBarContainer.topAnchor.constraint(equalTo: topAnchor).isActive = true
        searchBarContainer.heightAnchor.constraint(equalToConstant: searchBarHeight).isActive = true
        searchBarContainer.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        searchBarContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        searchBarContainer.layoutIfNeeded()
        
        searchController.searchBar.sizeToFit()
        searchBarContainer.addSubview(searchController.searchBar)
        
        // Setup the Search Controller
        searchController.searchBar.backgroundImage = GlobalFunctions.imageWithColor(UIColor.white)
    }
    
//    func addScopeBar() {
//        
//        if scopeBarContainer == nil {
//            scopeBarContainer = UIView()
//            addSubview(scopeBarContainer)
//            
//            scopeBarContainer.translatesAutoresizingMaskIntoConstraints = false
//            scopeBarContainer.topAnchor.constraint(equalTo: searchController.searchBar.bottomAnchor).isActive = true
//            scopeBarContainer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
//            scopeBarContainer.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
//            scopeBarContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
//            scopeBarContainer.layoutIfNeeded()
//            
//            let tagImage = UIImage(named: "tag")!
//            let questionImage = UIImage(named: "question")!
//            let personImage = UIImage(named: "add")!
//            
//            let titles = ["Tags", "Questions", "People"]
//            let icons = [tagImage, questionImage, personImage]
//            let frame = scopeBarContainer.bounds
//            
//            segmentedControl = XMSegmentedControl(frame: frame, segmentContent: (titles, icons), selectedItemHighlightStyle: XMSelectedItemHighlightStyle.bottomEdge)
//            
//            segmentedControl.backgroundColor = color2
//            segmentedControl.highlightColor = color2
//            segmentedControl.tint = UIColor.lightGray
//            segmentedControl.highlightTint = UIColor.white
//            segmentedControl.font = UIFont.systemFont(ofSize: FontSizes.caption.rawValue, weight: UIFontWeightRegular)
//            
//            scopeBarContainer.addSubview(segmentedControl)
//        } else {
//            scopeBarContainer.isHidden = false
//        }
//    }
//    
//    func hideScopeBar() {
//        if scopeBarContainer != nil {
//            scopeBarContainer.isHidden = true
//        }
//    }
}
