//
//  askQuestionVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 11/18/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AskQuestionVC: UIViewController, UITextViewDelegate {
    
    public var selectedTag : Tag! {
        didSet {
            setAskTag()
        }
    }
    
    public var selectedUser : User!  {
        didSet {
            setAskUser()
        }
    }
    
    fileprivate var isLoaded = false
    fileprivate var questionBody = UITextView()
    fileprivate var postButton = PulseButton()
    
    fileprivate var questionTo = UIView()
    fileprivate var questionToTitle = UILabel()
    fileprivate var questionToSubtitle = UILabel()
    
    fileprivate var hideStatusBar = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLoaded {
            updateHeader()
            setupQuestionTo()
            setupQuestionBox()
            
            view.backgroundColor = UIColor.white
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden: Bool {
        return hideStatusBar
    }
    
    fileprivate func updateHeader() {
        let backButton = PulseButton(size: .small, type: .back, isRound : true, hasBackground: true)
        backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        if let nav = navigationController as? PulseNavVC {
            nav.setNav(navTitle: "Ask Question", screenTitle: nil, screenImage: nil)
            nav.shouldShowScope = false
        } else {
            title = "Ask Question"
        }
    }
    
    func goBack() {
        let _ = navigationController?.popViewController(animated: true)
    }
    
    func askQuestion() {
        

        if selectedTag != nil {
            Database.askTagQuestion(tagID: selectedTag.tagID!, qText: questionBody.text, completion: {(success, error) in
                if success {
                    let questionConfirmation = UIAlertController(title: "Question Posted!", message: "Thanks for your question. You will get a notification as soon as someone posts an answer", preferredStyle: .actionSheet)
                    
                    questionConfirmation.addAction(UIAlertAction(title: "done", style: .default, handler: { (action: UIAlertAction!) in
                        self.goBack()
                    }))
                    
                    self.present(questionConfirmation, animated: true, completion: nil)

                    
                } else {
                    let questionConfirmation = UIAlertController(title: "Error Posting Question", message: error?.localizedDescription, preferredStyle: .actionSheet)
                    
                    questionConfirmation.addAction(UIAlertAction(title: "okay", style: .default, handler: { (action: UIAlertAction!) in
                        questionConfirmation.dismiss(animated: true, completion: nil)
                    }))
                    
                    self.present(questionConfirmation, animated: true, completion: nil)
                    
                }
            })
        }
    }
    
    fileprivate func setAskUser() {
        guard selectedUser != nil else { return }
        
        questionToTitle.text = selectedUser.name!.capitalized
        questionToSubtitle.text = selectedUser.shortBio
        questionBody.text = "ask \(selectedUser.name!.capitalized) your question"
    }
    
    fileprivate func setAskTag() {
        guard selectedTag != nil else { return }

        questionToTitle.text = selectedTag.tagID!.capitalized
        questionToSubtitle.text = selectedTag.tagDescription
        questionBody.text = "ask experts about \(selectedTag.tagID!.capitalized)"
    }
    
    fileprivate func setupQuestionBox() {
        view.addSubview(questionBody)
        view.addSubview(postButton)
        
        questionBody.translatesAutoresizingMaskIntoConstraints = false
        questionBody.topAnchor.constraint(equalTo: questionTo.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        questionBody.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        questionBody.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        questionBody.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        questionBody.layoutIfNeeded()
        
        questionBody.backgroundColor = UIColor.white
        questionBody.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        questionBody.textColor = UIColor.black
        questionBody.layer.borderColor = UIColor.lightGray.cgColor
        questionBody.layer.borderWidth = 1.0
        
        questionBody.text = "Type your question here"
        questionBody.textColor = UIColor.lightGray
        questionBody.delegate = self
        
        postButton.translatesAutoresizingMaskIntoConstraints = false
        postButton.topAnchor.constraint(equalTo: questionBody.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        postButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        postButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        postButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        postButton.layoutIfNeeded()
        
        postButton.makeRound()
        postButton.setTitle("Ask Question", for: UIControlState())
        postButton.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        postButton.setDisabled()
        
        postButton.addTarget(self, action: #selector(askQuestion), for: .touchUpInside)
    }
    
    fileprivate func setupQuestionTo() {
        view.addSubview(questionTo)
        
        questionTo.translatesAutoresizingMaskIntoConstraints = false
        questionTo.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        questionTo.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        questionTo.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        questionTo.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        questionTo.addSubview(questionToTitle)
        questionTo.addSubview(questionToSubtitle)
        
        questionToTitle.translatesAutoresizingMaskIntoConstraints = false
        questionToTitle.centerXAnchor.constraint(equalTo: questionTo.centerXAnchor).isActive = true
        questionToTitle.topAnchor.constraint(equalTo: questionTo.topAnchor).isActive = true
        
        questionToTitle.setFont(FontSizes.body.rawValue, weight: UIFontWeightBold, color: UIColor.black, alignment: .center)
        
        questionToSubtitle.translatesAutoresizingMaskIntoConstraints = false
        questionToSubtitle.centerXAnchor.constraint(equalTo: questionTo.centerXAnchor).isActive = true
        questionToSubtitle.topAnchor.constraint(equalTo: questionToTitle.bottomAnchor).isActive = true
        questionToSubtitle.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        
        questionToSubtitle.numberOfLines = 0
        questionToSubtitle.lineBreakMode = .byWordWrapping
        questionToSubtitle.layoutIfNeeded()
        
        questionToSubtitle.setFont(FontSizes.caption.rawValue, weight: UIFontWeightRegular, color: UIColor.gray, alignment: .center)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if textView.text == "Type your question here" {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            postButton.setEnabled()
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "Type your question here"
            textView.textColor = UIColor.lightGray
            postButton.setDisabled()
        }
    }
}
