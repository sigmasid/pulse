//
//  HomeVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class HomeVC: UIViewController {
    
    public var tabDelegate : tabVCDelegate!
    
    fileprivate var isLoaded = false
    fileprivate var homeFeedVC : FeedVC!
    fileprivate var loadingView : LoadingView?
    fileprivate var titleLabel = UILabel()
    
    //fileprivate var feed : Tag!
    fileprivate var notificationsSetup : Bool = false
    fileprivate var initialLoadComplete = false
    
    fileprivate var screenMenu = PulseMenu(_axis: .vertical, _spacing: Spacing.m.rawValue)
    
    fileprivate var channels : UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            view.backgroundColor = UIColor.white
            toggleLoading(show: true, message: "Loading feed...")
            
            loadFeed()
            
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
    
    
    func loadFeed() {
        if self.tabDelegate != nil { self.tabDelegate.removeLoading() }

        /**
        if User.isLoggedIn() && !initialLoadComplete {
            if homeFeedVC == nil {
                homeFeedVC = FeedVC()
                GlobalFunctions.addNewVC(self.homeFeedVC, parentVC: self)
            }

            Database.createFeed { feed in
                self.homeFeedVC.view.frame = self.view.bounds
                self.homeFeedVC.feedDelegate = self
                
                self.homeFeedVC.selectedTag = feed
                self.feed = feed
                self.homeFeedVC.allQuestions = feed.questions
                
                if self.homeFeedVC.allQuestions.count > 0 {
                    self.homeFeedVC.feedItemType = .question
                    self.toggleLoading(show: false, message: nil)
                } else {
                    self.view.bringSubview(toFront: self.loadingView!)
                    self.toggleLoading(show: true, message: "Explore new channels to add to your feed")
                }
                
                if self.tabDelegate != nil { self.tabDelegate.removeLoading() }
                self.initialLoadComplete = true
            }
        } else if !User.isLoggedIn() {
            if homeFeedVC != nil {
                view.bringSubview(toFront: loadingView!)
            }
            toggleLoading(show: true, message: "Please login to see your feed!")
        }
        
        if !notificationsSetup {
            NotificationCenter.default.addObserver(self, selector: #selector(updateFeed),
                                                   name: NSNotification.Name(rawValue: "FeedUpdated"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(loadFeed),
                                                   name: NSNotification.Name(rawValue: "FeedUpdateLogin"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(updateFeed),
                                                   name: NSNotification.Name(rawValue: "LogoutSuccess"), object: nil)
            
            notificationsSetup = true
        } **/
    }

    /**
    func returnHome() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        homeFeedVC.selectedTag = feed
        homeFeedVC.allQuestions = feed.items
        homeFeedVC.feedItemType = .question
        homeFeedVC.setSelectedIndex(index: nil)
    }
    
    func updateFeed() {
        if User.isLoggedIn() {
            Database.getFeed { feed in
                self.homeFeedVC.allQuestions = feed.items
                self.homeFeedVC.feedItemType = .question
            }
        } else {
            if homeFeedVC != nil {
                view.bringSubview(toFront: loadingView!)
            }
            initialLoadComplete = false
            toggleLoading(show: true, message: "Please login to see your feed!")
        }
    } **/
    
    /**
    func userSelected(type : FeedItemType, item : Any) {
        switch type {
        case .question:
            
            let selectedQuestion = item as! Question

            Database.getQuestion(selectedQuestion.qID, completion: { question, error in
                if let question = question, question.hasAnswers() {
                    //self.homeFeedVC.allAnswers = question.qAnswers.map{ (_aID) -> Answer in Answer(aID: _aID, qID : question.qID) }
                    self.homeFeedVC.feedItemType = .answer
                    self.homeFeedVC.setSelectedIndex(index: IndexPath(row: 0, section: 0))
                    self.toggleLoading(show: false, message : nil)
                    
                    guard let nav = self.navigationController as? PulseNavVC else { return }
                    nav.setNav(title: question.qTitle)
                    nav.setNavigationBarHidden(false, animated: true)
                } else {
                    self.toggleLoading(show: true, message : "No answers found")
                }
            })

        default: break
        }
    }
     **/
    
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
    
    fileprivate func toggleLoading(show: Bool, message: String?) {
        if loadingView == nil {
            loadingView = LoadingView(frame: view.frame, backgroundColor: UIColor.white)
            loadingView?.addIcon(IconSizes.medium, _iconColor: UIColor.black, _iconBackgroundColor: nil)
            toggleLoading(show: true, message: nil)
            view.addSubview(loadingView!)
        }
        
        loadingView?.isHidden = show ? false : true
        loadingView?.addMessage(message)
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

extension HomeVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 0.0, bottom: 1.0, right: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellHeight = GlobalFunctions.getCellHeight(type: .question)
        return CGSize(width: view.frame.width - 20, height: cellHeight)
    }
}

