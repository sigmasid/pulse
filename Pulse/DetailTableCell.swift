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
        selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    fileprivate func setupCellLayout() {
        /*TOP SEPARATOR VIEW*/
        separatorView = UIView()
        addSubview(separatorView!)
        
        separatorView!.translatesAutoresizingMaskIntoConstraints = false
        separatorView?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        separatorView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        separatorView?.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.2).isActive = true
        separatorView?.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        separatorView.layoutIfNeeded()
        
        /*LEFT SEPARATOR VIEW*/
        leftSeparatorView = UIView()
        addSubview(leftSeparatorView!)
        
        leftSeparatorView!.translatesAutoresizingMaskIntoConstraints = false
        leftSeparatorView?.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        leftSeparatorView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftSeparatorView?.topAnchor.constraint(equalTo: separatorView.bottomAnchor).isActive = true
        leftSeparatorView?.widthAnchor.constraint(equalToConstant: Spacing.s.rawValue).isActive = true
        leftSeparatorView.layoutIfNeeded()
        
        /*TITLE LABEL*/
        titleLabel = UILabel()
        titleLabel?.setPreferredFont(UIColor.white, alignment : .left)
        
        addSubview(titleLabel!)
        
        titleLabel!.translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.leadingAnchor.constraint(equalTo: leftSeparatorView.trailingAnchor).isActive = true
        titleLabel?.topAnchor.constraint(equalTo: separatorView.bottomAnchor).isActive = true
        titleLabel?.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        titleLabel?.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        titleLabel.layoutIfNeeded()
        
        /*SUBTITLE LABEL*/
        subtitleLabel = UILabel()
        subtitleLabel?.setPreferredFont(UIColor.white, alignment : .left)
        
        addSubview(subtitleLabel!)
        
        subtitleLabel!.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel?.leadingAnchor.constraint(equalTo: leftSeparatorView.trailingAnchor).isActive = true
        subtitleLabel?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        subtitleLabel?.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        subtitleLabel?.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        subtitleLabel.layoutIfNeeded()

        let _color = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.3 )
        leftSeparatorView.backgroundColor = _color
        titleLabel.backgroundColor = _color
        titleLabel.numberOfLines = 0
        subtitleLabel.backgroundColor = _color
        subtitleLabel.numberOfLines = 0
    }
}
