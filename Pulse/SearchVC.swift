//
//  SearchVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/26/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SearchVC: UIViewController {
    private let headerContainer = UIView()
    private var headerImage = UIImageView()
    private var headerTitle = UILabel()
    
    private var searchField = UISearchController(searchResultsController: nil)
    private var iconContainer : IconContainer!
    
    private var toggleTagButton = UIButton()
    private var toggleQuestionButton = UIButton()
    
    
    private var exploreContainer : FeedVC!
    private var isSearchSetup = false
    private var exploreViewSetup = false
    
    private var selectedExploreType : FeedItemType! {
        didSet {
            switch selectedExploreType! {
            case .Question:
                Database.getExploreQuestions({ questions, error in
                    if error == nil {
                        self.exploreContainer.allQuestions = questions
                        self.exploreContainer.feedItemType = self.selectedExploreType
                    }
                })
            case .Tag:
                Database.getExploreTags({ tags, error in
                    if error == nil {
                        self.exploreContainer.allTags = tags
                        self.exploreContainer.feedItemType = self.selectedExploreType
                    }
                })
            case .Answer:
                Database.getExploreAnswers({ answers, error in
                    if error == nil {
                        self.exploreContainer.allAnswers = answers
                        self.exploreContainer.feedItemType = self.selectedExploreType
                    }
                })
            }
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
    
    func updateHeader(tag : Tag) {
        
        headerTitle.text = "#"+(tag.tagID!).uppercaseString
        headerTitle.font = UIFont.systemFontOfSize(FontSizes.Mammoth.rawValue, weight: UIFontWeightHeavy)
        
        if let _tagImage = tag.previewImage {
            Database.getTagImage(_tagImage, maxImgSize: maxImgSize, completion: {(data, error) in
                if error != nil {
                    print (error?.localizedDescription)
                } else {
                    self.headerImage.image = UIImage(data: data!)
                }
            })
        }
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
            
            headerContainer.addSubview(searchField.searchBar)
            
            headerContainer.addSubview(toggleTagButton)
            
            toggleTagButton.translatesAutoresizingMaskIntoConstraints = false
            toggleTagButton.heightAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
            toggleTagButton.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.5).active = true
            toggleTagButton.topAnchor.constraintEqualToAnchor(headerContainer.bottomAnchor).active = true
            toggleTagButton.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
            toggleTagButton.layoutIfNeeded()
            
            headerContainer.addSubview(toggleQuestionButton)
            toggleQuestionButton.translatesAutoresizingMaskIntoConstraints = false
            toggleQuestionButton.heightAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
            toggleQuestionButton.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.5).active = true
            toggleQuestionButton.topAnchor.constraintEqualToAnchor(headerContainer.bottomAnchor).active = true
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
            
            searchField.searchBar.sizeToFit()
            //            searchField.searchResultsUpdater = self
            searchField.dimsBackgroundDuringPresentation = true
            searchField.searchBar.delegate = self
            
            searchField.searchBar.scopeButtonTitles = ["Tags", "Questions", "People"]
            definesPresentationContext = true
            
            isSearchSetup = true
        }
    }
    
    private func setupInitialView() {
        view.addSubview(headerContainer)
        
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.topAnchor.constraintEqualToAnchor(topLayoutGuide.topAnchor, constant: Spacing.s.rawValue).active = true
        headerContainer.widthAnchor.constraintEqualToAnchor(view.widthAnchor).active = true
        headerContainer.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 0.2).active = true
        headerContainer.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        headerContainer.layoutIfNeeded()
        
        headerContainer.addSubview(headerImage)
        headerContainer.addSubview(headerTitle)
        
        headerImage.frame = headerContainer.bounds
        headerImage.contentMode = UIViewContentMode.ScaleAspectFill

        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        headerTitle.topAnchor.constraintEqualToAnchor(headerContainer.topAnchor, constant: Spacing.s.rawValue).active = true
        headerTitle.leadingAnchor.constraintEqualToAnchor(headerContainer.leadingAnchor, constant: Spacing.s.rawValue).active = true
    }
    
    private func setupExplore() {
        if !exploreViewSetup {
            
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
            selectedExploreType = .Tag
            
            GlobalFunctions.addNewVC(exploreContainer, parentVC: self)
            exploreViewSetup = true
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
