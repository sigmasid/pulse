//
//  ItemTableHeader.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/23/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ItemTableHeader: UITableViewHeaderFooterView {
    public weak var delegate : HeaderDelegate!
    
    private var titleLabel = UILabel()
    lazy var headerMenu = PulseButton(size: .small, type: .ellipsis, isRound: true, background: .white, tint: .black)
    private var reuseCell = false
    private var isSetup = false
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        delegate = nil
    }
    
    func updateLabel(_ _title : String?) {
        if let _title = _title {
            titleLabel.text = _title
        }
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        super.prepareForReuse()
    }
    
    func clickedMenu() {
        if delegate != nil {
            delegate.clickedHeaderMenu()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupCell()
    }
    
    fileprivate func setupCell() {
        if !isSetup {
            contentView.backgroundColor = .white
            contentView.addSubview(titleLabel)
            contentView.addSubview(headerMenu)
            
            headerMenu.addTarget(self, action: #selector(clickedMenu), for: .touchUpInside)
            headerMenu.translatesAutoresizingMaskIntoConstraints = false
            headerMenu.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
            headerMenu.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
            headerMenu.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
            headerMenu.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
            headerMenu.layoutIfNeeded()
            headerMenu.removeShadow()
            
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
            titleLabel.trailingAnchor.constraint(equalTo: headerMenu.leadingAnchor, constant: -Spacing.xs.rawValue).isActive = true
            titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor).isActive = true
            titleLabel.layoutIfNeeded()

            titleLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: UIColor.black, alignment: .left)
            contentView.addBottomBorder(color: .pulseGrey)
            isSetup = true
        }
    }

}
