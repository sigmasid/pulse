//
//  SearchVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/26/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class ExploreVC: UIViewController, feedVCDelegate, XMSegmentedControlDelegate {
    
    fileprivate var iconContainer : IconContainer!
    fileprivate var headerContainer : ExploreHeader!
    fileprivate var exploreContainer : FeedVC!
    
    fileprivate var questionSelectedConstaint : NSLayoutConstraint!
    fileprivate var tagSelectedConstaint : NSLayoutConstraint!
    fileprivate var minimalHeaderHeightConstraint : NSLayoutConstraint!
    fileprivate var regularHeaderHeightConstraint : NSLayoutConstraint!
    
    fileprivate var isFollowingSelectedTag : Bool = false {
        didSet {
            isFollowingSelectedTag ? headerContainer.updateFollowButton(.unfollow) : headerContainer.updateFollowButton(.follow)
        }
    }
    
    fileprivate var isLoaded = false
    fileprivate var isSearchActive = false

    fileprivate var selectedExploreType : FeedItemType? {
        didSet {
            if isSearchActive {
                self.headerContainer.updateScopeBar(type: .search)
                updateSearchResults(for: headerContainer.searchController)

            } else if selectedExploreType != nil {
                self.headerContainer.updateScopeBar(type: .explore)

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
                case .people:
                    break
                }
            }
        }
    }
    
    fileprivate var selectedTagDetail : Tag! {
        didSet {
            if !selectedTagDetail.tagCreated {
                Database.getTag(selectedTagDetail.tagID!, completion: { tag, error in
                    if error == nil && tag.totalQuestionsForTag() > 0 {
                        self.exploreContainer.clearSelected()
                        self.exploreContainer.allQuestions = tag.questions!
                        self.exploreContainer.feedItemType = .question
                    }
                })
            } else {
                self.exploreContainer.clearSelected()
                self.exploreContainer.allQuestions = selectedTagDetail.questions
                self.exploreContainer.feedItemType = .question
            }
        }
    }
    
    fileprivate var selectedQuestion : Question!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLoaded {
            setupExplore()
            iconContainer = addIcon(text: "EXPLORE")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /* DELEGATE METHODS */
    
    //feedVCDelegate methods
    func userSelected(type : FeedItemType, item : Any) {
        
        switch type {
        case .tag:
            isSearchActive = false

            selectedTagDetail = item as! Tag //didSet method pulls questions from database in case of search else assigns questions from existing tag
            selectedExploreType = nil
            
            headerContainer.currentMode = .detail
            headerContainer.updateScopeBar(type: .tag)
            headerContainer.segmentedControl.selectedSegment = 0
            
            if User.currentUser?.savedTags != nil && User.currentUser!.savedTags[selectedTagDetail.tagID!] != nil {
                isFollowingSelectedTag = true
            } else {
                isFollowingSelectedTag = false
            }
            
            if let _tagImage = selectedTagDetail.previewImage {
                self.headerContainer.updateHeader(title: self.selectedTagDetail.tagID!, subtitle: self.selectedTagDetail.tagDescription, image : nil)
                Database.getTagImage(_tagImage, maxImgSize: maxImgSize, completion: {(data, error) in
                    if error != nil {
                        print (error?.localizedDescription)
                    } else {
                        self.headerContainer.updateHeader(title: self.selectedTagDetail.tagID!, subtitle: self.selectedTagDetail.tagDescription, image : UIImage(data: data!))
                    }
                })
            } else {
                headerContainer.updateHeader(title: selectedTagDetail.tagID!, subtitle: selectedTagDetail.tagDescription, image : nil)
            }
        case .question:
            selectedQuestion = item as! Question //didSet method pulls questions from database in case of search else assigns questions from existing tag
            
            exploreContainer.currentTag = isSearchActive ? Tag(tagID: "SEARCH") : Tag(tagID : "EXPLORE")
            headerContainer.updateHeader(title: headerContainer.headerTitle.text!, subtitle: selectedQuestion.qTitle, image : nil)
            headerContainer.updateScopeBar(type: .question)

        case .people:
            headerContainer.updateScopeBar(type: .people)

        default: break
        }
    }
    
    func userClickedSearch() {
        isSearchActive = true
        headerContainer.currentMode = .search
        headerContainer.updateHeader(title: "SEARCH", subtitle: nil, image: nil)
        headerContainer.updateScopeBar(type: .search)

        exploreContainer.clearSelected()
    }
    
    func userCancelledSearch() {
        isSearchActive = false
        headerContainer.currentMode = .explore
        headerContainer.updateHeader(title: "EXPLORE", subtitle: nil, image: nil)
        headerContainer.updateScopeBar(type: .explore)

        selectedExploreType = (selectedExploreType)
    }
    
    // UPDATE TAGS / QUESTIONS IN FEED
    internal func backToExplore() {
        selectedExploreType = .tag
        headerContainer.segmentedControl.selectedSegment = 0
        headerContainer.currentMode = .explore
        headerContainer.updateScopeBar(type: .explore)
        headerContainer.updateHeader(title: "EXPLORE", subtitle: nil, image: nil)
    }
    
    
    //FOLLOW / UNFOLLOW QUESTIONS AND UPDATE BUTTONS
    internal func follow() {
        Database.pinTagForUser(selectedTagDetail, completion: {(success, error) in
            if !success {
                GlobalFunctions.showErrorBlock("Error Pinning / Unpinning Tag", erMessage: error!.localizedDescription)
            } else {
                self.isFollowingSelectedTag = self.isFollowingSelectedTag ? false : true
            }
        })
    }
    
    override var prefersStatusBarHidden : Bool {
        return false
    }
    
    func xmSegmentedControl(_ xmSegmentedControl: XMSegmentedControl, selectedSegment: Int) {
        switch selectedSegment {
        case 0: selectedExploreType = .tag
        case 1: selectedExploreType = .question
        case 2: selectedExploreType = .people
        default: selectedExploreType = nil
        }
    }
    
    
    /* MARK : LAYOUT VIEW FUNCTIONS */
    fileprivate func setupExplore() {
        view.backgroundColor = UIColor.white

        headerContainer = ExploreHeader(frame: CGRect(x: 0, y: statusBarHeight, width: view.bounds.width, height: view.bounds.height * 0.175))
        view.addSubview(headerContainer)
        
        headerContainer.backButton.addTarget(self, action: #selector(backToExplore), for: UIControlEvents.touchDown)
        headerContainer.followButton.addTarget(self, action: #selector(follow), for: UIControlEvents.touchDown)
        headerContainer.searchButton.addTarget(self, action: #selector(userClickedSearch), for: UIControlEvents.touchDown)
        headerContainer.closeButton.addTarget(self, action: #selector(userCancelledSearch), for: UIControlEvents.touchDown)

        headerContainer.updateHeader(title: "EXPLORE", subtitle : nil, image: nil)
        headerContainer.updateScopeBar(type: .explore)
        headerContainer.currentMode = .explore
        
        headerContainer.segmentedControl.delegate = self
        headerContainer.searchController.searchResultsUpdater = self
        headerContainer.searchController.searchBar.delegate = self
        headerContainer.searchController.delegate = self

        exploreContainer = FeedVC()
        exploreContainer.feedDelegate = self
        selectedExploreType = .tag
        
        GlobalFunctions.addNewVC(exploreContainer, parentVC: self)
        exploreContainer.view.translatesAutoresizingMaskIntoConstraints = false
        exploreContainer.view.topAnchor.constraint(equalTo: headerContainer.bottomAnchor).isActive = true
        exploreContainer.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        exploreContainer.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        exploreContainer.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        exploreContainer.view.layoutIfNeeded()
        
        definesPresentationContext = true
    }
}

extension ExploreVC: UISearchBarDelegate, UISearchResultsUpdating, UISearchControllerDelegate {
    // MARK: - Search controller delegate methods
    func updateSearchResults(for searchController: UISearchController) {
        let _searchText = searchController.searchBar.text!
        
        if _searchText != "" && _searchText.characters.count > 1 {
            switch selectedExploreType! {
            case .tag:
                Database.searchTags(searchText: _searchText.lowercased(), completion:  { searchResults in
                    self.exploreContainer.allTags = searchResults
                    self.exploreContainer.feedItemType = self.selectedExploreType
                    self.exploreContainer.updateDataSource = true
                })
            case .question:
                Database.searchQuestions(searchText: _searchText.lowercased(), completion:  { searchResults in
                    self.exploreContainer.allQuestions = searchResults
                    self.exploreContainer.currentTag = Tag(tagID: "SEARCH")
                    self.exploreContainer.feedItemType = self.selectedExploreType
                    self.exploreContainer.updateDataSource = true
                })
            default: break
            }
        } else if _searchText == "" {
            //empty the dictionary
        }
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsCancelButton = false
        searchController.searchBar.becomeFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        userCancelledSearch()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
}


