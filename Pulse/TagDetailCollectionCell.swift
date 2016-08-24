//
//  TagDetailCollectionCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/2/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class TagDetailCollectionCell: UICollectionViewCell {
    var questionLabel: UILabel?
    private var answerPreview : QuestionPreviewVC?
    private var answerPreviewAdded = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        questionLabel = UILabel()
        questionLabel?.setPreferredFont(UIColor.whiteColor(), alignment : .Center)
        
        addSubview(questionLabel!)
        
        questionLabel!.translatesAutoresizingMaskIntoConstraints = false
        questionLabel?.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        questionLabel?.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        questionLabel?.heightAnchor.constraintEqualToAnchor(heightAnchor).active = true
        questionLabel?.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        questionLabel?.layoutIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func showAnswer(_question : Question) {
        answerPreview = QuestionPreviewVC(frame: CGRectMake(0, 0, contentView.bounds.width, contentView.bounds.height))
        answerPreview?.currentQuestion = _question
        questionLabel?.hidden = true
        UIView.transitionWithView( contentView, duration: 0.5, options: .TransitionFlipFromLeft, animations: { _ in self.contentView.addSubview(self.answerPreview!) }, completion: nil)
        answerPreviewAdded = true
    }
    
    func removeAnswer() {
        questionLabel?.hidden = false
        answerPreview?.removeFromSuperview()
    }
    
    override func prepareForReuse() {
        if answerPreviewAdded {
            removeAnswer()
        }
    }
}
