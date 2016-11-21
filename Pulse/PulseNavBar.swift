//
//  PulseNavBar.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
enum NavMode { case browse, detail, none }

public class PulseNavBar: UINavigationBar {
    fileprivate var logoView : Icon!
    
    public var navContainer = UIView()
    public var navTitle = UILabel()
    public var navImage = UIImageView()
    public var screenTitle = UILabel()
    public var screenOptions : XMSegmentedControl!
    
    fileprivate var searchContainer : UIView!
    
    fileprivate var isBrowseSetup = false
    fileprivate var isDetailSetup = false
    
    public var navBarSize : CGSize = CGSize(width: UIScreen.main.bounds.width, height: IconSizes.large.rawValue + Spacing.xxs.rawValue)
    public var fullNavHeight : CGFloat = IconSizes.large.rawValue + Spacing.xxs.rawValue
    
    /** SCOPE BAR VARS **/
    public var scopeBarHeight : CGFloat = 40
    public var shouldShowScope : Bool = false {
        didSet {
            if shouldShowScope && shouldShowScope != oldValue {
                navBarSize = CGSize(width: navBarSize.width, height: fullNavHeight + scopeBarHeight)

                UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
                    self.screenOptions.alpha = 1.0
                    self.screenOptions.frame.origin.y = self.fullNavHeight
                    self.screenOptions.isHidden = false

                }, completion: { _ in self.layoutIfNeeded() })
            } else if !shouldShowScope && shouldShowScope != oldValue {
                navBarSize = CGSize(width: navBarSize.width, height: fullNavHeight)

                UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
                    self.screenOptions.alpha = 1.0
                    self.screenOptions.frame.origin.y = self.fullNavHeight - self.scopeBarHeight

                    self.screenOptions.isHidden = true
                    
                    self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y,
                                        width: self.navBarSize.width, height: self.navBarSize.height)
                }, completion: { _ in self.layoutIfNeeded() })
            }
        }
    }
    
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        return navBarSize
     }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        for view in self.subviews {
            if view.isKind(of: UIButton.self) {
                view.frame.origin.y = Spacing.s.rawValue
            }
        }
    }
    
 
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if screenOptions != nil, !screenOptions.isHidden {
            if let translatedPoint = getScopeBar()?.convert(point, from: self), let scopeBar = getScopeBar() {
                if (scopeBar.bounds.contains(translatedPoint)){
                    return scopeBar.hitTest(translatedPoint, with: event)
                    
                }
            }
        }
        return super.hitTest(point, with: event)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.clipsToBounds = false
        self.contentMode = .redraw

        isTranslucent = false
        tintColor = .white //need to set tint color vs. background color
        
        if !isBrowseSetup { setupBrowseLayout() }
        if !isDetailSetup { setupDetailLayout() }
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    public func setTitles(_navTitle : String?, _screenTitle : String?, _navImage : UIImage?) {
        if _navImage != nil {
            setNavMode(mode: .browse)
            navTitle.isHidden = true
            navImage.isHidden = false
        } else if _screenTitle != nil  {
            setNavMode(mode: .detail)
        } else if _navTitle != nil {
            setNavMode(mode: .browse)
            navTitle.isHidden = false
            navImage.isHidden = true
        } else {
            setNavMode(mode: .none)
        }
        
        navImage.image = _navImage
        navTitle.text = _navTitle
        screenTitle.text = _screenTitle?.uppercased()
    }
    
    fileprivate func setNavMode(mode : NavMode) {
        switch mode {
        case .browse:
            navContainer.isHidden = false
            screenTitle.isHidden = true
        case .detail:
            navContainer.isHidden = true
            screenTitle.isHidden = false
        case .none:
            navContainer.isHidden = true
            screenTitle.isHidden = true
            navTitle.isHidden = true
            navImage.isHidden = true
            logoView.isHidden = true
        }
    }
    
    public func toggleSearch(show: Bool) {
        searchContainer.isHidden = show ? false : true
        screenTitle.isHidden = show ? true : false
    }
    
    public func toggleScopeBar(show : Bool) {
        screenOptions.isHidden = show ? false : true
    }
    
    public func getScopeBar() -> XMSegmentedControl? {
        if screenOptions == nil {
            addScopeBar()
        }
        return screenOptions
    }
    
    public func getSearchContainer() -> UIView {
        if searchContainer == nil {
            addSearch()
        }
        return searchContainer
    }
    
    public func updateScopeBarTitles(titles : [String], icons : [UIImage]?, selected : Int) {
        if screenOptions == nil {
            addScopeBar()
        }
        
        if icons != nil {
            screenOptions.segmentContent = (titles, icons!)
        } else {
            screenOptions.segmentTitle = titles
        }
        
        screenOptions.selectedSegment = selected
        screenOptions.layoutIfNeeded()
    }
    
    /** LAYOUT SCREEN **/
    fileprivate func setupBrowseLayout() {
        navContainer.frame = CGRect(x: 0, y: 0, width: navBarSize.width, height: navBarSize.height)
        navContainer.tag = 25
        navContainer.isUserInteractionEnabled = false
        
        addSubview(navContainer)
        
        addIcon()
        addNavImage()
        addNavTitle()
        
        navContainer.isHidden = true
        isBrowseSetup = true
    }
    
    fileprivate func setupDetailLayout() {
        addSubview(screenTitle)
        screenTitle.frame = CGRect(x: IconSizes.large.rawValue, y: 0, width: UIScreen.main.bounds.width - IconSizes.large.rawValue, height: IconSizes.large.rawValue)
        
        screenTitle.setFont(FontSizes.headline.rawValue, weight: UIFontWeightHeavy, color: .black, alignment: .left)
        
        screenTitle.lineBreakMode = .byTruncatingTail
        screenTitle.numberOfLines = 3
        screenTitle.tag = 10
        
        screenTitle.isHidden = true
        isDetailSetup = true
    }
    
    fileprivate func addIcon() {
        logoView = Icon(frame: CGRect(x: IconSizes.large.rawValue, y: 0, width: UIScreen.main.bounds.width - IconSizes.large.rawValue, height: IconSizes.medium.rawValue + statusBarHeight))
        logoView.drawLongIcon(UIColor.black, iconThickness: IconThickness.medium.rawValue)
        navContainer.addSubview(logoView)
    }
    
    fileprivate func addNavTitle() {
        navContainer.addSubview(navTitle)
        navTitle.frame = CGRect(x: navContainer.bounds.midX - (IconSizes.large.rawValue / 2), y: navContainer.bounds.origin.y, width: IconSizes.large.rawValue, height: IconSizes.large.rawValue)

        navTitle.font = UIFont.systemFont(ofSize: FontSizes.caption.rawValue, weight: UIFontWeightThin)
        navTitle.backgroundColor = UIColor.black
        navTitle.textColor = UIColor.white
        navTitle.layer.cornerRadius = navTitle.bounds.width / 2
        
        navTitle.lineBreakMode = .byWordWrapping
        navTitle.minimumScaleFactor = 0.1
        navTitle.numberOfLines = 0
        
        navTitle.textAlignment = .center
        navTitle.layer.masksToBounds = true
        
        navTitle.tag = 5
    }
    
    fileprivate func addNavImage() {
        navContainer.addSubview(navImage)
        navImage.frame = CGRect(x: navContainer.bounds.midX - (IconSizes.large.rawValue / 2), y: navContainer.bounds.origin.y, width: IconSizes.large.rawValue, height: IconSizes.large.rawValue)

        navImage.layer.cornerRadius = navImage.bounds.width / 2
        navImage.layer.masksToBounds = true
        navImage.layer.shouldRasterize = true
        navImage.layer.rasterizationScale = UIScreen.main.scale
        navImage.backgroundColor = UIColor.lightGray
        navImage.contentMode = .scaleAspectFill
    }
    
    fileprivate func addSearch() {
        searchContainer = UIView(frame: CGRect(x: IconSizes.large.rawValue,
                                               y: Spacing.s.rawValue,
                                               width: UIScreen.main.bounds.width - IconSizes.large.rawValue,
                                               height: IconSizes.medium.rawValue))

        self.addSubview(searchContainer)
        searchContainer.tag = 30
    }

    fileprivate func addScopeBar() {
        let frame = CGRect(x: 0, y: IconSizes.large.rawValue + Spacing.xxs.rawValue, width: UIScreen.main.bounds.width, height: scopeBarHeight)
        let titles = [" ", " ", " "]
        
        screenOptions = XMSegmentedControl(frame: frame,
                                              segmentTitle: titles,
                                              selectedItemHighlightStyle: XMSelectedItemHighlightStyle.bottomEdge)
        addSubview(screenOptions)

        screenOptions.backgroundColor = color7
        screenOptions.highlightColor = pulseBlue
        screenOptions.tint = .white
        screenOptions.highlightTint = pulseBlue
    }
}
