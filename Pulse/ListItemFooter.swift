//
//  ListItemFooter.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/21/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ListItemFooter: UITableViewHeaderFooterView, UITextViewDelegate {
    
    public var listDelegate : ListDelegate?
    
    private var titleLabel = UILabel()
    private var subtitleLabel = UILabel()
    private var imageView = UIImageView()
    private var addButton = PulseButton(size: .xSmall, type: .addCircle, isRound: true, hasBackground: false, tint: .black)

    private lazy var txtContainer = UIView()
    private lazy var txtBody : PaddingTextView! = PaddingTextView()
    private lazy var doneButton = PulseButton(title: "Add", isRound: true, hasShadow: false, buttonColor: UIColor.pulseRed, textColor: .white)
    private lazy var closeButton = PulseButton(size: .xSmall, type: .close, isRound: true, hasBackground: false, tint: .black)

    private var isSetup = false
    private var textBoxAdded = false
    
    private var placeholderText = "enter item title"
    fileprivate var textViewHeightConstraint : NSLayoutConstraint!
    fileprivate var containerHeightConstraint: NSLayoutConstraint!
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        imageView.image = nil
    }
    
    public func updateLabels(title : String?, subtitle: String?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
    
    public func updateImage(image: UIImage?) {
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        super.prepareForReuse()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupCell()
    }
    
    public func hideTextBox() {
        showTextBox(show: false)
    }
    
    public func showAddItem() {
        showTextBox(show: true)
    }
    
    public func showTextBox(show: Bool = true) {
        if !textBoxAdded, show {
            addTextBox()
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.txtBody.alpha = show ? 1.0 : 0.0
            self.txtContainer.alpha = show ? 1.0 : 0.0
            self.doneButton.alpha = show ? 1.0 : 0.0
            self.closeButton.alpha = show ? 1.0 : 0.0
            self.addButton.alpha = show ? 0.0 : 1.0
            self.titleLabel.alpha = show ? 0.0 : 1.0
            self.subtitleLabel.alpha = show ? 0.0 : 1.0
        }, completion: { _ in
            self.txtContainer.isHidden = !show
            self.txtBody.isHidden = !show
            self.doneButton.isHidden = !show
            self.closeButton.isHidden = !show
            self.addButton.isHidden = show
            self.titleLabel.isHidden = show
            self.subtitleLabel.isHidden = show
            
            if show {
                self.txtBody.becomeFirstResponder()
            } else {
                self.txtBody.resignFirstResponder()
            }
        })
    }
    
    public func addNewItem() {
        guard txtBody.text != "", txtBody.text != placeholderText else {
            return
        }
        
        showTextBox(show: false)
        listDelegate?.addListItem(title: txtBody.text!)
        txtBody.resignFirstResponder()
        txtBody.text = placeholderText
        txtBody.textColor = UIColor.placeholderGrey
        
        let sizeThatFitsTextView = txtBody.sizeThatFits(CGSize(width: txtBody.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        textViewHeightConstraint.constant = sizeThatFitsTextView.height
        containerHeightConstraint.constant = max(IconSizes.medium.rawValue, sizeThatFitsTextView.height)
    }
    
    public func addTextBox() {
        contentView.addSubview(txtContainer)
        contentView.addSubview(doneButton)
        
        txtContainer.addSubview(txtBody)
        txtContainer.addSubview(closeButton)

        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        doneButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        doneButton.widthAnchor.constraint(equalTo: doneButton.heightAnchor).isActive = true
        doneButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        doneButton.layoutIfNeeded()

        txtContainer.translatesAutoresizingMaskIntoConstraints = false
        txtContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        txtContainer.trailingAnchor.constraint(equalTo: doneButton.leadingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        txtContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        txtContainer.backgroundColor = UIColor.pulseGrey.withAlphaComponent(0.3)
        txtContainer.layer.cornerRadius = 5
        
        txtBody.translatesAutoresizingMaskIntoConstraints = false
        txtBody.centerYAnchor.constraint(equalTo: txtContainer.centerYAnchor).isActive = true
        txtBody.leadingAnchor.constraint(equalTo: txtContainer.leadingAnchor).isActive = true
        txtBody.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor).isActive = true
        
        txtBody.delegate = self
        txtBody.isScrollEnabled = false
        txtBody.backgroundColor = UIColor.clear
        txtBody.text = placeholderText
        txtBody.textColor = UIColor.placeholderGrey

        let sizeThatFitsTextView = txtBody.sizeThatFits(CGSize(width: txtBody.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        textViewHeightConstraint = txtBody.heightAnchor.constraint(equalToConstant: sizeThatFitsTextView.height)
        containerHeightConstraint = txtContainer.heightAnchor.constraint(equalToConstant: max(IconSizes.medium.rawValue, sizeThatFitsTextView.height))
        textViewHeightConstraint.isActive = true
        containerHeightConstraint.isActive = true
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.centerYAnchor.constraint(equalTo: txtContainer.centerYAnchor).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: txtContainer.trailingAnchor).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        closeButton.layoutIfNeeded()
        closeButton.removeShadow()
        
        txtContainer.layoutIfNeeded()
        txtBody.layoutIfNeeded()

        doneButton.makeRound()
        doneButton.setTitle("Add", for: UIControlState())
        doneButton.setButtonFont(FontSizes.caption2.rawValue, weight: UIFontWeightBold, color: .white, alignment: .center)
        doneButton.backgroundColor = .pulseRed
        
        closeButton.addTarget(self, action: #selector(hideTextBox), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(addNewItem), for: .touchUpInside)
        
        textBoxAdded = true
    }
    
    fileprivate func setupCell() {
        if !isSetup {
            contentView.backgroundColor = UIColor.white
            contentView.addSubview(addButton)
            contentView.addSubview(titleLabel)
            contentView.addSubview(subtitleLabel)
            
            addButton.translatesAutoresizingMaskIntoConstraints = false
            addButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
            addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.s.rawValue).isActive = true
            addButton.widthAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
            addButton.heightAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
            addButton.layoutIfNeeded()
            addButton.addTarget(self, action: #selector(showAddItem), for: .touchUpInside)
            addButton.removeShadow()
            
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.bottomAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
            titleLabel.leadingAnchor.constraint(equalTo: addButton.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
            titleLabel.layoutIfNeeded()
            
            subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
            subtitleLabel.topAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
            subtitleLabel.leadingAnchor.constraint(equalTo: addButton.trailingAnchor, constant: Spacing.xs.rawValue).isActive = true
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
            subtitleLabel.layoutIfNeeded()
            
            titleLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightBlack, color: UIColor.black, alignment: .left)
            subtitleLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightRegular, color: UIColor.placeholderGrey, alignment: .left)
            
            titleLabel.text = "new collection"
            subtitleLabel.text = "start a new collection or browse existing choices"
            
            isSetup = true
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = placeholderText
            textView.textColor = UIColor.placeholderGrey
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.text == placeholderText {
            textView.text = ""
            textView.textColor = UIColor.black
        }
        
        if text == "\n" {
            addNewItem()
            return false
        }
        
        return textView.text.characters.count + text.characters.count <= POST_TITLE_CHARACTER_COUNT
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            let sizeThatFitsTextView = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
            textViewHeightConstraint.constant = sizeThatFitsTextView.height
            containerHeightConstraint.constant = max(IconSizes.medium.rawValue, sizeThatFitsTextView.height)
        }
    }
}
