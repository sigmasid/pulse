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
    public var navSubtitle = UILabel()
    
    fileprivate var navLogo = UIImageView()
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
                if view.backgroundColor == nil {
                    view.frame.origin.y = Spacing.xs.rawValue + Spacing.xxs.rawValue
                } else {
                    view.frame.origin.y = Spacing.xs.rawValue
                }
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
    
    public func setLogo() {
        navTitle.text = nil
        navSubtitle.text = nil
        navLogo.image = UIImage(named: "pulse-logo-text")
    }
    
    public func setTitles(title : String?) {
        navLogo.image = nil
        navTitle.frame.origin.y = 0
        navTitle.text = title?.capitalized
        navTitle.textAlignment = .center
        
        navSubtitle.text = ""
    }
    
    public func setTitles(title : String?, subtitle : String?) {
        if let subtitle = subtitle {
            navLogo.image = nil
            navTitle.frame.origin.y = -Spacing.xs.rawValue
            navTitle.text = title?.capitalized
            navTitle.textAlignment = .center
            
            navSubtitle.text = subtitle.capitalized
            navSubtitle.textAlignment = .center
        } else {
            setTitles(title: title)
        }
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
        navTitle.setFont(FontSizes.headline.rawValue, weight: UIFontWeightHeavy, color: .white, alignment: .center)
        navSubtitle.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .white, alignment: .center)
        navTitle.setBlurredBackground()
    }
    
    public func setLightNav() {
        barStyle = .default
        navTitle.setFont(FontSizes.headline.rawValue, weight: UIFontWeightHeavy, color: .black, alignment: .center)
        navSubtitle.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        navTitle.removeShadow()
    }
    
    /** LAYOUT SCREEN **/
    fileprivate func setupDetailLayout() {
        addSubview(navLogo)
        addSubview(navTitle)
        addSubview(navSubtitle)
        
        navLogo.frame = CGRect(x: UIScreen.main.bounds.midX - IconSizes.large.rawValue, y: navBarSize.height / 4,
                               width: ( 2 * IconSizes.large.rawValue), height: navBarSize.height / 2)
        navLogo.contentMode = .scaleAspectFit
        navLogo.backgroundColor = UIColor.clear

        navTitle.frame = CGRect(x: IconSizes.large.rawValue, y: 0, width: UIScreen.main.bounds.width - ( 2 * IconSizes.large.rawValue ), height: navBarSize.height)
        navTitle.setFont(FontSizes.headline.rawValue, weight: UIFontWeightHeavy, color: .black, alignment: .center)
        navTitle.lineBreakMode = .byTruncatingTail
        navTitle.numberOfLines = 1
        
        navSubtitle.setFont(FontSizes.body2.rawValue, weight: UIFontWeightThin, color: .gray, alignment: .center)
        let navSubtitlefontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: navSubtitle.font.pointSize, weight: UIFontWeightThin)]
        let navSubtitleHeight = GlobalFunctions.getLabelSize(title: "Channel Name", width: navTitle.frame.width, fontAttributes: navSubtitlefontAttributes)
        navSubtitle.frame = CGRect(x: IconSizes.large.rawValue, y: navBarSize.height - navSubtitleHeight - Spacing.xs.rawValue,
                                   width: UIScreen.main.bounds.width - ( 2 * IconSizes.large.rawValue ), height: navSubtitleHeight)
        navSubtitle.numberOfLines = 1
        navSubtitle.lineBreakMode = .byTruncatingTail
        navSubtitle.adjustsFontSizeToFitWidth = true
        navSubtitle.minimumScaleFactor = 0.2
        
        isDetailSetup = true
    }


    fileprivate func addSearch() {
        searchContainer = UIView(frame: CGRect(x: Spacing.xs.rawValue,
                                               y: Spacing.xs.rawValue,
                                               width: UIScreen.main.bounds.width - Spacing.s.rawValue,
                                               height: IconSizes.medium.rawValue))

        addSubview(searchContainer)
    }
}
