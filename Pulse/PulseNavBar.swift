//
//  PulseNavBar.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class PulseNavBar: UINavigationBar {
    fileprivate let appTitleLabel = UILabel()
    fileprivate let screenTitleLabel = UILabel()
    fileprivate var logoView : Icon!
    
    fileprivate var statusLabel = UILabel()
    fileprivate var statusImage : UIImageView?
    fileprivate var subtitle = UILabel()
    
    fileprivate var scopeBarContainer = UIView()
    fileprivate var segmentedControl : XMSegmentedControl!
    fileprivate var isScopeBarVisible = false
    fileprivate var isSubtitleVisible = false
    
    fileprivate var searchContainer : UIView!
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if !isScopeBarVisible && !isSubtitleVisible { //neither visible
            let newSize:CGSize = CGSize(width: UIScreen.main.bounds.width, height: IconSizes.large.rawValue + Spacing.xs.rawValue)
            return newSize
        } else if isScopeBarVisible && !isSubtitleVisible { //only scope bar visible
            let newSize:CGSize = CGSize(width: UIScreen.main.bounds.width, height: IconSizes.large.rawValue + Spacing.xs.rawValue + Spacing.m.rawValue)
            segmentedControl.frame.origin.y = IconSizes.large.rawValue + Spacing.xs.rawValue
            return newSize
        } else if !isScopeBarVisible && isSubtitleVisible { //only subtitle bar visible
            let newSize:CGSize = CGSize(width: UIScreen.main.bounds.width, height: IconSizes.large.rawValue + Spacing.s.rawValue + Spacing.xs.rawValue)
            return newSize
        } else { //both visible
            segmentedControl.frame.origin.y = IconSizes.large.rawValue + Spacing.s.rawValue + Spacing.xs.rawValue
            let newSize:CGSize = CGSize(width: UIScreen.main.bounds.width, height: IconSizes.large.rawValue + Spacing.s.rawValue + Spacing.m.rawValue  + Spacing.xs.rawValue)
            return newSize
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.clipsToBounds = false
        self.contentMode = .redraw
        
        addIcon()
//        addScreenTitleLabel()
//        addAppTitleLabel()
        addStatus()
        addSubtitle()
        
        setBackgroundImage(UIImage(), for: .default)
        shadowImage = UIImage()
        isTranslucent = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        for view in self.subviews {
            if view.isKind(of: UIButton.self) {
                view.frame.origin.y = (IconSizes.large.rawValue - IconSizes.small.rawValue) / 2
            } else if view.tag == statusLabel.tag {
                view.frame.origin.y = 0
            } else if view.tag == subtitle.tag {
                view.frame.origin.y = IconSizes.large.rawValue + Spacing.xs.rawValue
            }
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    public func updateStatusMessage(_message : String?) {
        if _message != nil {
            statusLabel.isHidden = false
            statusImage?.isHidden = true
            statusLabel.text = _message
        }
    }
    
    func updateStatusImage(_image : UIImage?) {
        if statusImage == nil {
            addStatusImage()
        }
        
        statusImage?.isHidden = false
        statusLabel.isHidden = true
        statusImage?.image = _image
    }
    
    func setAppTitleLabel(_message : String) {
        appTitleLabel.text = _message
        appTitleLabel.addTextSpacing(2.5)
    }
    
    func setScreenTitleLabel(_message : String) {
        screenTitleLabel.text = _message
        screenTitleLabel.addTextSpacing(2.5)
        screenTitleLabel.adjustsFontSizeToFitWidth = true
    }
    
    func setSubtitle(text : String) {
        subtitle.text = text
    }
    
    fileprivate func toggleLogo(show : Bool) {
        logoView.isHidden = show ? false :  true
    }
    
    func toggleStatus(show : Bool) {
        statusImage?.isHidden = show ? false :  true
        statusLabel.isHidden = show ? false :  true
    }
    
    func toggleSearch(show: Bool) {
        searchContainer?.isHidden = show ? false :  true
    }
    
    func toggleSubtitle(show: Bool) {
        subtitle.isHidden = show ? false :  true
        isSubtitleVisible = show ? true : false
    }
    
    public func toggleScopeBar(show : Bool) {
        segmentedControl.isHidden = show ? false : true
        isScopeBarVisible = show ? true : false
    }
    
    func updateLogo(mode : LogoModes) {
        switch mode {
        case .full:
            toggleLogo(show: true)
            logoView.drawLongIcon(UIColor.black, iconThickness: IconThickness.medium.rawValue)
        case .line:
            toggleLogo(show: true)
            logoView.drawLineOnly(UIColor.black, iconThickness: IconThickness.medium.rawValue)
        case .none:
            toggleLogo(show: false)
        }
    }
    
    fileprivate func addIcon() {
        logoView = Icon(frame: CGRect(x: IconSizes.large.rawValue, y: 0, width: UIScreen.main.bounds.width - IconSizes.large.rawValue, height: IconSizes.medium.rawValue + statusBarHeight))
        addSubview(logoView)
    }
    
    fileprivate func addStatus() {
        addSubview(statusLabel)
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        statusLabel.widthAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        statusLabel.heightAnchor.constraint(equalTo: statusLabel.widthAnchor).isActive = true
        statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        statusLabel.layoutIfNeeded()
        statusLabel.font = UIFont.systemFont(ofSize: FontSizes.caption.rawValue, weight: UIFontWeightThin)
        statusLabel.backgroundColor = UIColor.black
        statusLabel.textColor = UIColor.white
        statusLabel.layer.cornerRadius = statusLabel.bounds.width / 2
        
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.minimumScaleFactor = 0.1
        statusLabel.numberOfLines = 0
        
        statusLabel.textAlignment = .center
        statusLabel.layer.masksToBounds = true
        
        statusLabel.tag = 5
    }
    
    fileprivate func addSubtitle() {
        addSubview(subtitle)
        
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.topAnchor.constraint(equalTo: statusLabel.bottomAnchor).isActive = true
        subtitle.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        subtitle.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        subtitle.layoutIfNeeded()
        
        subtitle.setFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: .black, alignment: .center)
        subtitle.textColor = UIColor.black
        subtitle.minimumScaleFactor = 0.5
        subtitle.sizeToFit()
        
        subtitle.tag = 10
        
        toggleSubtitle(show: false)
    }
    
    fileprivate func addStatusImage() {
        statusImage = UIImageView()
        if let statusImage = statusImage {
            addSubview(statusImage)
            
            statusImage.translatesAutoresizingMaskIntoConstraints = false
            statusImage.centerYAnchor.constraint(equalTo: logoView.centerYAnchor).isActive = true
            statusImage.widthAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
            statusImage.heightAnchor.constraint(equalTo: statusImage.widthAnchor).isActive = true
            statusImage.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            statusImage.layoutIfNeeded()
            
            statusImage.layer.cornerRadius = statusImage.bounds.width / 2
            statusImage.layer.masksToBounds = true
            statusImage.layer.shouldRasterize = true
            statusImage.layer.rasterizationScale = UIScreen.main.scale
            statusImage.backgroundColor = UIColor.lightGray
            statusImage.contentMode = .scaleAspectFill
        }
    }
    
    fileprivate func addSearch() {
        searchContainer = UIView(frame: CGRect(x: IconSizes.large.rawValue,
                                               y: (IconSizes.large.rawValue - IconSizes.small.rawValue) / 2,
                                               width: UIScreen.main.bounds.width - IconSizes.large.rawValue,
                                               height: IconSizes.medium.rawValue))
        addSubview(searchContainer)
        toggleSearch(show: false)
    }
    
    fileprivate func addAppTitleLabel() {
        addSubview(appTitleLabel)
        
        appTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        appTitleLabel.topAnchor.constraint(equalTo: logoView.topAnchor).isActive = true
        appTitleLabel.leadingAnchor.constraint(equalTo: logoView.leadingAnchor).isActive = true
        
        appTitleLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)
        appTitleLabel.textColor = UIColor.black
        appTitleLabel.textAlignment = .left
        appTitleLabel.addTextSpacing(10)
    }
    
    fileprivate func addScreenTitleLabel() {
        addSubview(screenTitleLabel)
        
        screenTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        screenTitleLabel.bottomAnchor.constraint(equalTo: logoView.bottomAnchor).isActive = true
        screenTitleLabel.leadingAnchor.constraint(equalTo: logoView.leadingAnchor).isActive = true
        
        screenTitleLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)
        screenTitleLabel.textColor = UIColor.black
        screenTitleLabel.textAlignment = .left
    }

    fileprivate func addScopeBar() {
        let frame = CGRect(x: 0, y: IconSizes.medium.rawValue + statusBarHeight + Spacing.s.rawValue, width: UIScreen.main.bounds.width, height: Spacing.l.rawValue)
        let titles = [" ", " ", " "]
        
        segmentedControl = XMSegmentedControl(frame: frame,
                                              segmentTitle: titles,
                                              selectedItemHighlightStyle: XMSelectedItemHighlightStyle.bottomEdge)
        addSubview(segmentedControl)

        segmentedControl.backgroundColor = color7
        segmentedControl.highlightColor = pulseBlue
        segmentedControl.tint = .white
        segmentedControl.highlightTint = pulseBlue
    }
    
    public func getScopeBar() -> XMSegmentedControl? {
        if segmentedControl == nil {
            addScopeBar()
        }
        return segmentedControl
    }
    
    public func getSearchContainer() -> UIView {
        if searchContainer == nil {
            addSearch()
        }
        return searchContainer
    }
    
    public func updateScopeBarTitles(titles : [String], icons : [UIImage]?, selected : Int) {
        if segmentedControl == nil {
            addScopeBar()
        }
        
        isScopeBarVisible = true
        
        if icons != nil {
            segmentedControl.segmentContent = (titles, icons!)
        } else {
            segmentedControl.segmentTitle = titles
        }
        
        segmentedControl.selectedSegment = selected
        segmentedControl.layoutIfNeeded()
    }
}
