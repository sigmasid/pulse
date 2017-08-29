//
//  MiniMessageVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/2/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class MiniMessageVC: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate {
    
    public var selectedUser : PulseUser!
    public weak var delegate : ModalDelegate?
    
    private var isLoaded = false
    private var observersAdded = false
    
    private var msgContainer = UIView()
    private var msgBody = UITextView()
    private var sendButton = PulseButton()
    
    private var msgBottomContainer : NSLayoutConstraint!
    private var textViewHeightConstraint : NSLayoutConstraint!
    private var containerHeightConstraint: NSLayoutConstraint!
    private var tap: UITapGestureRecognizer!
    private var backgroundView : UIView!
    
    fileprivate var hideStatusBar = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .coverVertical
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !observersAdded {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
            view.backgroundColor = .clear
            
            backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
            view.addSubview(backgroundView)
            
            tap = UITapGestureRecognizer(target: self, action: #selector(dismissMsg))
            tap.cancelsTouchesInView = false
            tap.isEnabled = true
            backgroundView.addGestureRecognizer(tap)
            msgBody.keyboardAppearance = .dark
            msgBody.becomeFirstResponder()
            
            setupQuestionBox()
            
            observersAdded = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        if !isLoaded {
            //For the dismiss touches
            
            
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        msgBody.becomeFirstResponder()
    }
    
    deinit {
        selectedUser = nil
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        backgroundView.removeGestureRecognizer(tap)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    internal func dismissMsg() {
        if delegate != nil {
            msgBody.resignFirstResponder()
            delegate?.userClosedModal(self)
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
    
    internal func sendMessage() {
        guard PulseUser.isLoggedIn(), PulseUser.currentUser.uID! != selectedUser.uID else { return }
        
        let message = Message(from: PulseUser.currentUser, to: selectedUser, body: msgBody.text)
        PulseDatabase.checkExistingConversation(to: selectedUser, completion: { success, conversationID in
            message.mID = success ? conversationID! : nil
            PulseDatabase.sendMessage(existing: success, message: message, completion: {[weak self] (success, _conversationID) in
                guard let `self` = self else { return }
                if success {
                    self.msgBody.text = "Type message here"
                    self.msgBody.textColor = UIColor.lightGray
                    self.sendButton.setDisabled()
                    self.dismissMsg()
                } else {
                    GlobalFunctions.showAlertBlock("Error Sending Message", erMessage: "Sorry we had a problem sending your message. Please try again!")
                }
            })
        })
    }
    
    private func setupQuestionBox() {
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
        msgContainer.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
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
        
        msgBody.font = UIFont.pulseFont(ofWeight: UIFontWeightThin, size: FontSizes.body.rawValue)
        msgBody.backgroundColor = .clear
        msgBody.delegate = self
        msgBody.textColor = UIColor.white
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
            textView.textColor = UIColor.white
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
        
        return textView.text.characters.count + text.characters.count <= POST_TITLE_CHARACTER_COUNT
    }
}
