//
//  ExploreHeader.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/10/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class ExploreHeader: UIView {

    fileprivate let leftContainer = UIView()
    fileprivate let middleContainer = UIView()
    fileprivate let rightContainer = UIView()
    
    fileprivate var headerImage = UIImageView()
    var headerTitle = UILabel()
    fileprivate var headerSubtitle = UILabel()
    
    var followButton = UIButton()
    let exploreButton = UIButton()
    let backButton = UIButton()
    let searchButton = UIButton()
    let closeButton = UIButton()
    
    fileprivate var scopeBarContainer = UIView()
    fileprivate var searchBarContainer = UIView()
    var searchController = UISearchController(searchResultsController: nil)
    var segmentedControl : XMSegmentedControl!
    
    let buttonInsets = UIEdgeInsetsMake(5, 5, 5, 5)
    
    fileprivate var isExploreHeaderSetup = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addScopeBar()
        setupExploreHeader()
        addSearchBar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    enum ScopeBarTypes { case explore, tag, question, people, search }
    var scopeBarType : ScopeBarTypes = .tag {
        didSet {
            updateScopeBar(type: scopeBarType)
        }
    }
    /* END PROPERTIES */
    
    func updateHeader(title : String, subtitle : String?, image : UIImage?) {
        headerTitle.text = title.uppercased()
        headerSubtitle.text = subtitle

        headerImage.image = image
    }
    
    func updateScopeBar(type : ScopeBarTypes) {
        switch type {
        case .explore:
            let titles = ["Tags", "Questions", "People"]
            let icons = [UIImage(named: "tag")!,
                         UIImage(named: "question")!,
                         UIImage(named: "add")!]
            segmentedControl.segmentContent = (text: titles, icon : icons)
            segmentedControl.layoutIfNeeded()
            updateButtons(mode: type)
        case .search:
            let titles = ["Tags", "Questions", "People"]
            let icons = [UIImage(named: "tag")!,
                         UIImage(named: "question")!,
                         UIImage(named: "add")!]
            segmentedControl.segmentContent = (text: titles, icon : icons)
            segmentedControl.layoutIfNeeded()
            updateButtons(mode: type)
        case .tag:
            let titles = ["Questions", "Experts", "Related"]
            let icons = [UIImage(named: "tag")!,
                         UIImage(named: "question")!,
                         UIImage(named: "add")!]
            segmentedControl.segmentContent = (text: titles, icon : icons)
            segmentedControl.layoutIfNeeded()
            updateButtons(mode: type)
        case .question:
            let titles = ["Answers", "Experts", "Related"]
            let icons = [UIImage(named: "tag")!,
                         UIImage(named: "question")!,
                         UIImage(named: "add")!]
            segmentedControl.segmentContent = (text: titles, icon : icons)
            segmentedControl.layoutIfNeeded()
            updateButtons(mode: type)
        case .people:
            let titles = ["Experts", "Questions", "People"]
            let icons = [UIImage(named: "tag")!,
                         UIImage(named: "question")!,
                         UIImage(named: "add")!]
            segmentedControl.segmentContent = (text: titles, icon : icons)
            segmentedControl.layoutIfNeeded()
            updateButtons(mode: type)
        }
    }
    
    fileprivate func updateButtons(mode : ScopeBarTypes) {
        switch mode {
        case .explore:
            exploreButton.isHidden = false
            searchButton.isHidden = false
            followButton.isHidden = true
            backButton.isHidden = true
            closeButton.isHidden = true
            searchController.isActive = false
            toggleSearchBar(show: false)
        case .search:
            followButton.isHidden = true
            backButton.isHidden = true
            exploreButton.isHidden = true
            searchButton.isHidden = true
            closeButton.isHidden = false
            searchController.isActive = true
            toggleSearchBar(show: true)
        case .question, .people, .tag:
            followButton.isHidden = false
            backButton.isHidden = false
            exploreButton.isHidden = true
            closeButton.isHidden = true
            searchButton.isHidden = true
            searchController.isActive = false
            toggleSearchBar(show: false)
        }
    }
    
    func updateExploreButtonImage(image : UIImage) {
        let exploreTintedImage = image.withRenderingMode(.alwaysTemplate)
        exploreButton.setImage(exploreTintedImage, for: UIControlState())
        exploreButton.contentEdgeInsets = buttonInsets
        exploreButton.tintColor = UIColor.white

    }
    
    func updateFollowButton(_ followMode : FollowToggle) {
        switch followMode {
        case .unfollow:
            let followTintedImage = UIImage(named: "remove")?.withRenderingMode(.alwaysTemplate)
            followButton.setImage(followTintedImage, for: UIControlState())
            followButton.tintColor = UIColor.white
        case .follow:
            let followTintedImage = UIImage(named: "add")?.withRenderingMode(.alwaysTemplate)
            followButton.setImage(followTintedImage, for: UIControlState())
            followButton.tintColor = UIColor.white
        }
        followButton.layoutIfNeeded()
    }
    
    func toggleSearchBar(show : Bool) {
        searchBarContainer.isHidden = show ? false : true
    }
    
    fileprivate func addSearchBar() {
        addSubview(searchBarContainer)
        searchBarContainer.translatesAutoresizingMaskIntoConstraints = false
        searchBarContainer.bottomAnchor.constraint(equalTo: scopeBarContainer.topAnchor).isActive = true
        searchBarContainer.topAnchor.constraint(equalTo: leftContainer.bottomAnchor).isActive = true
        searchBarContainer.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        searchBarContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        searchBarContainer.layoutIfNeeded()
        
        searchController.searchBar.sizeToFit()
        searchBarContainer.addSubview(searchController.searchBar)
        searchController.searchBar.backgroundImage = GlobalFunctions.imageWithColor(UIColor.white)
        searchBarContainer.isUserInteractionEnabled = true
        searchBarContainer.isHidden = true
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.setImage(UIImage(), for: UISearchBarIcon.clear, state: UIControlState.highlighted)
        searchController.searchBar.setImage(UIImage(), for: UISearchBarIcon.clear, state: UIControlState.normal)

    }
    
    fileprivate func addScopeBar() {
        addSubview(scopeBarContainer)
        
        scopeBarContainer.translatesAutoresizingMaskIntoConstraints = false
        scopeBarContainer.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        scopeBarContainer.heightAnchor.constraint(equalToConstant: Spacing.l.rawValue).isActive = true
        scopeBarContainer.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        scopeBarContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        scopeBarContainer.layoutIfNeeded()
        
        let titles = ["Tags", "Questions", "People"]
        let icons = [UIImage(named: "tag")!,
                     UIImage(named: "question")!,
                     UIImage(named: "add")!]
        
        let frame = scopeBarContainer.bounds
        segmentedControl = XMSegmentedControl(frame: frame,
                                              segmentContent: (titles, icons),
                                              selectedItemHighlightStyle: XMSelectedItemHighlightStyle.background)
        
        segmentedControl.backgroundColor = color8.withAlphaComponent(0.3)
        segmentedControl.highlightColor = color8.withAlphaComponent(0.7)
        segmentedControl.tint = UIColor.white
        segmentedControl.highlightTint = UIColor.white
        segmentedControl.font = UIFont.systemFont(ofSize: FontSizes.body2.rawValue, weight: UIFontWeightRegular)
        
        scopeBarContainer.addSubview(segmentedControl)
    }

    fileprivate func setupExploreHeader() {
        if !isExploreHeaderSetup {
            
            insertSubview(headerImage, at: 0)
            addSubview(leftContainer)
            addSubview(middleContainer)
            addSubview(rightContainer)
            
            headerImage.frame = bounds
            headerImage.contentMode = UIViewContentMode.scaleAspectFill
            headerImage.clipsToBounds = true
            
            leftContainer.translatesAutoresizingMaskIntoConstraints = false
            leftContainer.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
            leftContainer.widthAnchor.constraint(equalTo: leftContainer.heightAnchor).isActive = true
            leftContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
            leftContainer.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xs.rawValue).isActive = true
            leftContainer.layoutIfNeeded()
            
            rightContainer.translatesAutoresizingMaskIntoConstraints = false
            rightContainer.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
            rightContainer.widthAnchor.constraint(equalTo: rightContainer.heightAnchor).isActive = true
            rightContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
            rightContainer.topAnchor.constraint(equalTo: leftContainer.topAnchor).isActive = true
            rightContainer.layoutIfNeeded()
            
            middleContainer.translatesAutoresizingMaskIntoConstraints = false
            middleContainer.topAnchor.constraint(equalTo: leftContainer.topAnchor).isActive = true
            middleContainer.bottomAnchor.constraint(equalTo: scopeBarContainer.topAnchor).isActive = true
            middleContainer.trailingAnchor.constraint(equalTo: rightContainer.leadingAnchor, constant: -Spacing.xs.rawValue).isActive = true
            middleContainer.leadingAnchor.constraint(equalTo: leftContainer.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
            middleContainer.layoutIfNeeded()
            
            leftContainer.addSubview(exploreButton)
            leftContainer.addSubview(backButton)
            leftContainer.addSubview(closeButton)

            middleContainer.addSubview(headerTitle)
            middleContainer.addSubview(headerSubtitle)
            
            rightContainer.addSubview(followButton)
            rightContainer.addSubview(searchButton)
            
            /* LEFT CONTAINER */
            backButton.frame = leftContainer.bounds
            exploreButton.frame = leftContainer.bounds
            closeButton.frame = leftContainer.bounds

            let exploreTintedImage = UIImage(named: "collection-list")?.withRenderingMode(.alwaysTemplate)
            exploreButton.backgroundColor = color8
            exploreButton.makeRound()
            exploreButton.setImage(exploreTintedImage, for: UIControlState())
            exploreButton.contentEdgeInsets = buttonInsets
            exploreButton.tintColor = UIColor.white
            
            let backTintedImage = UIImage(named: "back")?.withRenderingMode(.alwaysTemplate)
            backButton.backgroundColor = color8
            backButton.makeRound()
            backButton.setImage(backTintedImage, for: UIControlState())
            backButton.tintColor = UIColor.white
            backButton.isHidden = true
            backButton.contentEdgeInsets = buttonInsets
            
            let closeButtonImage = UIImage(named: "close")?.withRenderingMode(.alwaysTemplate)
            closeButton.tintColor = UIColor.white
            closeButton.backgroundColor = color8
            closeButton.makeRound()
            closeButton.setImage(closeButtonImage, for: UIControlState())
            closeButton.contentEdgeInsets = buttonInsets
            closeButton.isHidden = true
            
            /* RIGHT CONTAINER */
            searchButton.frame = rightContainer.bounds
            followButton.frame = rightContainer.bounds

            let searchImage = UIImage(named: "search")?.withRenderingMode(.alwaysTemplate)
            searchButton.backgroundColor = color8
            searchButton.makeRound()
            searchButton.setImage(searchImage, for: UIControlState())
            searchButton.contentEdgeInsets = buttonInsets
            searchButton.tintColor = UIColor.white

            followButton.backgroundColor = color8
            followButton.tintColor = UIColor.white
            followButton.makeRound()
            followButton.imageView?.contentMode = .scaleAspectFit
            followButton.isHidden = true
            followButton.contentEdgeInsets = buttonInsets

            /* MIDDLE CONTAINER */
            headerTitle.translatesAutoresizingMaskIntoConstraints = false
            headerTitle.centerYAnchor.constraint(equalTo: leftContainer.centerYAnchor).isActive = true
            headerTitle.leadingAnchor.constraint(equalTo: middleContainer.leadingAnchor, constant: Spacing.xxs.rawValue).isActive = true
            headerTitle.trailingAnchor.constraint(equalTo: middleContainer.trailingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
            headerTitle.layoutIfNeeded()
            
            headerSubtitle.translatesAutoresizingMaskIntoConstraints = false
            headerSubtitle.topAnchor.constraint(equalTo: headerTitle.bottomAnchor).isActive = true
            headerSubtitle.leadingAnchor.constraint(equalTo: middleContainer.leadingAnchor, constant: Spacing.xxs.rawValue).isActive = true
            headerSubtitle.trailingAnchor.constraint(equalTo: middleContainer.trailingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
            headerSubtitle.layoutIfNeeded()

            headerTitle.setFont(FontSizes.headline.rawValue, weight: UIFontWeightBlack, color: UIColor.black, alignment: .left)
            headerSubtitle.setFont(FontSizes.body.rawValue, weight: UIFontWeightRegular, color: UIColor.black, alignment: .left)

            isExploreHeaderSetup = true
        }
    }
}
