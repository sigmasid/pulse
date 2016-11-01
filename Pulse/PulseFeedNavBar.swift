//
//  PulseFeedNavBar.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 11/1/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

public class PulseFeedNavBar: UINavigationBar {
    
    public var navSize : CGSize = CGSize(width: UIScreen.main.bounds.width, height: 40) {
        didSet { setNeedsLayout() }
    }
    
    fileprivate var segmentedControl : XMSegmentedControl!
    fileprivate let scopeBarHeight : CGFloat = 40
    fileprivate var feedTitle : UILabel!
    fileprivate var searchContainer : UIView!
    
    public var showScopeBar : Bool = false {
        willSet {
            if newValue != showScopeBar && newValue == true {
                navSize = CGSize(width: navSize.width, height: navSize.height + scopeBarHeight)
                if segmentedControl.superview != self { addScopeBar() }
            }
        }
    }
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        print("size that fits fired with size \(navSize)")
        return navSize
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = false
        self.contentMode = .redraw
        
        addTitle()
        
        //setBackgroundImage(GlobalFunctions.imageWithColor(.white), for: .default)
        //shadowImage = UIImage()
        
        isTranslucent = false
        tintColor = .yellow //need to set tint color vs. background color
        alpha = 1.0
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
    
    public func toggleSearch(show: Bool) {
        searchContainer?.isHidden = show ? false :  true
    }
    
    public func getSearchContainer() -> UIView {
        if searchContainer == nil {
            addSearch()
        }
        return searchContainer
    }

    public func getScopeBar() -> XMSegmentedControl? {
        if segmentedControl == nil {
            addScopeBar()
        }
        return segmentedControl
    }
    
    public func setTitle(_title : String) {
        if feedTitle == nil {
            addTitle()
        }
        
        feedTitle.text = _title.uppercased()
        updateSize(title : _title)
    }
    
    public func setScopeBarTitles(titles : [String], icons : [UIImage]?, selected : Int) {
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
    
    public func toggleScopeBar(show : Bool) {
        segmentedControl.isHidden = show ? false : true
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
        let frame = CGRect(x: 0, y: navSize.height - scopeBarHeight, width: UIScreen.main.bounds.width, height: scopeBarHeight)
        let titles = [" ", " ", " "]
        print("scope bar frame is \(frame)")
        segmentedControl = XMSegmentedControl(frame: frame,
                                              segmentTitle: titles,
                                              selectedItemHighlightStyle: XMSelectedItemHighlightStyle.bottomEdge)
        addSubview(segmentedControl)
        
        segmentedControl.backgroundColor = color7
        segmentedControl.highlightColor = pulseBlue
        segmentedControl.tint = .white
        segmentedControl.highlightTint = pulseBlue
    }
    
    fileprivate func addTitle() {
        feedTitle = UILabel(frame: CGRect(x: 0, y: 0, width: navSize.width, height: 40))
        print("title frame is \(feedTitle.frame)")
        feedTitle.setFont(FontSizes.headline.rawValue, weight: UIFontWeightHeavy, color: .black, alignment: .left)
        feedTitle.backgroundColor = .red
        addSubview(feedTitle)
        feedTitle.layoutIfNeeded()
    }

    
    fileprivate func updateSize(title : String) {
        let tempLabel = UILabel()
        let maxLabelWidth : CGFloat = UIScreen.main.bounds.width - Spacing.s.rawValue
        tempLabel.numberOfLines = 0
        let attributedFont = [ NSFontAttributeName:UIFont.systemFont(ofSize: FontSizes.headline.rawValue, weight: UIFontWeightHeavy),
                               NSForegroundColorAttributeName: UIColor.black]
        
        tempLabel.attributedText = NSMutableAttributedString(string: title , attributes: attributedFont )
        let neededSize : CGSize = tempLabel.sizeThatFits(CGSize(width: maxLabelWidth, height: CGFloat.greatestFiniteMagnitude))
        let labelHeight = neededSize.height
        
        navSize = showScopeBar ? CGSize(width: navSize.width, height: max(navSize.height, labelHeight + scopeBarHeight)) :
                                 CGSize(width: navSize.width, height: max(navSize.height, labelHeight))
    }
}
