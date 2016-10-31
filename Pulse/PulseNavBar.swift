//
//  PulseNavBar.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

public class PulseNavBar: UINavigationBar {
    fileprivate var logoView : Icon!
    
    public var expandedContainer = UIView()
    fileprivate var expandedTitleLabel = UILabel()
    fileprivate var expandedTitleImage : UIImageView?
    fileprivate var expandedSubtitleLabel = UILabel()
    fileprivate var scopeBarContainer = UIView()
    fileprivate var segmentedControl : XMSegmentedControl!
    
    public var collapsedTitleLabel = UILabel()
    fileprivate var searchContainer : UIView!
    
    public var navBarSize : CGSize = CGSize(width: UIScreen.main.bounds.width, height: NavBarSize.expandedScope.rawValue)
    
    /**
    public var navBarSize : CGSize = CGSize(width: UIScreen.main.bounds.width, height: NavBarSize.expandedScope.rawValue) {
        didSet {
            let oldFrame = expandedContainer.frame
            let newFrame = CGRect(x: oldFrame.minX, y: oldFrame.minY, width: oldFrame.width, height: navBarSize.height)
            
            expandedContainer.frame = newFrame
            expandedContainer.layoutIfNeeded()
        }
    } **/
    
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        return navBarSize
     }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.clipsToBounds = false
        self.contentMode = .redraw

        expandedContainer.frame = CGRect(x: 0, y: 0, width: navBarSize.width, height: navBarSize.height)
        expandedContainer.tag = 25
        expandedContainer.isUserInteractionEnabled = true
        expandedContainer.backgroundColor = .yellow
        
        addSubview(expandedContainer)
        
        collapsedTitleLabel.frame = CGRect(x: 0, y: navBarSize.height - NavBarSize.collapsed.rawValue, width: navBarSize.width, height: NavBarSize.collapsed.rawValue)
        collapsedTitleLabel.alpha = 0.0
        collapsedTitleLabel.backgroundColor = .green
        expandedTitleLabel.setFont(FontSizes.body.rawValue, weight: UIFontWeightHeavy, color: .black, alignment: .left)
        
        addSubview(collapsedTitleLabel)

        addIcon()
        addExpandedTitle()
        addSubtitle()
        
        setBackgroundImage(UIImage(), for: .default)
        shadowImage = UIImage()
        isTranslucent = false
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        for view in self.subviews {
            if view.isKind(of: UIButton.self) {
                view.frame.origin.y = (IconSizes.large.rawValue - IconSizes.small.rawValue) / 2
            }
        }
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    public func setExpandedTitle(_message : String?) {
        if _message != nil {
            expandedTitleLabel.isHidden = false
            expandedTitleImage?.isHidden = true
            expandedTitleLabel.text = _message
            collapsedTitleLabel.text = _message
        }
    }
    
    func setExpandedTitleImage(_image : UIImage?) {
        if expandedTitleImage == nil {
            addexpandedTitleImage()
        }
        
        expandedTitleImage?.isHidden = false
        expandedTitleLabel.isHidden = true
        expandedTitleImage?.image = _image
    }
    
    func setExpandedSubtitle(text : String) {
        expandedSubtitleLabel.text = text
    }
    
    fileprivate func toggleLogo(show : Bool) {
        logoView.isHidden = show ? false :  true
    }
    
    func toggleStatus(show : Bool) {
        expandedTitleImage?.isHidden = show ? false :  true
        expandedTitleLabel.isHidden = show ? false :  true
    }
    
    func toggleSearch(show: Bool) {
        searchContainer?.isHidden = show ? false :  true
    }
    
    func toggleSubtitle(show: Bool) {
        expandedSubtitleLabel.isHidden = show ? false :  true
    }
    
    public func toggleScopeBar(show : Bool) {
        segmentedControl.isHidden = show ? false : true
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
        expandedContainer.addSubview(logoView)
    }
    
    fileprivate func addExpandedTitle() {
        expandedContainer.addSubview(expandedTitleLabel)
        
        expandedTitleLabel.frame = CGRect(x: expandedContainer.bounds.midX - (IconSizes.large.rawValue / 2), y: expandedContainer.bounds.origin.y, width: IconSizes.large.rawValue, height: IconSizes.large.rawValue)
        
        expandedTitleLabel.font = UIFont.systemFont(ofSize: FontSizes.caption.rawValue, weight: UIFontWeightThin)
        expandedTitleLabel.backgroundColor = UIColor.black
        expandedTitleLabel.textColor = UIColor.white
        expandedTitleLabel.layer.cornerRadius = expandedTitleLabel.bounds.width / 2
        
        expandedTitleLabel.lineBreakMode = .byWordWrapping
        expandedTitleLabel.minimumScaleFactor = 0.1
        expandedTitleLabel.numberOfLines = 0
        
        expandedTitleLabel.textAlignment = .center
        expandedTitleLabel.layer.masksToBounds = true
        
        expandedTitleLabel.tag = 5
    }
    
    fileprivate func addSubtitle() {
        expandedContainer.addSubview(expandedSubtitleLabel)

        expandedSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        expandedSubtitleLabel.topAnchor.constraint(equalTo: expandedTitleLabel.bottomAnchor).isActive = true
        expandedSubtitleLabel.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        expandedSubtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        expandedSubtitleLabel.layoutIfNeeded()
        
        expandedSubtitleLabel.setFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: .black, alignment: .center)
        expandedSubtitleLabel.textColor = UIColor.black
        expandedSubtitleLabel.minimumScaleFactor = 0.5
        expandedSubtitleLabel.sizeToFit()
        
        expandedSubtitleLabel.tag = 10
        
        toggleSubtitle(show: false)
    }
    
    fileprivate func addexpandedTitleImage() {
        expandedTitleImage = UIImageView()
        if let expandedTitleImage = expandedTitleImage {
            addSubview(expandedTitleImage)
            expandedTitleImage.frame = CGRect(x: expandedContainer.bounds.midX - (IconSizes.large.rawValue / 2), y: expandedContainer.bounds.origin.y, width: IconSizes.large.rawValue, height: IconSizes.large.rawValue)

            expandedTitleImage.layer.cornerRadius = expandedTitleImage.bounds.width / 2
            expandedTitleImage.layer.masksToBounds = true
            expandedTitleImage.layer.shouldRasterize = true
            expandedTitleImage.layer.rasterizationScale = UIScreen.main.scale
            expandedTitleImage.backgroundColor = UIColor.lightGray
            expandedTitleImage.contentMode = .scaleAspectFill
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

    fileprivate func addScopeBar() {
        let frame = CGRect(x: 0, y: expandedContainer.bounds.maxY - 40, width: UIScreen.main.bounds.width, height: 40)
        let titles = [" ", " ", " "]
        
        segmentedControl = XMSegmentedControl(frame: frame,
                                              segmentTitle: titles,
                                              selectedItemHighlightStyle: XMSelectedItemHighlightStyle.bottomEdge)
        expandedContainer.addSubview(segmentedControl)

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
        
        if icons != nil {
            segmentedControl.segmentContent = (titles, icons!)
        } else {
            segmentedControl.segmentTitle = titles
        }
        
        segmentedControl.selectedSegment = selected
        segmentedControl.layoutIfNeeded()
    }
}
