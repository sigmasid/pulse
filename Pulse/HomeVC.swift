//
//  HomeVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class HomeVC: UIViewController {
    private var isLoaded = false
    private var homeFeedVC : FeedVC!
    private var iconContainer : IconContainer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            displayHomeFeed()
            displayIcon()
            isLoaded = true
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
            self.homeFeedVC.feedItemType = .Question
            
            GlobalFunctions.addNewVC(self.homeFeedVC, parentVC: self)
        }
    }
    
    func displayIcon() {
        iconContainer = IconContainer(frame: CGRectMake(0,0,IconSizes.Medium.rawValue, IconSizes.Medium.rawValue + Spacing.m.rawValue))
        iconContainer.setViewTitle("EXPLORE")
        view.addSubview(iconContainer)
        
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -Spacing.s.rawValue).active = true
        iconContainer.heightAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue + Spacing.m.rawValue).active = true
        iconContainer.widthAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
        iconContainer.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor, constant: -Spacing.s.rawValue).active = true
        iconContainer.layoutIfNeeded()
    }
}
