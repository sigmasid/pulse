//
//  HomeVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class HomeVC: UIViewController, feedVCDelegate {
    fileprivate var isLoaded = false
    fileprivate var homeFeedVC : FeedVC!
    fileprivate var iconContainer : IconContainer!
    fileprivate var loadingView : LoadingView?
    fileprivate var titleLabel = UILabel()
    
    fileprivate var feed : Tag!
    fileprivate var backButton : PulseButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            view.backgroundColor = UIColor.white
            displayHomeFeed()
            addIcon()
            updateNav()
            automaticallyAdjustsScrollViewInsets = false

            isLoaded = true
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }  
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func displayHomeFeed() {
        homeFeedVC = FeedVC()
        GlobalFunctions.addNewVC(self.homeFeedVC, parentVC: self)

        Database.createFeed { feed in
            self.homeFeedVC.view.frame = self.view.bounds
            self.homeFeedVC.feedDelegate = self
            
            self.homeFeedVC.selectedTag = feed
            self.feed = feed
            
            if let allQuestions = feed.questions {
                self.homeFeedVC.allQuestions = allQuestions
            }
            self.homeFeedVC.feedItemType = .question
        }
    }
    
    func returnHome() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        homeFeedVC.selectedTag = feed
        homeFeedVC.allQuestions = feed.questions
        homeFeedVC.feedItemType = .question
        homeFeedVC.setSelectedIndex(index: nil)
    }
    
    func userSelected(type : FeedItemType, item : Any) {
        switch type {
        case .question:
            navigationController?.setNavigationBarHidden(false, animated: true)
            
            let selectedQuestion = item as! Question //didSet method pulls questions from database in case of search else assigns questions from existing tag
            
            Database.getQuestion(selectedQuestion.qID, completion: { question, error in
                if error == nil && question.hasAnswers() {
                    self.homeFeedVC.allAnswers = question.qAnswers!.map{ (_aID) -> Answer in Answer(aID: _aID, qID : question.qID) }
                    self.homeFeedVC.feedItemType = .answer
                    self.homeFeedVC.setSelectedIndex(index: IndexPath(row: 0, section: 0))
                    self.toggleLoading(show: false, message : nil)
                    self.titleLabel.text = question.qTitle
                    self.titleLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightRegular, color: .black, alignment: .left)
                    self.titleLabel.adjustsFontSizeToFitWidth = true
                    self.titleLabel.sizeToFit()

                } else {
                    self.toggleLoading(show: true, message : "No answers found")
                }
            })

        default: break
        }
    }
    
    fileprivate func updateNav() {
        backButton = PulseButton(size: .xSmall, type: .back, isRound : true, hasBackground: true)
        backButton.addTarget(self, action: #selector(returnHome), for: .touchUpInside)

        titleLabel = UILabel(frame: CGRect(x: Spacing.xs.rawValue, y: 0, width: view.bounds.width, height: IconSizes.medium.rawValue))
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.minimumScaleFactor = 0.1
        
        navigationItem.leftBarButtonItem = backButton != nil ? UIBarButtonItem(customView: backButton!) : nil
        navigationItem.titleView = titleLabel
        
    }
    
    fileprivate func toggleLoading(show: Bool, message: String?) {
        if loadingView == nil {
            loadingView = LoadingView(frame: view.frame, backgroundColor: UIColor.white)
            loadingView?.addIcon(IconSizes.medium, _iconColor: UIColor.black, _iconBackgroundColor: nil)
            toggleLoading(show: true, message: "Loading Feed...")
        }
        
        loadingView?.isHidden = show ? false : true
        loadingView?.addMessage(message)
    }
    
    internal func addIcon() {
        iconContainer = addIcon(text: "FEED")
    }
}
