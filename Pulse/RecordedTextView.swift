//
//  RecordedTextView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/7/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class RecordedTextView: UIView {
    
    public var placeholderText : String! = "What's Happening?"
    public var maxLength: Int = 140
    public var charsRemainingDelegate : RecordedTextViewDelegate!
    
    public var textToShow : String! {
        didSet {
            textBox.text = textToShow
            textBox.textColor = UIColor.black
        }
    }
    public var finalText : String! {
        get {
            return textBox.text != placeholderText ? textBox.text : ""
        }
    }
    
    public var isEditable: Bool = true {
        didSet {
            textBox.isEditable = isEditable
            if !isEditable {
                removeObservers()
                if textBoxTopAnchor != nil {
                    textBoxTopAnchor.isActive = false
                }
                if textBoxCenterYAnchor != nil {
                    textBoxCenterYAnchor.isActive = true
                }
            }
        }
    }
    public var isPreview: Bool = false {
        didSet {
            if isPreview {
                textBox.setFont(FontSizes.caption.rawValue, weight: UIFontWeightBold, color: .black, alignment: .center)
                
                openDynamicBottomConstraint.isActive = false
                closeDyanmicBottomConstraint.isActive = false
                
                openStaticBottomConstraint.isActive = true
                closeStaticBottomConstraint.isActive = true
            }
        }
    }
    
    public var reduceQuoteSize : Bool = false {
        didSet {
            if reduceQuoteSize {
                quotesHeightAnchor.constant = IconSizes.small.rawValue
                textBoxWidthConstraint.constant = 0
            }
        }
    }
    
    private var textBox : UITextView = UITextView()
    fileprivate var openQuote = UIImageView(image: UIImage(named: "quote-open"))
    fileprivate var closeQuote = UIImageView(image: UIImage(named: "quote-close"))
    
    private var observersAdded = false
    
    private var textBoxCenterYAnchor : NSLayoutConstraint!
    private var textBoxTopAnchor : NSLayoutConstraint!
    private var textBoxWidthConstraint : NSLayoutConstraint!
    
    private var openDynamicBottomConstraint : NSLayoutConstraint!
    private var openStaticBottomConstraint : NSLayoutConstraint!
    
    private var closeDyanmicBottomConstraint : NSLayoutConstraint!
    private var closeStaticBottomConstraint : NSLayoutConstraint!
    private var quotesHeightAnchor : NSLayoutConstraint!
    
    override func point(inside point : CGPoint, with event : UIEvent?) -> Bool {
        for _view in subviews {
            
            if _view.isUserInteractionEnabled == true && _view.point(inside: convert(point, to: _view) , with: event) {
                return isEditable
            }
        }
        return false
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        self.clipsToBounds   = true
        setupLayout()
        hideKeyboardWhenTappedAroundView()
        addObservers()
    }
    
    convenience init(frame: CGRect, text: String) {
        self.init(frame: frame)
        textToShow = text
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    private func removeObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        observersAdded = false
    }
    
    private func addObservers() {
        if !observersAdded {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
            observersAdded = true
        }
    }
        
    func keyboardWillShow(notification: NSNotification) {
        self.textBoxCenterYAnchor.isActive = false
        self.textBoxTopAnchor.isActive = true
        
        UIView.animate(withDuration: 1.0) {
            self.layoutIfNeeded()
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.textBoxCenterYAnchor.isActive = true
        self.textBoxTopAnchor.isActive = false
        
        UIView.animate(withDuration: 1.0) {
            self.layoutIfNeeded()
        }
    }
    
    public func makeFirstResponder() {
        DispatchQueue.main.async {[weak self] in
            guard let `self` = self else { return }
            self.textBox.becomeFirstResponder()
        }
    }
    
    private func setupLayout() {
        /** add textbox **/
        addSubview(textBox)
        textBox.translatesAutoresizingMaskIntoConstraints = false
        
        textBoxCenterYAnchor = textBox.centerYAnchor.constraint(equalTo: centerYAnchor)
        textBoxCenterYAnchor.isActive = false
        
        textBoxTopAnchor = textBox.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.max.rawValue)
        textBoxTopAnchor.isActive = true
        
        textBox.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        textBoxWidthConstraint = textBox.widthAnchor.constraint(equalTo: widthAnchor, constant: -bounds.width * 0.1)
        textBoxWidthConstraint.isActive = true
        textBox.layoutIfNeeded()
        
        textBox.setFont(FontSizes.headline2.rawValue, weight: UIFontWeightBold, color: UIColor.placeholderGrey, alignment: .center)
        textBox.backgroundColor = .white
        textBox.isScrollEnabled = false
        textBox.autocapitalizationType = .sentences
        textBox.text = placeholderText
        textBox.delegate = self
        /** addRemainingChars message **/
        
        /** setup quotes **/
        addSubview(openQuote)
        openQuote.translatesAutoresizingMaskIntoConstraints = false
        openDynamicBottomConstraint = openQuote.bottomAnchor.constraint(equalTo: textBox.topAnchor, constant: -Spacing.s.rawValue)
        openDynamicBottomConstraint.isActive = true
        openStaticBottomConstraint = openQuote.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xxs.rawValue)
        openStaticBottomConstraint.isActive = false
        openQuote.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.xxs.rawValue).isActive = true
        
        quotesHeightAnchor = openQuote.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue)
        quotesHeightAnchor.isActive = true
        openQuote.widthAnchor.constraint(equalTo: openQuote.heightAnchor).isActive = true
        openQuote.layoutIfNeeded()
        
        addSubview(closeQuote)
        closeQuote.translatesAutoresizingMaskIntoConstraints = false
        closeDyanmicBottomConstraint = closeQuote.topAnchor.constraint(equalTo: textBox.bottomAnchor, constant: Spacing.s.rawValue)
        closeDyanmicBottomConstraint.isActive = true
        closeStaticBottomConstraint = closeQuote.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.xxs.rawValue)
        closeStaticBottomConstraint.isActive = false
        
        closeQuote.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        closeQuote.heightAnchor.constraint(equalTo: openQuote.heightAnchor).isActive = true
        closeQuote.widthAnchor.constraint(equalTo: openQuote.heightAnchor).isActive = true
        closeQuote.layoutIfNeeded()
        
        openQuote.contentMode = .scaleAspectFit
        closeQuote.contentMode = .scaleAspectFit
    }
}

extension RecordedTextView: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = placeholderText
            textView.textColor = UIColor.placeholderGrey
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            let currentHeight = textView.frame.height
            let sizeThatFitsTextView = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
            
            if currentHeight < sizeThatFitsTextView.height {
                //if new height is bigger, move the text view up and increase height
                textView.textContainer.size = CGSize(width: textView.frame.width, height: textView.frame.height + (sizeThatFitsTextView.height - currentHeight))
                textView.frame = CGRect(x: textView.frame.origin.x, y: textView.frame.origin.y,
                                        width: textView.frame.width, height: textView.frame.height + (sizeThatFitsTextView.height - currentHeight))
                closeQuote.layoutIfNeeded()
            }
            
            let remainingCount = maxLength - textView.text.characters.count
            charsRemainingDelegate?.charsRemaining(count: remainingCount)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.text == placeholderText {
            textView.text = ""
            textView.textColor = UIColor.black
        }
        
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        return textView.text.characters.count + (text.characters.count - range.length) <= maxLength
    }
}
