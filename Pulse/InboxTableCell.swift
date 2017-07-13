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
    fileprivate var lastMessageTime = UILabel()
    
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
            userImage.makeRound()
        }
    }
    
    func updateName(name : String?) {
        userName.text = name?.capitalized
    }
    
    func updateLastMessage(conversation: Conversation, sentByUser: Bool?) {
        let firstName = conversation.cUser.getFirstName() ?? "user"
        
        if let sentByUser = sentByUser {
            switch conversation.cLastMessageType! {
            case .message:
                lastMessage.text = conversation.cLastMessage
            case .interviewInvite:
                lastMessage.text = sentByUser ? "You sent an interview request" : "You received an interview request"
            case .perspectiveInvite:
                lastMessage.text = sentByUser ? "You invited \(firstName) to share perspectives" : "You are invited to share your perspectives"
            case .contributorInvite:
                lastMessage.text = sentByUser ? "You invited \(firstName) to become a contributor" : "You are invite to be a featured contributor!"
            case .channelInvite:
                lastMessage.text = sentByUser ? "You invited \(firstName) to a new channel" : "You are invited to check out a new channel"
            case .questionInvite:
                lastMessage.text = sentByUser ? "You sent a question to \(firstName)" : "You have a new question to answer"
            case .showcaseInvite:
                lastMessage.text = sentByUser ? "You invted \(firstName) to create a showcase" : "You got an invite to create a showcase"
            case .feedbackInvite:
                lastMessage.text = sentByUser ? "You invted \(firstName) to give feed" : "You got an invite to give feedback"
            }
        } else {
            lastMessage.text = conversation.cLastMessage
        }
    }
    
    func updateMessageTime(time: String?) {
        lastMessageTime.text = time
    }
    
    fileprivate func setupCellLayout() {
        contentView.addSubview(userImage)
        userImage.translatesAutoresizingMaskIntoConstraints = false
        userImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        userImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        userImage.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        userImage.heightAnchor.constraint(equalTo: userImage.widthAnchor).isActive = true
        userImage.layoutIfNeeded()
        userImage.tintColor = .black
        userImage.contentMode = .scaleAspectFill

        contentView.addSubview(lastMessageTime)
        lastMessageTime.translatesAutoresizingMaskIntoConstraints = false
        lastMessageTime.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        lastMessageTime.topAnchor.constraint(equalTo: userImage.topAnchor).isActive = true
        lastMessageTime.layoutIfNeeded()
        
        lastMessageTime.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: .darkGray, alignment: .left)
        lastMessageTime.lineBreakMode = .byTruncatingTail

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
        lastMessage.topAnchor.constraint(equalTo: userName.bottomAnchor).isActive = true
        lastMessage.layoutIfNeeded()
        
        lastMessage.setFont(FontSizes.body2.rawValue, weight: UIFontWeightRegular, color: .gray, alignment: .left)
        lastMessage.lineBreakMode = .byTruncatingTail
        lastMessage.numberOfLines = 2
    }
}
