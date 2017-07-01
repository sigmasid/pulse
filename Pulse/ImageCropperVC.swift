//
//  ImageCropperVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/30/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ImageCropperVC: UIViewController {
    public weak var delegate : ImageTrimmerDelegate!
    public var screenTitle : String = "Edit Image"
    public var selectedImage : UIImage?
    public var captureSize : AssetSize! = .fullScreen {
        didSet {
            if imageCropperView != nil {
                imageCropperView.frame = getCropperFrame()
            }
        }
    }
    
    fileprivate var controlsView: UIView!
    fileprivate var imageCropperView : ImageCropView!
    fileprivate var chooseButton = PulseButton(size: .xSmall, type: .check, isRound: true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    fileprivate var cancelButton = PulseButton(size: .xSmall, type: .close, isRound: true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    fileprivate var titleLabel : UILabel!
    private var isLoaded = false
    
    deinit {
        delegate = nil
        selectedImage = nil
        imageCropperView = nil
    }
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            view.backgroundColor = .black
            setupLayout()
            imageCropperView.image = selectedImage
            isLoaded = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ImageCropperVC {
    fileprivate func setupLayout() {
        let buttonHeight = IconSizes.xSmall.rawValue
        
        controlsView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: IconSizes.medium.rawValue))
        imageCropperView = ImageCropView(frame: getCropperFrame())
        titleLabel = UILabel(frame: CGRect(x: Spacing.m.rawValue + buttonHeight, y: 0,
                                           width: view.bounds.width - (Spacing.m.rawValue + buttonHeight) * 2, height: controlsView.frame.height))
        cancelButton.frame = CGRect(x: Spacing.s.rawValue, y: controlsView.frame.height / 2 - buttonHeight / 2,
                                    width: buttonHeight, height: buttonHeight)
        chooseButton.frame = CGRect(x: controlsView.frame.width - buttonHeight - Spacing.s.rawValue, y: controlsView.frame.height / 2 - buttonHeight / 2,
                                    width: buttonHeight, height: buttonHeight)
        
        view.addSubview(imageCropperView)
        view.addSubview(controlsView)
        
        controlsView.backgroundColor = UIColor.white
        controlsView.addShadow()
        imageCropperView.addBorder(color: .pulseGrey, thickness: 1.0)
        
        controlsView.addSubview(cancelButton)
        controlsView.addSubview(chooseButton)
        controlsView.addSubview(titleLabel)
        
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        chooseButton.addTarget(self, action: #selector(handleSelected), for: .touchUpInside)
        
        titleLabel.setFont(FontSizes.headline.rawValue, weight: UIFontWeightHeavy, color: .black, alignment: .center)
        titleLabel.text = screenTitle
    }
    
    fileprivate func getCropperFrame() -> CGRect {
        switch captureSize! {
        case .fullScreen:
            return view.bounds
        case .square:
            let minLength = min(view.bounds.width, view.bounds.height)
            return CGRect(x: 0, y: IconSizes.medium.rawValue, width: minLength, height: minLength)
        }
    }
    
    internal func handleCancel(_ sender: UIButton) {
        delegate?.dismissedTrimmer()
    }
    
    internal func handleSelected(_ sender: UIButton) {
        guard imageCropperView != nil else { return }
        self.delegate?.capturedItem(image: imageCropperView.getCroppedImage())
    }
}
