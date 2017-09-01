//
//  ListItemFooter.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/21/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ListItemFooter: UITableViewHeaderFooterView, UITextFieldDelegate {
    
    public var listDelegate : ListDelegate?
    
    private var titleLabel = UILabel()
    private var subtitleLabel = UILabel()
    private var imageView = UIImageView()
    private var addButton = PulseButton(size: .xSmall, type: .addCircle, isRound: true, hasBackground: false, tint: .black)

    private lazy var addTitle : PaddingTextField! = PaddingTextField()
    private lazy var doneButton = PulseButton(title: "Add", isRound: true, hasShadow: false, buttonColor: UIColor.pulseRed, textColor: .white)
    private lazy var closeButton = PulseButton(size: .xSmall, type: .close, isRound: true, hasBackground: false, tint: .black)

    private var isSetup = false
    private var textBoxAdded = false
    
    private var placeholderText = "enter item title"
    
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
            self.addTitle.alpha = show ? 1.0 : 0.0
            self.doneButton.alpha = show ? 1.0 : 0.0
            self.closeButton.alpha = show ? 1.0 : 0.0
            self.addButton.alpha = show ? 0.0 : 1.0
            self.titleLabel.alpha = show ? 0.0 : 1.0
            self.subtitleLabel.alpha = show ? 0.0 : 1.0
        }, completion: { _ in
            self.addTitle.isHidden = !show
            self.doneButton.isHidden = !show
            self.closeButton.isHidden = !show
            self.addButton.isHidden = show
            self.titleLabel.isHidden = show
            self.subtitleLabel.isHidden = show
            
            if show {
                self.addTitle.becomeFirstResponder()
            } else {
                self.addTitle.resignFirstResponder()
            }
        })
    }
    
    public func addNewItem() {
        guard addTitle.text != "", addTitle.text != placeholderText else {
            return
        }
        
        showTextBox(show: false)
        listDelegate?.addListItem(title: addTitle.text!)
        addTitle.text = ""
    }
    
    public func addTextBox() {
        contentView.addSubview(addTitle)
        contentView.addSubview(doneButton)
        contentView.addSubview(closeButton)

        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        doneButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        doneButton.widthAnchor.constraint(equalTo: doneButton.heightAnchor).isActive = true
        doneButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        doneButton.layoutIfNeeded()

        addTitle.translatesAutoresizingMaskIntoConstraints = false
        addTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        addTitle.trailingAnchor.constraint(equalTo: doneButton.leadingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        addTitle.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        addTitle.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        addTitle.layoutIfNeeded()
        addTitle.delegate = self
        addTitle.placeholder = placeholderText
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.centerYAnchor.constraint(equalTo: addTitle.centerYAnchor).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: addTitle.trailingAnchor, constant: -Spacing.xxs.rawValue).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        closeButton.layoutIfNeeded()
        closeButton.removeShadow()

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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
