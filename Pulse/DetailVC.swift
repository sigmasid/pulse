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
                    _allQuestions = [Question?](repeating: nil, count: self.currentTag!.totalQuestionsForTag())
                    setupScreenLayout()
                }
            case .Answers:
                if !returningToExplore {
                    gettingImageForCell = [Bool](repeating: false, count: self.currentQuestion!.totalAnswers())
                    gettingInfoForCell = [Bool](repeating: false, count: self.currentQuestion!.totalAnswers())
                    browseAnswerPreviewImages = [UIImage?](repeating: nil, count: currentQuestion!.totalAnswers())
                    usersForAnswerPreviews = [User?](repeating: nil, count: currentQuestion!.totalAnswers())
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
    fileprivate var _allQuestions : [Question?]!
    fileprivate var gettingImageForCell : [Bool]!
    fileprivate var gettingInfoForCell : [Bool]!
    fileprivate var browseAnswerPreviewImages : [UIImage?]!
    fileprivate var usersForAnswerPreviews : [User?]!

    fileprivate enum currentLoadedView : String {
        case tableview = "tableView"
        case collectionview = "collectionView"
    }
    
    fileprivate var _currentView : currentLoadedView? {
        didSet {
            toggleView()
        }
    }
    
    let tableReuseIdentifier = "tableDetailCell"
    let collectionReuseIdentifier = "collectionDetailCell"
    
    var questionCount = 1

    fileprivate var titleLabel = UILabel()
    fileprivate var rotatedView = UIView()
    fileprivate var backgroundImage = UIImageView()
    fileprivate var toggleButton = UIButton()
    
    fileprivate var DetailTableView: UITableView?
    fileprivate var DetailCollectionView : UICollectionView?
    fileprivate var selectedIndex : IndexPath? {
        didSet {
            DetailCollectionView?.reloadItems(at: [selectedIndex!])
            if deselectedIndex != nil && deselectedIndex != selectedIndex {
                DetailCollectionView?.reloadItems(at: [deselectedIndex!])
            }
        }
        willSet {
            if selectedIndex != nil {
                deselectedIndex = selectedIndex
            }
        }
    }
    fileprivate var deselectedIndex : IndexPath?
    
    var returningToExplore = false
    weak var returnToParentDelegate : ParentDelegate!
    
    fileprivate var panStartingPointX : CGFloat = 0
    fileprivate var panStartingPointY : CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        _panGesture.minimumNumberOfTouches = 1
        view.addGestureRecognizer(_panGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden : Bool {
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
            
            toggleButton.setImage(UIImage(named: "collection-list"), for: UIControlState())
            
            if DetailTableView == nil {
                setupTableView()
            } else {
                DetailTableView?.isHidden = false
            }
            
            DetailCollectionView?.isHidden = true
            
        } else {
            
            toggleButton.setImage(UIImage(named: "table-list"), for: UIControlState())
            
            if DetailCollectionView == nil {
                setupCollectionView()
            } else {
                DetailCollectionView?.isHidden = false
            }
            DetailTableView?.isHidden = true
        }
    }
    
    fileprivate func setupScreenLayout() {
        backgroundImage = UIImageView()
        view.addSubview(backgroundImage)
        
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        backgroundImage.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        backgroundImage.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        backgroundImage.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        
        view.addSubview(toggleButton)
        toggleButton.addTarget(self, action: #selector(setCurrentView), for: UIControlEvents.touchDown)
        toggleButton.backgroundColor = UIColor.darkGray
        
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.bottomAnchor.constraint(equalTo: backgroundImage.bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
        toggleButton.trailingAnchor.constraint(equalTo: backgroundImage.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        toggleButton.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        toggleButton.widthAnchor.constraint(equalTo: toggleButton.heightAnchor).isActive = true
        toggleButton.contentEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15)

        toggleButton.layoutIfNeeded()
        toggleButton.makeRound()
        
        view.addSubview(rotatedView)
        rotatedView.translatesAutoresizingMaskIntoConstraints = false
        rotatedView.bottomAnchor.constraint(equalTo: toggleButton.topAnchor).isActive = true
        rotatedView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
//        rotatedView.topAnchor.constraint(equalTo: view.leadingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        rotatedView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2).isActive = true
        rotatedView.layoutIfNeeded()
        
        rotatedView.addSubview(titleLabel)
        
        if currentLoadedItem == .Questions {
            titleLabel.text = "#"+(currentTag.tagID!).uppercased()
            titleLabel.font = UIFont.systemFont(ofSize: FontSizes.mammoth.rawValue, weight: UIFontWeightHeavy)
        } else if currentLoadedItem  == .Answers {
            titleLabel.text = currentQuestion.qTitle
            titleLabel.font = UIFont.systemFont(ofSize: FontSizes.headline.rawValue, weight: UIFontWeightBold)
        }
        
        titleLabel.textColor = UIColor.white
        titleLabel.transform = CGAffineTransform.identity
        titleLabel.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: rotatedView.bounds.height, height: rotatedView.bounds.width))

        var transform = CGAffineTransform.identity
        
        // translate to new center
        transform = transform.translatedBy(x: (rotatedView.bounds.width / 2)-(rotatedView.bounds.height / 2), y: (rotatedView.bounds.height / 2)-(rotatedView.bounds.width / 2))
        // rotate counterclockwise around center
        transform = transform.rotated(by: CGFloat(-M_PI_2))
        
        titleLabel.transform = transform
        titleLabel.numberOfLines = 0
        
        if let _tagImage = currentTag.tagImage {
            Database.getTagImage(_tagImage, maxImgSize: maxImgSize, completion: {(data, error) in
                if error == nil {
                    self.backgroundImage.image = UIImage(data: data!)
                }
            })
        }
        
        _currentView = .collectionview

    }
    
    fileprivate func setupCollectionView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.vertical
        layout.minimumLineSpacing = Spacing.xs.rawValue
        layout.minimumInteritemSpacing = Spacing.xs.rawValue
        
        DetailCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        DetailCollectionView?.register(DetailCollectionCell.self, forCellWithReuseIdentifier: collectionReuseIdentifier)

        view.addSubview(DetailCollectionView!)
        
        DetailCollectionView?.translatesAutoresizingMaskIntoConstraints = false
        DetailCollectionView?.topAnchor.constraint(equalTo: backgroundImage.topAnchor, constant: Spacing.s.rawValue).isActive = true
        DetailCollectionView?.bottomAnchor.constraint(equalTo: toggleButton.topAnchor, constant: -Spacing.s.rawValue).isActive = true
        DetailCollectionView?.leadingAnchor.constraint(equalTo: rotatedView.trailingAnchor,  constant: Spacing.xs.rawValue).isActive = true
        DetailCollectionView?.trailingAnchor.constraint(equalTo: backgroundImage.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        DetailCollectionView?.layoutIfNeeded()
        
        DetailCollectionView?.backgroundView = nil
        DetailCollectionView?.backgroundColor = UIColor.clear
        DetailCollectionView?.showsVerticalScrollIndicator = false
        DetailCollectionView?.isPagingEnabled = true
        
        DetailCollectionView?.delegate = self
        DetailCollectionView?.dataSource = self
        DetailCollectionView?.reloadData()
    }
    
    fileprivate func setupTableView() {
        DetailTableView = UITableView()
        DetailTableView?.register(DetailTableCell.self, forCellReuseIdentifier: tableReuseIdentifier)
        
        view.addSubview(DetailTableView!)

        DetailTableView?.translatesAutoresizingMaskIntoConstraints = false
        DetailTableView?.topAnchor.constraint(equalTo: backgroundImage.topAnchor, constant: Spacing.s.rawValue).isActive = true
        DetailTableView?.bottomAnchor.constraint(equalTo: toggleButton.topAnchor, constant: -Spacing.s.rawValue).isActive = true
        DetailTableView?.widthAnchor.constraint(equalTo: backgroundImage.widthAnchor, multiplier: 0.75).isActive = true
        DetailTableView?.trailingAnchor.constraint(equalTo: backgroundImage.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        
        DetailTableView?.backgroundView = nil
        DetailTableView?.backgroundColor = UIColor.clear
        DetailTableView?.separatorStyle = .none
        DetailTableView?.tableFooterView = UIView()
        DetailTableView?.showsVerticalScrollIndicator = false
        DetailTableView?.isPagingEnabled = true
        
        DetailTableView?.delegate = self
        DetailTableView?.dataSource = self
        DetailTableView?.reloadData()
    }
    
    func showQuestion(_ _selectedQuestion : Question?, _allQuestions : [Question?], _questionIndex : Int, _selectedTag : Tag, _frame : CGRect?) {
        let QAVC = QAManagerVC()
        QAVC.selectedTag = _selectedTag
        QAVC.allQuestions = _allQuestions
        QAVC.currentQuestion = _selectedQuestion
        QAVC.questionCounter = _questionIndex
//        QAVC.returnToParentDelegate = self
        QAVC.view.frame = view.bounds
        GlobalFunctions.addNewVC(QAVC, parentVC: self)
    }
    
    func returnToParent(_ currentVC : UIViewController) {
        returningToExplore = true
        GlobalFunctions.dismissVC(currentVC)
    }
    
    func handlePan(_ pan : UIPanGestureRecognizer) {
        
        if (pan.state == UIGestureRecognizerState.began) {
            panStartingPointX = pan.view!.center.x
            panStartingPointY = pan.view!.center.y
            
        } else if (pan.state == UIGestureRecognizerState.ended) {
            let panFinishingPointX = pan.view!.center.x
            _ = pan.view!.center.y
            
            if (panFinishingPointX > view.bounds.width) {
                returnToParentDelegate.returnToParent(self)
            } else {
                view.center = CGPoint(x: view.bounds.width / 2, y: pan.view!.center.y)
                pan.setTranslation(CGPoint.zero, in: view)
            }
        } else {
            let translation = pan.translation(in: view)
            if translation.x > 0 {
                view.center = CGPoint(x: pan.view!.center.x + translation.x, y: pan.view!.center.y)
                pan.setTranslation(CGPoint.zero, in: view)
            }
        }
    }
}

/* SETUP TABLEVIEW */
extension DetailVC : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentLoadedItem == .Questions {
            return currentTag.totalQuestionsForTag()
        } else if currentLoadedItem == .Answers {
            return currentQuestion.totalAnswers()
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableReuseIdentifier) as! DetailTableCell
        cell.backgroundColor = UIColor.clear
        
        if currentLoadedItem == .Questions {
            if _allQuestions.count > (indexPath as NSIndexPath).row && _allQuestions[(indexPath as NSIndexPath).row] != nil{
                let _currentQuestion = _allQuestions[(indexPath as NSIndexPath).row]
                cell.titleLabel.text = _currentQuestion?.qTitle
            } else {
                Database.getQuestion(currentTag.questions![(indexPath as NSIndexPath).row]!.qID, completion: { (question, error) in
                    if error == nil {
                        self._allQuestions[(indexPath as NSIndexPath).row] =  question
                        cell.titleLabel.text = question.qTitle
                    }
                })
            }
        } else if currentLoadedItem == .Answers {
            /* GET NAME & BIO FROM DATABASE */
            if usersForAnswerPreviews.count > (indexPath as NSIndexPath).row {
                cell.titleLabel.text = usersForAnswerPreviews[(indexPath as NSIndexPath).row]?.name
                cell.subtitleLabel.text = usersForAnswerPreviews[(indexPath as NSIndexPath).row]?.shortBio
            } else if gettingInfoForCell[(indexPath as NSIndexPath).row] {
                //ignore if already fetching the image, so don't refetch if already getting
            } else {
                cell.titleLabel.text = nil
                cell.subtitleLabel.text = nil
                gettingInfoForCell[(indexPath as NSIndexPath).row] = true
                
                Database.getUserSummaryForAnswer(currentQuestion!.qAnswers![(indexPath as NSIndexPath).row], completion: { (user, error) in
                    if error != nil {
                        cell.titleLabel.text = nil
                        cell.subtitleLabel.text = nil
                        self.usersForAnswerPreviews[(indexPath as NSIndexPath).row] = nil
                    } else {
                        cell.titleLabel.text = user?.name
                        cell.subtitleLabel.text = user?.shortBio
                        self.usersForAnswerPreviews[(indexPath as NSIndexPath).row] = user
                    }
                })
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let _selectedQuestion = _allQuestions[(indexPath as NSIndexPath).row] {
            showQuestion(_selectedQuestion, _allQuestions: _allQuestions, _questionIndex: (indexPath as NSIndexPath).row, _selectedTag: currentTag, _frame: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Spacing.l.rawValue * 2
    }
}

/* COLLECTION VIEW */
extension DetailVC : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if currentLoadedItem == .Questions {
            return currentTag.totalQuestionsForTag()
        } else if currentLoadedItem == .Answers {
            return currentQuestion.totalAnswers()
        } else {
            return 0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int{
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionReuseIdentifier, for: indexPath) as! DetailCollectionCell
        let _rand = arc4random_uniform(UInt32(_backgroundColors.count))
        cell.contentView.backgroundColor = _backgroundColors[Int(_rand)].withAlphaComponent(0.4)
        
        if currentLoadedItem == .Questions {
            cell.feedItemType = .question
            
            if _allQuestions.count > (indexPath as NSIndexPath).row && _allQuestions[(indexPath as NSIndexPath).row] != nil {
                let _currentQuestion = _allQuestions[(indexPath as NSIndexPath).row]
                cell.titleLabel!.text = _currentQuestion?.qTitle
            } else {
                Database.getQuestion(currentTag.questions![(indexPath as NSIndexPath).row]!.qID, completion: { (question, error) in
                    if error == nil {
                        self._allQuestions[(indexPath as NSIndexPath).row] = question
                        cell.titleLabel!.text = question.qTitle
                    }
                })
            }
            
            if indexPath == selectedIndex && indexPath == deselectedIndex {
                if let _selectedQuestion = _allQuestions[(indexPath as NSIndexPath).row] {
                    let _translatedFrame = cell.convert(cell.frame, to: self.view)
                    showQuestion(_selectedQuestion, _allQuestions: _allQuestions, _questionIndex: (indexPath as NSIndexPath).row, _selectedTag: currentTag, _frame : _translatedFrame)
                }
            } else if indexPath == selectedIndex {
                if let _selectedQuestion = _allQuestions[(indexPath as NSIndexPath).row] {
                    if _selectedQuestion.hasAnswers() {
                        cell.showQuestion(_selectedQuestion)
                    }
                }
            } else if indexPath == deselectedIndex {
                cell.removeAnswer()
            }
            
        } else if currentLoadedItem == .Answers {
            cell.feedItemType = .answer

            /* GET ANSWER PREVIEW IMAGE FROM STORAGE */
            if browseAnswerPreviewImages[(indexPath as NSIndexPath).row] != nil && gettingImageForCell[(indexPath as NSIndexPath).row] == true {
                cell.previewImage.image = browseAnswerPreviewImages[(indexPath as NSIndexPath).row]!
            } else if gettingImageForCell[(indexPath as NSIndexPath).row] {
                //ignore if already fetching the image, so don't refetch if already getting
            } else {
                gettingImageForCell[(indexPath as NSIndexPath).row] = true
                cell.previewImage.image = nil

                Database.getImage(.AnswerThumbs, fileID: currentQuestion!.qAnswers![(indexPath as NSIndexPath).row], maxImgSize: maxImgSize, completion: {(_data, error) in
                    if error != nil {
                        cell.previewImage?.backgroundColor = UIColor.red
                    } else {
                        let _answerPreviewImage = GlobalFunctions.createImageFromData(_data!)
                        cell.previewImage.image = _answerPreviewImage
                    }
                })
            }
            
            /* GET NAME & BIO FROM DATABASE */
            if usersForAnswerPreviews.count > (indexPath as NSIndexPath).row && gettingInfoForCell[(indexPath as NSIndexPath).row] == true {
                if let _user = usersForAnswerPreviews[(indexPath as NSIndexPath).row] {
                    cell.titleLabel.text = _user.name
                    cell.subtitleLabel.text = _user.shortBio
                }
            } else if gettingInfoForCell[(indexPath as NSIndexPath).row] {
                //ignore if already fetching the image, so don't refetch if already getting
            } else {
                cell.titleLabel.text = nil
                cell.subtitleLabel.text = nil
                gettingInfoForCell[(indexPath as NSIndexPath).row] = true
                
                Database.getUserSummaryForAnswer(currentQuestion!.qAnswers![(indexPath as NSIndexPath).row], completion: { (user, error) in
                    if error != nil {
                        cell.titleLabel.text = nil
                        cell.subtitleLabel.text = nil
                        self.usersForAnswerPreviews[(indexPath as NSIndexPath).row] = nil
                    } else {
                        cell.titleLabel.text = user?.name
                        cell.subtitleLabel.text = user?.shortBio
                        self.usersForAnswerPreviews[(indexPath as NSIndexPath).row] = user
                    }
                })
            }
            
            if indexPath == selectedIndex && indexPath == deselectedIndex {
//                let _selectedAnswerID = currentQuestion.qAnswers![(indexPath as NSIndexPath).row]
//                    showQuestion(_selectedQuestion, _allQuestions: _allQuestions, _questionIndex: indexPath.row, _selectedTag: currentTag, _frame : _translatedFrame)
            } else if indexPath == selectedIndex {
                let _selectedAnswerID = currentQuestion.qAnswers![(indexPath as NSIndexPath).row]
                cell.showAnswer(_selectedAnswerID)
            } else if indexPath == deselectedIndex {
                cell.removeAnswer()
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
}

extension DetailVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (DetailCollectionView!.frame.width - (Spacing.xs.rawValue * 2)) / 2, height: DetailCollectionView!.frame.height / 3)
    }
}
