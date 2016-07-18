//
//  AccountPageViewController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AccountPageVC: UIViewController {

    @IBOutlet weak var uProfilePic: UIImageView!
    @IBOutlet weak var uNameLabel: UITextField!
    @IBOutlet weak var numAnswersLabel: UILabel!
    @IBOutlet weak var subscribedTagsLabel: UITextView!
    @IBOutlet weak var inButton: UIButton!
    @IBOutlet weak var twtrButton: UIButton!
    @IBOutlet weak var fbButton: UIButton!
    
    weak var returnToParentDelegate : ParentDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        fbButton.layer.cornerRadius = fbButton.frame.width / 2
        twtrButton.layer.cornerRadius = twtrButton.frame.width / 2
        inButton.layer.cornerRadius = inButton.frame.width / 2
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.updateLabels), name: "UserUpdated", object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func ClickedSettings(sender: UIButton) {
        Database.signOut({ success in
            if success {
                //switch to sign in screen
            } else {
                //show error that could not sign out - try again later
            }
        })
    }

    @IBAction func LinkAccount(sender: UIButton) {
        //check w/ social source and connect to user profile on firebase
    }
    
    func updateLabels(notification: NSNotification) {
        if let _userName = User.currentUser!.name {
            uNameLabel.text = _userName
            uNameLabel.userInteractionEnabled = false
        } else {
            uNameLabel.text = "tap to edit name"
            uNameLabel.userInteractionEnabled = true
        }
        
        if let _uPic = User.currentUser!.profilePic {
            addUserProfilePic(NSURL(string: _uPic))
        } else {
            self.uProfilePic.image = UIImage(named: "default-profile")
        }
        
        numAnswersLabel.text = String(User.currentUser!.totalAnswers())
        self.view.setNeedsLayout()
    }
    
    func addUserProfilePic(_userImageURL : NSURL?) {
        if let _ = _userImageURL {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let _userImageData = NSData(contentsOfURL: _userImageURL!)
                dispatch_async(dispatch_get_main_queue(), {
                    self.uProfilePic.image = UIImage(data: _userImageData!)
                })
            }
        }
    }
    
    func highlightConnectedSocialSources() {
        
    }
}
