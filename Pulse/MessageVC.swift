//
//  MessageVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 10/3/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class MessageVC: UIViewController, UITextFieldDelegate, UITextViewDelegate{
    
    var toUser : User! {
        didSet {
            setupToUserLayout()
            updateToUserData()
        }
    }
    
    var toUserImage : UIImage? {
        didSet {
            msgToUserImage.image = toUserImage
            msgToUserImage.contentMode = .scaleAspectFit
        }
    }
    
    fileprivate var msgTo = UIView()
    fileprivate var msgToUserImage = UIImageView()
    fileprivate var msgToUserName = UILabel()
    fileprivate var msgToUserBio = UILabel()
    
    fileprivate var msgFrom = UITextField()
    fileprivate var msgSubject = UITextField()
    fileprivate var msgBody = UITextView()
    
    fileprivate var msgSend = UIButton()
    fileprivate var _loginHeader : LoginHeaderView?
    fileprivate var _hasMovedUp = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        hideKeyboardWhenTappedAround()
        addHeader()
        setupLayout()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func addHeader() {
        _loginHeader = addHeader(text: "MESSAGE")
        _loginHeader?.addGoBack()
        _loginHeader?.updateStatusMessage(_message: "send message")
        _loginHeader?._goBack.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        _loginHeader?.layoutIfNeeded()
    }
    
    func goBack() {
        GlobalFunctions.dismissVC(self)
    }
    
    fileprivate func setupLayout() {
        view.addSubview(msgTo)
        view.addSubview(msgFrom)
        view.addSubview(msgSubject)
        view.addSubview(msgBody)
        view.addSubview(msgSend)

        msgTo.translatesAutoresizingMaskIntoConstraints = false
        msgTo.topAnchor.constraint(equalTo: _loginHeader!.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        msgTo.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        msgTo.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        msgTo.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        msgFrom.translatesAutoresizingMaskIntoConstraints = false
        msgFrom.topAnchor.constraint(equalTo: msgTo.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        msgFrom.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        msgFrom.widthAnchor.constraint(equalTo: msgTo.widthAnchor).isActive = true
        msgFrom.centerXAnchor.constraint(equalTo: msgTo.centerXAnchor).isActive = true
        msgFrom.layoutIfNeeded()
        
        msgFrom.backgroundColor = UIColor.clear
        msgFrom.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        msgFrom.textColor = UIColor.black
        msgFrom.layer.addSublayer(GlobalFunctions.addBorders(msgFrom, _color: UIColor.black, thickness: 1.0))
        if let _name = User.currentUser?.name {
            msgFrom.text = "FROM: \(_name)"
        }
        msgFrom.delegate = self

        
        msgSubject.translatesAutoresizingMaskIntoConstraints = false
        msgSubject.topAnchor.constraint(equalTo: msgFrom.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        msgSubject.heightAnchor.constraint(equalTo: msgFrom.heightAnchor).isActive = true
        msgSubject.widthAnchor.constraint(equalTo: msgTo.widthAnchor).isActive = true
        msgSubject.centerXAnchor.constraint(equalTo: msgTo.centerXAnchor).isActive = true
        msgSubject.layoutIfNeeded()

        msgSubject.placeholder = "SUBJECT:"
        msgSubject.delegate = self
        msgSubject.backgroundColor = UIColor.clear
        msgSubject.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        msgSubject.textColor = UIColor.black
        msgSubject.layer.addSublayer(GlobalFunctions.addBorders(msgFrom, _color: UIColor.black, thickness: 1.0))
        
        msgBody.translatesAutoresizingMaskIntoConstraints = false
        msgBody.topAnchor.constraint(equalTo: msgSubject.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        msgBody.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/6).isActive = true
        msgBody.widthAnchor.constraint(equalTo: msgTo.widthAnchor).isActive = true
        msgBody.centerXAnchor.constraint(equalTo: msgTo.centerXAnchor).isActive = true
        msgBody.layoutIfNeeded()
        
        msgBody.backgroundColor = UIColor.clear
        msgBody.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        msgBody.textColor = UIColor.black
        msgBody.layer.borderColor = UIColor.black.cgColor
        msgBody.layer.borderWidth = 1.0
        msgBody.delegate = self

        msgSend.translatesAutoresizingMaskIntoConstraints = false
        msgSend.topAnchor.constraint(equalTo: msgBody.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        msgSend.heightAnchor.constraint(equalTo: msgFrom.heightAnchor).isActive = true
        msgSend.widthAnchor.constraint(equalTo: msgTo.widthAnchor).isActive = true
        msgSend.centerXAnchor.constraint(equalTo: msgTo.centerXAnchor).isActive = true
        
        msgSend.layer.cornerRadius = buttonCornerRadius.radius(.regular)
        msgSend.setTitle("Send", for: UIControlState())
        msgSend.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        msgSend.setEnabled()
    }
    
    fileprivate func setupToUserLayout() {
        msgTo.addSubview(msgToUserImage)
        msgTo.addSubview(msgToUserName)
        msgTo.addSubview(msgToUserBio)

        msgToUserImage.translatesAutoresizingMaskIntoConstraints = false
        msgToUserImage.topAnchor.constraint(equalTo: msgTo.topAnchor).isActive = true
        msgToUserImage.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        msgToUserImage.widthAnchor.constraint(equalTo: msgToUserImage.heightAnchor).isActive = true
        msgToUserImage.leadingAnchor.constraint(equalTo: msgTo.leadingAnchor).isActive = true
        msgToUserImage.layoutIfNeeded()
        
        msgToUserImage.layer.cornerRadius = msgToUserImage.bounds.height / 2
        msgToUserImage.layer.masksToBounds = true
        msgToUserImage.layer.shouldRasterize = true
        msgToUserImage.layer.rasterizationScale = UIScreen.main.scale
        
        msgToUserName.translatesAutoresizingMaskIntoConstraints = false
        msgToUserName.leadingAnchor.constraint(equalTo: msgToUserImage.trailingAnchor, constant: Spacing.s.rawValue).isActive = true
        msgToUserName.topAnchor.constraint(equalTo: msgTo.topAnchor).isActive = true
        msgToUserName.trailingAnchor.constraint(equalTo: msgTo.trailingAnchor).isActive = true
        
        msgToUserBio.translatesAutoresizingMaskIntoConstraints = false
        msgToUserBio.leadingAnchor.constraint(equalTo: msgToUserImage.trailingAnchor, constant: Spacing.s.rawValue).isActive = true
        msgToUserBio.topAnchor.constraint(equalTo: msgToUserName.bottomAnchor).isActive = true
        msgToUserBio.trailingAnchor.constraint(equalTo: msgTo.trailingAnchor).isActive = true
    }
    
    fileprivate func updateToUserData() {
        if let _uName = toUser.name {
            msgToUserName.text = _uName
        }
        
        if let _uBio = toUser.shortBio {
            msgToUserBio.text = _uBio
        }
        
        msgToUserImage.backgroundColor = UIColor.lightGray
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if !_hasMovedUp {
            UIView.animate(withDuration: 0.1, animations: {
                self.view.frame.origin.y -= (self._loginHeader!.frame.height + Spacing.l.rawValue + Spacing.xs.rawValue)
            })
            _hasMovedUp = true
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if _hasMovedUp {
            UIView.animate(withDuration: 0.1, animations: {
                self.view.frame.origin.y += (self._loginHeader!.frame.height + Spacing.l.rawValue + Spacing.xs.rawValue)
            })
            _hasMovedUp = false
        }
    }
    
    func textViewDidBeginEditing(_ textField: UITextView) {
        if !_hasMovedUp {
            UIView.animate(withDuration: 0.1, animations: {
                self.view.frame.origin.y -= (self._loginHeader!.frame.height + Spacing.l.rawValue + Spacing.xs.rawValue)
            })
            _hasMovedUp = true
        }
    }
    
    func textViewDidEndEditing(_ textField: UITextView) {
        if _hasMovedUp {
            UIView.animate(withDuration: 0.1, animations: {
                self.view.frame.origin.y += (self._loginHeader!.frame.height + Spacing.l.rawValue + Spacing.xs.rawValue)
            })
            _hasMovedUp = false
        }
    }
}
