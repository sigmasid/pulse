//
//  SearchVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/26/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SearchVC: UIViewController {
    private var searchField = UITextField()
    private var searchOptions = UISegmentedControl()
    private var icon : Icon!
    private var viewTitleLabel = UILabel()
    
    private var searchButton = UIButton()
    private var toggleButton = UIButton()
    
    private lazy var searchResults = UITableView()
    private var isMainViewSetup = false
    private var resultsViewSetup = false
    
    //set by delegate
    var rootVC : UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupView() {
        
        if !isMainViewSetup {
            view.backgroundColor = UIColor.whiteColor()
            icon = Icon(frame: CGRectMake(0, 0, IconSizes.Medium.rawValue, IconSizes.Medium.rawValue))
            icon.drawIconBackground(UIColor.blackColor())
            icon.drawIcon(UIColor.whiteColor(), iconThickness: IconThickness.Medium.rawValue)
            view.addSubview(icon)
            
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -Spacing.s.rawValue).active = true
            icon.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor, constant: -Spacing.s.rawValue).active = true
            icon.widthAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
            icon.heightAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
            icon.layoutIfNeeded()
            
            view.addSubview(viewTitleLabel)
            viewTitleLabel.translatesAutoresizingMaskIntoConstraints = false
            viewTitleLabel.topAnchor.constraintEqualToAnchor(icon.bottomAnchor).active = true
            viewTitleLabel.centerXAnchor.constraintEqualToAnchor(icon.centerXAnchor).active = true
            viewTitleLabel.font = UIFont.systemFontOfSize(FontSizes.Caption.rawValue, weight: UIFontWeightBold)
            viewTitleLabel.text = "SEARCH"
            
            view.addSubview(toggleButton)
//            toggleButton.addTarget(self, action: #selector(setCurrentView), forControlEvents: UIControlEvents.TouchDown)
            toggleButton.translatesAutoresizingMaskIntoConstraints = false
            toggleButton.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: Spacing.l.rawValue).active = true
            toggleButton.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor, constant: Spacing.m.rawValue).active = true
            toggleButton.heightAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
            toggleButton.widthAnchor.constraintEqualToAnchor(toggleButton.heightAnchor).active = true
            toggleButton.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
            toggleButton.layoutIfNeeded()
            
            let toggleIconImage = UIImage(named: "collection-list")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
            toggleButton.setImage(toggleIconImage, forState: .Normal)
            toggleButton.tintColor = UIColor.blackColor()
            
            view.addSubview(searchField)
            searchField.translatesAutoresizingMaskIntoConstraints = false
            searchField.topAnchor.constraintEqualToAnchor(toggleButton.bottomAnchor, constant: Spacing.xl.rawValue * 1.25).active = true
            searchField.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.8).active = true
            searchField.heightAnchor.constraintEqualToConstant(IconSizes.Large.rawValue).active = true
            searchField.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
            searchField.layoutIfNeeded()
            searchField.layer.addSublayer(GlobalFunctions.addBorders(searchField, _color: UIColor.blackColor(), thickness: IconThickness.ExtraThick.rawValue))
            
            searchField.addSubview(searchButton)
            searchButton.translatesAutoresizingMaskIntoConstraints = false
            searchButton.topAnchor.constraintEqualToAnchor(searchField.topAnchor, constant: Spacing.s.rawValue).active = true
            searchButton.bottomAnchor.constraintEqualToAnchor(searchField.bottomAnchor, constant: -Spacing.s.rawValue).active = true
            searchButton.widthAnchor.constraintEqualToAnchor(searchButton.heightAnchor).active = true
            searchButton.trailingAnchor.constraintEqualToAnchor(searchField.trailingAnchor).active = true
            searchButton.layoutIfNeeded()
            searchButton.setImage(UIImage(named: "search"), forState: .Normal)
            
            searchOptions = UISegmentedControl(items: ["TAGS","QUESTIONS","USERS"])
            searchOptions.selectedSegmentIndex = 1
            
            
            let attributes = [
                NSForegroundColorAttributeName : UIColor.blackColor(),
                NSFontAttributeName : UIFont.systemFontOfSize(FontSizes.Caption.rawValue, weight: UIFontWeightHeavy)
            ]
            
            searchOptions.setTitleTextAttributes(attributes, forState: .Normal)
            
            searchOptions.setDividerImage(imageWithColor(UIColor.clearColor()), forLeftSegmentState: UIControlState.Normal,
                                               rightSegmentState: UIControlState.Normal, barMetrics: UIBarMetrics.Default)
            searchOptions.setDividerImage(imageWithColor(UIColor.clearColor()), forLeftSegmentState: UIControlState.Selected,
                                               rightSegmentState: UIControlState.Normal, barMetrics: UIBarMetrics.Default)
            searchOptions.setDividerImage(imageWithColor(UIColor.clearColor()), forLeftSegmentState: UIControlState.Normal,
                                               rightSegmentState: UIControlState.Selected, barMetrics: UIBarMetrics.Default)

            searchOptions.setBackgroundImage(imageWithColor(UIColor.clearColor()), forState: .Normal, barMetrics: .Default)
            searchOptions.setBackgroundImage(imageWithColor(UIColor.grayColor()), forState: .Selected, barMetrics: .Default)

            
            view.addSubview(searchOptions)
            searchOptions.translatesAutoresizingMaskIntoConstraints = false
            searchOptions.topAnchor.constraintEqualToAnchor(searchField.bottomAnchor, constant: Spacing.m.rawValue).active = true
            searchOptions.widthAnchor.constraintEqualToAnchor(searchField.widthAnchor).active = true
            searchOptions.heightAnchor.constraintEqualToConstant(IconSizes.Small.rawValue).active = true
            searchOptions.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
            searchOptions.layoutIfNeeded()
            
            hideKeyboardWhenTappedAround()
        }
    }
    
    private func setupResults() {
        if !resultsViewSetup {
            view.addSubview(searchResults)
            
            searchResults.translatesAutoresizingMaskIntoConstraints = false
            searchResults.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -Spacing.m.rawValue).active = true
            searchResults.topAnchor.constraintEqualToAnchor(searchOptions.bottomAnchor, constant: Spacing.m.rawValue).active = true
            searchResults.widthAnchor.constraintEqualToAnchor(searchOptions.widthAnchor).active = true
            searchResults.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
            searchResults.layoutIfNeeded()
            
            resultsViewSetup = true
        }
    }
    
    private func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillRect(context, rect);
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image
    }
}
