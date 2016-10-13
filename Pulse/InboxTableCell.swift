//
//  InboxTableCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/13/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class InboxTableCell: UITableViewCell {
    fileprivate var userImage = UIImageView()
    fileprivate var userName = UILabel()
    fileprivate var lastMessage = UILabel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCellLayout()
        selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateImage( image : UIImage?) {
        if let image = image{
            userImage.image = image
            userImage.layer.cornerRadius = userImage.bounds.height / 2
            userImage.layer.masksToBounds = true
            userImage.clipsToBounds = true
        }
    }
    
    func updateName(name : String?) {
        userName.text = name
    }
    
    func updateLastMessage(message : String?) {
        lastMessage.text = message
    }
    
    fileprivate func setupCellLayout() {
        print("setup cell layout fired")
        contentView.addSubview(userImage)
        userImage.translatesAutoresizingMaskIntoConstraints = false
        userImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        userImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.s.rawValue).isActive = true
        userImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
        userImage.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        userImage.layoutIfNeeded()
        
        contentView.addSubview(userName)
        userName.translatesAutoresizingMaskIntoConstraints = false
        userName.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        userName.topAnchor.constraint(equalTo: userImage.topAnchor).isActive = true
        userName.leadingAnchor.constraint(equalTo: userImage.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
        userName.layoutIfNeeded()
        
        userName.setFont(FontSizes.body.rawValue, weight: UIFontWeightBold, color: .black, alignment: .left)
        
        contentView.addSubview(lastMessage)
        lastMessage.translatesAutoresizingMaskIntoConstraints = false
        lastMessage.trailingAnchor.constraint(equalTo: userName.trailingAnchor).isActive = true
        lastMessage.leadingAnchor.constraint(equalTo: userName.leadingAnchor).isActive = true
        lastMessage.bottomAnchor.constraint(equalTo: userImage.bottomAnchor).isActive = true
        lastMessage.topAnchor.constraint(equalTo: userName.bottomAnchor).isActive = true
        lastMessage.layoutIfNeeded()
        
        lastMessage.setFont(FontSizes.body2.rawValue, weight: UIFontWeightRegular, color: .black, alignment: .left)
        lastMessage.lineBreakMode = .byTruncatingTail
    }
}
