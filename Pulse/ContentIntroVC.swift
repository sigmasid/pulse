//
//  QuestionPreviewOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/2/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

class ContentIntroVC: UIViewController {
    
    fileprivate let subtitleLabel = UILabel()
    fileprivate let titleLabel = UILabel()
    
    fileprivate var userNameLabel = UILabel()
    fileprivate var userStack = PulseMenu(_axis: .vertical, _spacing: 0)
    fileprivate var userBioLabel = UILabel()
    fileprivate var userImage = UIImageView()
    
    fileprivate var seriesTitle = UILabel()
    fileprivate var seriesImage = UIImageView()
    
    fileprivate var loadingButton = UIButton()
    fileprivate var cleanupComplete = false
    
    public var item : Item! {
        didSet {
            if item != nil {
                titleLabel.text = item.itemTitle.uppercased()
                subtitleLabel.text = item.type.rawValue
                
                if let image = item.tag?.content {
                    seriesTitle.text = item.tag?.itemTitle
                    seriesImage.image = image
                    seriesTitle.setBlurredBackground()
                } else if item.tag == nil, let image = item.content {
                    seriesImage.image = image
                } else {
                    seriesTitle.text = item.tag?.itemTitle
                    seriesTitle.removeShadow()                    
                }
                
                guard let user = item.user else { return }
                
                userNameLabel.text = user.name
                userBioLabel.text = user.shortBio
                
                PulseDatabase.getCachedUserPic(uid: user.uID!, completion: {[weak self] image in
                    guard let `self` = self else { return }
                    DispatchQueue.main.async {
                        self.userImage.image = image
                    }
                })
            }
        }
    }
    
    deinit {
        performCleanup()
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            item = nil
            userImage.image = nil
            seriesImage.image = nil
            cleanupComplete = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white

        addUserData()
        addTitleLabel()
        addSeriesCover()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        userImage.image = nil
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    fileprivate func addUserData() {
        view.addSubview(userImage)
        view.addSubview(userStack)

        userStack.addArrangedSubview(userNameLabel)
        userStack.addArrangedSubview(userBioLabel)

        userImage.frame = CGRect(x: Spacing.m.rawValue, y: Spacing.m.rawValue, width: IconSizes.medium.rawValue, height: IconSizes.medium.rawValue)
        userImage.layer.cornerRadius = userImage.frame.width / 2
        userImage.contentMode = .scaleAspectFill
        userImage.clipsToBounds = true
        
        userStack.translatesAutoresizingMaskIntoConstraints = false
        userStack.leadingAnchor.constraint(equalTo: userImage.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
        userStack.centerYAnchor.constraint(equalTo: userImage.centerYAnchor).isActive = true
        
        userNameLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: .black, alignment: .left)
        userBioLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightRegular, color: .lightGray, alignment: .left)
        userStack.distribution = .equalCentering
        userStack.alignment = .leading
    }
    
    fileprivate func addTitleLabel() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)

        titleLabel.backgroundColor = UIColor.clear
        titleLabel.setFont(FontSizes.headline2.rawValue, weight: UIFontWeightBlack, color: .black, alignment: .left)
        
        titleLabel.numberOfLines = 3
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.lineBreakMode = .byTruncatingTail
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.m.rawValue).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.m.rawValue).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.setFont(FontSizes.headline.rawValue, weight: UIFontWeightBlack, color: .lightGray, alignment: .left)

        subtitleLabel.numberOfLines = 1
        subtitleLabel.lineBreakMode = .byTruncatingTail
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor).isActive = true
        subtitleLabel.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -Spacing.s.rawValue).isActive = true
    }
    
    fileprivate func addSeriesCover() {
        view.addSubview(seriesImage)
        view.addSubview(seriesTitle)
        view.addSubview(loadingButton)

        seriesImage.translatesAutoresizingMaskIntoConstraints = false
        seriesImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        seriesImage.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        seriesImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        seriesImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        seriesImage.backgroundColor = .black
        seriesImage.contentMode = .scaleAspectFill
        seriesImage.clipsToBounds = true
        
        seriesTitle.translatesAutoresizingMaskIntoConstraints = false
        seriesTitle.centerYAnchor.constraint(equalTo: seriesImage.centerYAnchor).isActive = true
        seriesTitle.leadingAnchor.constraint(equalTo: seriesImage.leadingAnchor, constant: Spacing.m.rawValue).isActive = true
        seriesTitle.trailingAnchor.constraint(equalTo: seriesImage.trailingAnchor, constant: -Spacing.m.rawValue - IconSizes.large.rawValue).isActive = true
        
        loadingButton.translatesAutoresizingMaskIntoConstraints = false
        loadingButton.centerYAnchor.constraint(equalTo: seriesImage.centerYAnchor).isActive = true
        loadingButton.leadingAnchor.constraint(equalTo: seriesTitle.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
        loadingButton.trailingAnchor.constraint(equalTo: seriesImage.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        loadingButton.heightAnchor.constraint(equalTo: seriesImage.heightAnchor).isActive = true
        loadingButton.layoutIfNeeded()
        
        let _ = loadingButton.addLoadingIndicator()
        
        seriesTitle.backgroundColor = .clear
        seriesTitle.setFont(FontSizes.headline.rawValue, weight: UIFontWeightBlack, color: .white, alignment: .left)
    }
}
