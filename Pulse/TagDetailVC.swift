//
//  TagDetailVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//
import UIKit

protocol questionPreviewDelegate: class {
    func updateQuestion()
}

class TagDetailVC: UIViewController, questionPreviewDelegate {
    var tagID : String?
    var currentTag : Tag!
    var questionCount = 1
    
    @IBOutlet weak var qPreviewContainer: QuestionPreviewVC?
    @IBOutlet weak var tagImage: UIImageView!
    @IBOutlet weak var tagTitleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let _tagID = self.tagID {
            let tagsPath = databaseRef.child("tags/\(_tagID)")
            tagsPath.observeSingleEventOfType(.Value, withBlock: { snapshot in
                self.currentTag = Tag(tagID: snapshot.key, snapshot: snapshot)
                
                self.currentTag.addObserver(self, forKeyPath: "tagCreated", options: NSKeyValueObservingOptions.New, context: nil)
            })
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadTagData() {
        
        tagTitleLabel.textAlignment = .Left
        tagTitleLabel.text = "#"+(currentTag.tagID!).uppercaseString
        tagTitleLabel.textColor = UIColor.whiteColor()
        tagTitleLabel.alignmentRectInsets()
        let newLabelFrame = CGRectMake(0,0,tagTitleLabel.intrinsicContentSize().width,tagTitleLabel.intrinsicContentSize().height)
        tagTitleLabel.frame = newLabelFrame
        
        tagTitleLabel.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
        
        tagTitleLabel.bottomAnchor.constraintEqualToAnchor(tagImage.bottomAnchor, constant: -newLabelFrame.maxX/2 - 10).active = true
        tagTitleLabel.centerXAnchor.constraintEqualToAnchor(view.leftAnchor, constant: newLabelFrame.maxY/2 + 10).active = true
        tagTitleLabel.heightAnchor.constraintEqualToConstant(newLabelFrame.maxY).active = true
        
        let downloadRef = storageRef.child("tags/\(currentTag.tagImage!)")
        let _ = downloadRef.dataWithMaxSize(1242 * 2208) { (data, error) -> Void in
            if (error != nil) {
                print(error.debugDescription)
            } else {
                self.tagImage.image = UIImage(data: data!)
            }
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "tagCreated" {
            self.loadTagData()
            qPreviewContainer!.currentQuestionID = self.currentTag.questions!.first
            self.currentTag.removeObserver(self, forKeyPath: "tagCreated")
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "containerViewSegue" {
            qPreviewContainer = segue.destinationViewController as? QuestionPreviewVC
            qPreviewContainer?.qPreviewDelegate = self
        }
    }
    
    /* DELEGATE METHODS */
    func updateQuestion() {
        if questionCount < self.currentTag.totalQuestionsForTag() {
            qPreviewContainer?.currentQuestionID = self.currentTag.questions![questionCount]
            questionCount += 1
        }
    }
}
