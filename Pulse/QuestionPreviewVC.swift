//
//  QuestionPreviewOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/2/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class QuestionPreviewVC: UIViewController {
    
    fileprivate let _questionLabel = UILabel()
    fileprivate let _answerCount = UIButton()
    
    var questionTitle : String! {
        didSet {
            _questionLabel.text = questionTitle.uppercased()
        }
    }
    
    var numAnswers : Int! {
        didSet {
            _answerCount.setTitle(String(numAnswers), for: UIControlState())
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
        let _rand = arc4random_uniform(UInt32(_backgroundColors.count))
        view.backgroundColor = _backgroundColors[Int(_rand)]
    }
    
    fileprivate func addQuestionLabel() {
        view.addSubview(_questionLabel)
        
        _questionLabel.backgroundColor = UIColor.clear
        _questionLabel.font = UIFont.systemFont(ofSize: 40, weight: UIFontWeightBlack)
        _questionLabel.numberOfLines = 0
        _questionLabel.textAlignment = .center
        _questionLabel.lineBreakMode = .byWordWrapping
        
        _questionLabel.translatesAutoresizingMaskIntoConstraints = false
        _questionLabel.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        _questionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        _questionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    ///Add icon in top left
    fileprivate func addAnswerCount() {
        view.addSubview(_answerCount)
        
        _answerCount.translatesAutoresizingMaskIntoConstraints = false
        _answerCount.widthAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        _answerCount.heightAnchor.constraint(equalTo: _answerCount.widthAnchor).isActive = true
        _answerCount.topAnchor.constraint(equalTo: view.topAnchor, constant: Spacing.m.rawValue).isActive = true
        _answerCount.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.m.rawValue).isActive = true
        _answerCount.layoutIfNeeded()
        
        _answerCount.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 10, 0)
        _answerCount.titleLabel!.font = UIFont.systemFont(ofSize: 25, weight: UIFontWeightBold)
        _answerCount.titleLabel!.textColor = UIColor.white
        _answerCount.titleLabel!.textAlignment = .center
        _answerCount.setBackgroundImage(UIImage(named: "count-label"), for: UIControlState())
        _answerCount.imageView?.contentMode = .scaleAspectFit
    }
    
    func setQuestionLabel(_ qTitle : String?) {

    }
    
    func setNumAnswersLabel(_ numAnswers : Int) {
    }
}
