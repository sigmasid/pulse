//
//  RecordedAnswerOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/6/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class RecordedAnswerOverlay: UIView {
    private var _saveToDiskButton = UIButton()
    private var _addMoreButton = UIButton()
    private var _postButton = UIButton()
    private var _closeButton = UIButton()
    private var _savingLabel = UILabel()
    private var _progressBar = UIProgressView()
   
    private var _iconSize : CGFloat = IconSizes.XSmall.rawValue
    
    var tap : UITapGestureRecognizer!
    
    internal enum ControlButtons: Int {
        case Save, Post, Close, AddMore
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        addFooterButtons()
        addCloseButton()
        addSaveButton()
    }
    
    func gestureRecognizer(gesture: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer : UIGestureRecognizer) -> Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func pointInside(point : CGPoint, withEvent event : UIEvent?) -> Bool {
        for _view in self.subviews {
            if (_view.userInteractionEnabled == true && _view.pointInside(self.convertPoint(point, toView: _view) , withEvent: event)) {
                return true
            }
        }
        return false
    }
    
    func getButton(buttonName : ControlButtons) -> UIButton {
        switch buttonName {
        case .Save: return _saveToDiskButton
        case .Post: return _postButton
        case .Close: return _closeButton
        case .AddMore: return _addMoreButton
        }
    }
    
    private func addFooterButtons() {
        addSubview(_postButton)
        addSubview(_addMoreButton)

        _postButton.backgroundColor = UIColor( red: 35/255, green: 31/255, blue:32/255, alpha: 1.0 )
        _postButton.setTitle("DONE", forState: UIControlState.Normal)
        _postButton.titleLabel!.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        _postButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        _postButton.setImage(UIImage(named: "check"), forState: .Normal)
        _postButton.imageEdgeInsets = UIEdgeInsetsMake(10, -10, 10, 10)
        _postButton.imageView?.contentMode = .ScaleAspectFit

        _addMoreButton.backgroundColor = UIColor( red: 35/255, green: 31/255, blue:32/255, alpha: 1.0 )
        _addMoreButton.setTitle("ADD MORE", forState: UIControlState.Normal)
        _addMoreButton.titleLabel!.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        _addMoreButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        _addMoreButton.setImage(UIImage(named: "add"), forState: .Normal)
        _addMoreButton.imageEdgeInsets = UIEdgeInsetsMake(10, -10, 10, 10)
        _addMoreButton.imageView?.contentMode = .ScaleAspectFit

        _postButton.translatesAutoresizingMaskIntoConstraints = false
        _postButton.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        _postButton.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: 0.5).active = true
        _postButton.trailingAnchor.constraintEqualToAnchor(trailingAnchor).active = true
        _postButton.heightAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
        
        _addMoreButton.translatesAutoresizingMaskIntoConstraints = false
        _addMoreButton.bottomAnchor.constraintEqualToAnchor(_postButton.bottomAnchor).active = true
        _addMoreButton.widthAnchor.constraintEqualToAnchor(_postButton.widthAnchor).active = true
        _addMoreButton.leadingAnchor.constraintEqualToAnchor(leadingAnchor).active = true
        _addMoreButton.heightAnchor.constraintEqualToAnchor(_postButton.heightAnchor).active = true
    }
    
    private func addSaveButton() {
        if let saveToDiskImage = UIImage(named: "download-to-disk") {
            _saveToDiskButton.setImage(saveToDiskImage, forState: UIControlState.Normal)
        }
        addSubview(_saveToDiskButton)
        
        _saveToDiskButton.translatesAutoresizingMaskIntoConstraints = false
        
        _saveToDiskButton.topAnchor.constraintEqualToAnchor(_closeButton.topAnchor).active = true
        _saveToDiskButton.leadingAnchor.constraintEqualToAnchor(_closeButton.trailingAnchor, constant: Spacing.s.rawValue).active = true
        _saveToDiskButton.widthAnchor.constraintEqualToConstant(_iconSize).active = true
        _saveToDiskButton.heightAnchor.constraintEqualToConstant(_iconSize).active = true
    }
    
    private func addCloseButton() {
        if let closeButtonImage = UIImage(named: "close") {
            _closeButton.setImage(closeButtonImage, forState: UIControlState.Normal)
        } else {
            _closeButton.titleLabel?.text = "Close"
        }
        addSubview(_closeButton)
        
        _closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        _closeButton.topAnchor.constraintEqualToAnchor(topAnchor, constant: Spacing.s.rawValue + IconSizes.XSmall.rawValue).active = true
        _closeButton.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: Spacing.s.rawValue).active = true
        _closeButton.widthAnchor.constraintEqualToConstant(_iconSize).active = true
        _closeButton.heightAnchor.constraintEqualToConstant(_iconSize).active = true
    }
    
    func addSavingLabel(label : String) {
        _savingLabel.hidden = false
        _savingLabel.text = label
        _savingLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        _savingLabel.textAlignment = .Center
        _savingLabel.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        _savingLabel.textColor = UIColor.whiteColor()
        addSubview(_savingLabel)
        
        _savingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        _savingLabel.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        _savingLabel.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        _savingLabel.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: 0.7).active = true
        _savingLabel.heightAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
    }
    
    func addAnswerPagers(count : Int) {
        let _pulseDot = UIView()
        addSubview(_pulseDot)
        
        _pulseDot.translatesAutoresizingMaskIntoConstraints = false
        _pulseDot.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -(CGFloat(count) * Spacing.m.rawValue) ).active = true
        _pulseDot.topAnchor.constraintEqualToAnchor(topAnchor, constant: Spacing.s.rawValue + IconSizes.XSmall.rawValue).active = true
        _pulseDot.widthAnchor.constraintEqualToConstant(IconSizes.XXSmall.rawValue).active = true
        _pulseDot.heightAnchor.constraintEqualToAnchor(_pulseDot.widthAnchor).active = true
    
        _pulseDot.layoutIfNeeded()
        _pulseDot.layer.cornerRadius = _pulseDot.frame.width / 2
        _pulseDot.backgroundColor = UIColor.whiteColor()
    }
    
    func hideSavingLabel(label : String) {
        _savingLabel.text = label
        
        let delay = 1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self._savingLabel.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = false
            self._savingLabel.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor).active = false
            self._savingLabel.heightAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = false
            self._savingLabel.widthAnchor.constraintEqualToAnchor(self.widthAnchor, multiplier: 0.7).active = false
            super.updateConstraints()

            self._savingLabel.hidden = true
        }
        
        UIView.animateWithDuration(1) { () -> Void in
            self.layoutIfNeeded()
        }
    }
    
    func addAnswerMakers(num : Int) {
        
    }
    
    func addUploadProgressBar() {
        _progressBar.progressTintColor = UIColor.whiteColor()
        _progressBar.trackTintColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        _progressBar.progressViewStyle = .Bar
        
        self.addSubview(_progressBar)
        
        _progressBar.translatesAutoresizingMaskIntoConstraints = false

        _progressBar.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        _progressBar.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        _progressBar.heightAnchor.constraintEqualToConstant(IconSizes.XSmall.rawValue).active = true
        _progressBar.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
    }
    
    func updateProgressBar(percentComplete : Float) {
        _progressBar.setProgress(percentComplete, animated: true)
    }
}
