//
//  TagDetailVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//
import UIKit

class DetailVC: UIViewController, ParentDelegate {
    
    var currentLoadedItem : Item? {
        didSet {
            switch currentLoadedItem! {
            case .Questions:
                if !returningToExplore {
                    _allQuestions = [Question?](count: self.currentTag!.totalQuestionsForTag(), repeatedValue: nil)
                    setupScreenLayout()
                }
            case .Answers:
                if !returningToExplore {
                    gettingImageForCell = [Bool](count: self.currentQuestion!.totalAnswers(), repeatedValue: false)
                    gettingInfoForCell = [Bool](count: self.currentQuestion!.totalAnswers(), repeatedValue: false)
                    browseAnswerPreviewImages = [UIImage?](count: currentQuestion!.totalAnswers(), repeatedValue: nil)
                    usersForAnswerPreviews = [User?](count: currentQuestion!.totalAnswers(), repeatedValue: nil)
                    setupScreenLayout()
                }
            case .Tags: return
            default: return
            }
        }
    }
    
    var currentTag : Tag!
    var currentQuestion : Question!
    
    /* save questions & answers that have been shown */
    private var _allQuestions : [Question?]!
    private var gettingImageForCell : [Bool]!
    private var gettingInfoForCell : [Bool]!
    private var browseAnswerPreviewImages : [UIImage?]!
    private var usersForAnswerPreviews : [User?]!

    private enum currentLoadedView : String {
        case tableview = "tableView"
        case collectionview = "collectionView"
    }
    
    private var _currentView : currentLoadedView? {
        didSet {
            toggleView()
        }
    }
    
    let tableReuseIdentifier = "tableDetailCell"
    let collectionReuseIdentifier = "collectionDetailCell"
    
    var questionCount = 1

    private var titleLabel = UILabel()
    private var rotatedView = UIView()
    private var backgroundImage = UIImageView()
    private var toggleButton = UIButton()
    
    private var DetailTableView: UITableView?
    private var DetailCollectionView : UICollectionView?
    private var selectedIndex : NSIndexPath? {
        didSet {
            DetailCollectionView?.reloadItemsAtIndexPaths([selectedIndex!])
            if deselectedIndex != nil && deselectedIndex != selectedIndex {
                DetailCollectionView?.reloadItemsAtIndexPaths([deselectedIndex!])
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
    
    func setCurrentView() {
        if _currentView == .tableview {
            _currentView = .collectionview
        } else {
            _currentView = .tableview
        }
    }

    func toggleView() {
        if _currentView == .tableview {
            
            toggleButton.setImage(UIImage(named: "collection-list"), forState: .Normal)
            
            if DetailTableView == nil {
                setupTableView()
            } else {
                DetailTableView?.hidden = false
            }
            
            DetailCollectionView?.hidden = true
            
        } else {
            
            toggleButton.setImage(UIImage(named: "table-list"), forState: .Normal)
            
            if DetailCollectionView == nil {
                setupCollectionView()
            } else {
                DetailCollectionView?.hidden = false
            }
            DetailTableView?.hidden = true
        }
    }
    
    private func setupScreenLayout() {
        backgroundImage = UIImageView()
        view.addSubview(backgroundImage)
        
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        backgroundImage.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true
        backgroundImage.widthAnchor.constraintEqualToAnchor(view.widthAnchor).active = true
        backgroundImage.heightAnchor.constraintEqualToAnchor(view.heightAnchor).active = true
        
        view.addSubview(toggleButton)
        toggleButton.addTarget(self, action: #selector(setCurrentView), forControlEvents: UIControlEvents.TouchDown)
        toggleButton.backgroundColor = UIColor.darkGrayColor()
        
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.bottomAnchor.constraintEqualToAnchor(backgroundImage.bottomAnchor, constant: -Spacing.s.rawValue).active = true
        toggleButton.trailingAnchor.constraintEqualToAnchor(backgroundImage.trailingAnchor, constant: -Spacing.s.rawValue).active = true
        toggleButton.heightAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
        toggleButton.widthAnchor.constraintEqualToAnchor(toggleButton.heightAnchor).active = true
        toggleButton.contentEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15)

        toggleButton.layoutIfNeeded()
        toggleButton.makeRound()
        
        view.addSubview(rotatedView)
        rotatedView.translatesAutoresizingMaskIntoConstraints = false
        rotatedView.bottomAnchor.constraintEqualToAnchor(toggleButton.topAnchor).active = true
        rotatedView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor, constant: Spacing.xs.rawValue).active = true
        rotatedView.topAnchor.constraintEqualToAnchor(view.leadingAnchor, constant: -Spacing.xs.rawValue).active = true
        rotatedView.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.2).active = true
        rotatedView.layoutIfNeeded()
        
        rotatedView.addSubview(titleLabel)
        
        if currentLoadedItem == .Questions {
            titleLabel.text = "#"+(currentTag.tagID!).uppercaseString
            titleLabel.font = UIFont.systemFontOfSize(FontSizes.Mammoth.rawValue, weight: UIFontWeightHeavy)
        } else if currentLoadedItem  == .Answers {
            titleLabel.text = currentQuestion.qTitle
            titleLabel.font = UIFont.systemFontOfSize(FontSizes.Headline.rawValue, weight: UIFontWeightBold)
        }
        
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.transform = CGAffineTransformIdentity
        titleLabel.frame = CGRect(origin: CGPointZero, size: CGSize(width: rotatedView.bounds.height, height: rotatedView.bounds.width))

        var transform = CGAffineTransformIdentity
        
        // translate to new center
        transform = CGAffineTransformTranslate(transform, (rotatedView.bounds.width / 2)-(rotatedView.bounds.height / 2), (rotatedView.bounds.height / 2)-(rotatedView.bounds.width / 2))
        // rotate counterclockwise around center
        transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
        
        titleLabel.transform = transform
        titleLabel.numberOfLines = 0
        
        if let _tagImage = currentTag.tagImage {
            Database.getTagImage(_tagImage, maxImgSize: maxImgSize, completion: {(data, error) in
                if error != nil {
                    print (error?.localizedDescription)
                } else {
                    self.backgroundImage.image = UIImage(data: data!)
                }
            })
        }
        
        _currentView = .collectionview

    }
    
    private func setupCollectionView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.Vertical
        layout.minimumLineSpacing = Spacing.xs.rawValue
        layout.minimumInteritemSpacing = Spacing.xs.rawValue
        
        DetailCollectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
        DetailCollectionView?.registerClass(DetailCollectionCell.self, forCellWithReuseIdentifier: collectionReuseIdentifier)

        view.addSubview(DetailCollectionView!)
        
        DetailCollectionView?.translatesAutoresizingMaskIntoConstraints = false
        DetailCollectionView?.topAnchor.constraintEqualToAnchor(backgroundImage.topAnchor, constant: Spacing.s.rawValue).active = true
        DetailCollectionView?.bottomAnchor.constraintEqualToAnchor(toggleButton.topAnchor, constant: -Spacing.s.rawValue).active = true
        DetailCollectionView?.leadingAnchor.constraintEqualToAnchor(rotatedView.trailingAnchor,  constant: Spacing.xs.rawValue).active = true
        DetailCollectionView?.trailingAnchor.constraintEqualToAnchor(backgroundImage.trailingAnchor, constant: -Spacing.xs.rawValue).active = true
        DetailCollectionView?.layoutIfNeeded()
        
        DetailCollectionView?.backgroundView = nil
        DetailCollectionView?.backgroundColor = UIColor.clearColor()
        DetailCollectionView?.showsVerticalScrollIndicator = false
        DetailCollectionView?.pagingEnabled = true
        
        DetailCollectionView?.delegate = self
        DetailCollectionView?.dataSource = self
        DetailCollectionView?.reloadData()
    }
    
    private func setupTableView() {
        DetailTableView = UITableView()
        DetailTableView?.registerClass(DetailTableCell.self, forCellReuseIdentifier: tableReuseIdentifier)
        
        view.addSubview(DetailTableView!)

        DetailTableView?.translatesAutoresizingMaskIntoConstraints = false
        DetailTableView?.topAnchor.constraintEqualToAnchor(backgroundImage.topAnchor, constant: Spacing.s.rawValue).active = true
        DetailTableView?.bottomAnchor.constraintEqualToAnchor(toggleButton.topAnchor, constant: -Spacing.s.rawValue).active = true
        DetailTableView?.widthAnchor.constraintEqualToAnchor(backgroundImage.widthAnchor, multiplier: 0.75).active = true
        DetailTableView?.trailingAnchor.constraintEqualToAnchor(backgroundImage.trailingAnchor, constant: -Spacing.s.rawValue).active = true
        
        DetailTableView?.backgroundView = nil
        DetailTableView?.backgroundColor = UIColor.clearColor()
        DetailTableView?.separatorStyle = .None
        DetailTableView?.tableFooterView = UIView()
        DetailTableView?.showsVerticalScrollIndicator = false
        DetailTableView?.pagingEnabled = true
        
        DetailTableView?.delegate = self
        DetailTableView?.dataSource = self
        DetailTableView?.reloadData()
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

/* SETUP TABLEVIEW */
extension DetailVC : UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentLoadedItem == .Questions {
            return currentTag.totalQuestionsForTag()
        } else if currentLoadedItem == .Answers {
            return currentQuestion.totalAnswers()
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(tableReuseIdentifier) as! DetailTableCell
        cell.backgroundColor = UIColor.clearColor()
        
        if currentLoadedItem == .Questions {
            if _allQuestions.count > indexPath.row && _allQuestions[indexPath.row] != nil{
                let _currentQuestion = _allQuestions[indexPath.row]
                cell.titleLabel.text = _currentQuestion?.qTitle
            } else {
                Database.getQuestion(currentTag.questions![indexPath.row], completion: { (question, error) in
                    if error == nil {
                        self._allQuestions[indexPath.row] =  question
                        cell.titleLabel.text = question.qTitle
                    }
                })
            }
        } else if currentLoadedItem == .Answers {
            /* GET NAME & BIO FROM DATABASE */
            if usersForAnswerPreviews.count > indexPath.row {
                cell.titleLabel.text = usersForAnswerPreviews[indexPath.row]?.name
                cell.subtitleLabel.text = usersForAnswerPreviews[indexPath.row]?.shortBio
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
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let _selectedQuestion = _allQuestions[indexPath.row] {
            showQuestion(_selectedQuestion, _allQuestions: _allQuestions, _questionIndex: indexPath.row, _selectedTag: currentTag, _frame: nil)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Spacing.l.rawValue * 2
    }
}

/* COLLECTION VIEW */
extension DetailVC : UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if currentLoadedItem == .Questions {
            return currentTag.totalQuestionsForTag()
        } else if currentLoadedItem == .Answers {
            return currentQuestion.totalAnswers()
        } else {
            return 0
        }
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int{
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(collectionReuseIdentifier, forIndexPath: indexPath) as! DetailCollectionCell
        let _rand = arc4random_uniform(UInt32(_backgroundColors.count))
        cell.contentView.backgroundColor = _backgroundColors[Int(_rand)].colorWithAlphaComponent(0.4)
        
        if currentLoadedItem == .Questions {
            cell.feedItemType = .Question
            
            if _allQuestions.count > indexPath.row && _allQuestions[indexPath.row] != nil {
                let _currentQuestion = _allQuestions[indexPath.row]
                cell.titleLabel!.text = _currentQuestion?.qTitle
            } else {
                Database.getQuestion(currentTag.questions![indexPath.row], completion: { (question, error) in
                    if error == nil {
                        self._allQuestions[indexPath.row] = question
                        cell.titleLabel!.text = question.qTitle
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
            
        } else if currentLoadedItem == .Answers {
            cell.feedItemType = .Answer

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
                        cell.previewImage?.backgroundColor = UIColor.redColor()
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

extension DetailVC: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: (DetailCollectionView!.frame.width - (Spacing.xs.rawValue * 2)) / 2, height: DetailCollectionView!.frame.height / 3)
    }
}
