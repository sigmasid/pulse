//
//  FeedPreview.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 9/6/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class FeedPreview: UIView {
    
    fileprivate var leftTile = UIView()
    fileprivate var rightTile = UIView()
    
    fileprivate var qTitleLabel = UILabel()
    fileprivate var tagTitleLabel = UILabel()
    fileprivate var exploreButton = UIButton()
    
    fileprivate var previewPlayer : PreviewVC?
    fileprivate var tileBackgroundImage : UIImageView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        setupLeftTile()
        setupRightTile()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func setupLeftTile() {
        addSubview(leftTile)
        
        leftTile.translatesAutoresizingMaskIntoConstraints = false
        leftTile.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftTile.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        leftTile.topAnchor.constraint(equalTo: topAnchor).isActive = true
        leftTile.widthAnchor.constraint(equalTo: widthAnchor , multiplier: 0.5).isActive = true
        leftTile.layoutIfNeeded()
        
        leftTile.addSubview(tagTitleLabel)
        
        tagTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        tagTitleLabel.bottomAnchor.constraint(equalTo: leftTile.bottomAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        tagTitleLabel.leadingAnchor.constraint(equalTo: leftTile.leadingAnchor, constant: Spacing.xxs.rawValue).isActive = true
        tagTitleLabel.trailingAnchor.constraint(equalTo: leftTile.trailingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        tagTitleLabel.layoutIfNeeded()
        
        leftTile.addSubview(qTitleLabel)
        
        qTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        qTitleLabel.bottomAnchor.constraint(equalTo: tagTitleLabel.topAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        qTitleLabel.leadingAnchor.constraint(equalTo: tagTitleLabel.leadingAnchor).isActive = true
        qTitleLabel.trailingAnchor.constraint(equalTo: tagTitleLabel.trailingAnchor).isActive = true
        qTitleLabel.layoutIfNeeded()
        
        leftTile.addSubview(exploreButton)
        
        exploreButton.translatesAutoresizingMaskIntoConstraints = false
        exploreButton.topAnchor.constraint(equalTo: leftTile.topAnchor, constant: Spacing.xs.rawValue).isActive = true
        exploreButton.leadingAnchor.constraint(equalTo: leftTile.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        exploreButton.widthAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        exploreButton.heightAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true

        let exploreImage = UIImage(named: "collection-list")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        exploreButton.setImage(exploreImage, for: UIControlState())
        exploreButton.tintColor = UIColor.black
        
        
        let nowPlayingLabel = UILabel()
        let nowPlayingImage = UIImageView()
        
        leftTile.addSubview(nowPlayingLabel)
        leftTile.addSubview(nowPlayingImage)

        nowPlayingImage.translatesAutoresizingMaskIntoConstraints = false
        nowPlayingImage.centerYAnchor.constraint(equalTo: exploreButton.centerYAnchor).isActive = true
        nowPlayingImage.trailingAnchor.constraint(equalTo: leftTile.trailingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        nowPlayingImage.widthAnchor.constraint(equalToConstant: IconSizes.xxSmall.rawValue).isActive = true
        nowPlayingImage.heightAnchor.constraint(equalToConstant: IconSizes.xxSmall.rawValue).isActive = true
        nowPlayingImage.layoutIfNeeded()
        
        nowPlayingImage.image = UIImage(named: "filled-arrow")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        nowPlayingImage.tintColor = UIColor.black
        
        nowPlayingLabel.translatesAutoresizingMaskIntoConstraints = false
        nowPlayingLabel.centerYAnchor.constraint(equalTo: nowPlayingImage.centerYAnchor).isActive = true
        nowPlayingLabel.trailingAnchor.constraint(equalTo: nowPlayingImage.leadingAnchor).isActive = true
        nowPlayingLabel.leadingAnchor.constraint(equalTo: exploreButton.trailingAnchor).isActive = true
        
        nowPlayingLabel.text = "NOW PLAYING"
        nowPlayingLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: UIColor.black, alignment: .right)
        
        qTitleLabel.numberOfLines = 0
        qTitleLabel.lineBreakMode = .byWordWrapping
        tagTitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightBold, color: UIColor.black, alignment: .left)
        qTitleLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: UIColor.black, alignment: .left)
    }
    
    fileprivate func setupRightTile() {
        addSubview(rightTile)
        
        rightTile.translatesAutoresizingMaskIntoConstraints = false
        rightTile.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        rightTile.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        rightTile.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rightTile.widthAnchor.constraint(equalTo: widthAnchor , multiplier: 0.5).isActive = true
        rightTile.layoutIfNeeded()
        
        previewPlayer = PreviewVC(frame: rightTile.bounds)
        if let previewPlayer = previewPlayer {
            rightTile.addSubview(previewPlayer)
        }
    }
    
    func setLabels(_ questionTitle : String?, tagTitle : String?) {
        qTitleLabel.text = questionTitle
        
        if let tagTitle = tagTitle {
            tagTitleLabel.text = "#\(tagTitle.uppercased())"
        }
    }
    
    func showQuestion(_ question : Question) {
        if let previewPlayer = previewPlayer {
            previewPlayer.currentQuestion = question
        }
    }
    
    func setTileImage(_ image : UIImage) {
        if tileBackgroundImage == nil {
            tileBackgroundImage = UIImageView()
            
            leftTile.addSubview(tileBackgroundImage!)
            
            tileBackgroundImage!.translatesAutoresizingMaskIntoConstraints = false
            tileBackgroundImage!.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            tileBackgroundImage!.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            tileBackgroundImage!.topAnchor.constraint(equalTo: topAnchor).isActive = true
            tileBackgroundImage!.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
            tileBackgroundImage!.layoutIfNeeded()
            
        }
        
        tileBackgroundImage!.image = image
        tileBackgroundImage!.contentMode = .scaleAspectFill

    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
