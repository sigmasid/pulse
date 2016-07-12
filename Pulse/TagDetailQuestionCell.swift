//
//  TagDetailQuestionCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/11/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class TagDetailQuestionCell: UITableViewCell {
    
    @IBOutlet weak var questionTextView: UITextView!
    @IBOutlet weak var separatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.questionTextView.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.3 )
        self.questionTextView.textContainerInset = UIEdgeInsetsMake(10, 10, 0, 0)
//        self.questionTextView.textColor = UIColor.whiteColor()
//        self.questionTextView.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
