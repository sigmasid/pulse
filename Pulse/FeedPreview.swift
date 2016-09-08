//
//  FeedPreview.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/6/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class FeedPreview: UIView {
    
    private var leftTile = UIView()
    private var rightTile = UIView()
    
    private var qTitleLabel = UILabel()
    private var tagTitleLabel = UILabel()
    private var exploreButton = UIButton()
    
    private var previewPlayer : PreviewVC?
    private var tileBackgroundImage : UIImageView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.whiteColor()
        
        setupLeftTile()
        setupRightTile()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupLeftTile() {
        addSubview(leftTile)
        
        leftTile.translatesAutoresizingMaskIntoConstraints = false
        leftTile.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        leftTile.leadingAnchor.constraintEqualToAnchor(leadingAnchor).active = true
        leftTile.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        leftTile.widthAnchor.constraintEqualToAnchor(widthAnchor , multiplier: 0.5).active = true
        leftTile.layoutIfNeeded()
        
        leftTile.addSubview(tagTitleLabel)
        
        tagTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        tagTitleLabel.bottomAnchor.constraintEqualToAnchor(leftTile.bottomAnchor, constant: -Spacing.xxs.rawValue).active = true
        tagTitleLabel.leadingAnchor.constraintEqualToAnchor(leftTile.leadingAnchor, constant: Spacing.xxs.rawValue).active = true
        tagTitleLabel.trailingAnchor.constraintEqualToAnchor(leftTile.trailingAnchor, constant: -Spacing.xxs.rawValue).active = true
        tagTitleLabel.layoutIfNeeded()
        
        leftTile.addSubview(qTitleLabel)
        
        qTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        qTitleLabel.bottomAnchor.constraintEqualToAnchor(tagTitleLabel.topAnchor, constant: -Spacing.xxs.rawValue).active = true
        qTitleLabel.leadingAnchor.constraintEqualToAnchor(tagTitleLabel.leadingAnchor).active = true
        qTitleLabel.trailingAnchor.constraintEqualToAnchor(tagTitleLabel.trailingAnchor).active = true
        qTitleLabel.layoutIfNeeded()
        
        leftTile.addSubview(exploreButton)
        
        exploreButton.translatesAutoresizingMaskIntoConstraints = false
        exploreButton.topAnchor.constraintEqualToAnchor(leftTile.topAnchor, constant: Spacing.xs.rawValue).active = true
        exploreButton.leadingAnchor.constraintEqualToAnchor(leftTile.leadingAnchor, constant: Spacing.xs.rawValue).active = true
        exploreButton.widthAnchor.constraintEqualToConstant(IconSizes.XSmall.rawValue).active = true
        exploreButton.heightAnchor.constraintEqualToConstant(IconSizes.XSmall.rawValue).active = true

        let exploreImage = UIImage(named: "collection-list")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        exploreButton.setImage(exploreImage, forState: .Normal)
        exploreButton.tintColor = UIColor.blackColor()
        
        
        let nowPlayingLabel = UILabel()
        let nowPlayingImage = UIImageView()
        
        leftTile.addSubview(nowPlayingLabel)
        leftTile.addSubview(nowPlayingImage)

        nowPlayingImage.translatesAutoresizingMaskIntoConstraints = false
        nowPlayingImage.centerYAnchor.constraintEqualToAnchor(exploreButton.centerYAnchor).active = true
        nowPlayingImage.trailingAnchor.constraintEqualToAnchor(leftTile.trailingAnchor, constant: -Spacing.xxs.rawValue).active = true
        nowPlayingImage.widthAnchor.constraintEqualToConstant(IconSizes.XXSmall.rawValue).active = true
        nowPlayingImage.heightAnchor.constraintEqualToConstant(IconSizes.XXSmall.rawValue).active = true
        nowPlayingImage.layoutIfNeeded()
        
        nowPlayingImage.image = UIImage(named: "filled-arrow")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        nowPlayingImage.tintColor = UIColor.blackColor()
        
        nowPlayingLabel.translatesAutoresizingMaskIntoConstraints = false
        nowPlayingLabel.centerYAnchor.constraintEqualToAnchor(nowPlayingImage.centerYAnchor).active = true
        nowPlayingLabel.trailingAnchor.constraintEqualToAnchor(nowPlayingImage.leadingAnchor).active = true
        nowPlayingLabel.leadingAnchor.constraintEqualToAnchor(exploreButton.trailingAnchor).active = true
        
        nowPlayingLabel.text = "NOW PLAYING"
        nowPlayingLabel.setFont(FontSizes.Caption.rawValue, weight: UIFontWeightRegular, color: UIColor.blackColor(), alignment: .Right)
        
        qTitleLabel.numberOfLines = 0
        qTitleLabel.lineBreakMode = .ByWordWrapping
        tagTitleLabel.setFont(FontSizes.Caption.rawValue, weight: UIFontWeightBold, color: UIColor.blackColor(), alignment: .Left)
        qTitleLabel.setFont(FontSizes.Caption.rawValue, weight: UIFontWeightRegular, color: UIColor.blackColor(), alignment: .Left)
    }
    
    private func setupRightTile() {
        addSubview(rightTile)
        
        rightTile.translatesAutoresizingMaskIntoConstraints = false
        rightTile.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        rightTile.trailingAnchor.constraintEqualToAnchor(trailingAnchor).active = true
        rightTile.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        rightTile.widthAnchor.constraintEqualToAnchor(widthAnchor , multiplier: 0.5).active = true
        rightTile.layoutIfNeeded()
        
        previewPlayer = PreviewVC(frame: rightTile.bounds)
        if let previewPlayer = previewPlayer {
            rightTile.addSubview(previewPlayer)
        }
    }
    
    func setLabels(questionTitle : String?, tagTitle : String?) {
        qTitleLabel.text = questionTitle
        
        if let tagTitle = tagTitle {
            tagTitleLabel.text = "#\(tagTitle.uppercaseString)"
        }
    }
    
    func showQuestion(question : Question) {
        if let previewPlayer = previewPlayer {
            previewPlayer.currentQuestion = question
        }
    }
    
    func setTileImage(image : UIImage) {
        if tileBackgroundImage == nil {
            tileBackgroundImage = UIImageView()
            
            leftTile.addSubview(tileBackgroundImage!)
            
            tileBackgroundImage!.translatesAutoresizingMaskIntoConstraints = false
            tileBackgroundImage!.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
            tileBackgroundImage!.trailingAnchor.constraintEqualToAnchor(trailingAnchor).active = true
            tileBackgroundImage!.topAnchor.constraintEqualToAnchor(topAnchor).active = true
            tileBackgroundImage!.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
            tileBackgroundImage!.layoutIfNeeded()
            
        }
        
        tileBackgroundImage!.image = image
        tileBackgroundImage!.contentMode = .ScaleAspectFill

    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
