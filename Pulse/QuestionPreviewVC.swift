//
//  QuestionPreviewOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/2/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class ContentIntroVC: UIViewController {
    
    fileprivate let questionLabel = UILabel()
    fileprivate let answerCount = UIButton()
    fileprivate var imageView = UIImageView()
    
    public var itemTitle : String! {
        didSet {
            if itemTitle != nil {
                questionLabel.text = itemTitle.uppercased()
            }
        }
    }
    
    public var numAnswers : Int! {
        didSet {
            answerCount.setTitle(String(numAnswers), for: UIControlState())
        }
    }
    
    public var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white

        addBackgroundImage()
        addQuestionLabel()
        addAnswerCount()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        imageView.image = nil
    }
    
    fileprivate func addBackgroundImage() {
        view.addSubview(imageView)
        imageView.frame = view.frame
        imageView.contentMode = .scaleAspectFill
    }
    
    fileprivate func addQuestionLabel() {
        view.addSubview(questionLabel)
        
        questionLabel.backgroundColor = UIColor.clear
        questionLabel.font = UIFont.systemFont(ofSize: 40, weight: UIFontWeightBlack)
        questionLabel.numberOfLines = 0
        questionLabel.textAlignment = .center
        questionLabel.lineBreakMode = .byWordWrapping
        
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        questionLabel.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        questionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        questionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    ///Add icon in top left
    fileprivate func addAnswerCount() {
        view.addSubview(answerCount)
        
        answerCount.translatesAutoresizingMaskIntoConstraints = false
        answerCount.widthAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        answerCount.heightAnchor.constraint(equalTo: answerCount.widthAnchor).isActive = true
        answerCount.topAnchor.constraint(equalTo: view.topAnchor, constant: Spacing.m.rawValue).isActive = true
        answerCount.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.m.rawValue).isActive = true
        answerCount.layoutIfNeeded()
        
        answerCount.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 10, 0)
        answerCount.titleLabel!.font = UIFont.systemFont(ofSize: 25, weight: UIFontWeightBold)
        answerCount.titleLabel!.textColor = UIColor.white
        answerCount.titleLabel!.textAlignment = .center
        answerCount.setBackgroundImage(UIImage(named: "count-label"), for: UIControlState())
        answerCount.imageView?.contentMode = .scaleAspectFit
    }
    
    func setQuestionLabel(_ qTitle : String?) {

    }
    
    func setNumAnswersLabel(_ numAnswers : Int) {
    }
}
