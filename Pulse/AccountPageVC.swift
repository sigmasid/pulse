//
//  AccountPageViewController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AccountPageVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var uProfilePic: UIImageView!
    @IBOutlet weak var uNameLabel: UITextField!
    @IBOutlet weak var numAnswersLabel: UILabel!
    @IBOutlet weak var subscribedTagsLabel: UITextView!
    @IBOutlet weak var inButton: UIButton!
    @IBOutlet weak var twtrButton: UIButton!
    @IBOutlet weak var fbButton: UIButton!
    
    weak var returnToParentDelegate : ParentDelegate!
    private var _nameErrorLabel = UILabel()
    private var _Camera : CameraManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        fbButton.layer.cornerRadius = fbButton.frame.width / 2
        twtrButton.layer.cornerRadius = twtrButton.frame.width / 2
        inButton.layer.cornerRadius = inButton.frame.width / 2
        
        uNameLabel.delegate = self
        uNameLabel.clearsOnBeginEditing = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.updateLabels), name: "UserUpdated", object: nil)
        
        let _tapGesture = UIPanGestureRecognizer(target: self, action: #selector(handleImageTap))
        _tapGesture.minimumNumberOfTouches = 1
        uProfilePic.addGestureRecognizer(_tapGesture)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        _nameErrorLabel.text = ""
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.dismissKeyboard()
        GlobalFunctions.validateName(uNameLabel.text, completion: {(verified, error) in
            if verified {
                Database.updateUserDisplayName(self.uNameLabel.text!, completion: { (success, error) in
                    if success {
                        //print("updated name in DB")
                    } else {
                        self.setupErrorLabel()
                        self.updateErrorLabelText(error!.localizedDescription)
                    }
                })
            } else {
                self.setupErrorLabel()
                self.updateErrorLabelText(error!.localizedDescription)
            }
        })
        return true
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
    
    func setupErrorLabel() {
        self.view.addSubview(_nameErrorLabel)
        
        _nameErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        _nameErrorLabel.topAnchor.constraintEqualToAnchor(uNameLabel.topAnchor).active = true
        _nameErrorLabel.trailingAnchor.constraintEqualToAnchor(self.view.trailingAnchor).active = true
        _nameErrorLabel.heightAnchor.constraintEqualToAnchor(uNameLabel.heightAnchor).active = true
        _nameErrorLabel.leadingAnchor.constraintEqualToAnchor(uNameLabel.trailingAnchor, constant: 10).active = true
        
        _nameErrorLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
        _nameErrorLabel.backgroundColor = UIColor.grayColor()
        _nameErrorLabel.textColor = UIColor.blackColor()
        _nameErrorLabel.textAlignment = .Left
    }
    
    func updateErrorLabelText(_errorText : String) {
        _nameErrorLabel.text = _errorText
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
    
    func handleImageTap() {
        _Camera = CameraManager()
    }
    
    func highlightConnectedSocialSources() {
        
    }
}
