//
//  MessageTableCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/4/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class MessageTableCell: UITableViewCell {
    
    var message : Message! {
        didSet {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let stringDate: String = message.time != nil ? formatter.string(from: message.time) : ""
            messageTimestamp.text = stringDate
            messageBody.text = message.body
        }
    }
    
    enum MessageCellType { case sent, received }
    var messageType : MessageCellType! {
        didSet {
            if messageType == .sent {
                sentByUser()
                messageLeadingAnchor.isActive = false
                messageTrailingAnchor.isActive = true
                messageBody.layoutIfNeeded()
                
                messageTimestamp.textAlignment = .right
                messageBody.textAlignment = .right
                messageBody.backgroundColor = .clear
            } else {
                receivedByUser()
                messageTrailingAnchor.isActive = false
                messageLeadingAnchor.isActive = true
                messageBody.layoutIfNeeded()
                
                messageTimestamp.textAlignment = .left
                messageBody.textAlignment = .left
                messageBody.backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.3)
                messageBody.layer.cornerRadius = 5
                messageBody.layoutIfNeeded()
            }
        }
    }
    
    private var leftContainer = UIView()
    private var rightContainer = UIView()
    private var middleContainer = UIView()

    private var messageSenderName = UILabel()
    var messageSenderImage = UIImageView()
    
    private var messageTimestamp = UILabel()
    private var messageBody = PaddingLabel()
    
    private var messageTrailingAnchor: NSLayoutConstraint!
    private var messageLeadingAnchor: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCellLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        message = nil
        messageSenderImage.image = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    fileprivate func setupCellLayout() {
        contentView.addSubview(leftContainer)
        leftContainer.translatesAutoresizingMaskIntoConstraints = false
        leftContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        leftContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        leftContainer.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        leftContainer.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        leftContainer.layoutIfNeeded()
        
        contentView.addSubview(rightContainer)
        rightContainer.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        rightContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        rightContainer.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        rightContainer.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        rightContainer.layoutIfNeeded()
        
        contentView.addSubview(middleContainer)
        middleContainer.translatesAutoresizingMaskIntoConstraints = false
        middleContainer.trailingAnchor.constraint(equalTo: rightContainer.leadingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        middleContainer.leadingAnchor.constraint(equalTo: leftContainer.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
        middleContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        middleContainer.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        middleContainer.layoutIfNeeded()
        
        setupMiddle()
    }
    
    fileprivate func sentByUser() {
        rightContainer.addSubview(messageSenderName)
        rightContainer.addSubview(messageSenderImage)
        
        messageSenderImage.translatesAutoresizingMaskIntoConstraints = false
        messageSenderImage.centerXAnchor.constraint(equalTo: rightContainer.centerXAnchor).isActive = true
        messageSenderImage.centerYAnchor.constraint(equalTo: rightContainer.centerYAnchor).isActive = true
        messageSenderImage.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        messageSenderImage.widthAnchor.constraint(equalTo: messageSenderImage.heightAnchor).isActive = true
        messageSenderImage.layoutIfNeeded()
        
        messageSenderImage.layer.cornerRadius = messageSenderImage.bounds.height / 2
        messageSenderImage.layer.masksToBounds = true
        messageSenderImage.layer.shouldRasterize = true
        messageSenderImage.layer.rasterizationScale = UIScreen.main.scale
        messageSenderImage.backgroundColor = UIColor.lightGray
        
        messageSenderName.translatesAutoresizingMaskIntoConstraints = false
        messageSenderName.topAnchor.constraint(equalTo: messageSenderImage.bottomAnchor).isActive = true
        messageSenderName.leadingAnchor.constraint(equalTo: messageSenderImage.leadingAnchor).isActive = true
        messageSenderName.widthAnchor.constraint(equalTo: messageSenderImage.widthAnchor).isActive = true
        messageSenderName.layoutIfNeeded()
    }
    
    fileprivate func receivedByUser() {
        leftContainer.addSubview(messageSenderName)
        leftContainer.addSubview(messageSenderImage)
        
        messageSenderImage.translatesAutoresizingMaskIntoConstraints = false
        messageSenderImage.centerXAnchor.constraint(equalTo: leftContainer.centerXAnchor).isActive = true
        messageSenderImage.centerYAnchor.constraint(equalTo: leftContainer.centerYAnchor).isActive = true
        messageSenderImage.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        messageSenderImage.widthAnchor.constraint(equalTo: messageSenderImage.heightAnchor).isActive = true
        messageSenderImage.layoutIfNeeded()
        
        messageSenderImage.layer.cornerRadius = messageSenderImage.bounds.height / 2
        messageSenderImage.layer.masksToBounds = true
        messageSenderImage.layer.shouldRasterize = true
        messageSenderImage.layer.rasterizationScale = UIScreen.main.scale
        messageSenderImage.backgroundColor = UIColor.lightGray
        
        messageSenderName.translatesAutoresizingMaskIntoConstraints = false
        messageSenderName.topAnchor.constraint(equalTo: messageSenderImage.bottomAnchor).isActive = true
        messageSenderName.leadingAnchor.constraint(equalTo: messageSenderImage.leadingAnchor).isActive = true
        messageSenderName.widthAnchor.constraint(equalTo: messageSenderImage.widthAnchor).isActive = true
        messageSenderName.layoutIfNeeded()
    }
    
    fileprivate func setupMiddle() {
        middleContainer.addSubview(messageTimestamp)
        middleContainer.addSubview(messageBody)
        
        messageBody.translatesAutoresizingMaskIntoConstraints = false
        messageTrailingAnchor = messageBody.trailingAnchor.constraint(equalTo: middleContainer.trailingAnchor)
        messageTrailingAnchor.isActive = false
        
        messageLeadingAnchor = messageBody.leadingAnchor.constraint(equalTo: middleContainer.leadingAnchor)
        messageLeadingAnchor.isActive = false
        
        messageBody.widthAnchor.constraint(lessThanOrEqualTo: middleContainer.widthAnchor, multiplier: 0.9).isActive = true
        messageBody.bottomAnchor.constraint(equalTo: middleContainer.bottomAnchor, constant: -Spacing.xs.rawValue).isActive = true
        messageBody.layoutIfNeeded()
        
        messageBody.setFont(FontSizes.body2.rawValue, weight: UIFontWeightRegular, color: .black, alignment: .left)
        messageBody.numberOfLines = 0
        messageBody.lineBreakMode = .byWordWrapping
        messageBody.clipsToBounds = true
        messageBody.layer.masksToBounds = true
        messageBody.layer.cornerRadius = buttonCornerRadius.radius(.small)
        
        messageTimestamp.translatesAutoresizingMaskIntoConstraints = false
        messageTimestamp.trailingAnchor.constraint(equalTo: middleContainer.trailingAnchor).isActive = true
        messageTimestamp.leadingAnchor.constraint(equalTo: middleContainer.leadingAnchor).isActive = true
        messageTimestamp.topAnchor.constraint(equalTo: middleContainer.topAnchor, constant: Spacing.xs.rawValue).isActive = true
        messageTimestamp.bottomAnchor.constraint(equalTo: messageBody.topAnchor).isActive = true

        messageTimestamp.layoutIfNeeded()
        messageTimestamp.setFont(FontSizes.caption2.rawValue, weight: UIFontWeightRegular, color: .lightGray, alignment: .left)
    }
}
