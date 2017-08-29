//
//  askQuestionVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 11/18/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

class AskQuestionVC: PulseVC, UITextViewDelegate, UIGestureRecognizerDelegate {
    
    public var selectedTag : Item!
    public var selectedUser : PulseUser!
    public weak var modalDelegate : ModalDelegate!
    
    fileprivate var questionContainer = UIView()
    fileprivate var questionBody = UITextView()
    fileprivate var askButton = PulseButton()
    
    fileprivate var questionBottomConstraint : NSLayoutConstraint!
    fileprivate var textViewHeightConstraint : NSLayoutConstraint!
    fileprivate var containerHeightConstraint: NSLayoutConstraint!
    fileprivate var tap: UITapGestureRecognizer!
    
    fileprivate var observersAdded = false
    private var cleanupComplete = false
    
    fileprivate var hideStatusBar = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !observersAdded {
            tabBarHidden = true
            
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
            view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

            tap = UITapGestureRecognizer(target: self, action: #selector(dismissAsk))
            tap.cancelsTouchesInView = false
            tap.isEnabled = true
            tap.delegate = self
            view.addGestureRecognizer(tap)
            
            observersAdded = true
        }
    }
    
    deinit {
        performCleanup()
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            cleanupComplete = true
            selectedTag = nil
            selectedUser = nil
            modalDelegate = nil
            tap = nil
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    override func viewDidLayoutSubviews() {
        if !isLoaded {
            setupQuestionBox()
            questionBody.becomeFirstResponder()
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view == askButton {
            return false
        }
        
        return true
    }
    
    func dismissAsk() {
        if modalDelegate != nil {
            questionBody.resignFirstResponder()
            modalDelegate.userClosedModal(self)
            performCleanup()
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            questionBottomConstraint.constant = -keyboardHeight - (tabBarController?.tabBar.frame.height ?? 0)
            questionContainer.layoutIfNeeded()
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        questionBottomConstraint.constant = 0
        questionContainer.layoutIfNeeded()
    }
    
    func askQuestion() {
        askButton.setDisabled()
        askButton.setTitle(nil, for: .normal)
        let _loadingIndicator = askButton.addLoadingIndicator()
        dismissKeyboard()
        
        if selectedTag != nil {
            PulseDatabase.askQuestion(parentItem: selectedTag, qText: questionBody.text, completion: {[weak self] (success, error) in
                guard let `self` = self else { return }
                
                if success {
                    let questionConfirmation = UIAlertController(title: "Question Posted!",
                                                                 message: "Thanks for your question. You will get a notification as soon as someone posts an answer",
                                                                 preferredStyle: .actionSheet)
                    
                    questionConfirmation.addAction(UIAlertAction(title: "done",
                                                                 style: .default,
                                                                 handler: {[weak self] (action: UIAlertAction!) in
                            guard let `self` = self else { return }
                            self.dismissAsk()
                    }))
                    
                    self.askButton.setEnabled()
                    self.askButton.removeLoadingIndicator(_loadingIndicator)
                    self.askButton.setTitle("Ask", for: .normal)
                    
                    self.present(questionConfirmation, animated: true, completion: nil)
                } else {
                    let questionConfirmation = UIAlertController(title: "Error Posting Question",
                                                                 message: error?.localizedDescription,
                                                                 preferredStyle: .actionSheet)
                    
                    questionConfirmation.addAction(UIAlertAction(title: "okay", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                        guard let `self` = self else { return }
                        self.dismissAsk()
                    }))
                    
                    self.askButton.setEnabled()
                    self.askButton.removeLoadingIndicator(_loadingIndicator)
                    self.askButton.setTitle("Ask", for: .normal)
                    
                    self.present(questionConfirmation, animated: true, completion: nil)
                }
            })
        } else if selectedUser != nil {
            PulseDatabase.askUserQuestion(askUserID: selectedUser.uID!, qText: questionBody.text, completion: {[weak self] (success, error) in
                guard let `self` = self else { return }
                
                if success {
                    let personName = self.selectedUser.name ?? " the user"
                    let questionConfirmation = UIAlertController(title: "Question Posted!",
                                                                 message: "Thanks for your question. You will get a notification as soon as \(personName) responds",
                                                                preferredStyle: .actionSheet)
                    
                    questionConfirmation.addAction(UIAlertAction(title: "done", style: .default, handler: {[weak self] (action: UIAlertAction!) in
                        guard let `self` = self else { return }
                        self.dismissAsk()
                    }))
                    
                    self.askButton.setEnabled()
                    self.askButton.removeLoadingIndicator(_loadingIndicator)
                    self.present(questionConfirmation, animated: true, completion: nil)
                    
                } else {
                    let questionConfirmation = UIAlertController(title: "Error Posting Question", message: error?.localizedDescription, preferredStyle: .actionSheet)
                    
                    questionConfirmation.addAction(UIAlertAction(title: "okay", style: .default, handler: {(action: UIAlertAction!) in
                        questionConfirmation.dismiss(animated: true, completion: nil)
                    }))
                    
                    self.askButton.setEnabled()
                    self.askButton.removeLoadingIndicator(_loadingIndicator)
                    self.present(questionConfirmation, animated: true, completion: nil)
                }
            })
        }
    }
    
    fileprivate func setupQuestionBox() {
        view.addSubview(questionContainer)
        
        questionContainer.addSubview(questionBody)
        questionContainer.addSubview(askButton)
        
        questionContainer.translatesAutoresizingMaskIntoConstraints = false
        questionBottomConstraint = questionContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        questionBottomConstraint.isActive = true
        questionContainer.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        questionContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        questionContainer.backgroundColor = .white
        
        askButton.translatesAutoresizingMaskIntoConstraints = false
        askButton.trailingAnchor.constraint(equalTo: questionContainer.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        askButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        askButton.widthAnchor.constraint(equalTo: askButton.heightAnchor).isActive = true
        askButton.centerYAnchor.constraint(equalTo: questionContainer.centerYAnchor).isActive = true
        askButton.layoutIfNeeded()
        
        questionBody.translatesAutoresizingMaskIntoConstraints = false
        questionBody.centerYAnchor.constraint(equalTo: questionContainer.centerYAnchor).isActive = true
        questionBody.leadingAnchor.constraint(equalTo: questionContainer.leadingAnchor).isActive = true
        questionBody.trailingAnchor.constraint(equalTo: askButton.leadingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        
        questionBody.setFont(FontSizes.body.rawValue, weight: UIFontWeightThin, color: .black, alignment: .left)
        questionBody.backgroundColor = .white
        questionBody.delegate = self
        questionBody.isScrollEnabled = false
        questionBody.text = "Type your question here"
        
        let sizeThatFitsTextView = questionBody.sizeThatFits(CGSize(width: questionBody.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        textViewHeightConstraint = questionBody.heightAnchor.constraint(equalToConstant: sizeThatFitsTextView.height)
        containerHeightConstraint = questionContainer.heightAnchor.constraint(equalToConstant: max(IconSizes.medium.rawValue, sizeThatFitsTextView.height))
        textViewHeightConstraint.isActive = true
        containerHeightConstraint.isActive = true
        
        questionContainer.layoutIfNeeded()
        questionBody.layoutIfNeeded()

        askButton.makeRound()
        askButton.setTitle("Ask", for: UIControlState())
        askButton.setButtonFont(FontSizes.caption2.rawValue, weight: UIFontWeightBold, color: .white, alignment: .center)
        askButton.setDisabled()
        askButton.backgroundColor = .pulseRed
        questionContainer.layoutIfNeeded()
        
        askButton.addTarget(self, action: #selector(askQuestion), for: .touchUpInside)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            askButton.setEnabled()
            
            let sizeThatFitsTextView = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
            textViewHeightConstraint.constant = sizeThatFitsTextView.height
            containerHeightConstraint.constant = max(IconSizes.medium.rawValue, sizeThatFitsTextView.height)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Type your question here" {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "Type your question here"
            textView.textColor = UIColor.lightGray
            askButton.setDisabled()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            askQuestion()
            textView.resignFirstResponder()
            return false
        }
        
        return textView.text.characters.count + text.characters.count <= POST_TITLE_CHARACTER_COUNT
    }
}
