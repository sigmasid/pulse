//
//  askQuestionVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 11/18/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

protocol ParentDelegate: class {
    func dismiss(_ viewController : UIViewController)
}

class AskQuestionVC: PulseVC, UITextViewDelegate {
    
    public var selectedTag : Item!
    public var selectedUser : User!
    public var delegate : ParentDelegate!
    
    fileprivate var isLoaded = false
    fileprivate var observersAdded = false
    
    fileprivate var questionContainer = UIView()
    fileprivate var questionBody = UITextView()
    fileprivate var askButton = PulseButton()
    
    fileprivate var questionBottomConstraint : NSLayoutConstraint!
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
            tabBarHidden = true
            
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
            view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

            tap = UITapGestureRecognizer(target: self, action: #selector(dismissAsk))
            tap.cancelsTouchesInView = false
            tap.isEnabled = true
            view.addGestureRecognizer(tap)
            
            observersAdded = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        if !isLoaded {
            setupQuestionBox()
            questionBody.becomeFirstResponder()
            
            isLoaded = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.removeGestureRecognizer(tap)
    }
    
    func dismissAsk() {
        if delegate != nil {
            questionBody.resignFirstResponder()
            delegate.dismiss(self)
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            questionBottomConstraint.constant = -keyboardHeight - (tabBarController?.tabBar.frame.height ?? 0) - Spacing.m.rawValue
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
            Database.askQuestion(item: selectedTag, qText: questionBody.text, completion: {(success, error) in
                if success {
                    let questionConfirmation = UIAlertController(title: "Question Posted!",
                                                                 message: "Thanks for your question. You will get a notification as soon as someone posts an answer",
                                                                 preferredStyle: .actionSheet)
                    
                    questionConfirmation.addAction(UIAlertAction(title: "done",
                                                                 style: .default,
                                                                 handler: { (action: UIAlertAction!) in
                            self.dismissAsk()
                    }))
                    
                    self.present(questionConfirmation, animated: true, completion: nil)
                    self.askButton.setEnabled()
                    self.askButton.removeLoadingIndicator(_loadingIndicator)
                    self.askButton.setTitle("Ask", for: .normal)

                } else {
                    let questionConfirmation = UIAlertController(title: "Error Posting Question",
                                                                 message: error?.localizedDescription,
                                                                 preferredStyle: .actionSheet)
                    
                    questionConfirmation.addAction(UIAlertAction(title: "okay",
                                                                 style: .default,
                                                                 handler: { (action: UIAlertAction!) in
                        questionConfirmation.dismiss(animated: true, completion: nil)
                    }))
                    
                    self.present(questionConfirmation, animated: true, completion: nil)
                    self.askButton.setEnabled()
                    self.askButton.removeLoadingIndicator(_loadingIndicator)
                    self.askButton.setTitle("Ask", for: .normal)

                }
            })
        } else if selectedUser != nil {
            Database.askUserQuestion(askUserID: selectedUser.uID!, qText: questionBody.text, completion: {(success, error) in
                if success {
                    let questionConfirmation = UIAlertController(title: "Question Posted!", message: "Thanks for your question. You will get a notification as soon as \(self.selectedUser.name) responds", preferredStyle: .actionSheet)
                    
                    questionConfirmation.addAction(UIAlertAction(title: "done", style: .default, handler: { (action: UIAlertAction!) in
                        self.dismissAsk()
                    }))
                    
                    self.present(questionConfirmation, animated: true, completion: nil)
                    self.askButton.setEnabled()
                    self.askButton.removeLoadingIndicator(_loadingIndicator)
                    
                } else {
                    let questionConfirmation = UIAlertController(title: "Error Posting Question", message: error?.localizedDescription, preferredStyle: .actionSheet)
                    
                    questionConfirmation.addAction(UIAlertAction(title: "okay", style: .default, handler: { (action: UIAlertAction!) in
                        questionConfirmation.dismiss(animated: true, completion: nil)
                    }))
                    
                    self.present(questionConfirmation, animated: true, completion: nil)
                    self.askButton.setEnabled()
                    self.askButton.removeLoadingIndicator(_loadingIndicator)

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
        containerHeightConstraint = questionContainer.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue)
        containerHeightConstraint.isActive = true
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
        
        textViewHeightConstraint = questionBody.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue)
        textViewHeightConstraint.isActive = true
        questionBody.layoutIfNeeded()
        
        questionBody.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightThin)
        questionBody.backgroundColor = .white
        questionBody.delegate = self
        questionBody.textColor = UIColor.black
        questionBody.isScrollEnabled = false
        questionBody.text = "Type your question here"

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
        
        return textView.text.characters.count + (text.characters.count - range.length) <= 140
    }
}
