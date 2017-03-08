//
//  MiniMessageVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/2/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class MiniMessageVC: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate {
    
    public var selectedUser : User!
    public var delegate : ParentDelegate!
    
    fileprivate var isLoaded = false
    fileprivate var observersAdded = false
    
    fileprivate var msgContainer = UIView()
    fileprivate var msgBody = UITextView()
    fileprivate var sendButton = PulseButton()
    
    fileprivate var msgBottomContainer : NSLayoutConstraint!
    fileprivate var textViewHeightConstraint : NSLayoutConstraint!
    fileprivate var containerHeightConstraint: NSLayoutConstraint!
    fileprivate var tap: UITapGestureRecognizer!
    
    fileprivate var hideStatusBar = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !observersAdded {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
            view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            
            tap = UITapGestureRecognizer(target: self, action: #selector(dismissMsg))
            tap.cancelsTouchesInView = false
            tap.isEnabled = true
            view.addGestureRecognizer(tap)
            
            observersAdded = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        if !isLoaded {
            setupQuestionBox()
            msgBody.becomeFirstResponder()
            
            isLoaded = true
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        print("gesture recognizer fired")
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.removeGestureRecognizer(tap)
    }
    
    func dismissMsg() {
        if delegate != nil {
            msgBody.resignFirstResponder()
            delegate.dismiss(self)
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            msgBottomContainer.constant = -keyboardHeight
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        msgBottomContainer.constant = 0
        msgContainer.layoutIfNeeded()
    }
    
    func sendMessage() {
        guard User.currentUser!.uID != selectedUser.uID else { return }
        
        let message = Message(from: User.currentUser!, to: selectedUser, body: msgBody.text)
        Database.checkExistingConversation(to: selectedUser, completion: { success, conversationID in
            message.mID = success ? conversationID! : nil
            Database.sendMessage(existing: success, message: message, completion: {(success, _conversationID) in
                if success {
                    self.msgBody.text = "Type message here"
                    self.msgBody.textColor = UIColor.lightGray
                    self.sendButton.setDisabled()
                    self.dismissMsg()
                } else {
                    GlobalFunctions.showErrorBlock("Error Sending Message", erMessage: "Sorry we had a problem sending your message. Please try again!")
                }
            })
        })
        

    }
    
    fileprivate func setupQuestionBox() {
        view.addSubview(msgContainer)
        
        msgContainer.addSubview(msgBody)
        msgContainer.addSubview(sendButton)
        
        msgContainer.translatesAutoresizingMaskIntoConstraints = false
        msgBottomContainer = msgContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        msgBottomContainer.isActive = true
        msgContainer.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerHeightConstraint = msgContainer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue)
        containerHeightConstraint.isActive = true
        msgContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        msgContainer.backgroundColor = .white
        
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.trailingAnchor.constraint(equalTo: msgContainer.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        sendButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        sendButton.widthAnchor.constraint(equalTo: sendButton.heightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: msgContainer.centerYAnchor).isActive = true
        sendButton.layoutIfNeeded()
        
        msgBody.translatesAutoresizingMaskIntoConstraints = false
        msgBody.centerYAnchor.constraint(equalTo: msgContainer.centerYAnchor).isActive = true
        msgBody.leadingAnchor.constraint(equalTo: msgContainer.leadingAnchor).isActive = true
        msgBody.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        
        textViewHeightConstraint = msgBody.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue)
        textViewHeightConstraint.isActive = true
        msgBody.layoutIfNeeded()
        
        msgBody.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        msgBody.backgroundColor = .white
        msgBody.delegate = self
        msgBody.textColor = UIColor.black
        msgBody.isScrollEnabled = false
        msgBody.text = "Type your message here"
        
        sendButton.makeRound()
        sendButton.setTitle("Send", for: UIControlState())
        sendButton.setButtonFont(FontSizes.caption2.rawValue, weight: UIFontWeightBold, color: .white, alignment: .center)
        sendButton.setDisabled()
        sendButton.backgroundColor = .pulseRed
        msgContainer.layoutIfNeeded()
        
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            sendButton.setEnabled()
            
            let sizeThatFitsTextView = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
            textViewHeightConstraint.constant = sizeThatFitsTextView.height
            containerHeightConstraint.constant = max(IconSizes.medium.rawValue, sizeThatFitsTextView.height)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Type your message here" {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "Type your message here"
            textView.textColor = UIColor.lightGray
            sendButton.setDisabled()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            sendMessage()
            textView.resignFirstResponder()
            return false
        }
        
        return textView.text.characters.count + (text.characters.count - range.length) <= 140
    }
}
