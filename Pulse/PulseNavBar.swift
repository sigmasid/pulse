//
//  PulseNavBar.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/14/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
enum NavMode { case browseImage, browse, detail, none }

public class PulseNavBar: UINavigationBar {
    public var navTitle = UILabel()
    
    fileprivate var searchContainer : UIView!
    fileprivate var isDetailSetup = false
    
    public var navBarSize : CGSize = CGSize(width: UIScreen.main.bounds.width, height: IconSizes.medium.rawValue * 1.2)

    /** SCOPE BAR VARS **/
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        return navBarSize
     }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        for view in self.subviews {
            if view.isKind(of: UIButton.self) {
                view.frame.origin.y = Spacing.xs.rawValue
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = false
        contentMode = .redraw
        
        isTranslucent = false
        tintColor = .white //need to set tint color vs. background color
        
        if !isDetailSetup { setupDetailLayout() }
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    public func setTitles(title : String?) {
        self.navTitle.text = title?.uppercased()
        
    }
    
    public func toggleSearch(show: Bool) {
        searchContainer.isHidden = show ? false : true
        navTitle.isHidden = show ? true : false
    }
    
    public func getSearchContainer() -> UIView {
        if searchContainer == nil {
            addSearch()
        }
        return searchContainer
    }
    
    public func setDarkNav() {
        barStyle = .black
        navTitle.setFont(FontSizes.headline.rawValue, weight: UIFontWeightHeavy, color: .white, alignment: .left)
        navTitle.setBlurredBackground()
    }
    
    public func setLightNav() {
        barStyle = .default
        navTitle.setFont(FontSizes.headline.rawValue, weight: UIFontWeightHeavy, color: .black, alignment: .left)
        navTitle.removeShadow()
    }

    
    /** LAYOUT SCREEN **/
    fileprivate func setupDetailLayout() {
        addSubview(navTitle)
        
        navTitle.frame = CGRect(x: IconSizes.large.rawValue, y: 0, width: UIScreen.main.bounds.width - IconSizes.large.rawValue, height: navBarSize.height)
        navTitle.setFont(FontSizes.headline.rawValue, weight: UIFontWeightHeavy, color: .black, alignment: .left)
        navTitle.lineBreakMode = .byTruncatingTail
        navTitle.numberOfLines = 2
        navTitle.tag = 10
        
        isDetailSetup = true
    }

    fileprivate func addSearch() {
        searchContainer = UIView(frame: CGRect(x: IconSizes.large.rawValue,
                                               y: Spacing.s.rawValue,
                                               width: UIScreen.main.bounds.width - IconSizes.large.rawValue,
                                               height: IconSizes.medium.rawValue))

        self.addSubview(searchContainer)
        searchContainer.tag = 30
    }
}
