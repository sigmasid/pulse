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

class TagDetailVC: UIViewController, ParentDelegate {
    var _allQuestions = [Question?]()
    
    var questionCount = 1
    let questionReuseIdentifier = "questionListCell"
    let collectionReuseIdentifier = "collectionQuestionCell"
    
    @IBOutlet var QuestionsTableView: UITableView!
    
    @IBOutlet weak var tagImage: UIImageView!
    @IBOutlet weak var tagTitleLabel: UILabel!
    @IBOutlet weak var toggleButtonView: UIButton!
    
    private var QuestionsCollectionView : UICollectionView?
    private var selectedIndex : NSIndexPath? {
        didSet {
            QuestionsCollectionView?.reloadData()
        }
        willSet {
            if selectedIndex != nil {
                deselectedIndex = selectedIndex
            }
        }
    }
    private var deselectedIndex : NSIndexPath?
    
    var currentTag : Tag!
    var returningToExplore = false
    weak var returnToParentDelegate : ParentDelegate!
    
    private var panStartingPointX : CGFloat = 0
    private var panStartingPointY : CGFloat = 0
    private var _currentView : currentLoadedView?
    
    private enum currentLoadedView : String {
        case tableview = "tableView"
        case collectionview = "collectionView"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        _panGesture.minimumNumberOfTouches = 1
        self.view.addGestureRecognizer(_panGesture)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        if currentTag != nil && !returningToExplore {
            toggleButtonView.makeRound()
            _currentView = .tableview
//            self.qPreviewContainer?.currentQuestionID = currentTag.questions?.first
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
    
    private func loadTagData() {
        tagTitleLabel.text = "#"+(currentTag.tagID!).uppercaseString
        let newLabelFrame = CGRectMake(0,0,tagTitleLabel.intrinsicContentSize().width,tagTitleLabel.intrinsicContentSize().height)
        tagTitleLabel.frame = newLabelFrame
        tagTitleLabel.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
        
        tagTitleLabel.bottomAnchor.constraintEqualToAnchor(toggleButtonView.topAnchor, constant: -newLabelFrame.maxX/2).active = true
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
    
    @IBAction func toggleView(sender: UIButton) {
        if _currentView == .tableview {
            QuestionsTableView.hidden = true
            toggleButtonView.setImage(UIImage(named: "table-list"), forState: .Normal)
            if QuestionsCollectionView == nil {
                setupCollectionView()
            } else {
                QuestionsCollectionView?.hidden = false
            }
            _currentView = .collectionview
        } else {
            QuestionsTableView.hidden = false
            QuestionsCollectionView?.hidden = true
            toggleButtonView.setImage(UIImage(named: "collection-list"), forState: .Normal)
            _currentView = .tableview
        }

    }
    
    private func setupCollectionView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.Vertical
        layout.minimumLineSpacing = Spacing.xs.rawValue
        layout.minimumInteritemSpacing = Spacing.xs.rawValue
        
        QuestionsCollectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
        QuestionsCollectionView!.registerClass(TagDetailCollectionCell.self, forCellWithReuseIdentifier: collectionReuseIdentifier)

        view.addSubview(QuestionsCollectionView!)
        
        QuestionsCollectionView?.translatesAutoresizingMaskIntoConstraints = false
        QuestionsCollectionView?.topAnchor.constraintEqualToAnchor(tagImage.topAnchor, constant: Spacing.s.rawValue).active = true
        QuestionsCollectionView?.bottomAnchor.constraintEqualToAnchor(toggleButtonView.topAnchor, constant: -Spacing.s.rawValue).active = true
        QuestionsCollectionView?.widthAnchor.constraintEqualToAnchor(tagImage.widthAnchor, multiplier: 0.75).active = true
        QuestionsCollectionView?.trailingAnchor.constraintEqualToAnchor(tagImage.trailingAnchor, constant: -Spacing.s.rawValue).active = true
        QuestionsCollectionView?.layoutIfNeeded()
        
        QuestionsCollectionView?.backgroundView = nil
        QuestionsCollectionView?.backgroundColor = UIColor.clearColor()
        QuestionsCollectionView?.showsVerticalScrollIndicator = false
        QuestionsCollectionView?.pagingEnabled = true
        
        QuestionsCollectionView?.delegate = self
        QuestionsCollectionView?.dataSource = self
        QuestionsCollectionView?.reloadData()
    }
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "containerViewSegue" {
//            qPreviewContainer = segue.destinationViewController as? QuestionPreviewVC
//            qPreviewContainer?.qPreviewDelegate = self
//        }
//    }
    
    /* DELEGATE METHODS */
//    func updateContainerQuestion() {
//        if questionCount < self.currentTag.totalQuestionsForTag() {
//            qPreviewContainer?.currentQuestionID = self.currentTag.questions![questionCount]
//            questionCount += 1
//        }
//    }
    
    func showQuestion(_selectedQuestion : Question?, _allQuestions : [Question?], _questionIndex : Int, _selectedTag : Tag) {
        let QAVC = QAManagerVC()
        QAVC.selectedTag = _selectedTag
        QAVC.allQuestions = _allQuestions
        QAVC.currentQuestion = _selectedQuestion
        QAVC.questionCounter = _questionIndex
        QAVC.view.frame = self.view.bounds
        
        QAVC.returnToParentDelegate = self
        
        GlobalFunctions.addNewVC(QAVC, parentVC: self)
    }
    
    func returnToParent(currentVC : UIViewController) {
        returningToExplore = true
        GlobalFunctions.dismissVC(currentVC)
    }
    
    func handlePan(pan : UIPanGestureRecognizer) {
        
        if (pan.state == UIGestureRecognizerState.Began) {
            panStartingPointX = pan.view!.center.x
            panStartingPointY = pan.view!.center.y
            
        } else if (pan.state == UIGestureRecognizerState.Ended) {
            let panFinishingPointX = pan.view!.center.x
            _ = pan.view!.center.y
            
            if (panFinishingPointX > self.view.bounds.width) {
                returnToParentDelegate.returnToParent(self)
            } else {
                self.view.center = CGPoint(x: self.view.bounds.width / 2, y: pan.view!.center.y)
                pan.setTranslation(CGPointZero, inView: self.view)
            }
        } else {
            let translation = pan.translationInView(self.view)
            if translation.x > 0 {
                self.view.center = CGPoint(x: pan.view!.center.x + translation.x, y: pan.view!.center.y)
                pan.setTranslation(CGPointZero, inView: self.view)
            }
        }
    }
}

extension TagDetailVC : UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentTag.totalQuestionsForTag()!
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(questionReuseIdentifier) as! TagDetailQuestionCell
        cell.backgroundColor = UIColor.clearColor()
        let _cellLabel = cell.questionLabel
        _cellLabel.userInteractionEnabled = false

        if _allQuestions.count > indexPath.row {
            let _currentQuestion = self._allQuestions[indexPath.row]
            _cellLabel.text = _currentQuestion?.qTitle
        } else {
            Database.getQuestion(currentTag.questions![indexPath.row], completion: { (question, error) in
                if error == nil {
                    self._allQuestions.append(question)
                    _cellLabel.text = question.qTitle
                }
            })
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let _selectedQuestion = _allQuestions[indexPath.row] {
            showQuestion(_selectedQuestion, _allQuestions: _allQuestions, _questionIndex: indexPath.row, _selectedTag: currentTag)
        }
    }
}

/* COLLECTION VIEW */
extension TagDetailVC : UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentTag.totalQuestionsForTag()!
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int{
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(collectionReuseIdentifier, forIndexPath: indexPath) as! TagDetailCollectionCell
        let _rand = arc4random_uniform(UInt32(_backgroundColors.count))
        cell.contentView.backgroundColor = _backgroundColors[Int(_rand)].colorWithAlphaComponent(0.4)
        
        if _allQuestions.count > indexPath.row {
            let _currentQuestion = _allQuestions[indexPath.row]
            cell.questionLabel!.text = _currentQuestion?.qTitle
        } else {
            Database.getQuestion(currentTag.questions![indexPath.row], completion: { (question, error) in
                if error == nil {
                    self._allQuestions.append(question)
                    cell.questionLabel!.text = question.qTitle
                }
            })
        }
        
        if indexPath == selectedIndex && indexPath == deselectedIndex {
            if let _selectedQuestion = _allQuestions[indexPath.row] {
                showQuestion(_selectedQuestion, _allQuestions: _allQuestions, _questionIndex: indexPath.row, _selectedTag: currentTag)
            }
        } else if indexPath == selectedIndex {
            if let _selectedQuestion = _allQuestions[indexPath.row] {
                if _selectedQuestion.hasAnswers() {
                    cell.showAnswer(_selectedQuestion)
                }
            }
        } else if indexPath == deselectedIndex {
            cell.removeAnswer()
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedIndex = indexPath
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}

extension TagDetailVC: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: (QuestionsCollectionView!.frame.width - (Spacing.xs.rawValue * 2)) / 2, height: QuestionsCollectionView!.frame.height / 3)
    }
}
