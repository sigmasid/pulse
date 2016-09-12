//
//  QuestionPreviewOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/2/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class QuestionPreviewVC: UIViewController {
    
    private let _questionLabel = UILabel()
    private let _answerCount = UIButton()
    
    var questionTitle : String! {
        didSet {
            _questionLabel.text = questionTitle.uppercaseString
        }
    }
    
    var numAnswers : Int! {
        didSet {
            _answerCount.setTitle(String(numAnswers), forState: .Normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBackgroundColor()
        addQuestionLabel()
        addAnswerCount()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    private func addBackgroundColor() {
        let _rand = arc4random_uniform(UInt32(_backgroundColors.count))
        view.backgroundColor = _backgroundColors[Int(_rand)]
    }
    
    private func addQuestionLabel() {
        view.addSubview(_questionLabel)
        
        _questionLabel.backgroundColor = UIColor.clearColor()
        _questionLabel.font = UIFont.systemFontOfSize(40, weight: UIFontWeightBlack)
        _questionLabel.numberOfLines = 0
        _questionLabel.textAlignment = .Center
        _questionLabel.lineBreakMode = .ByWordWrapping
        
        _questionLabel.translatesAutoresizingMaskIntoConstraints = false
        _questionLabel.widthAnchor.constraintEqualToAnchor(view.widthAnchor).active = true
        _questionLabel.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        _questionLabel.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true
    }
    
    ///Add icon in top left
    private func addAnswerCount() {
        view.addSubview(_answerCount)
        
        _answerCount.translatesAutoresizingMaskIntoConstraints = false
        _answerCount.widthAnchor.constraintEqualToConstant(IconSizes.Large.rawValue).active = true
        _answerCount.heightAnchor.constraintEqualToAnchor(_answerCount.widthAnchor).active = true
        _answerCount.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: Spacing.m.rawValue).active = true
        _answerCount.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor, constant: -Spacing.m.rawValue).active = true
        _answerCount.layoutIfNeeded()
        
        _answerCount.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 10, 0)
        _answerCount.titleLabel!.font = UIFont.systemFontOfSize(25, weight: UIFontWeightBold)
        _answerCount.titleLabel!.textColor = UIColor.whiteColor()
        _answerCount.titleLabel!.textAlignment = .Center
        _answerCount.setBackgroundImage(UIImage(named: "count-label"), forState: .Normal)
        _answerCount.imageView?.contentMode = .ScaleAspectFit
    }
    
    func setQuestionLabel(qTitle : String?) {

    }
    
    func setNumAnswersLabel(numAnswers : Int) {
    }
}
