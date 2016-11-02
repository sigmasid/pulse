//
//  SearchVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/26/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class ExploreVC: UIViewController, feedVCDelegate, XMSegmentedControlDelegate, UIScrollViewDelegate, PulseNavControllerDelegate {
    
    fileprivate var iconContainer : IconContainer!
    fileprivate var exploreContainer : FeedVC!
    fileprivate var loadingView : LoadingView?

    fileprivate var headerNav : PulseNavVC?
    
    fileprivate var searchButton : PulseButton!
    fileprivate var closeButton : PulseButton!
    fileprivate var followButton : PulseButton!
    fileprivate var unfollowButton : PulseButton!
    fileprivate var backButton : PulseButton!
    fileprivate var blankButton : PulseButton!
    fileprivate var messageButton : PulseButton!

    fileprivate var hideStatusBar = false {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    var tapGesture = UITapGestureRecognizer()
    var searchController = UISearchController(searchResultsController: nil)
    
    fileprivate var exploreStack = [Explore]()
    var currentExploreMode : Explore! {
        didSet {
            updateScopeBar()
            updateModes()
        }
    }
    
    /* END EXPLORE STACK */
    fileprivate var isFollowingSelectedTag : Bool = false {
        didSet {
            navigationItem.rightBarButtonItem = isFollowingSelectedTag ?
                                                UIBarButtonItem(customView: unfollowButton) :
                                                UIBarButtonItem(customView: followButton)
        }
    }
    
    fileprivate var isLoaded = false
    
    fileprivate var selectedTag : Tag!
    fileprivate var selectedQuestion : Question!
    fileprivate var selectedUser : User!

    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLoaded {
            if let nav = navigationController as? PulseNavVC { headerNav = nav }
            
            getButtons()
            setupExplore()
            setupSearch()
            
            iconContainer = addIcon(text: "EXPLORE")
            automaticallyAdjustsScrollViewInsets = false
            
            tapGesture.addTarget(self, action: #selector(dismissSearchTap))
            loadingView?.addGestureRecognizer(tapGesture)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // navigationController?.isNavigationBarHidden = false
        
        guard let headerNav = headerNav else { return }
        headerNav.followScrollView(exploreContainer.view, delay: 50.0)
        headerNav.scrollingNavbarDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard let headerNav = headerNav else { return }
        headerNav.stopFollowingScrollView()
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    func dismissSearchTap() {
        searchController.searchBar.resignFirstResponder()
    }
    
    fileprivate func updateScopeBar() {
        if let scopeBar = currentExploreMode.currentScopeBar {
            headerNav?.shouldShowScope = true
            headerNav?.updateScopeBar(titles: scopeBar.titles,
                                      icons: scopeBar.icons,
                                      selected: currentExploreMode.currentSelection )
        } else {
            headerNav?.shouldShowScope = false
        }
    }
    
    func scrollingNavDidSet(_ controller: PulseNavVC, state: NavBarState) {
        print("scolling nav did set fired with state \(state)")
        switch state {
        case .collapsed:
            hideStatusBar = true
        case .expanded:
            hideStatusBar = false
        case .scrolling:
            hideStatusBar = true
        }
    }
    
    fileprivate func updateModes() {
        toggleLoading(show: true, message : "Loading...")
        headerNav?.toggleSearch(show: currentExploreMode.currentMode == .search ? true : false)

        switch currentExploreMode.currentMode {
        case .root:
            updateHeader(_title: "Explore", _subtitle : nil, leftButton: searchButton, rightButton: nil, statusImage: nil)
            updateRootScopeSelection()
        case .tag:
            updateHeader(_title: nil, _subtitle : selectedTag.tagID!, leftButton: backButton, rightButton: nil, statusImage: nil)
            isFollowingSelectedTag = User.currentUser?.savedTags != nil && User.currentUser!.savedTags[selectedTag.tagID!] != nil ? true : false
            updateTagScopeSelection()
        case .search:
            updateHeader(_title: nil, _subtitle : nil, leftButton: closeButton, rightButton: nil, statusImage: nil)
            updateSearchResults(for: searchController)
        case .question:
            updateHeader(_title: currentExploreMode.getModeTitle(), _subtitle : selectedQuestion.qTitle, leftButton: backButton, rightButton: nil, statusImage: nil)
            updateQuestionScopeSelection()
        case .people:
            updateHeader(_title: selectedUser.thumbPicImage != nil ? nil : selectedUser.name,
                         _subtitle : selectedUser.thumbPicImage != nil ? selectedUser.name : nil,
                         leftButton: backButton, rightButton: messageButton, statusImage: selectedUser.thumbPicImage)
            updatePeopleScopeSelection()
        }
    }
    
    fileprivate func updateRootScopeSelection() {
        switch currentExploreMode.currentSelectionValue() {
        case .tags:
            Database.getExploreTags({ tags, error in
                if error == nil {
                    self.exploreContainer.allTags = tags
                    self.exploreContainer.feedItemType = self.currentExploreMode.getFeedType()
                    self.toggleLoading(show: false, message : nil)
                }
            })
        case .questions:
            Database.getExploreQuestions({ questions, error in
                if error == nil {
                    self.exploreContainer.allQuestions = questions
                    self.exploreContainer.feedItemType = self.currentExploreMode.getFeedType()
                    self.toggleLoading(show: false, message : nil)
                }
            })
        case .people:
            Database.getExploreUsers({ users, error in
                if error == nil {
                    self.exploreContainer.allUsers = users
                    self.exploreContainer.feedItemType = self.currentExploreMode.getFeedType()
                    self.toggleLoading(show: false, message : nil)
                }
            })
        default: return
        }
    }
    
    fileprivate func updateTagScopeSelection() {
        switch currentExploreMode.currentSelectionValue() {
        case .questions:
            if !selectedTag.tagCreated {
                Database.getTag(selectedTag.tagID!, completion: { tag, error in
                    if error == nil && tag.totalQuestionsForTag() > 0 {
                        self.exploreContainer.setSelectedIndex(index: nil)
                        self.exploreContainer.allQuestions = tag.questions!
                        self.exploreContainer.feedItemType = .question
                        self.toggleLoading(show: false, message : nil)
                    }  else {
                        self.toggleLoading(show: true, message : "No questions found")
                    }
                })
            } else {
                exploreContainer.setSelectedIndex(index: nil)
                exploreContainer.allQuestions = selectedTag.questions!
                exploreContainer.feedItemType = .question
                toggleLoading(show: false, message : nil)
            }
        case .experts:
            Database.getExpertsForTag(tagID: selectedTag.tagID!, completion: { experts in
                self.exploreContainer.setSelectedIndex(index: nil)
                self.exploreContainer.allUsers = experts
                self.exploreContainer.feedItemType = .people
                
                if experts.count > 0 {
                    self.toggleLoading(show: false, message : nil)
                } else {
                    self.toggleLoading(show: true, message : "No experts for this tag yet")
                }
                
            })
        case .related:
            Database.getRelatedTags(selectedTag.tagID!, completion: { tags in
                self.exploreContainer.setSelectedIndex(index: nil)
                self.exploreContainer.allTags = tags
                self.exploreContainer.feedItemType = .tag
                
                if tags.count > 0 {
                    self.toggleLoading(show: false, message : nil)
                } else {
                    self.toggleLoading(show: true, message : "No related tags found")
                }

            })
        default: return
        }
    }
    
    fileprivate func updateQuestionScopeSelection() {
        toggleLoading(show: true, message : "Loading...")
        exploreContainer.setSelectedIndex(index: nil)

        switch currentExploreMode.currentSelectionValue() {
        case .answers:
            if !selectedQuestion.qCreated {
                Database.getQuestion(selectedQuestion.qID, completion: { question, error in
                    if error == nil && question.hasAnswers() {
                        self.exploreContainer.allAnswers = question.qAnswers!.map{ (_aID) -> Answer in Answer(aID: _aID, qID : question.qID) }
                        self.exploreContainer.selectedQuestion = self.selectedQuestion
                        self.exploreContainer.feedItemType = .answer
                        
                        self.toggleLoading(show: false, message : nil)
                        self.exploreContainer.setSelectedIndex(index: IndexPath(row: 0, section: 0))
                    } else {
                        self.toggleLoading(show: true, message : "No answers found")
                    }
                })
            } else {
                if selectedQuestion.hasAnswers() {
                    exploreContainer.allAnswers = selectedQuestion.qAnswers!.map{ (_aID) -> Answer in Answer(aID: _aID, qID : selectedQuestion.qID) }
                    exploreContainer.selectedQuestion = selectedQuestion

                    exploreContainer.feedItemType = .answer
                    exploreContainer.setSelectedIndex(index: IndexPath(row: 0, section: 0))
                    
                    toggleLoading(show: false, message : nil)
                } else {
                    self.toggleLoading(show: true, message : "No answers found")
                }
            }
        case .experts: return
        case .related:
            Database.getRelatedQuestions(selectedQuestion.qID, completion: { questions in
                self.exploreContainer.setSelectedIndex(index: nil)
                self.exploreContainer.allQuestions = questions
                self.exploreContainer.feedItemType = .question
                
                if questions.count > 0 {
                    self.toggleLoading(show: false, message : nil)
                } else {
                    self.toggleLoading(show: true, message : "No related questions found")
                }
            })
        default: return
        }
    }
    
    fileprivate func updatePeopleScopeSelection() {
        self.toggleLoading(show: true, message : "Loading...")
        
        Database.getUserAnswerIDs(uID: selectedUser.uID!, completion: { answers in
            if answers.count > 0 {
                self.exploreContainer.selectedUser = self.selectedUser
                self.exploreContainer.allAnswers = answers
                self.exploreContainer.feedItemType = self.currentExploreMode.getFeedType()

                self.toggleLoading(show: false, message : nil)
            } else {
                self.toggleLoading(show: true, message : "No answers found!")
            }
        })
    }
    
    func userSelected(type : FeedItemType, item : Any) {
        dismissSearchTap()
        
        switch type {
        case .tag:
            selectedTag = item as! Tag //didSet method pulls questions from database in case of search else assigns questions from existing tag
            currentExploreMode = Explore(currentMode: .tag, currentSelection: 0)
            exploreStack.append(currentExploreMode)
            exploreContainer.updateDataSource = true
        case .question:
            selectedQuestion = item as! Question //didSet method pulls questions from database in case of search else assigns questions from existing tag
            currentExploreMode = Explore(currentMode: .question, currentSelection: 0)
            exploreStack.append(currentExploreMode)
            exploreContainer.selectedTag = currentExploreMode.currentMode == .search ? Tag(tagID: "SEARCH") : Tag(tagID : "EXPLORE")
        case .people:
            selectedUser = item as! User //didSet method pulls questions from database in case of search else assigns questions from existing tag
            currentExploreMode = Explore(currentMode: .people, currentSelection: 0)
            exploreStack.append(currentExploreMode)
        default: break
        }
    }
    
    //Update Nav Header
    fileprivate func updateHeader(_title : String?,
                                  _subtitle : String?,
                                  leftButton : UIButton?,
                                  rightButton : UIButton?,
                                  statusImage : UIImage?) {
        
        navigationItem.leftBarButtonItem = leftButton != nil ? UIBarButtonItem(customView: leftButton!) : nil
        navigationItem.rightBarButtonItem = rightButton != nil ? UIBarButtonItem(customView: rightButton!) : nil
        
        if let nav = headerNav {
            nav.setNav(navTitle: _title, screenTitle: _subtitle, screenImage: statusImage)
        } else {
            title = _title
        }
    }
    
    //Initial setup for search - controller is set to active when user clicks search
    fileprivate func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.delegate = self
        searchController.searchBar.setBackgroundImage(GlobalFunctions.imageWithColor(.white), for: .any , barMetrics: UIBarMetrics.default)

        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.setImage(UIImage(), for: UISearchBarIcon.clear, state: UIControlState.highlighted)
        searchController.searchBar.setImage(UIImage(), for: UISearchBarIcon.clear, state: UIControlState.normal)
        
        headerNav?.getSearchContainer()?.addSubview(searchController.searchBar)
        
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.sizeToFit()
        headerNav?.toggleSearch(show: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /* SEARCH FUNCTIONS */
    func userClickedSearch() {
        searchController.isActive = true
        currentExploreMode = Explore(currentMode: .search, currentSelection: 0)
        exploreStack.append(currentExploreMode)
        tapGesture.isEnabled = true
        
        toggleLoading(show: true, message : "Searching...")
    }
    
    func userCancelledSearch() {
        tapGesture.isEnabled = false
        searchController.isActive = false
        goBack()
    }
    
    
    //UPDATE TAGS / QUESTIONS IN FEED
    internal func goBack() {
        guard exploreStack.last != nil else { return }
        
        switch exploreStack.last!.currentMode {
        case .people: selectedUser = nil
        case .question: selectedQuestion = nil
        case .tag: selectedTag = nil
        default: return
        }
        
        let _ = exploreStack.popLast()
        currentExploreMode = exploreStack.last
    }
    
    //FOLLOW / UNFOLLOW QUESTIONS AND UPDATE BUTTONS
    internal func follow() {
        Database.pinTagForUser(selectedTag, completion: {(success, error) in
            if !success {
                GlobalFunctions.showErrorBlock("Error Saving Tag", erMessage: error!.localizedDescription)
            } else {
                self.isFollowingSelectedTag = self.isFollowingSelectedTag ? false : true
            }
        })
    }
    
    ///Launch messenger for selected user
    func userClickedSendMessage() {
        let messageVC = MessageVC()
        messageVC.toUser = selectedUser
        
        if let selectedUserImage = selectedUser.thumbPicImage {
            messageVC.toUserImage = selectedUserImage
        }
        
        navigationController?.pushViewController(messageVC, animated: true)
    }
    
    func xmSegmentedControl(_ xmSegmentedControl: XMSegmentedControl, selectedSegment: Int) {
        currentExploreMode.currentSelection = selectedSegment
        exploreStack[exploreStack.count - 1].currentSelection = selectedSegment
    }
    
    fileprivate func toggleLoading(show: Bool, message: String?) {
        loadingView?.isHidden = show ? false : true
        loadingView?.addMessage(message)
    }
    
    /* MARK : LAYOUT VIEW FUNCTIONS */
    fileprivate func setupExplore() {
        view.backgroundColor = UIColor.white
        
        headerNav?.getScopeBar()?.delegate = self

        exploreContainer = FeedVC()
        exploreContainer.view.frame = view.bounds
        GlobalFunctions.addNewVC(exploreContainer, parentVC: self)
        exploreContainer.feedDelegate = self

        currentExploreMode = Explore(currentMode: .root, currentSelection: 0)
        exploreStack.append(currentExploreMode)
        

        loadingView = LoadingView(frame: CGRect.zero, backgroundColor: UIColor.white)
        view.addSubview(loadingView!)

        loadingView?.translatesAutoresizingMaskIntoConstraints = false
        loadingView?.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        loadingView?.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        loadingView?.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        loadingView?.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        loadingView?.layoutIfNeeded()

        loadingView?.addIcon(IconSizes.medium, _iconColor: UIColor.black, _iconBackgroundColor: nil)
        toggleLoading(show: true, message: "Loading...")
        
        definesPresentationContext = true
    }
    
    //Get all buttons for the controller to use
    fileprivate func getButtons() {
        searchButton = PulseButton(size: .small, type: .search, isRound : true, hasBackground: true)
        searchButton.addTarget(self, action: #selector(userClickedSearch), for: UIControlEvents.touchUpInside)
        
        closeButton = PulseButton(size: .small, type: .close, isRound : true, hasBackground: true)
        closeButton.addTarget(self, action: #selector(userCancelledSearch), for: UIControlEvents.touchUpInside)
        
        followButton = PulseButton(size: .small, type: .add, isRound : true, hasBackground: true)
        followButton.addTarget(self, action: #selector(follow), for: UIControlEvents.touchUpInside)
        
        unfollowButton = PulseButton(size: .small, type: .remove, isRound : true, hasBackground: true)
        unfollowButton.addTarget(self, action: #selector(follow), for: UIControlEvents.touchUpInside)
        
        backButton = PulseButton(size: .small, type: .back, isRound : true, hasBackground: true)
        backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
        
        messageButton = PulseButton(size: .small, type: .message, isRound : true, hasBackground: true)
        messageButton.addTarget(self, action: #selector(userClickedSendMessage), for: UIControlEvents.touchUpInside)
        
        blankButton = PulseButton(size: .small, type: .blank, isRound : true, hasBackground: true)
    }
}

extension ExploreVC: UISearchBarDelegate, UISearchResultsUpdating, UISearchControllerDelegate {
    // MARK: - Search controller delegate methods
    func updateSearchResults(for searchController: UISearchController) {
        toggleLoading(show: true, message: "Searching...")

        let _searchText = searchController.searchBar.text!
        
        if _searchText != "" && _searchText.characters.count > 1 {
            switch currentExploreMode.currentSelectionValue() {
            case .tags:
                Database.searchTags(searchText: _searchText.lowercased(), completion:  { searchResults in
                    if searchResults.count > 0 {
                        self.exploreContainer.allTags = searchResults
                        self.exploreContainer.feedItemType = self.currentExploreMode.getFeedType()
                        self.toggleLoading(show: false, message : nil)
                    } else {
                        self.toggleLoading(show: true, message : "Sorry no tags found")
                    }
                })
            case .questions:
                Database.searchQuestions(searchText: _searchText.lowercased(), completion:  { searchResults in
                    if searchResults.count > 0 {
                        self.exploreContainer.allQuestions = searchResults
                        self.exploreContainer.selectedTag = Tag(tagID: "SEARCH")
                        self.exploreContainer.feedItemType = self.currentExploreMode.getFeedType()
                        self.toggleLoading(show: false, message : nil)
                    } else {
                        self.toggleLoading(show: true, message : "Sorry no questions found")
                    }
                })
            case .people:
                Database.searchUsers(searchText: _searchText.lowercased(), completion:  { searchResults in
                    if searchResults.count > 0 {
                        self.exploreContainer.allUsers = searchResults
                        self.exploreContainer.feedItemType = self.currentExploreMode.getFeedType()
                        self.toggleLoading(show: false, message : nil)
                    } else {
                        self.toggleLoading(show: true, message : "Sorry no users found")
                    }

                })
            default: self.toggleLoading(show: true, message : "Sorry no results found")
            }
        } else if _searchText == "" {
            self.toggleLoading(show: true, message : "Searching")
        }
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async { [] in
            searchController.searchBar.becomeFirstResponder()
            searchController.searchBar.showsCancelButton = false
            searchController.searchBar.tintColor = pulseBlue
        }
        searchController.searchBar.placeholder = "enter search text"
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        userCancelledSearch()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchController.searchBar.resignFirstResponder()
        searchBar.endEditing(true)
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
}

extension ExploreVC {
    /* STACK TO KEEP WINDOW SYNC'D / REFRESH AS NEEDED */
    struct Explore {
        
        enum Options { case tags, questions, people, experts, related, answers }
        enum Modes { case root, tag, question, search, people }
        
        struct scopeBar {
            var titles = [String]()
            var icons : [UIImage]!
        }
        
        private let rootIcons = [UIImage(named: "tag")!, UIImage(named: "question")!, UIImage(named: "profile")!]
        private let questionIcons = [UIImage(named: "count-label")!, UIImage(named: "profile")!, UIImage(named: "related")!]
        private let tagIcons = [UIImage(named: "question")!, UIImage(named: "profile")!, UIImage(named: "related")!]
        private let searchIcons = [UIImage(named: "tag")!, UIImage(named: "question")!, UIImage(named: "profile")!]
        
        /* PROPERTIES */
        var currentMode : Modes = .root
        var currentModeOptions : [Options] {
            switch currentMode {
            case .root: return [.tags, .questions, .people]
            case .tag: return [.questions, .experts, .related]
            case .question: return [.answers, .experts, .related]
            case .people: return [ .answers ]
            case .search: return [.tags, .questions, .people]
            }
        }
        
        var currentSelection : Int = 0
        var currentScopeBar : scopeBar? {
            switch currentMode {
            case .root: return scopeBar(titles: getOptionTitles(), icons: rootIcons)
            case .tag: return scopeBar(titles: getOptionTitles(), icons: tagIcons)
            case .question: return scopeBar(titles: getOptionTitles(), icons: questionIcons)
            case .people: return nil
            case .search: return scopeBar(titles: getOptionTitles(), icons: searchIcons)
            }
        }
        
        /* FUNCTIONS */
        
        //Return mapped titles if total options > 1 else return empty array i.e. no scope bar
        private func getOptionTitles() -> [String] {
            return currentModeOptions.count > 1 ? currentModeOptions.map{ (option) -> String in return "\(option)" } : []
        }
        
        func currentSelectionValue() -> Options {
            return currentModeOptions[currentSelection]
        }
        
        func getFeedType() -> FeedItemType? {
            switch currentModeOptions[currentSelection] {
            case .people, .experts: return .people
            case .answers: return .answer
            case .tags: return .tag
            case .questions: return .question
            case .related:
                switch currentMode {
                case .tag: return .tag
                case .question: return .question
                default: return nil
                }
            }
        }
        
        func getModeTitle() -> String {
            switch currentMode {
            case .root: return "Explore"
            case .tag: return "Tag"
            case .question: return "Question"
            case .people: return "People"
            case .search: return "Search"
            }
        }
    }
}

//if let _tagImage = selectedTag.previewImage {
//    Database.getTagImage(_tagImage, maxImgSize: maxImgSize, completion: {(data, error) in
//        if error != nil {
//            print (error?.localizedDescription)
//        } else {
//            if let backgroundImage = UIImage(data: data!) {
//                self.headerNav?.updateBackgroundImage(image: backgroundImage)
//            }
//        }
//    })
//}

