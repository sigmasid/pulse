//
//  LoginAddNameVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/8/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class LoginAddNameVC: UIViewController {

    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var firstName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewDidAppear(animated : Bool) {
        super.viewDidAppear(true)
        
        let pulseIcon = Icon(frame: CGRectMake(0,0,self.logoView.frame.width, self.logoView.frame.height))
        pulseIcon.drawIcon(iconColor, iconThickness: 3)
        pulseIcon.drawIconBackground(iconBackgroundColor)
        
        logoView.addSubview(pulseIcon)
        
        self.firstName.layer.addSublayer(addBorders(self.firstName))
        self.lastName.layer.addSublayer(addBorders(self.lastName))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func addName(sender: UIButton) {
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
