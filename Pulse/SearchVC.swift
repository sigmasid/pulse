//
//  SearchVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/26/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SearchVC: UIViewController {
    private let searchContainer = UIView()
    private var searchField = UISearchController(searchResultsController: nil)
    private var iconContainer : IconContainer!
    
    private var toggleTagButton = UIButton()
    private var toggleQuestionButton = UIButton()
    
    
    private var exploreContainer : FeedVC!
    private var isSearchSetup = false
    private var exploreViewSetup = false
    
    private var selectedExploreType : FeedItemType! {
        didSet {
            print("set feed item type")
            exploreContainer.feedItemType = selectedExploreType
        }
    }
    
    private var panPresentInteractionController = PanEdgeInteractionController()

    //set by delegate
    var rootVC : UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearch()
        setupExplore()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupSearch() {
        if !isSearchSetup {
            view.backgroundColor = UIColor.whiteColor()
            
            iconContainer = IconContainer(frame: CGRectMake(0,0,IconSizes.Medium.rawValue, IconSizes.Medium.rawValue + Spacing.m.rawValue))
            iconContainer.setViewTitle("EXPLORE")
            view.addSubview(iconContainer)
            
            iconContainer.translatesAutoresizingMaskIntoConstraints = false
            iconContainer.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -Spacing.s.rawValue).active = true
            iconContainer.heightAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue + Spacing.m.rawValue).active = true
            iconContainer.widthAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
            iconContainer.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor, constant: -Spacing.s.rawValue).active = true
            iconContainer.layoutIfNeeded()
            
            view.addSubview(searchContainer)
            searchContainer.translatesAutoresizingMaskIntoConstraints = false
            searchContainer.topAnchor.constraintEqualToAnchor(topLayoutGuide.topAnchor, constant: Spacing.s.rawValue).active = true
            searchContainer.widthAnchor.constraintEqualToAnchor(view.widthAnchor).active = true
            searchContainer.heightAnchor.constraintEqualToConstant(IconSizes.Large.rawValue).active = true
            searchContainer.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
            searchContainer.layoutIfNeeded()
            
            searchContainer.addSubview(searchField.searchBar)
            searchField.searchBar.sizeToFit()
//            searchField.searchResultsUpdater = self
            searchField.dimsBackgroundDuringPresentation = true
            searchField.searchBar.delegate = self

            searchField.searchBar.scopeButtonTitles = ["Tags", "Questions", "People"]
            definesPresentationContext = true

            isSearchSetup = true
        }
    }
    
    private func setupExplore() {
        if !exploreViewSetup {
            
            view.addSubview(toggleTagButton)
            toggleTagButton.translatesAutoresizingMaskIntoConstraints = false
            toggleTagButton.heightAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
            toggleTagButton.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.5).active = true
            toggleTagButton.topAnchor.constraintEqualToAnchor(searchContainer.bottomAnchor).active = true
            toggleTagButton.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
            toggleTagButton.layoutIfNeeded()
            
            view.addSubview(toggleQuestionButton)
            toggleQuestionButton.translatesAutoresizingMaskIntoConstraints = false
            toggleQuestionButton.heightAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
            toggleQuestionButton.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.5).active = true
            toggleQuestionButton.topAnchor.constraintEqualToAnchor(searchContainer.bottomAnchor).active = true
            toggleQuestionButton.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
            toggleQuestionButton.layoutIfNeeded()
            
            toggleTagButton.backgroundColor = UIColor.blackColor()
            toggleQuestionButton.backgroundColor = UIColor.blackColor()
            
            toggleTagButton.titleLabel?.setFont(FontSizes.Caption.rawValue, weight: UIFontWeightRegular, color: UIColor.whiteColor(), alignment: .Center)
            toggleQuestionButton.titleLabel?.setFont(FontSizes.Caption.rawValue, weight: UIFontWeightRegular, color: UIColor.whiteColor(), alignment: .Center)
            
            toggleTagButton.setTitle("TAGS", forState: .Normal)
            toggleQuestionButton.setTitle("QUESTIONS", forState: .Normal)
            
            toggleTagButton.addTarget(self, action: #selector(toggleTags), forControlEvents: .TouchUpInside)
            toggleQuestionButton.addTarget(self, action: #selector(toggleQuestions), forControlEvents: .TouchUpInside)

            let containerView = UIView()
            view.addSubview(containerView)
            
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
            containerView.topAnchor.constraintEqualToAnchor(toggleTagButton.bottomAnchor).active = true
            containerView.widthAnchor.constraintEqualToAnchor(view.widthAnchor).active = true
            containerView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
            containerView.layoutIfNeeded()
            
            exploreContainer = FeedVC()
            exploreContainer.view.frame = containerView.frame
            exploreContainer.pageType = .Explore
            selectedExploreType = .Tag

            GlobalFunctions.addNewVC(exploreContainer, parentVC: self)
            exploreViewSetup = true
        }
    }
    
    func toggleTags() {
        if selectedExploreType != .Tag {
            selectedExploreType = .Tag
        }
    }
    
    func toggleQuestions() {
        if selectedExploreType != .Question {
            selectedExploreType = .Question
        }
    }
}

extension SearchVC: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
//        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

extension SearchVC: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
//        filterContentForSearchText(searchController.searchBar.text!, scope: scope)
    }
}
