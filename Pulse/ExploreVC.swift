//
//  SearchVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/26/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class ExploreVC: UIViewController, feedVCDelegate, XMSegmentedControlDelegate, UIScrollViewDelegate, PulseNavControllerDelegate {
    public var tabDelegate : tabVCDelegate!
    
    fileprivate var exploreContainer : FeedVC!
    fileprivate var loadingView : LoadingView?
    
    fileprivate var headerNav : PulseNavVC?
    
    fileprivate var searchButton : PulseButton!
    fileprivate var closeButton : PulseButton!
    fileprivate var blankButton : PulseButton!
    fileprivate var backButton : PulseButton!
    
    fileprivate var activityController: UIActivityViewController?
    
    /* SIDE MENU VARS */
    fileprivate var screenMenu = PulseMenu(_axis: .vertical, _spacing: Spacing.m.rawValue)

    fileprivate var messageButton = PulseButton(size: .medium, type: .messageCircle, isRound : true, hasBackground: false, tint: .black)
    fileprivate var messageLabel = PulseButton(title: "Send Message", isRound: false)
    fileprivate var messageStack = PulseMenu(_axis: .horizontal, _spacing: Spacing.s.rawValue)
    
    fileprivate var becomeExpertButton = PulseButton(size: .medium, type: .checkCircle, isRound : true, hasBackground: false, tint: .black)
    fileprivate var becomeExpertLabel = PulseButton(title: "Become Expert", isRound: false)
    fileprivate var becomeExpertStack = PulseMenu(_axis: .horizontal, _spacing: Spacing.s.rawValue)
    
    fileprivate var askQuestionButton = PulseButton(size: .medium, type: .questionCircle, isRound : true, hasBackground: false, tint: .black)
    fileprivate var askQuestionLabel = PulseButton(title: "Ask Question", isRound: false)
    fileprivate var askQuestionStack = PulseMenu(_axis: .horizontal, _spacing: Spacing.s.rawValue)
    
    fileprivate var addAnswerButton = PulseButton(size: .medium, type: .addCircle, isRound : true, hasBackground: false, tint: .black)
    fileprivate var addAnswerLabel = PulseButton(title: "Add Answer", isRound: false)
    fileprivate var addAnswerStack = PulseMenu(_axis: .horizontal, _spacing: Spacing.s.rawValue)
    
    fileprivate var toggleFollowButton = PulseButton(size: .medium, type: .addCircle, isRound : true, hasBackground: false, tint: .black)
    fileprivate var toggleFollowLabel = PulseButton(title: "Follow Tag", isRound: false)
    fileprivate var toggleFollowStack = PulseMenu(_axis: .horizontal, _spacing: Spacing.s.rawValue)
    
    fileprivate var searchMenuButton = PulseButton(size: .medium, type: .searchCircle, isRound : true, hasBackground: false, tint: .black)
    fileprivate var searchLabel = PulseButton(title: "Search", isRound: false)
    fileprivate var searchStack = PulseMenu(_axis: .horizontal, _spacing: Spacing.s.rawValue)
    
    fileprivate var shareButton = PulseButton(size: .medium, type: .shareCircle, isRound : true, hasBackground: false, tint: .black)
    fileprivate var shareLabel = PulseButton(title: "Share", isRound: false)
    fileprivate var shareStack = PulseMenu(_axis: .horizontal, _spacing: Spacing.s.rawValue)
    /* END SIDE MENU VARS */
    
    fileprivate var hideStatusBar = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    var tapGesture = UITapGestureRecognizer()
    var searchController = UISearchController(searchResultsController: nil)
    
    fileprivate var exploreStack = [Explore]()
    var currentExploreMode : Explore! {
        didSet {
            updateScopeBar()
            updateModes()
            updateMenu()
        }
    }
    
    /* END EXPLORE STACK */
    fileprivate var isFollowingSelectedTag : Bool = false {
        didSet {
            isFollowingSelectedTag ?
                toggleFollowButton.setImage(UIImage(named: "remove-circle")?.withRenderingMode(.alwaysTemplate), for: UIControlState()) :
                toggleFollowButton.setImage(UIImage(named: "add-circle")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            toggleFollowLabel.setTitle(isFollowingSelectedTag ? "Unfollow Tag" : "Follow Tag", for: UIControlState())
        }
    }
    
    fileprivate var isFollowingSelectedQuestion : Bool = false {
        didSet {
            isFollowingSelectedQuestion ?
                toggleFollowButton.setImage(UIImage(named: "remove-circle")?.withRenderingMode(.alwaysTemplate), for: UIControlState()) :
                toggleFollowButton.setImage(UIImage(named: "add-circle")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            toggleFollowLabel.setTitle(isFollowingSelectedTag ? "Unfollow Question" : "Follow Question", for: UIControlState())
        }
    }
    
    fileprivate var isLoaded = false
    
    fileprivate var selectedTag : Tag!
    fileprivate var selectedQuestion : Question!
    fileprivate var selectedUser : User!

    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLoaded {
            if let nav = navigationController as? PulseNavVC {
                headerNav = nav
            }

            getButtons()
            setupSearch()
            setupExplore()
            setupMenu()
            
            automaticallyAdjustsScrollViewInsets = false
            
            tapGesture.addTarget(self, action: #selector(dismissSearchTap))
            loadingView?.addGestureRecognizer(tapGesture)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)

        navigationController?.isNavigationBarHidden = false //neeed in case coming back from messageVC
        
        guard let headerNav = headerNav else { return }
        guard let scrollView = exploreContainer.getScrollView() else { return }
        
        headerNav.followScrollView(scrollView, delay: 20.0)
        headerNav.scrollingNavbarDelegate = self
        
        if exploreStack.last != nil {
            currentExploreMode = exploreStack.last
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(false)
        
        guard let headerNav = headerNav else { return }
        headerNav.stopFollowingScrollView()
        exploreContainer.getScrollView()?.contentInset = UIEdgeInsets.zero
    }
    
    override var prefersStatusBarHidden: Bool {
        return hideStatusBar
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
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
        switch state {
        case .collapsed:
            hideStatusBar = true

        case .expanded:
            hideStatusBar = false
            
        case .scrolling:
            hideStatusBar = false
        }
    }
    
    fileprivate func updateModes() {
        toggleLoading(show: true, message : "Loading...")
        headerNav?.toggleSearch(show: currentExploreMode.currentMode == .search ? true : false)

        switch currentExploreMode.currentMode {
        case .root:
            updateHeader(navTitle: nil, screentitle : "Explore", leftButton: searchButton, rightButton: nil, navImage: nil)
            updateRootScopeSelection()
        case .tag:
            updateHeader(navTitle: nil, screentitle : selectedTag.tagTitle ?? "Explore Tag", leftButton: backButton, rightButton: nil, navImage: nil)
            isFollowingSelectedTag = User.currentUser?.savedTags != nil && User.currentUser!.savedTagIDs.contains(selectedTag.tagID!) ? true : false
            updateTagScopeSelection()
        case .search:
            updateHeader(navTitle: nil, screentitle : nil, leftButton: closeButton, rightButton: nil, navImage: nil)
            updateSearchResults(for: searchController)
        case .question:
            isFollowingSelectedQuestion = User.currentUser?.savedQuestions != nil && User.currentUser!.savedQuestions[selectedQuestion.qID] != nil ? true : false
            updateQuestionScopeSelection()
            updateHeader(navTitle: currentExploreMode.getModeTitle(), screentitle : selectedQuestion.qTitle, leftButton: backButton, rightButton: nil, navImage: nil)

        case .people:
            updateHeader(navTitle: selectedUser.thumbPicImage != nil ? nil : selectedUser.name,
                         screentitle : selectedUser.name,
                         leftButton: backButton, rightButton: nil, navImage: selectedUser.thumbPicImage)
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
                    
                    if !self.isLoaded {
                        if self.tabDelegate != nil { self.tabDelegate.removeLoading() }
                        self.isLoaded = true
                    }
                }
            })
        case .questions:
            Database.getExploreQuestions({ questions, error in
                if error == nil {
                    self.exploreContainer.allQuestions = questions
                    self.exploreContainer.feedItemType = self.currentExploreMode.getFeedType()
                    self.toggleLoading(show: false, message : nil)
                    
                    if !self.isLoaded {
                        if self.tabDelegate != nil { self.tabDelegate.removeLoading() }
                        self.isLoaded = true
                    }

                }
            })
        case .people:
            Database.getExploreUsers({ users, error in
                if error == nil {
                    self.exploreContainer.allUsers = users
                    self.exploreContainer.feedItemType = self.currentExploreMode.getFeedType()
                    self.toggleLoading(show: false, message : nil)
                    
                    if !self.isLoaded {
                        if self.tabDelegate != nil { self.tabDelegate.removeLoading() }
                        self.isLoaded = true
                    }

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
                        self.exploreContainer.allQuestions = tag.questions
                        self.exploreContainer.feedItemType = .question
                        self.toggleLoading(show: false, message : nil)
                    }  else {
                        self.toggleLoading(show: true, message : "No questions found")
                    }
                })
            } else {
                exploreContainer.setSelectedIndex(index: nil)
                exploreContainer.allQuestions = selectedTag.questions
                exploreContainer.feedItemType = .question
                toggleLoading(show: false, message : nil)
            }
        case .experts:
            Database.getExpertsForTag(tagID: selectedTag.tagID!, completion: { (experts, error) in
                if error == nil {
                    self.exploreContainer.setSelectedIndex(index: nil)
                    self.exploreContainer.allUsers = experts
                    self.exploreContainer.feedItemType = .people
                    
                    if experts.count > 0 {
                        self.toggleLoading(show: false, message : nil)
                    } else {
                        self.toggleLoading(show: true, message : "No experts for this tag yet")
                    }
                }
                
            })
        case .related:
            Database.getRelatedTags(selectedTag.tagID!, completion: { (tags, error) in
                if error == nil {
                    self.exploreContainer.setSelectedIndex(index: nil)
                    self.exploreContainer.allTags = tags
                    self.exploreContainer.feedItemType = .tag
                    
                    if tags.count > 0 {
                        self.toggleLoading(show: false, message : nil)
                    } else {
                        self.toggleLoading(show: true, message : "No related tags found")
                    }
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
                    if let question = question, question.hasAnswers() {
                        self.exploreContainer.allAnswers = question.qAnswers.map{ (_aID) -> Answer in Answer(aID: _aID, qID : question.qID) }
                        self.exploreContainer.feedItemType = .answer
                        
                        self.toggleLoading(show: false, message : nil)
                        self.exploreContainer.setSelectedIndex(index: IndexPath(row: 0, section: 0))
                    } else {
                        self.toggleLoading(show: true, message : "No answers found")
                    }
                })
            } else {
                if selectedQuestion.hasAnswers() {
                    exploreContainer.allAnswers = selectedQuestion.qAnswers.map{ (_aID) -> Answer in Answer(aID: _aID, qID : selectedQuestion.qID) }

                    exploreContainer.feedItemType = .answer
                    exploreContainer.setSelectedIndex(index: IndexPath(row: 0, section: 0))
                    
                    toggleLoading(show: false, message : nil)
                } else {
                    self.toggleLoading(show: true, message : "No answers found")
                }
            }
        case .experts:
            //removed this option - but had it before
            Database.getExpertsForQuestion(qID: selectedQuestion.qID, completion: { experts in
                self.exploreContainer.setSelectedIndex(index: nil)
                self.exploreContainer.allUsers = experts
                self.exploreContainer.feedItemType = .people
                
                if experts.count > 0 {
                    self.toggleLoading(show: false, message : nil)
                } else {
                    self.toggleLoading(show: true, message : "No experts found")
                }
            })
        case .related:
            Database.getRelatedQuestions(selectedQuestion.qID, completion: { (questions, error) in
                if error == nil {
                    self.exploreContainer.setSelectedIndex(index: nil)
                    self.exploreContainer.allQuestions = questions
                    self.exploreContainer.feedItemType = .question
                    
                    if questions.count > 0 {
                        self.toggleLoading(show: false, message : nil)
                    } else {
                        self.toggleLoading(show: true, message : "No related questions found")
                    }
                }
            })
        default: return
        }
    }
    
    fileprivate func updatePeopleScopeSelection() {
        self.toggleLoading(show: true, message : "Loading...")
        switch currentExploreMode.currentSelectionValue() {
        case .answers:
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
        case .tags:
            Database.getUserExpertTags(uID: selectedUser.uID!, completion: { tags in
                if tags.count > 0 {
                    self.exploreContainer.selectedUser = self.selectedUser
                    self.exploreContainer.allTags = tags
                    self.exploreContainer.feedItemType = self.currentExploreMode.getFeedType()
                    
                    self.toggleLoading(show: false, message : nil)
                } else {
                    self.toggleLoading(show: true, message : "No verified expertise yet!")
                }
            })
        default: return
        }
    }
    
    func userSelected(type : FeedItemType, item : Any) {
        dismissSearchTap()
        
        switch type {
        case .tag:
            selectedTag = item as! Tag
            currentExploreMode = Explore(currentMode: .tag, currentSelection: 0, currentSelectedItem: selectedTag)
            exploreStack.append(currentExploreMode)
            exploreContainer.updateDataSource = true
        case .question:
            selectedQuestion = item as! Question
            currentExploreMode = Explore(currentMode: .question, currentSelection: 0, currentSelectedItem: selectedQuestion)
            exploreStack.append(currentExploreMode)
            exploreContainer.selectedTag = currentExploreMode.currentMode == .search ? Tag(tagID: "SEARCH") : Tag(tagID : "EXPLORE")
        case .people:
            selectedUser = item as! User
            currentExploreMode = Explore(currentMode: .people, currentSelection: 0, currentSelectedItem: selectedUser)
            exploreStack.append(currentExploreMode)
        default: break
        }
    }
    
    //Update Nav Header
    fileprivate func updateHeader(navTitle : String?,
                                  screentitle : String?,
                                  leftButton : UIButton?,
                                  rightButton : UIButton?,
                                  navImage : UIImage?) {
        
        navigationItem.leftBarButtonItem = leftButton != nil ? UIBarButtonItem(customView: leftButton!) : nil
        navigationItem.rightBarButtonItem = rightButton != nil ? UIBarButtonItem(customView: rightButton!) : nil
        
        if let nav = headerNav {
            nav.setNav(navTitle: navTitle, screenTitle: screentitle, screenImage: navImage)
        } else {
            title = navTitle
        }
    }
    
    ///Shows / hides the menu - update menu has the components of the menu
    public func appButtonTapped() {
        if screenMenu.isHidden {
            toggleLoading(show: true, message: nil)
            loadingView?.alpha = 0.9
        } else {
            toggleLoading(show: false, message: nil)
            loadingView?.alpha = 1.0
        }
        
        screenMenu.isHidden = screenMenu.isHidden ? false : true
    }
    
    fileprivate func hideMenu() {
        screenMenu.isHidden = true
        toggleLoading(show: false, message: nil)
        loadingView?.alpha = 1.0
    }
    
    fileprivate func updateMenu() {
        for menu in screenMenu.subviews {
            screenMenu.removeArrangedSubview(menu)
            menu.removeFromSuperview()
        }
        
        switch currentExploreMode.currentMode {
        case .root:
            screenMenu.addArrangedSubview(searchStack)

        case .tag:
            screenMenu.addArrangedSubview(becomeExpertStack)
            screenMenu.addArrangedSubview(askQuestionStack)
            screenMenu.addArrangedSubview(toggleFollowStack)

        case .question:
            screenMenu.addArrangedSubview(addAnswerStack)
            screenMenu.addArrangedSubview(shareStack)

        case .people:
            screenMenu.addArrangedSubview(askQuestionStack)
            screenMenu.addArrangedSubview(messageStack)

        default:
            screenMenu.isHidden = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /* SEARCH FUNCTIONS */
    //Initial setup for search - controller is set to active when user clicks search
    fileprivate func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.delegate = self
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.setImage(UIImage(), for: UISearchBarIcon.clear, state: UIControlState.highlighted)
        searchController.searchBar.setImage(UIImage(), for: UISearchBarIcon.clear, state: UIControlState.normal)
        searchController.searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)

        headerNav?.getSearchContainer()?.addSubview(searchController.searchBar)
        
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.sizeToFit()
        headerNav?.toggleSearch(show: false)
    }
    
    func userClickedSearch() {
        hideMenu()

        searchController.isActive = true
        currentExploreMode = Explore(currentMode: .search, currentSelection: 0, currentSelectedItem: nil)
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
        hideMenu()
        
        switch exploreStack.last!.currentMode {
        case .people:
            selectedUser = nil
            exploreContainer.selectedUser = nil
        case .question:
            selectedQuestion = nil
            exploreContainer.selectedQuestion = nil
        case .tag:
            selectedTag = nil
            exploreContainer.selectedTag = nil
        default: break
        }
        
        let _ = exploreStack.popLast()
        
        switch exploreStack.last!.currentMode {
        case .people:
            selectedUser = exploreStack.last?.currentSelectedItem as? User
        case .question:
            selectedQuestion = exploreStack.last?.currentSelectedItem as? Question
        case .tag:
            selectedTag = exploreStack.last?.currentSelectedItem as? Tag
        default: break
        }
        
        currentExploreMode = exploreStack.last
    }
    
    //FOLLOW / UNFOLLOW QUESTIONS AND UPDATE BUTTONS
    internal func follow() {
        hideMenu()
        
        switch currentExploreMode.currentMode {
        case .question:
            Database.saveQuestion(selectedQuestion.qID, completion: {(success, error) in
                if !success {
                    GlobalFunctions.showErrorBlock("Error Saving Question", erMessage: error!.localizedDescription)
                } else {
                    self.isFollowingSelectedQuestion = self.isFollowingSelectedQuestion ? false : true
                }
            })
        case .tag:
            Database.pinTagForUser(selectedTag, completion: {(success, error) in
                if !success {
                    GlobalFunctions.showErrorBlock("Error Saving Tag", erMessage: error!.localizedDescription)
                } else {
                    self.isFollowingSelectedTag = self.isFollowingSelectedTag ? false : true
                }
            })
        default: return
        }

    }
    
    ///Launch messenger for selected user
    func userClickedSendMessage() {
        hideMenu()
        
        let messageVC = MessageVC()
        messageVC.toUser = selectedUser
        
        if let selectedUserImage = selectedUser.thumbPicImage {
            messageVC.toUserImage = selectedUserImage
        }
        
        navigationController?.pushViewController(messageVC, animated: true)
    }
    
    func userClickedAddAnswer() {
        hideMenu()
        
        guard let currentUser = User.currentUser else {
            GlobalFunctions.showErrorBlock("Please Login!", erMessage: "You need to be logged in to answer this question.")
            return
        }
        
        guard let selectedTag = self.selectedTag != nil ? self.selectedTag : Tag(tagID: selectedQuestion.getTag()) else {
            GlobalFunctions.showErrorBlock("Error Adding Answer", erMessage: "Sorry there was an error trying to add your answer.")
            return
        }
        
        currentUser.canAnswer(qID: selectedQuestion.qID, tag: selectedTag, completion: { (success, errorTitle, errorDescription) in
            if success {
                let addAnswerVC = QAManagerVC()
                addAnswerVC.allQuestions = [selectedQuestion]
                addAnswerVC.currentQuestion = selectedQuestion
                addAnswerVC.selectedTag = selectedTag
                addAnswerVC.openingScreen = .camera
                
                present(addAnswerVC, animated: true, completion: nil)
            } else {
                guard errorTitle != nil, errorDescription != nil else {
                    GlobalFunctions.showErrorBlock("Error Adding Answer", erMessage: "Sorry there was an error!")
                    return
                }
                GlobalFunctions.showErrorBlock(errorTitle!, erMessage: errorDescription!)
            }
        })
    }
    
    ///Hide menu and push apply to become expert VC and set tag to currently selected tag
    func userClickedBecomeExpert() {
        guard selectedTag != nil else { return }
        
        hideMenu()
        
        let applyExpertVC = ApplyExpertVC()
        applyExpertVC.selectedTag = selectedTag
        
        navigationController?.pushViewController(applyExpertVC, animated: true)
    }
    
    func userClickedAskQuestion() {
        hideMenu()
        
        let questionVC = AskQuestionVC()
        
        switch currentExploreMode.currentMode {
        case .tag:
            questionVC.selectedTag = selectedTag
        case .people:
            questionVC.selectedUser = selectedUser
        default: return
        }
        
        navigationController?.pushViewController(questionVC, animated: true)
    }
    
    func userClickedShare() {
        switch currentExploreMode.currentMode {
        case .tag:
            selectedTag.createShareLink(completion: { link in
                guard let link = link else { return }
                self.activityController = GlobalFunctions.shareContent(shareType: "channel",
                                                                  shareText: self.selectedTag.tagTitle ?? "",
                                                                  shareLink: link, presenter: self)
            })
        case .question:
            selectedQuestion.createShareLink(completion: { link in
                guard let link = link else { return }
                self.activityController = GlobalFunctions.shareContent(shareType: "question",
                                                                  shareText: self.selectedQuestion.qTitle ?? "",
                                                                  shareLink: link, presenter: self)
            })
        case .people:
            selectedUser.createShareLink(completion: { link in
                guard let link = link else { return }
                self.activityController = GlobalFunctions.shareContent(shareType: "person",
                                                                  shareText: self.selectedUser.name ?? "",
                                                                  shareLink: link, presenter: self)
            })

        default: return
        }
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
        GlobalFunctions.addNewVC(exploreContainer, parentVC: self)

        exploreContainer.view.translatesAutoresizingMaskIntoConstraints = false
        exploreContainer.view.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        exploreContainer.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        exploreContainer.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        exploreContainer.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        exploreContainer.view.layoutIfNeeded()
        exploreContainer.feedDelegate = self

        currentExploreMode = Explore(currentMode: .root, currentSelection: 0, currentSelectedItem: nil)
        exploreStack.append(currentExploreMode)
        
        loadingView = LoadingView(frame: CGRect.zero, backgroundColor: .white)
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
        
        backButton = PulseButton(size: .small, type: .back, isRound : true, hasBackground: true)
        backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)

        blankButton = PulseButton(size: .small, type: .blank, isRound : true, hasBackground: true)

        // SIDE MENU OPTIONS //
        toggleFollowStack.addArrangedSubview(toggleFollowLabel)
        toggleFollowStack.addArrangedSubview(toggleFollowButton)
        
        messageStack.addArrangedSubview(messageLabel)
        messageStack.addArrangedSubview(messageButton)
        
        addAnswerStack.addArrangedSubview(addAnswerLabel)
        addAnswerStack.addArrangedSubview(addAnswerButton)
        
        askQuestionStack.addArrangedSubview(askQuestionLabel)
        askQuestionStack.addArrangedSubview(askQuestionButton)
        
        becomeExpertStack.addArrangedSubview(becomeExpertLabel)
        becomeExpertStack.addArrangedSubview(becomeExpertButton)
        
        searchStack.addArrangedSubview(searchLabel)
        searchStack.addArrangedSubview(searchMenuButton)
        
        shareStack.addArrangedSubview(shareLabel)
        shareStack.addArrangedSubview(shareButton)

        toggleFollowButton.addTarget(self, action: #selector(follow), for: UIControlEvents.touchUpInside)
        toggleFollowLabel.addTarget(self, action: #selector(follow), for: UIControlEvents.touchUpInside)
        
        messageButton.addTarget(self, action: #selector(userClickedSendMessage), for: UIControlEvents.touchUpInside)
        messageLabel.addTarget(self, action: #selector(userClickedSendMessage), for: UIControlEvents.touchUpInside)

        addAnswerButton.addTarget(self, action: #selector(userClickedAddAnswer), for: UIControlEvents.touchUpInside)
        addAnswerLabel.addTarget(self, action: #selector(userClickedAddAnswer), for: UIControlEvents.touchUpInside)

        askQuestionButton.addTarget(self, action: #selector(userClickedAskQuestion), for: UIControlEvents.touchUpInside)
        askQuestionLabel.addTarget(self, action: #selector(userClickedAskQuestion), for: UIControlEvents.touchUpInside)
        
        becomeExpertButton.addTarget(self, action: #selector(userClickedBecomeExpert), for: UIControlEvents.touchUpInside)
        becomeExpertLabel.addTarget(self, action: #selector(userClickedBecomeExpert), for: UIControlEvents.touchUpInside)
        
        searchMenuButton.addTarget(self, action: #selector(userClickedSearch), for: UIControlEvents.touchUpInside)
        searchLabel.addTarget(self, action: #selector(userClickedSearch), for: UIControlEvents.touchUpInside)
        
        shareButton.addTarget(self, action: #selector(userClickedShare), for: UIControlEvents.touchUpInside)
        shareLabel.addTarget(self, action: #selector(userClickedShare), for: UIControlEvents.touchUpInside)
    }
    
    fileprivate func setupMenu() {
        view.addSubview(screenMenu)
        
        screenMenu.translatesAutoresizingMaskIntoConstraints = false
        screenMenu.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomLogoLayoutHeight).isActive = true
        screenMenu.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4).isActive = true
        screenMenu.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        screenMenu.layoutIfNeeded()
        
        screenMenu.isHidden = true
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
        private let questionIcons = [UIImage(named: "count-label")!, UIImage(named: "related")!]
        private let tagIcons = [UIImage(named: "question")!, UIImage(named: "profile")!, UIImage(named: "related")!]
        private let searchIcons = [UIImage(named: "tag")!, UIImage(named: "question")!, UIImage(named: "profile")!]
        private let peopleIcons = [UIImage(named: "answers")!, UIImage(named: "tag")!]

        /* PROPERTIES */
        var currentMode : Modes = .root
        var currentModeOptions : [Options] {
            switch currentMode {
            case .root: return [.tags, .questions, .people]
            case .tag: return [.questions, .experts, .related]
            case .question: return [.answers, .related]
            case .people: return [ .answers, .tags ]
            case .search: return [.tags, .questions, .people]
            }
        }
        
        var currentSelection : Int = 0
        var currentSelectedItem : Any?
        
        var currentScopeBar : scopeBar? {
            switch currentMode {
            case .root: return scopeBar(titles: getOptionTitles(), icons: rootIcons)
            case .tag: return scopeBar(titles: getOptionTitles(), icons: tagIcons)
            case .question: return scopeBar(titles: getOptionTitles(), icons: questionIcons)
            case .people: return scopeBar(titles: getOptionTitles(), icons: peopleIcons)
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

//Moving side menu layout & functions here for clean up
extension ExploreVC {
    
}
