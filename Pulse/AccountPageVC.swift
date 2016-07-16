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
    
    var returnToParentDelegate : ParentDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                print("signed out")
            } else {
                print("error signing out")
            }
        })
    }

    @IBAction func LinkAccount(sender: UIButton) {
        //check w/ social source and connect to user profile on firebase
    }
    
    func updateLabels(notification: NSNotification) {
        if let _userName = User.currentUser!.name {
            uNameLabel.text = _userName
        } else {
            uNameLabel.text = "Add Name"
        }
        
        if let _uPic = User.currentUser!.profilePic {
            addUserProfilePic(NSURL(string: _uPic))
        } else {
            //put in generic user image
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
