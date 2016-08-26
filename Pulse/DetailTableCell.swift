//
//  DetailTableCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/11/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class DetailTableCell: UITableViewCell {
    
    var separatorView: UIView!
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    var leftSeparatorView: UIView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCellLayout()
        selectionStyle = .None
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    private func setupCellLayout() {
        /*TOP SEPARATOR VIEW*/
        separatorView = UIView()
        addSubview(separatorView!)
        
        separatorView!.translatesAutoresizingMaskIntoConstraints = false
        separatorView?.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        separatorView?.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        separatorView?.heightAnchor.constraintEqualToAnchor(heightAnchor, multiplier: 0.2).active = true
        separatorView?.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        separatorView.layoutIfNeeded()
        
        /*LEFT SEPARATOR VIEW*/
        leftSeparatorView = UIView()
        addSubview(leftSeparatorView!)
        
        leftSeparatorView!.translatesAutoresizingMaskIntoConstraints = false
        leftSeparatorView?.leadingAnchor.constraintEqualToAnchor(leadingAnchor).active = true
        leftSeparatorView?.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        leftSeparatorView?.topAnchor.constraintEqualToAnchor(separatorView.bottomAnchor).active = true
        leftSeparatorView?.widthAnchor.constraintEqualToConstant(Spacing.s.rawValue).active = true
        leftSeparatorView.layoutIfNeeded()
        
        /*TITLE LABEL*/
        titleLabel = UILabel()
        titleLabel?.setPreferredFont(UIColor.whiteColor(), alignment : .Left)
        
        addSubview(titleLabel!)
        
        titleLabel!.translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.leadingAnchor.constraintEqualToAnchor(leftSeparatorView.trailingAnchor).active = true
        titleLabel?.topAnchor.constraintEqualToAnchor(separatorView.bottomAnchor).active = true
        titleLabel?.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        titleLabel?.trailingAnchor.constraintEqualToAnchor(trailingAnchor).active = true
        titleLabel.layoutIfNeeded()
        
        /*SUBTITLE LABEL*/
        subtitleLabel = UILabel()
        subtitleLabel?.setPreferredFont(UIColor.whiteColor(), alignment : .Left)
        
        addSubview(subtitleLabel!)
        
        subtitleLabel!.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel?.leadingAnchor.constraintEqualToAnchor(leftSeparatorView.trailingAnchor).active = true
        subtitleLabel?.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        subtitleLabel?.topAnchor.constraintEqualToAnchor(titleLabel.bottomAnchor).active = true
        subtitleLabel?.trailingAnchor.constraintEqualToAnchor(trailingAnchor).active = true
        subtitleLabel.layoutIfNeeded()

        let _color = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.3 )
        leftSeparatorView.backgroundColor = _color
        titleLabel.backgroundColor = _color
        titleLabel.numberOfLines = 0
        subtitleLabel.backgroundColor = _color
        subtitleLabel.numberOfLines = 0
    }
}
