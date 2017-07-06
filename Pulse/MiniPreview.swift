//
//  MiniPreview.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/5/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class MiniPreview: UIView {

    fileprivate var backgroundImage : UIImageView!
    fileprivate lazy var titleLabel : PaddingLabel = PaddingLabel()
    fileprivate var miniDescriptionLabel : UILabel!
    fileprivate var longDescriptionLabel : UILabel!
    fileprivate lazy var actionButton : PulseButton = PulseButton(title: "View Profile", isRound: true)
    fileprivate var closeButton : PulseButton!
    fileprivate lazy var previewIcon : UIImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = buttonCornerRadius.radius(.regular)
        clipsToBounds = true
        
        addBackgroundImage()
        addActionButton()
        addLabels()
        addCloseButton()
    }
    
    convenience init(frame: CGRect, buttonTitle: String) {
        self.init(frame: frame)
        actionButton.setTitle(buttonTitle, for: .normal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func point(inside point : CGPoint, with event : UIEvent?) -> Bool {
        for _view in self.subviews {
            if _view.isUserInteractionEnabled == true && _view.point(inside: convert(point, to: _view) , with: event) {
                return true
            }
        }
        return false
    }
    
    func gestureRecognizer(_ gesture: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer : UIGestureRecognizer) -> Bool {
        return false
    }
    
    fileprivate func addBackgroundImage() {
        backgroundImage = UIImageView(frame: bounds)
        addSubview(backgroundImage)
        
        backgroundImage.contentMode = UIViewContentMode.scaleAspectFill
    }
    
    fileprivate func addLabels() {
        addSubview(titleLabel)
        
        miniDescriptionLabel = UILabel()
        addSubview(miniDescriptionLabel)
        
        longDescriptionLabel = UILabel()
        addSubview(longDescriptionLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s.rawValue).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        
        longDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        longDescriptionLabel.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -Spacing.s.rawValue).isActive = true
        longDescriptionLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        longDescriptionLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8).isActive = true
        longDescriptionLabel.heightAnchor.constraint(equalToConstant: 70).isActive = true
        longDescriptionLabel.layoutIfNeeded()
        
        miniDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        miniDescriptionLabel.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -Spacing.xs.rawValue).isActive = true
        miniDescriptionLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        miniDescriptionLabel.widthAnchor.constraint(equalTo: longDescriptionLabel.widthAnchor).isActive = true
        
        longDescriptionLabel.numberOfLines = 3
        longDescriptionLabel.lineBreakMode = .byTruncatingTail
        
        miniDescriptionLabel.numberOfLines = 2
        miniDescriptionLabel.lineBreakMode = .byTruncatingTail
    }
    
    fileprivate func addActionButton() {
        addSubview(actionButton)
        
        actionButton.backgroundColor = .pulseRed
        
        actionButton.titleLabel?.setPreferredFont(UIColor.white, alignment : .center)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
        actionButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        actionButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8).isActive = true
        actionButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        actionButton.layoutIfNeeded()

        actionButton.makeRound()
        actionButton.setButtonFont(FontSizes.body2.rawValue, weight: UIFontWeightRegular, color: .white, alignment: .center)

        actionButton.addTarget(self, action: #selector(actionButtonClicked), for: UIControlEvents.touchDown)
    }
    
    fileprivate func addCloseButton() {
        closeButton = PulseButton(size: .xSmall, type: .close, isRound : true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
        closeButton.addTarget(self, action: #selector(closeButtonClicked), for: UIControlEvents.touchUpInside)

        addSubview(closeButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        
        closeButton.layoutIfNeeded()
    }
    
    fileprivate func setupPreviewIcon() {
        insertSubview(previewIcon, aboveSubview: backgroundImage)
        
        previewIcon.translatesAutoresizingMaskIntoConstraints = false
        previewIcon.topAnchor.constraint(equalTo: topAnchor).isActive = true
        previewIcon.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        previewIcon.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        previewIcon.bottomAnchor.constraint(equalTo: longDescriptionLabel.topAnchor, constant: -Spacing.s.rawValue).isActive = true
        
        previewIcon.layoutIfNeeded()
    }
    
    /* SETTER / PUBLIC FUNCTIONS */
    public func closeButtonClicked() {
        //delegate.userClosedPreview(self)
    }
    
    public func actionButtonClicked() {
        //delegate.userClickedButton()
    }
    
    
    public func setActionButton(disabled : Bool) {
        if disabled {
            actionButton.setDisabled()
        }
    }
    
    public func setTitleLabel(_ name : String?, textColor : UIColor = .white, blurText : Bool = true) {
        titleLabel.text = name?.capitalized
        titleLabel.setFont(FontSizes.title.rawValue, weight: UIFontWeightHeavy, color: textColor, alignment: .left)
        
        if textColor != .black, blurText {
            titleLabel.setBlurredBackground()
        }
    }
    
    public func setMiniDescriptionLabel(_ text : String?, textColor : UIColor = .white, blurText : Bool = true) {
        miniDescriptionLabel.text = text
        miniDescriptionLabel.numberOfLines = 0
        miniDescriptionLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightHeavy, color: textColor, alignment: .center)
        
        if textColor != .black, blurText {
            miniDescriptionLabel.setBlurredBackground()
        }
    }
    
    public func setLongDescriptionLabel(_ text : String?, textColor : UIColor = .white, blurText : Bool = true) {
        longDescriptionLabel.text = text
        longDescriptionLabel.numberOfLines = 0
        
        longDescriptionLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightRegular, color: textColor, alignment: .center)
        
        if textColor != .black, blurText {
            longDescriptionLabel.setBlurredBackground()
        }
    }
    
    public func setBackgroundImage(_ image : UIImage, shouldFilter: Bool = true) {
        guard let cgimg = image.cgImage else {
            return
        }
        
        if shouldFilter {
            let openGLContext = EAGLContext(api: .openGLES2)
            let context = CIContext(eaglContext: openGLContext!)
            
            let coreImage = CIImage(cgImage: cgimg)
            
            let filter = CIFilter(name: "CIPhotoEffectTransfer")
            filter?.setValue(coreImage, forKey: kCIInputImageKey)
            
            if let output = filter?.value(forKey: kCIOutputImageKey) as? CIImage {
                let cgimgresult = context.createCGImage(output, from: output.extent)
                let result = UIImage(cgImage: cgimgresult!)
                backgroundImage?.image = result
            } else {
                backgroundImage.image = image
            }
        } else {
            backgroundImage.image = image
        }
        backgroundImage.clipsToBounds = true
    }
    
    public func setIcon(image: UIImage, tintColor: UIColor, backgroundColor: UIColor) {
        setupPreviewIcon()
        previewIcon.backgroundColor = backgroundColor
        previewIcon.image = image
        previewIcon.tintColor = tintColor
        previewIcon.contentMode = .center
    }

}
