//
//  RecordedAnswerOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/6/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class RecordedAnswerOverlay: UIView {
    fileprivate var _saveToDiskButton = UIButton()
    fileprivate var _addMoreButton = UIButton()
    fileprivate var _postButton = UIButton()
    fileprivate var _closeButton = UIButton()
    fileprivate var _savingLabel = UILabel()
    fileprivate var _progressBar = UIProgressView()
    
    fileprivate var _pagers = [UIView]()
    fileprivate lazy var _answerPagers = UIStackView()
    fileprivate var _iconSize : CGFloat = IconSizes.xSmall.rawValue
    
    var tap : UITapGestureRecognizer!
    
    internal enum ControlButtons: Int {
        case save, post, close, addMore
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        addFooterButtons()
        addCloseButton()
        addSaveButton()
        setupAnswerPagers()
    }
    
    func gestureRecognizer(_ gesture: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer : UIGestureRecognizer) -> Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func point(inside point : CGPoint, with event : UIEvent?) -> Bool {
        for _view in self.subviews {
            if (_view.isUserInteractionEnabled == true && _view.point(inside: self.convert(point, to: _view) , with: event)) {
                return true
            }
        }
        return false
    }
    
    func getButton(_ buttonName : ControlButtons) -> UIButton {
        switch buttonName {
        case .save: return _saveToDiskButton
        case .post: return _postButton
        case .close: return _closeButton
        case .addMore: return _addMoreButton
        }
    }
    
    fileprivate func addFooterButtons() {
        addSubview(_postButton)
        addSubview(_addMoreButton)

        _postButton.backgroundColor = UIColor( red: 35/255, green: 31/255, blue:32/255, alpha: 1.0 )
        _postButton.setTitle("Post", for: UIControlState())
        _postButton.titleLabel!.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightRegular)
        _postButton.setTitleColor(UIColor.white, for: UIControlState())
        _postButton.setImage(UIImage(named: "check"), for: UIControlState())
        _postButton.imageView?.contentMode = .scaleAspectFit

        _addMoreButton.backgroundColor = UIColor( red: 35/255, green: 31/255, blue:32/255, alpha: 1.0 )
        _addMoreButton.setTitle("Add More", for: UIControlState())
        _addMoreButton.titleLabel!.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightRegular)
        _addMoreButton.setTitleColor(UIColor.white, for: UIControlState())
        _addMoreButton.setImage(UIImage(named: "add"), for: UIControlState())
        _addMoreButton.imageView?.contentMode = .scaleAspectFit

        _postButton.translatesAutoresizingMaskIntoConstraints = false
        _postButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        _postButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5).isActive = true
        _postButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        _postButton.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue * 0.9).isActive = true
        _postButton.layoutIfNeeded()
        _postButton.imageEdgeInsets = UIEdgeInsetsMake(15, -7.5, 15, 15)
        
        _addMoreButton.translatesAutoresizingMaskIntoConstraints = false
        _addMoreButton.bottomAnchor.constraint(equalTo: _postButton.bottomAnchor).isActive = true
        _addMoreButton.widthAnchor.constraint(equalTo: _postButton.widthAnchor).isActive = true
        _addMoreButton.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        _addMoreButton.heightAnchor.constraint(equalTo: _postButton.heightAnchor).isActive = true
        _addMoreButton.layoutIfNeeded()
        _addMoreButton.imageEdgeInsets = UIEdgeInsetsMake(16, -8, 16, 16)

    }
    
    fileprivate func addSaveButton() {
        _saveToDiskButton = NavVC.getButton(type: .save)

        addSubview(_saveToDiskButton)
        _saveToDiskButton.translatesAutoresizingMaskIntoConstraints = false
        _saveToDiskButton.topAnchor.constraint(equalTo: _closeButton.topAnchor).isActive = true
        _saveToDiskButton.leadingAnchor.constraint(equalTo: _closeButton.trailingAnchor, constant: Spacing.m.rawValue).isActive = true
    }
    
    fileprivate func addCloseButton() {
        _closeButton = NavVC.getButton(type: .close)
        
        addSubview(_closeButton)
        
        _closeButton.translatesAutoresizingMaskIntoConstraints = false
        _closeButton.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s.rawValue + statusBarHeight).isActive = true
        _closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.m.rawValue).isActive = true
    }
    
    func addSavingLabel(_ label : String) {
        _savingLabel.isHidden = false
        _savingLabel.text = label
        _savingLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        _savingLabel.textAlignment = .center
        _savingLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        _savingLabel.textColor = UIColor.white
        addSubview(_savingLabel)
        
        _savingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        _savingLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        _savingLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        _savingLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7).isActive = true
        _savingLabel.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
    }
    
    func setupAnswerPagers() {
        addSubview(_answerPagers)
        
        _answerPagers.translatesAutoresizingMaskIntoConstraints = false
        _answerPagers.widthAnchor.constraint(equalToConstant: Spacing.xs.rawValue).isActive = true
        _answerPagers.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s.rawValue + statusBarHeight).isActive = true
        _answerPagers.trailingAnchor.constraint(equalTo: trailingAnchor, constant : -Spacing.s.rawValue).isActive = true
        
        _answerPagers.axis = .vertical
        _answerPagers.distribution = .fillEqually
        _answerPagers.spacing = Spacing.s.rawValue
    }

    
    func addAnswerPagers() {
        let _pager = UIView()
        _pager.translatesAutoresizingMaskIntoConstraints = false
        _pager.heightAnchor.constraint(equalTo: _pager.widthAnchor).isActive = true
        _pager.backgroundColor = pulseBlue
        
        if _answerPagers.arrangedSubviews.last != nil {
            _answerPagers.arrangedSubviews.last!.backgroundColor = .white
        }
        
        _answerPagers.addArrangedSubview(_pager)
        
        _pager.layoutIfNeeded()
        _pager.layer.cornerRadius = _pager.frame.width / 2
        _pager.layer.masksToBounds = true
    }
    
    func removeAnswerPager() {
        if _answerPagers.arrangedSubviews.last != nil {
            let lastView = _answerPagers.arrangedSubviews.last!
            _answerPagers.removeArrangedSubview(lastView)
            lastView.removeFromSuperview()
        }
        
        if _answerPagers.arrangedSubviews.last != nil {
            _answerPagers.arrangedSubviews.last!.backgroundColor = pulseBlue
        }
    }
    
    func hideSavingLabel(_ label : String) {
        _savingLabel.text = label
        
        let delay = 1 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            self._savingLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = false
            self._savingLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = false
            self._savingLabel.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = false
            self._savingLabel.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.7).isActive = false
            super.updateConstraints()

            self._savingLabel.isHidden = true
        }
        
        UIView.animate(withDuration: 1, animations: { () -> Void in
            self.layoutIfNeeded()
        }) 
    }
    
    func addUploadProgressBar() {
        _progressBar.progressTintColor = UIColor.white
        _progressBar.trackTintColor = UIColor.black.withAlphaComponent(0.7)
        _progressBar.progressViewStyle = .bar
        
        self.addSubview(_progressBar)
        
        _progressBar.translatesAutoresizingMaskIntoConstraints = false

        _progressBar.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        _progressBar.topAnchor.constraint(equalTo: topAnchor).isActive = true
        _progressBar.heightAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        _progressBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    func updateProgressBar(_ percentComplete : Float) {
        _progressBar.setProgress(percentComplete, animated: true)
    }
}
