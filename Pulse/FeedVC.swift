//
//  FeedVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class FeedVC: UIViewController, ParentDelegate {
    
    var pageType : PageType! {
        didSet {
            switch pageType! {
            case .Home:
                setupScreenLayout(pageType)
            case .Detail:
                setupDetailView()
                setupScreenLayout(pageType)
            }
        }
    }
    
    var feedItemType : FeedItemType! {
        didSet {
            switch feedItemType! {
            case .Question:
                if !returningToExplore {
                    totalItemCount = currentTag!.totalQuestionsForTag()
                    _allQuestions = [Question?](count: totalItemCount, repeatedValue: nil)
                }
            case .Answer:
                if !returningToExplore {
                    totalItemCount = currentQuestion!.totalAnswers()
                    gettingImageForCell = [Bool](count: totalItemCount, repeatedValue: false)
                    gettingInfoForCell = [Bool](count: totalItemCount, repeatedValue: false)
                    browseAnswerPreviewImages = [UIImage?](count: totalItemCount, repeatedValue: nil)
                    usersForAnswerPreviews = [User?](count: totalItemCount, repeatedValue: nil)
                }
            case .Tag: return
            }
            if pageType! == .Detail {
                updateTitleTag()
            }
            FeedCollectionView?.delegate = self
            FeedCollectionView?.dataSource = self
            FeedCollectionView?.reloadData()
        }
    }

    var currentTag : Tag!
    var currentQuestion : Question!
    private var totalItemCount = 0
    
    /* cache questions & answers that have been shown */
    private var _allQuestions : [Question?]!
    private var gettingImageForCell : [Bool]!
    private var gettingInfoForCell : [Bool]!
    private var browseAnswerPreviewImages : [UIImage?]!
    private var usersForAnswerPreviews : [User?]!
    
    let collectionReuseIdentifier = "FeedCell"
    var questionCount = 1
    
    private lazy var titleLabel = UILabel()
    private lazy var rotatedView = UIView()
    private lazy var backgroundImage = UIImageView()
    
    private var FeedCollectionView : UICollectionView?
    private var selectedIndex : NSIndexPath? {
        didSet {
            FeedCollectionView?.reloadItemsAtIndexPaths([selectedIndex!])
            if deselectedIndex != nil && deselectedIndex != selectedIndex {
                FeedCollectionView?.reloadItemsAtIndexPaths([deselectedIndex!])
            }
        }
        willSet {
            if selectedIndex != nil {
                deselectedIndex = selectedIndex
            }
        }
    }
    private var deselectedIndex : NSIndexPath?
    
    var returningToExplore = false
    weak var returnToParentDelegate : ParentDelegate!
    
    private var panStartingPointX : CGFloat = 0
    private var panStartingPointY : CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        _panGesture.minimumNumberOfTouches = 1
        view.addGestureRecognizer(_panGesture)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    private func setupScreenLayout(pageType : PageType) {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.Vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        FeedCollectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
        FeedCollectionView?.registerClass(FeedCell.self, forCellWithReuseIdentifier: collectionReuseIdentifier)
        
        view.addSubview(FeedCollectionView!)
        
        FeedCollectionView?.translatesAutoresizingMaskIntoConstraints = false
        FeedCollectionView?.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        FeedCollectionView?.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        FeedCollectionView?.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        
        if pageType == .Home {
            FeedCollectionView?.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        } else if pageType == .Detail {
            FeedCollectionView?.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.8).active = true
        }
        
        FeedCollectionView?.layoutIfNeeded()
        
        FeedCollectionView?.backgroundView = nil
        FeedCollectionView?.backgroundColor = UIColor.clearColor()
        FeedCollectionView?.showsVerticalScrollIndicator = false
        FeedCollectionView?.pagingEnabled = true
    }
    
    private func setupDetailView() {
        view.addSubview(backgroundImage)
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        backgroundImage.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        backgroundImage.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        backgroundImage.widthAnchor.constraintEqualToAnchor(view.widthAnchor).active = true
        backgroundImage.layoutIfNeeded()
        if let _tagImage = currentTag.tagImage {
            Database.getTagImage(_tagImage, maxImgSize: maxImgSize, completion: {(data, error) in
                if error != nil {
                    print (error?.localizedDescription)
                } else {
                    self.backgroundImage.image = UIImage(data: data!)
                }
            })
        }
        
        view.addSubview(rotatedView)
        rotatedView.translatesAutoresizingMaskIntoConstraints = false
        rotatedView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -Spacing.xs.rawValue).active = true
        rotatedView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        rotatedView.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: Spacing.xs.rawValue).active = true
        rotatedView.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.2).active = true
        rotatedView.layoutIfNeeded()
        rotatedView.addSubview(titleLabel)
        
        titleLabel.transform = CGAffineTransformIdentity
        titleLabel.frame = CGRect(origin: CGPointZero, size: CGSize(width: rotatedView.bounds.height, height: rotatedView.bounds.width))
        
        //rotate tag
        var transform = CGAffineTransformIdentity
        transform = CGAffineTransformTranslate(transform, (rotatedView.bounds.width / 2)-(rotatedView.bounds.height / 2), (rotatedView.bounds.height / 2)-(rotatedView.bounds.width / 2))
        transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
        
        titleLabel.transform = transform
    }
    
    private func updateTitleTag() {
        if feedItemType! == .Question {
            titleLabel.text = "#"+(currentTag.tagID!).uppercaseString
            titleLabel.font = UIFont.systemFontOfSize(FontSizes.Mammoth.rawValue, weight: UIFontWeightHeavy)
        } else if feedItemType!  == .Answer {
            titleLabel.text = currentQuestion.qTitle
            titleLabel.font = UIFont.systemFontOfSize(FontSizes.Headline2.rawValue, weight: UIFontWeightBold)
        }
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.numberOfLines = 0
    }
    
    func showQuestion(_selectedQuestion : Question?, _allQuestions : [Question?], _questionIndex : Int, _selectedTag : Tag, _frame : CGRect?) {
        let QAVC = QAManagerVC()
        QAVC.selectedTag = _selectedTag
        QAVC.allQuestions = _allQuestions
        QAVC.currentQuestion = _selectedQuestion
        QAVC.questionCounter = _questionIndex
        QAVC.returnToParentDelegate = self
        QAVC.view.frame = view.bounds
        GlobalFunctions.addNewVC(QAVC, parentVC: self)
    }
    
    func returnToParent(currentVC : UIViewController) {
        returningToExplore = true
        GlobalFunctions.dismissVC(currentVC)
    }
    
    private func loadHomeFeed() {
        
    }
    
    private func keepFeedUpdated() {
        
    }
    
    func handlePan(pan : UIPanGestureRecognizer) {
        
        if (pan.state == UIGestureRecognizerState.Began) {
            panStartingPointX = pan.view!.center.x
            panStartingPointY = pan.view!.center.y
            
        } else if (pan.state == UIGestureRecognizerState.Ended) {
            let panFinishingPointX = pan.view!.center.x
            _ = pan.view!.center.y
            
            if (panFinishingPointX > view.bounds.width) {
                returnToParentDelegate.returnToParent(self)
            } else {
                view.center = CGPoint(x: view.bounds.width / 2, y: pan.view!.center.y)
                pan.setTranslation(CGPointZero, inView: view)
            }
        } else {
            let translation = pan.translationInView(view)
            if translation.x > 0 {
                view.center = CGPoint(x: pan.view!.center.x + translation.x, y: pan.view!.center.y)
                pan.setTranslation(CGPointZero, inView: view)
            }
        }
    }
}

/* COLLECTION VIEW */
extension FeedVC : UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalItemCount
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int{
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(collectionReuseIdentifier, forIndexPath: indexPath) as! FeedCell
        let _rand = arc4random_uniform(UInt32(_backgroundColors.count))
        cell.contentView.backgroundColor = _backgroundColors[Int(_rand)].colorWithAlphaComponent(0.4)
        
        if feedItemType! == .Question {
            cell.itemType = .Question
            
            if _allQuestions.count > indexPath.row && _allQuestions[indexPath.row] != nil {
                let _currentQuestion = _allQuestions[indexPath.row]
                cell.updateLabel(_currentQuestion!.qTitle, _subtitle: "#\(self.currentTag.tagID!.uppercaseString)")
                cell.answerCount.setTitle(String(_currentQuestion!.totalAnswers()), forState: .Normal)
            } else {
                Database.getQuestion(currentTag.questions![indexPath.row], completion: { (question, error) in
                    if error == nil {
                        self._allQuestions[indexPath.row] = question
                        cell.updateLabel(question.qTitle, _subtitle: "#\(self.currentTag.tagID!.uppercaseString)")
                        cell.answerCount.setTitle(String(question.totalAnswers()), forState: .Normal)
                    }
                })
            }
            
            if indexPath == selectedIndex && indexPath == deselectedIndex {
                if let _selectedQuestion = _allQuestions[indexPath.row] {
                    let _translatedFrame = cell.convertRect(cell.frame, toView: self.view)
                    showQuestion(_selectedQuestion, _allQuestions: _allQuestions, _questionIndex: indexPath.row, _selectedTag: currentTag, _frame : _translatedFrame)
                }
            } else if indexPath == selectedIndex {
                if let _selectedQuestion = _allQuestions[indexPath.row] {
                    if _selectedQuestion.hasAnswers() {
                        cell.showQuestion(_selectedQuestion)
                    }
                }
            } else if indexPath == deselectedIndex {
                cell.removeAnswer()
            }
            
        } else if feedItemType == .Answer {
            cell.itemType = .Answer
            
            /* GET ANSWER PREVIEW IMAGE FROM STORAGE */
            if browseAnswerPreviewImages[indexPath.row] != nil && gettingImageForCell[indexPath.row] == true {
                cell.previewImage.image = browseAnswerPreviewImages[indexPath.row]!
            } else if gettingImageForCell[indexPath.row] {
                //ignore if already fetching the image, so don't refetch if already getting
            } else {
                gettingImageForCell[indexPath.row] = true
                cell.previewImage.image = nil
                
                Database.getImage(.AnswerThumbs, fileID: currentQuestion!.qAnswers![indexPath.row], maxImgSize: maxImgSize, completion: {(_data, error) in
                    if error != nil {
                        cell.previewImage.backgroundColor = UIColor.redColor()
                    } else {
                        let _answerPreviewImage = GlobalFunctions.createImageFromData(_data!)
                        cell.previewImage.image = _answerPreviewImage
                    }
                })
            }
            
            /* GET NAME & BIO FROM DATABASE */
            if usersForAnswerPreviews.count > indexPath.row && gettingInfoForCell[indexPath.row] == true {
                if let _user = usersForAnswerPreviews[indexPath.row] {
                    cell.titleLabel.text = _user.name
                    cell.subtitleLabel.text = _user.shortBio
                }
            } else if gettingInfoForCell[indexPath.row] {
                //ignore if already fetching the image, so don't refetch if already getting
            } else {
                cell.titleLabel.text = nil
                cell.subtitleLabel.text = nil
                gettingInfoForCell[indexPath.row] = true
                
                Database.getUserSummaryForAnswer(currentQuestion!.qAnswers![indexPath.row], completion: { (user, error) in
                    if error != nil {
                        cell.titleLabel.text = nil
                        cell.subtitleLabel.text = nil
                        self.usersForAnswerPreviews[indexPath.row] = nil
                    } else {
                        cell.titleLabel.text = user?.name
                        cell.subtitleLabel.text = user?.shortBio
                        self.usersForAnswerPreviews[indexPath.row] = user
                    }
                })
            }
            
            if indexPath == selectedIndex && indexPath == deselectedIndex {
                let _selectedAnswerID = currentQuestion.qAnswers![indexPath.row]
                //                    showQuestion(_selectedQuestion, _allQuestions: _allQuestions, _questionIndex: indexPath.row, _selectedTag: currentTag, _frame : _translatedFrame)
            } else if indexPath == selectedIndex {
                let _selectedAnswerID = currentQuestion.qAnswers![indexPath.row]
                cell.showAnswer(_selectedAnswerID)
            } else if indexPath == deselectedIndex {
                cell.removeAnswer()
            }
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

extension FeedVC: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: (FeedCollectionView!.frame.width / 2), height: FeedCollectionView!.frame.height / 3.5)
    }
}