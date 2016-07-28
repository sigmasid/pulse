//
//  TagDetailQuestionCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/11/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class TagDetailQuestionCell: UITableViewCell {
    
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var leftSeparatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let _color = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.3 )
        leftSeparatorView.backgroundColor = _color
        questionLabel.backgroundColor = _color
        questionLabel.numberOfLines = 0
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
