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
            self.homeFeedVC.feedItemType = .question
            
            GlobalFunctions.addNewVC(self.homeFeedVC, parentVC: self)
        }
    }
    
    func displayIcon() {
        iconContainer = IconContainer(frame: CGRect(x: 0,y: 0,width: IconSizes.medium.rawValue, height: IconSizes.medium.rawValue + Spacing.m.rawValue))
        iconContainer.setViewTitle("EXPLORE")
        view.addSubview(iconContainer)
        
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
        iconContainer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue + Spacing.m.rawValue).isActive = true
        iconContainer.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        iconContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        iconContainer.layoutIfNeeded()
    }
}
