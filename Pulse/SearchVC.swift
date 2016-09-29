//
//  SearchVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/26/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SearchVC: UIViewController {
    fileprivate let headerContainer = UIView()
    fileprivate var headerImage = UIImageView()
    fileprivate var headerTitle = UILabel()
    
    fileprivate var searchField = UISearchController(searchResultsController: nil)
    fileprivate var iconContainer : IconContainer!
    
    fileprivate var toggleTagButton = UIButton()
    fileprivate var toggleQuestionButton = UIButton()
    
    fileprivate var exploreContainer : FeedVC!
    fileprivate var isSearchSetup = false
    fileprivate var exploreViewSetup = false
        
    fileprivate var selectedExploreType : FeedItemType! {
        didSet {
            switch selectedExploreType! {
            case .question:
                Database.getExploreQuestions({ questions, error in
                    if error == nil {
                        self.exploreContainer.allQuestions = questions
                        self.exploreContainer.feedItemType = self.selectedExploreType
                    }
                })
            case .tag:
                Database.getExploreTags({ tags, error in
                    if error == nil {
                        self.exploreContainer.allTags = tags
                        self.exploreContainer.feedItemType = self.selectedExploreType
                    }
                })
            case .answer:
                Database.getExploreAnswers({ answers, error in
                    if error == nil {
                        self.exploreContainer.allAnswers = answers
                        self.exploreContainer.feedItemType = self.selectedExploreType
                    }
                })
            }
        }
    }
    
    fileprivate var panPresentInteractionController = PanEdgeInteractionController()

    //set by delegate
    var rootVC : UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialView()
        setupSearch()
        setupExplore()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func toggleTags() {
        if selectedExploreType != .tag {
            selectedExploreType = .tag
        }
    }
    
    func toggleQuestions() {
        if selectedExploreType != .question {
            selectedExploreType = .question
        }
    }
    
    func updateHeader(_ tag : Tag) {
        
        headerTitle.text = "#"+(tag.tagID!).uppercased()
        headerTitle.font = UIFont.systemFont(ofSize: FontSizes.mammoth.rawValue, weight: UIFontWeightHeavy)
        
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
            view.backgroundColor = UIColor.white
            
            iconContainer = IconContainer(frame: CGRect(x: 0,y: 0,width: IconSizes.medium.rawValue, height: IconSizes.medium.rawValue + Spacing.m.rawValue))
            iconContainer.setViewTitle("EXPLORE")
            view.addSubview(iconContainer)
            
            iconContainer.translatesAutoresizingMaskIntoConstraints = false
            iconContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
            iconContainer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue + Spacing.m.rawValue).isActive = true
            iconContainer.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
            iconContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
            iconContainer.layoutIfNeeded()
            
            headerContainer.addSubview(searchField.searchBar)
            headerContainer.addSubview(toggleTagButton)
            
            toggleTagButton.translatesAutoresizingMaskIntoConstraints = false
            toggleTagButton.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
            toggleTagButton.widthAnchor.constraint(equalTo: headerContainer.widthAnchor, multiplier: 0.5).isActive = true
            toggleTagButton.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor).isActive = true
            toggleTagButton.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor).isActive = true
            toggleTagButton.layoutIfNeeded()
            
            headerContainer.addSubview(toggleQuestionButton)
            toggleQuestionButton.translatesAutoresizingMaskIntoConstraints = false
            toggleQuestionButton.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
            toggleQuestionButton.widthAnchor.constraint(equalTo: headerContainer.widthAnchor, multiplier: 0.5).isActive = true
            toggleQuestionButton.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor).isActive = true
            toggleQuestionButton.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor).isActive = true
            toggleQuestionButton.layoutIfNeeded()
            
            toggleTagButton.backgroundColor = UIColor.black
            toggleQuestionButton.backgroundColor = UIColor.black
            
            toggleTagButton.titleLabel?.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: UIColor.white, alignment: .center)
            toggleQuestionButton.titleLabel?.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: UIColor.white, alignment: .center)
            
            toggleTagButton.setTitle("TAGS", for: UIControlState())
            toggleQuestionButton.setTitle("QUESTIONS", for: UIControlState())
            
            toggleTagButton.addTarget(self, action: #selector(toggleTags), for: .touchUpInside)
            toggleQuestionButton.addTarget(self, action: #selector(toggleQuestions), for: .touchUpInside)
            
            searchField.searchBar.sizeToFit()
            //            searchField.searchResultsUpdater = self
            searchField.dimsBackgroundDuringPresentation = true
            searchField.searchBar.delegate = self
            
            searchField.searchBar.scopeButtonTitles = ["Tags", "Questions", "People"]
            definesPresentationContext = true
            
            isSearchSetup = true
        }
    }
    
    fileprivate func setupInitialView() {
        view.addSubview(headerContainer)
        
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor, constant: Spacing.s.rawValue).isActive = true
        headerContainer.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        headerContainer.heightAnchor.constraint(equalToConstant: searchField.searchBar.frame.height + IconSizes.medium.rawValue).isActive = true
        headerContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        headerContainer.layoutIfNeeded()
        
        headerContainer.addSubview(headerImage)
        headerContainer.addSubview(headerTitle)
        
        headerImage.frame = headerContainer.bounds
        headerImage.contentMode = UIViewContentMode.scaleAspectFill

        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        headerTitle.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: Spacing.s.rawValue).isActive = true
        headerTitle.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: Spacing.s.rawValue).isActive = true
    }
    
    fileprivate func setupExplore() {
        if !exploreViewSetup {
            
            let containerView = UIView()
            view.addSubview(containerView)
            
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            containerView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor).isActive = true
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            containerView.layoutIfNeeded()
            
            exploreContainer = FeedVC()
            exploreContainer.view.frame = containerView.frame
            selectedExploreType = .question
            
            GlobalFunctions.addNewVC(exploreContainer, parentVC: self)
            exploreViewSetup = true
        }
    }
}

extension SearchVC: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
//        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

extension SearchVC: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
//        filterContentForSearchText(searchController.searchBar.text!, scope: scope)
    }
}
