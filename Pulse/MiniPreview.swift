//
//  MiniProfile.swift
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
    
    var delegate : ItemPreviewDelegate!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = buttonCornerRadius.radius(.regular)
        clipsToBounds = true
        
        addbackgroundImage()
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
    
    func setActionButton(disabled : Bool) {
        if disabled {
            actionButton.setDisabled()
        }
    }
    
    fileprivate func addbackgroundImage() {
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
        
        miniDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        miniDescriptionLabel.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -Spacing.xs.rawValue).isActive = true
        miniDescriptionLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        miniDescriptionLabel.widthAnchor.constraint(equalTo: longDescriptionLabel.widthAnchor).isActive = true
    }
    
    fileprivate func addActionButton() {
        addSubview(actionButton)
        
        actionButton.backgroundColor = .pulseRed
        
        actionButton.titleLabel?.setPreferredFont(UIColor.white, alignment : .center)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
        actionButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        actionButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7).isActive = true
        actionButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        actionButton.layoutIfNeeded()

        actionButton.makeRound()
        actionButton.setButtonFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: .white, alignment: .center)

        actionButton.addTarget(self, action: #selector(actionButtonClicked), for: UIControlEvents.touchDown)
    }
    
    fileprivate func addCloseButton() {
        closeButton = PulseButton(size: .small, type: .close, isRound : true, hasBackground: false)
        closeButton.addTarget(self, action: #selector(closeButtonClicked), for: UIControlEvents.touchUpInside)

        addSubview(closeButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        
        closeButton.layoutIfNeeded()
    }
    
    /* SETTER / PUBLIC FUNCTIONS */
    func closeButtonClicked() {
        delegate.userClosedPreview(self)
    }
    
    func actionButtonClicked() {
        delegate.userClickedButton()
    }
    
    func setTitleLabel(_ name : String?) {
        titleLabel.text = name?.capitalized
        titleLabel.setFont(FontSizes.title.rawValue, weight: UIFontWeightHeavy, color: .white, alignment: .left)
        titleLabel.setBlurredBackground()
    }
    
    func setMiniDescriptionLabel(_ text : String?) {
        miniDescriptionLabel.text = text
        miniDescriptionLabel.numberOfLines = 0
        miniDescriptionLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightHeavy, color: .white, alignment: .center)
        miniDescriptionLabel.setBlurredBackground()
    }
    
    func setLongDescriptionLabel(_ text : String?) {
        //longDescriptionLabel.text = text
        longDescriptionLabel.numberOfLines = 0
        
        longDescriptionLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightHeavy, color: .white, alignment: .center)
        longDescriptionLabel.setBlurredBackground()
    }
    
    func setBackgroundImage(_ image : UIImage) {
        guard let cgimg = image.cgImage else {
            return
        }
        
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
        
        backgroundImage.clipsToBounds = true
    }

}
