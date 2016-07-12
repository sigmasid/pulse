//
//  TagDetailVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//
import UIKit

protocol questionPreviewDelegate: class {
    func updateContainerQuestion()
}

class TagDetailVC: UIViewController, questionPreviewDelegate {
    var _allQuestions = [Question?]()
    
    var questionCount = 1
    let questionReuseIdentifier = "questionListCell"
    
    @IBOutlet var QuestionsTableView: UITableView!
    @IBOutlet weak var qPreviewContainer: QuestionPreviewVC?
    @IBOutlet weak var tagImage: UIImageView!
    @IBOutlet weak var tagTitleLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    var currentTag : Tag!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if currentTag != nil {
            print("set container question")
            self.qPreviewContainer?.currentQuestionID = currentTag.questions?.first
            loadTagData()
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
        /* FIX THIS WITH NSLAYOUTANCHORS */
        tagTitleLabel.text = "#"+(currentTag.tagID!).uppercaseString
        tagTitleLabel.alignmentRectInsets()
        let newLabelFrame = CGRectMake(0,0,tagTitleLabel.intrinsicContentSize().width,tagTitleLabel.intrinsicContentSize().height)
        tagTitleLabel.frame = newLabelFrame
        
        tagTitleLabel.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
        
        tagTitleLabel.bottomAnchor.constraintEqualToAnchor(tagImage.bottomAnchor, constant: -newLabelFrame.maxX/2 - 10).active = true
        tagTitleLabel.centerXAnchor.constraintEqualToAnchor(view.leftAnchor, constant: newLabelFrame.maxY/2 + 10).active = true
        tagTitleLabel.heightAnchor.constraintEqualToConstant(newLabelFrame.maxY).active = true
        
        if let _tagImage = currentTag.tagImage {
            Database.getImage(_tagImage, completion: {(data, error) in
                if error != nil {
                    print (error?.localizedDescription)
                } else {
                    self.tagImage.image = UIImage(data: data!)
                }
            })
        }
    }
    
    func loadQuestion() {


    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "tagCreated" {
            print("tag created success")
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
    func updateContainerQuestion() {
        if questionCount < self.currentTag.totalQuestionsForTag() {
            qPreviewContainer?.currentQuestionID = self.currentTag.questions![questionCount]
            questionCount += 1
        }
    }
    
    func showQuestion(_selectedQuestion : Question?, _allQuestions : [Question?], _questionIndex : Int) {
        let QAVC = QAManagerVC()
        QAVC.selectedTag = currentTag
        QAVC.allQuestions = _allQuestions
        QAVC.currentQuestion = _selectedQuestion
        QAVC.questionCounter = _questionIndex
        QAVC.view.frame = self.view.bounds
        
//        QAVC.exploreDelegate = self
        
        self.presentViewController(QAVC, animated: true, completion: nil)
    }
    
    //    func loadMoreQuestions(indexPath  : NSIndexPath) {
    //        if questionsShown == _totalQuestions {
    //            loadingStatus = .Finished
    //            return
    //        } else if questionsShown + questionsIncrement < _totalQuestions {
    //            questionsShown += questionsIncrement
    //            ExploreQuestions.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Left, animated: true)
    //            ExploreQuestions.reloadData()
    //            return
    //        } else {
    //            questionsShown += _totalQuestions - questionsShown
    //            ExploreQuestions.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Left, animated: true)
    //            loadingStatus = .Finished
    //            return
    //        }
    //    }
}

extension TagDetailVC : UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentTag.totalQuestionsForTag()!
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(questionReuseIdentifier) as! TagDetailQuestionCell
        cell.backgroundColor = UIColor.clearColor()
        let _cellTextView = cell.questionTextView

        if _allQuestions.count > indexPath.row {
            let _currentQuestion = self._allQuestions[indexPath.row]
            _cellTextView.text = _currentQuestion?.qTitle
        } else {
            let questionRef = databaseRef.child("questions/\(self.currentTag.questions![indexPath.row])")
            questionRef.observeSingleEventOfType(.Value, withBlock: { snap in
                let _currentQuestion = Question(qID: snap.key, snapshot: snap)
                self._allQuestions.append(_currentQuestion)
                _cellTextView.text = snap.childSnapshotForPath("title").value as? String
            })
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let _selectedQuestion = self._allQuestions[indexPath.row]
//        delegate.showQuestion(_selectedQuestion, _allQuestions: self._allQuestions, _questionIndex: indexPath.row)
    }
}
