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
            
            let selectedQuestion = item as! Question //didSet method pulls questions from database in case of search else assigns questions from existing tag

            Database.getQuestion(selectedQuestion.qID, completion: { question, error in
                if let question = question, question.hasAnswers() {
                    self.homeFeedVC.allAnswers = question.qAnswers!.map{ (_aID) -> Answer in Answer(aID: _aID, qID : question.qID) }
                    self.homeFeedVC.feedItemType = .answer
                    self.homeFeedVC.setSelectedIndex(index: IndexPath(row: 0, section: 0))
                    self.toggleLoading(show: false, message : nil)
                    
                    guard let nav = self.navigationController as? PulseNavVC else { return }
                    nav.setNav(navTitle: nil, screenTitle: question.qTitle, screenImage: nil)
                    nav.setNavigationBarHidden(false, animated: true)
                } else {
                    self.toggleLoading(show: true, message : "No answers found")
                }
            })

        default: break
        }
    }
    
    fileprivate func updateNav() {
        backButton = PulseButton(size: .small, type: .back, isRound : true, hasBackground: true)
        backButton.addTarget(self, action: #selector(returnHome), for: .touchUpInside)
        
        navigationItem.leftBarButtonItem = backButton != nil ? UIBarButtonItem(customView: backButton!) : nil
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
