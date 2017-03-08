//
//  AccountPageMenu.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/18/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AccountPageMenu: UIStackView {
    enum menuOptions { case profile, messages, saved, subscriptions, logout, settings }

    fileprivate var sAboutButton = PulseButton()
    fileprivate var sMessagesButton = PulseButton()
    fileprivate var sSettingsButton = PulseButton()
    fileprivate var sSavedButton = PulseButton()
    fileprivate var sLogoutButton = PulseButton()
    fileprivate var sSubscriptionsButton = PulseButton()
    
    fileprivate var selectedButton : menuOptions?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        selectedButton = nil
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func getButton(type: menuOptions ) -> UIButton {
        switch type {
        case .profile: return sAboutButton
        case .messages: return sMessagesButton
        case .saved: return sSavedButton
        case .subscriptions: return sSubscriptionsButton
        case .settings: return sSettingsButton
        case .logout: return sLogoutButton
        }
    }
    
    fileprivate func updatePulseButton(button : PulseButton, title : String, image : UIImage) -> PulseButton {
        button.setTitle(title, for: UIControlState())
        button.setImage(image, for: UIControlState())
        button.changeTint(color: .black, state: UIControlState())
        button.setButtonFont(FontSizes.caption2.rawValue, weight: UIFontWeightMedium, color: .black, alignment: .center)
        button.imageView?.contentMode = .scaleAspectFit
        button.regularTint = .black
        return button
    }
    
    public func setSelectedButton(type : menuOptions?) {
        if let selectedButton = selectedButton {
            getButton(type: selectedButton).backgroundColor = .clear
            getButton(type: selectedButton).changeTint(color: .black, state: UIControlState())
            getButton(type: selectedButton).setButtonFont(FontSizes.caption2.rawValue, weight: UIFontWeightMedium, color: .black, alignment: .center)
        }
        
        selectedButton = type
        if let type = type {
            getButton(type: type).backgroundColor = .pulseBlue
            getButton(type: type).changeTint(color: .white, state: UIControlState())
            getButton(type: type).setButtonFont(FontSizes.caption2.rawValue, weight: UIFontWeightHeavy, color: .pulseBlue, alignment: .center)
        }
    }
    
    public func setupSettingsMenuLayout() {
        //        let logoutImage = UIImage(cgImage: UIImage(named: "login")!.cgImage!, scale: CGFloat(1.0), orientation: .downMirrored)
        
        sAboutButton = updatePulseButton(button: sAboutButton, title: "profile", image: UIImage(named: "profile")!)
        sMessagesButton = updatePulseButton(button: sMessagesButton, title: "messaging", image: UIImage(named: "messenger")!)
        sSavedButton = updatePulseButton(button: sSavedButton, title: "saved", image: UIImage(named: "save")!)
        sSubscriptionsButton = updatePulseButton(button: sSubscriptionsButton, title: "subscriptions", image: UIImage(named: "answers")!)
        sSettingsButton = updatePulseButton(button: sSettingsButton, title: "account", image: UIImage(named: "settings")!)
        sLogoutButton = updatePulseButton(button: sLogoutButton, title: "logout", image: UIImage(named: "login")!)

        addArrangedSubview(sAboutButton)
        addArrangedSubview(sMessagesButton)
        addArrangedSubview(sSavedButton)
        addArrangedSubview(sSubscriptionsButton)
        addArrangedSubview(sSettingsButton)
        addArrangedSubview(sLogoutButton)
        
        let imageInset = UIEdgeInsetsMake(Spacing.xxs.rawValue, Spacing.xs.rawValue, Spacing.xxs.rawValue, 0)
        sAboutButton.imageEdgeInsets = imageInset
        sMessagesButton.imageEdgeInsets = imageInset
        sSavedButton.imageEdgeInsets = imageInset
        sSubscriptionsButton.imageEdgeInsets = imageInset
        sSettingsButton.imageEdgeInsets = imageInset
        sLogoutButton.imageEdgeInsets = imageInset
        
        let titleInset = UIEdgeInsetsMake(IconSizes.medium.rawValue, -sAboutButton.titleLabel!.frame.width, 0, 0)
        sAboutButton.titleEdgeInsets = titleInset
        sMessagesButton.titleEdgeInsets = titleInset
        sSavedButton.titleEdgeInsets = titleInset
        sSubscriptionsButton.titleEdgeInsets = titleInset
        sSettingsButton.titleEdgeInsets = titleInset
        sLogoutButton.titleEdgeInsets = titleInset
        
        axis = .vertical
        alignment = .top
        distribution = .fillEqually
        spacing = Spacing.m.rawValue
    }

}
