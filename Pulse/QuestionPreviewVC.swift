//
//  QuestionPreviewOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/2/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class QuestionPreviewVC: UIViewController {
    
    fileprivate let questionLabel = UILabel()
    fileprivate let answerCount = UIButton()
    
    var questionTitle : String! {
        didSet {
            if questionTitle != nil {
                questionLabel.text = questionTitle.uppercased()
            }
        }
    }
    
    var numAnswers : Int! {
        didSet {
            answerCount.setTitle(String(numAnswers), for: UIControlState())
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBackgroundColor()
        addQuestionLabel()
        addAnswerCount()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    fileprivate func addBackgroundColor() {
//        let _rand = arc4random_uniform(UInt32(_backgroundColors.count))
//        view.backgroundColor = _backgroundColors[Int(_rand)]
        
        view.backgroundColor = UIColor.white
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
