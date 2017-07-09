//
//  TextInputVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/6/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class TextInputVC: PulseVC, RecordedTextViewDelegate {
    
    public weak var delegate: InputItemDelegate?
    
    private var textBox : RecordedTextView!
    private var controlsView : UIView!
    private var titleLabel : UILabel!
    
    private var cancelButton = PulseButton(size: .xSmall, type: .close, isRound: true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    private var chooseButton = PulseButton(size: .xSmall, type: .check, isRound: true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    private var cameraButton = PulseButton(size: .xSmall, type: .camera, isRound: true, background: UIColor.white.withAlphaComponent(0.3), tint: .black)
    
    fileprivate var placeholderText = "What's Happening?"
    fileprivate var remainingChars = UILabel()
    fileprivate var cleanupComplete = false
    private var maxLength: Int = 140
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            setupLayout()
            hideKeyboardWhenTappedAround()
            isLoaded = true
        }
        // Do any additional setup after loading the view.
    }
    
    deinit {
        performCleanup()
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            delegate = nil
            textBox = nil
            controlsView = nil
            cleanupComplete = true
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if textBox != nil {
            textBox.makeFirstResponder()
        }
    }
    
    private func setupLayout() {
        let buttonHeight = IconSizes.xSmall.rawValue
        let headerHeight = IconSizes.medium.rawValue * 1.2
        
        controlsView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: headerHeight))
            
        titleLabel = UILabel(frame: CGRect(x: Spacing.m.rawValue + buttonHeight, y: 0,
                                           width: view.bounds.width - (Spacing.m.rawValue + buttonHeight) * 2, height: headerHeight))
        
        chooseButton.frame = CGRect(x: controlsView.frame.width - buttonHeight - Spacing.s.rawValue,
                                    y: headerHeight / 2 - buttonHeight / 2, width: buttonHeight, height: buttonHeight)
        cancelButton.frame = CGRect(x: controlsView.frame.width - buttonHeight - Spacing.s.rawValue - Spacing.s.rawValue - buttonHeight,
                                    y: headerHeight / 2 - buttonHeight / 2, width: buttonHeight, height: buttonHeight)
        cameraButton.frame = CGRect(x: Spacing.s.rawValue, y: headerHeight / 2 - buttonHeight / 2, width: buttonHeight, height: buttonHeight)
        
        view.addSubview(controlsView)
        controlsView.backgroundColor = UIColor.white
        controlsView.addShadow()
        
        controlsView.addSubview(cancelButton)
        controlsView.addSubview(chooseButton)
        controlsView.addSubview(cameraButton)
        controlsView.addSubview(titleLabel)
        
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(handleSwitchInput), for: .touchUpInside)
        chooseButton.addTarget(self, action: #selector(handleChoose), for: .touchUpInside)
        //add choosebutton target
        
        titleLabel.setFont(FontSizes.headline.rawValue, weight: UIFontWeightHeavy, color: .black, alignment: .center)
        titleLabel.text = "Postcard"
        
        /** add textbox **/
        textBox = RecordedTextView(frame: CGRect(x: 0, y: headerHeight,
                                                 width: view.bounds.width, height: view.bounds.height - headerHeight), text: placeholderText)
        textBox.charsRemainingDelegate = self
        textBox.maxLength = maxLength
        view.addSubview(textBox)
        
        /** addRemainingChars message **/
        view.addSubview(remainingChars)
        remainingChars.translatesAutoresizingMaskIntoConstraints = false
        remainingChars.topAnchor.constraint(equalTo: controlsView.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        remainingChars.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        remainingChars.setFont(FontSizes.caption.rawValue, weight: UIFontWeightThin, color: UIColor.placeholderGrey, alignment: .right)
        charsRemaining(count: maxLength)
    }
    
    internal func charsRemaining(count: Int) {
        remainingChars.text = "\(count) chars remaining"
    }
    
    internal func handleCancel(_ sender: UIButton) {
        delegate?.dismissInput()
    }
    
    internal func handleSwitchInput(_ sender: UIButton) {
        delegate?.switchInput(to: .camera, from: .text)
    }
    
    internal func handleChoose(_ sender: UIButton) {
        guard textBox.finalText != "" else {
            GlobalFunctions.showAlertBlock(viewController: self, erTitle: "Your Postcard is Empty!", erMessage: "Add some text before proceeding")
            return
        }
        
        delegate?.capturedItem(item: textBox.finalText, location: nil, assetType: .postcard)
        textBox.textToShow = ""
    }
}

