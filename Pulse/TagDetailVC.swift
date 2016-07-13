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

class TagDetailVC: UIViewController, questionPreviewDelegate, ExploreDelegate {
    var _allQuestions = [Question?]()
    
    var questionCount = 1
    let questionReuseIdentifier = "questionListCell"
    
    @IBOutlet var QuestionsTableView: UITableView!
    @IBOutlet weak var qPreviewContainer: QuestionPreviewVC?
    @IBOutlet weak var tagImage: UIImageView!
    @IBOutlet weak var tagTitleLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    var currentTag : Tag!
    var returningToExplore = false
    var _exploreDelegate : ExploreDelegate!
    
    private var panStartingPointX : CGFloat = 0
    private var panStartingPointY : CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        _panGesture.minimumNumberOfTouches = 1
        self.view.addGestureRecognizer(_panGesture)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
    
        if currentTag != nil && !returningToExplore {
            self.qPreviewContainer?.currentQuestionID = currentTag.questions?.first
            loadTagData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func loadTagData() {
        tagTitleLabel.text = "#"+(currentTag.tagID!).uppercaseString
        tagTitleLabel.alignmentRectInsets()
        let newLabelFrame = CGRectMake(0,0,tagTitleLabel.intrinsicContentSize().width,tagTitleLabel.intrinsicContentSize().height)
        tagTitleLabel.frame = newLabelFrame
        
        tagTitleLabel.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
        
        tagTitleLabel.bottomAnchor.constraintEqualToAnchor(tagImage.bottomAnchor, constant: -newLabelFrame.maxX/2 - 10).active = true
        tagTitleLabel.centerXAnchor.constraintEqualToAnchor(view.leftAnchor, constant: newLabelFrame.maxY/2 + 10).active = true
        tagTitleLabel.heightAnchor.constraintEqualToConstant(newLabelFrame.maxY).active = true
        
        if let _tagImage = currentTag.tagImage {
            Database.getTagImage(_tagImage, maxImgSize: maxImgSize, completion: {(data, error) in
                if error != nil {
                    print (error?.localizedDescription)
                } else {
                    self.tagImage.image = UIImage(data: data!)
                }
            })
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
    
    func showQuestion(_selectedQuestion : Question?, _allQuestions : [Question?], _questionIndex : Int, _selectedTag : Tag) {
        let QAVC = QAManagerVC()
        QAVC.selectedTag = _selectedTag
        QAVC.allQuestions = _allQuestions
        QAVC.currentQuestion = _selectedQuestion
        QAVC.questionCounter = _questionIndex
        QAVC.view.frame = self.view.bounds
        
        QAVC.exploreDelegate = self
        
        GlobalFunctions.addNewVC(QAVC, parentVC: self)
    }
    
    func returnToExplore(currentVC : UIViewController) {
        returningToExplore = true
        GlobalFunctions.dismissVC(currentVC)
    }
    
    func handlePan(pan : UIPanGestureRecognizer) {
        
        if (pan.state == UIGestureRecognizerState.Began) {
            panStartingPointX = pan.view!.center.x
            panStartingPointY = pan.view!.center.y
            
        } else if (pan.state == UIGestureRecognizerState.Ended) {
            let panFinishingPointX = pan.view!.center.x
            let panFinishingPointY = pan.view!.center.y
            
            if (panFinishingPointX > self.view.bounds.width) {
                _exploreDelegate.returnToExplore(self)
            } else {
                self.view.center = CGPoint(x: self.view.bounds.width / 2, y: pan.view!.center.y)
                pan.setTranslation(CGPointZero, inView: self.view)
            }
        } else {
            let translation = pan.translationInView(self.view)
            self.view.center = CGPoint(x: pan.view!.center.x + translation.x, y: pan.view!.center.y)
            pan.setTranslation(CGPointZero, inView: self.view)
        }
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
        _cellTextView.userInteractionEnabled = false

        if _allQuestions.count > indexPath.row {
            let _currentQuestion = self._allQuestions[indexPath.row]
            _cellTextView.text = _currentQuestion?.qTitle
        } else {
            Database.getQuestion(currentTag.questions![indexPath.row], completion: { (question, error) in
                if error == nil {
                    self._allQuestions.append(question)
                    _cellTextView.text = question.qTitle
                }
            })
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let _selectedQuestion = _allQuestions[indexPath.row]
        showQuestion(_selectedQuestion, _allQuestions: _allQuestions, _questionIndex: indexPath.row, _selectedTag: currentTag)
    }
}
