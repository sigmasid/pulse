//
//  SearchVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/26/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class ExploreVC: UIViewController, feedVCDelegate, searchVCDelegate {
    
    fileprivate var iconContainer : IconContainer!

    fileprivate let headerContainer = UIView()
    fileprivate let headerButtonContainer = UIView()
    fileprivate var exploreContainer : FeedVC!

    fileprivate var headerImage = UIImageView()
    fileprivate var headerTitle = UILabel()
    
    fileprivate var followButton = UIButton()
    fileprivate let exploreButton = UIButton()
    fileprivate let backButton = UIButton()

    fileprivate var toggleTagButton = UIButton()
    fileprivate var toggleQuestionButton = UIButton()
    
    fileprivate var questionSelectedConstaint : NSLayoutConstraint!
    fileprivate var tagSelectedConstaint : NSLayoutConstraint!
    fileprivate var minimalHeaderHeightConstraint : NSLayoutConstraint!
    fileprivate var regularHeaderHeightConstraint : NSLayoutConstraint!

    fileprivate var isFollowingSelectedTag : Bool = false {
        didSet {
            isFollowingSelectedTag ? updateFollowButton(.unfollow) : updateFollowButton(.follow)
        }
    }
    
    fileprivate var isLoaded = false
    fileprivate var isExploreHeaderSetup = false
    fileprivate var isExploreSubHeaderSetup = false
    fileprivate var exploreViewSetup = false
        
    fileprivate var selectedExploreType : FeedItemType? {
        didSet {
            if selectedExploreType != nil {
                switch selectedExploreType! {
                case .question:
                    toggleQuestionButton.backgroundColor = highlightedColor
                    toggleTagButton.backgroundColor = UIColor.black
                    Database.getExploreQuestions({ questions, error in
                        if error == nil {
                            self.exploreContainer.allQuestions = questions
                            self.exploreContainer.feedItemType = self.selectedExploreType
                        }
                    })
                case .tag:
                    toggleTagButton.backgroundColor = highlightedColor
                    toggleQuestionButton.backgroundColor = UIColor.black
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
                case .people: break
                }
            }
        }
    }
    
    fileprivate var selectedTagDetail : Tag! {
        didSet {
            Database.getTag(selectedTagDetail.tagID!, completion: ({ tag, error in
                if error == nil {
                    self.exploreContainer.allQuestions = tag.questions
                    self.exploreContainer.feedItemType = .question
                }
            })
            )
        }
    }
    
    fileprivate var currentMode : currentModeTypes = .explore {
        didSet {
            followButton.isHidden = followButton.isHidden ? false : true
            backButton.isHidden = backButton.isHidden ? false : true

            exploreButton.isHidden = exploreButton.isHidden ? false : true
            toggleTagButton.isHidden = toggleTagButton.isHidden ? false : true
            toggleQuestionButton.isHidden = toggleQuestionButton.isHidden ? false : true
        }
    }
    
    fileprivate enum currentModeTypes { case explore, detail }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isLoaded {
            setupExploreHeader()
            setupExplore()
            iconContainer = addIcon(text: "EXPLORE")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /* DELEGATE METHODS */
    func userSelectedTag(_ selectedTag : Tag) {
        selectedTagDetail = selectedTag
        updateTagDetailHeader(selectedTag)
        selectedExploreType = nil
        currentMode = .detail

        if User.currentUser?.savedTags != nil && User.currentUser!.savedTags[selectedTag.tagID!] != nil {
            isFollowingSelectedTag = true
        } else {
            isFollowingSelectedTag = false
        }
    }
    
    //searchVCDelegate methods
    func userClickedSearch() {
    }
    
    func userCancelledSearch() {
    }
    
    // UPDATE TAGS / QUESTIONS IN FEED
    fileprivate func updateTagDetailHeader(_ tag : Tag) {
        headerTitle.text = "#"+(tag.tagID!).uppercased()

        
        //        if let _tagImage = tag.previewImage {
        //            Database.getTagImage(_tagImage, maxImgSize: maxImgSize, completion: {(data, error) in
        //                if error != nil {
        //                    print (error?.localizedDescription)
        //                } else {
        //                    self.headerImage.image = UIImage(data: data!)
        //                    self.headerImage.contentMode = UIViewContentMode.scaleAspectFill
        //                }
        //            })
        //        } else {
        //            headerImage.image = nil
        //        }
        
    }

    internal func backToExplore() {
        selectedExploreType = .tag
        currentMode = .explore
        
        headerTitle.text = "EXPLORE"
        headerImage.image = nil
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
    
    fileprivate func updateFollowButton(_ followMode : FollowToggle) {
        switch followMode {
        case .unfollow:
            let followTintedImage = UIImage(named: "remove")?.withRenderingMode(.alwaysTemplate)
            followButton.setImage(followTintedImage, for: UIControlState())
            followButton.tintColor = UIColor.black
            followButton.setTitle("UNFOLLOW", for: UIControlState())
        case .follow:
            let followTintedImage = UIImage(named: "add")?.withRenderingMode(.alwaysTemplate)
            followButton.setImage(followTintedImage, for: UIControlState())
            followButton.tintColor = UIColor.black
            followButton.setTitle("FOLLOW", for: UIControlState())
        }
        followButton.layoutIfNeeded()
    }
    
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    internal func toggleExploreMode(_ sender : UIButton!) {
        if sender == toggleTagButton && selectedExploreType != .tag {
            selectedExploreType = .tag
        } else if sender == toggleQuestionButton && selectedExploreType != .question {
            selectedExploreType = .question
        }
    }
    
    
    /* MARK : LAYOUT VIEW FUNCTIONS */
    fileprivate func setupExplore() {
        if !exploreViewSetup {
            
            exploreContainer = FeedVC()
            exploreContainer.feedDelegate = self
            exploreContainer.searchDelegate = self
            selectedExploreType = .tag
            
            GlobalFunctions.addNewVC(exploreContainer, parentVC: self)
            exploreContainer.view.translatesAutoresizingMaskIntoConstraints = false
            exploreContainer.view.topAnchor.constraint(equalTo: headerContainer.bottomAnchor).isActive = true
            exploreContainer.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            exploreContainer.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            exploreContainer.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
            exploreContainer.view.layoutIfNeeded()
            
            exploreViewSetup = true
        }
    }
    
    fileprivate func setupExploreSubHeader() {
        if !isExploreSubHeaderSetup {
            
            headerContainer.addSubview(toggleTagButton)
            headerContainer.addSubview(toggleQuestionButton)

            toggleQuestionButton.translatesAutoresizingMaskIntoConstraints = false
            toggleQuestionButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
            toggleQuestionButton.widthAnchor.constraint(equalTo: toggleQuestionButton.heightAnchor).isActive = true
            toggleQuestionButton.centerYAnchor.constraint(equalTo: headerTitle.centerYAnchor).isActive = true
            toggleQuestionButton.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
            toggleQuestionButton.layoutIfNeeded()
            
            toggleTagButton.translatesAutoresizingMaskIntoConstraints = false
            toggleTagButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
            toggleTagButton.widthAnchor.constraint(equalTo: toggleTagButton.heightAnchor).isActive = true
            toggleTagButton.centerYAnchor.constraint(equalTo: headerTitle.centerYAnchor).isActive = true
            toggleTagButton.trailingAnchor.constraint(equalTo: toggleQuestionButton.leadingAnchor, constant: -Spacing.s.rawValue).isActive = true
            toggleTagButton.layoutIfNeeded()
            
            toggleTagButton.backgroundColor = UIColor.black
            toggleTagButton.setImage(UIImage(named: "tag"), for: UIControlState())
            toggleTagButton.imageEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7)
            toggleTagButton.makeRound()
//            toggleTagButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
//            toggleTagButton.setTitle("TAGS", for: UIControlState())
//            toggleTagButton.setTitleColor(UIColor.black, for: UIControlState())
            toggleTagButton.addTarget(self, action: #selector(toggleExploreMode(_:)), for: .touchUpInside)
            
            toggleQuestionButton.backgroundColor = UIColor.black
            toggleQuestionButton.setImage(UIImage(named: "question"), for: UIControlState())
            toggleQuestionButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
            toggleQuestionButton.makeRound()
//            toggleQuestionButton.setTitle("QUESTIONS", for: UIControlState())
//            toggleQuestionButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
//            toggleQuestionButton.setTitleColor(UIColor.black, for: UIControlState())
            toggleQuestionButton.addTarget(self, action: #selector(toggleExploreMode(_:)), for: .touchUpInside)

        }
    }
    
    func setupExploreHeader() {
        if !isExploreHeaderSetup {
            view.backgroundColor = UIColor.white
            
            view.addSubview(headerContainer)
            headerContainer.translatesAutoresizingMaskIntoConstraints = false
            headerContainer.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor, constant: Spacing.xs.rawValue).isActive = true
            headerContainer.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
            headerContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            headerContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.125).isActive = true
            headerContainer.layoutIfNeeded()
            
            headerContainer.addSubview(headerImage)
            headerContainer.addSubview(headerTitle)
            headerContainer.addSubview(headerButtonContainer)
            headerContainer.addSubview(followButton)

            headerImage.frame = headerContainer.bounds
            headerImage.contentMode = UIViewContentMode.scaleAspectFill
            
            headerButtonContainer.translatesAutoresizingMaskIntoConstraints = false
            headerButtonContainer.heightAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
            headerButtonContainer.widthAnchor.constraint(equalTo: headerButtonContainer.heightAnchor).isActive = true
            headerButtonContainer.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
            headerButtonContainer.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: Spacing.xs.rawValue).isActive = true
            headerButtonContainer.layoutIfNeeded()
            
            headerButtonContainer.addSubview(exploreButton)
            headerButtonContainer.addSubview(backButton)

            exploreButton.frame = headerButtonContainer.bounds
            backButton.frame = headerButtonContainer.bounds
            
            let exploreTintedImage = UIImage(named: "collection-list")?.withRenderingMode(.alwaysTemplate)
            exploreButton.setImage(exploreTintedImage, for: UIControlState())
            exploreButton.tintColor = UIColor.black
            
            let backTintedImage = UIImage(named: "back")?.withRenderingMode(.alwaysTemplate)
            backButton.setImage(backTintedImage, for: UIControlState())
            backButton.tintColor = UIColor.black
            backButton.isHidden = true
            backButton.addTarget(self, action: #selector(backToExplore), for: UIControlEvents.touchDown)
            
            followButton.translatesAutoresizingMaskIntoConstraints = false
            followButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
            followButton.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -Spacing.m.rawValue).isActive = true
            followButton.centerYAnchor.constraint(equalTo: headerTitle.centerYAnchor).isActive = true
            followButton.layoutIfNeeded()
            
            followButton.backgroundColor = UIColor.white
            followButton.setButtonFont(FontSizes.caption.rawValue, weight : UIFontWeightMedium, color : UIColor.black, alignment : .center)
            
            followButton.makeRound()
            followButton.layer.borderColor = UIColor.black.cgColor
            followButton.layer.borderWidth = IconThickness.medium.rawValue
            followButton.contentEdgeInsets = UIEdgeInsetsMake(7, 0, 7, 7)
            followButton.imageView?.contentMode = .scaleAspectFit
            followButton.isHidden = true
            followButton.addTarget(self, action: #selector(follow), for: UIControlEvents.touchDown)
            
            headerTitle.translatesAutoresizingMaskIntoConstraints = false
            headerTitle.centerYAnchor.constraint(equalTo: headerButtonContainer.centerYAnchor).isActive = true
            headerTitle.leadingAnchor.constraint(equalTo: headerButtonContainer.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
            headerTitle.widthAnchor.constraint(equalTo: headerContainer.widthAnchor, multiplier: 0.5).isActive = true

            headerTitle.text = "EXPLORE"
            headerTitle.setFont(FontSizes.headline.rawValue, weight: UIFontWeightBlack, color: UIColor.black, alignment: .left)
            
            setupExploreSubHeader()
            isExploreHeaderSetup = true
        }
    }
}
