//
//  HomeVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class HomeVC: UIViewController {
    fileprivate var isLoaded = false
    fileprivate var homeFeedVC : FeedVC!
    fileprivate var iconContainer : IconContainer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            view.backgroundColor = UIColor.white

            displayHomeFeed()

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
        let containerView = UIView(frame: view.bounds)
        view.addSubview(containerView)
        
        Database.createFeed { feed in
            self.homeFeedVC = FeedVC()
            self.homeFeedVC.view.frame = containerView.frame
            
            self.homeFeedVC.currentTag = feed
            if let allQuestions = feed.questions {
                self.homeFeedVC.allQuestions = allQuestions
            }
            self.homeFeedVC.feedItemType = .question
            
            GlobalFunctions.addNewVC(self.homeFeedVC, parentVC: self)
            self.addIcon()
        }
    }
    
    internal func addIcon() {
        iconContainer = addIcon(text: "FEED")
    }
}
