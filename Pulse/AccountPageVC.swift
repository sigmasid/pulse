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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func ClickedSettings(sender: UIButton) {
    }

    @IBAction func LinkAccount(sender: UIButton) {
    }
    
    
}
