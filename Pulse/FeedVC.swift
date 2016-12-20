//
//  FeedVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

protocol feedVCDelegate: class {
    func userSelected(type : FeedItemType, item : Any)
}

class FeedVC: UIViewController {
    
    fileprivate var isLoaded = false
    fileprivate var panPresentInteractionController = PanEdgeInteractionController()
    fileprivate var panDismissInteractionController = PanEdgeInteractionController()
    
    fileprivate var initialFrame : CGRect!
    fileprivate var rectToRight : CGRect!
    fileprivate var rectToLeft : CGRect!
    fileprivate var QAVC : QAManagerVC!
    
    fileprivate var searchScope : FeedItemType? = .question
    
    public func getScrollView() -> UICollectionView? {
        return feedCollectionView != nil ? feedCollectionView : nil
    }
    
    struct AnswerPreviewData {
        var user : User?
        var answer : Answer!
        var question : Question?
        
        var gettingImageForAnswerPreview : Bool = false
        var gettingInfoForAnswerPreview : Bool = false
    }
    
    /* SET BY PARENT */
    var feedDelegate : feedVCDelegate!
    var feedItemType : FeedItemType! {
        didSet {
            updateDataSource = true
        }
    }
    /* END SET BY PARENT */
    
    var updateDataSource : Bool = false {
        didSet {
            selectedIndex = nil
            answerStack.removeAll()

            switch feedItemType! {
            case .tag:
                totalItemCount = allTags.count
            case .question:
                totalItemCount = allQuestions.count
            case .answer:
                totalItemCount = allAnswers.count
                
                for (index, answer) in allAnswers.enumerated() {
                    let currentAnswerData = AnswerPreviewData(user: nil,
                                                       answer: answer,
                                                       question: nil,
                                                       gettingImageForAnswerPreview: false,
                                                       gettingInfoForAnswerPreview: false)
                    answerStack.insert(currentAnswerData, at: index)
                }
                
            case .people:
                totalItemCount = allUsers.count
            }
            
            feedCollectionView?.delegate = self
            feedCollectionView?.dataSource = self
            feedCollectionView?.reloadData()
            feedCollectionView?.layoutIfNeeded()
            
            if totalItemCount > 0 {
                feedCollectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
            }
        }
    }
    
    fileprivate var feedCollectionView : UICollectionView?
    fileprivate var selectedIndex : IndexPath? {
        didSet {
            if selectedIndex != nil && feedItemType! == .question {
                selectedIndex = nil
                if feedDelegate != nil {
                    feedDelegate.userSelected(type : .question, item : selectedQuestion)
                }
            } else if selectedIndex != nil && feedItemType! == .tag {
                selectedIndex = nil
                if feedDelegate != nil {
                    feedDelegate.userSelected(type : .tag, item : selectedTag)
                }
            } else if selectedIndex != nil && feedItemType! == .people {
                selectedIndex = nil
                if feedDelegate != nil {
                    feedDelegate.userSelected(type : .people, item : selectedUser)
                }
            } else if selectedIndex != nil && feedItemType! == .answer {
                feedCollectionView?.reloadItems(at: [selectedIndex!])
                if deselectedIndex != nil && deselectedIndex != selectedIndex {
                    feedCollectionView?.reloadItems(at: [deselectedIndex!])
                }
                if feedDelegate != nil {
                    feedDelegate.userSelected(type : .answer, item : selectedAnswer)
                }
            }
        }
        willSet {
            if selectedIndex != nil {
                deselectedIndex = selectedIndex
            }
            
            if newValue == nil && feedItemType != nil {
                switch feedItemType! {
                case .answer:
                    if let selectedIndex = selectedIndex {
                        let cell = feedCollectionView?.dequeueReusableCell(withReuseIdentifier: collectionAnswerReuseIdentifier, for: selectedIndex) as! FeedAnswerCell
                        cell.removeAnswer()
                    }
                default: return
                }
            }
        }
    }
    fileprivate var deselectedIndex : IndexPath?

    var allTags : [Tag]!
    var allQuestions : [Question?]!
    var allAnswers : [Answer]!
    var allUsers : [User]!
    
    var selectedUser : User!
    var selectedTag : Tag!
    var selectedQuestion : Question!
    var selectedAnswer: Answer!
    
    var selectedQuestionIndex = 0
    
    fileprivate var totalItemCount = 0

    fileprivate var answerStack = [AnswerPreviewData]()

    let collectionReuseIdentifier = "FeedCell"
    let collectionPeopleReuseIdentifier = "FeedPeopleCell"
    let collectionAnswerReuseIdentifier = "FeedAnswerCell"
    let collectionQuestionReuseIdentifier = "FeedQuestionCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            view.backgroundColor = .white
            
            rectToLeft = view.frame
            rectToLeft.origin.x = view.frame.minX - view.frame.size.width
            
            rectToRight = view.frame
            rectToRight.origin.x = view.frame.maxX
            
            setupScreenLayout()
            definesPresentationContext = true
            feedCollectionView?.isMultipleTouchEnabled = true
            
            isLoaded = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func setupScreenLayout() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.vertical
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        feedCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        feedCollectionView?.register(FeedCell.self, forCellWithReuseIdentifier: collectionReuseIdentifier)
        feedCollectionView?.register(FeedQuestionCell.self, forCellWithReuseIdentifier: collectionQuestionReuseIdentifier)
        feedCollectionView?.register(FeedAnswerCell.self, forCellWithReuseIdentifier: collectionAnswerReuseIdentifier)

        view.addSubview(feedCollectionView!)
        
        feedCollectionView?.translatesAutoresizingMaskIntoConstraints = false
        feedCollectionView?.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        feedCollectionView?.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        feedCollectionView?.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        feedCollectionView?.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        feedCollectionView?.layoutIfNeeded()
        
        feedCollectionView?.backgroundColor = UIColor.clear
        feedCollectionView?.backgroundView = nil
        feedCollectionView?.showsVerticalScrollIndicator = false
    }
    
    func showQuestion(_ selectedQuestion : Question?, allQuestions : [Question?], questionIndex : Int, answerIndex : Int, selectedTag : Tag) {
        QAVC = QAManagerVC()
        QAVC.selectedTag = selectedTag
        QAVC.allQuestions = allQuestions
        QAVC.currentQuestion = selectedQuestion
        QAVC.questionCounter = questionIndex
        QAVC.answerIndex = answerIndex
        QAVC.openingScreen = .question

        selectedIndex = nil
        
        QAVC.transitioningDelegate = self
        present(QAVC, animated: true, completion: nil)
    }
    
    func setSelectedIndex(index : IndexPath?) {
        if index != nil && feedItemType! == .answer {
            selectedAnswer = allAnswers[index!.row]
            selectedIndex = index!
        } else {
            selectedIndex = nil
            deselectedIndex = nil
        }
    }
}

/* COLLECTION VIEW */
extension FeedVC : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalItemCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch feedItemType! {
            
        /** FEED ITEM: QUESTION **/
        case .question:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionQuestionReuseIdentifier, for: indexPath) as! FeedQuestionCell
            let _rand = arc4random_uniform(UInt32(_backgroundColors.count))
            
            cell.contentView.backgroundColor = _backgroundColors[Int(_rand)].withAlphaComponent(1.0)

            //clear the cells and set the item type first
            cell.updateLabel(nil, _subtitle: nil)

            if allQuestions.count > indexPath.row && allQuestions[indexPath.row]!.qTitle != nil {
                guard let _currentQuestion = allQuestions[indexPath.row] else { return cell }

                if let tagTitle = _currentQuestion.qTag?.tagTitle {
                    cell.updateLabel(_currentQuestion.qTitle, _subtitle: tagTitle.capitalized)
                } else {
                    cell.updateLabel(_currentQuestion.qTitle, _subtitle: nil)
                }
                
                if _currentQuestion.hasAnswers() {
                    cell.answerCount.setTitle(String(_currentQuestion.totalAnswers()), for: UIControlState())
                } else {
                    cell.answerCount.setTitle("0", for: UIControlState())
                }
            } else {
                Database.getQuestion(allQuestions[indexPath.row]!.qID, completion: { (question, error) in
                    if let question = question {

                        if let tagTitle = question.qTag?.tagTitle  {
                            DispatchQueue.main.async {
                                cell.updateLabel(question.qTitle, _subtitle: tagTitle.capitalized)
                                collectionView.reloadItems(at: [indexPath])
                            }
                            self.allQuestions[indexPath.row] = question

                        } else if let tag = self.allQuestions[indexPath.row]?.qTag {
                            DispatchQueue.main.async {
                                cell.updateLabel(question.qTitle, _subtitle: tag.tagTitle?.capitalized)
                                collectionView.reloadItems(at: [indexPath])
                            }
                            self.allQuestions[indexPath.row] = question
                            self.allQuestions[indexPath.row]?.qTag = tag

                        } else {
                            DispatchQueue.main.async {
                                cell.updateLabel(question.qTitle, _subtitle: nil)
                                collectionView.reloadItems(at: [indexPath])
                            }
                            self.allQuestions[indexPath.row] = question
                        }
                        DispatchQueue.main.async {
                            cell.answerCount.setTitle(String(question.totalAnswers()), for: UIControlState())
                            collectionView.reloadItems(at: [indexPath])
                        }
                    }
                })
            }
            return cell

        /** FEED ITEM: TAG **/
        case .tag:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionReuseIdentifier, for: indexPath) as! FeedCell
            let _rand = arc4random_uniform(UInt32(_backgroundColors.count))
            
            cell.contentView.backgroundColor = _backgroundColors[Int(_rand)].withAlphaComponent(1.0)

            if cell.itemType == nil || cell.itemType != feedItemType {
                cell.itemType = .tag
            }
            cell.updateLabel(nil, _subtitle: nil)
            cell.showAnswerCount()

            if allTags.count > indexPath.row && allTags[indexPath.row].tagCreated {
                let _currentTag = allTags[indexPath.row]
                cell.updateLabel(_currentTag.tagTitle, _subtitle: _currentTag.tagDescription)
                cell.answerCount.setTitle(String(_currentTag.totalQuestionsForTag()), for: UIControlState())
            } else if allTags.count > indexPath.row {

                Database.getTag(allTags[indexPath.row].tagID!, completion: { (tag, error) in
                    if error == nil {
                        self.allTags[indexPath.row] = tag
                        cell.updateLabel(tag.tagTitle, _subtitle: tag.tagDescription)
                        cell.answerCount.setTitle(String(tag.totalQuestionsForTag()), for: UIControlState())
                    }
                })
            }
            return cell

        /** FEED ITEM: ANSWER **/
        case .answer:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionAnswerReuseIdentifier, for: indexPath) as! FeedAnswerCell
            let _rand = arc4random_uniform(UInt32(_backgroundColors.count))
            
            cell.contentView.backgroundColor = _backgroundColors[Int(_rand)].withAlphaComponent(1.0)
            cell.updateLabel(nil, _subtitle: nil, _image : nil)
            
            let currentAnswer = answerStack[indexPath.row]
            // let _answer = allAnswers[indexPath.row]
            
            /* GET ANSWER PREVIEW IMAGE FROM STORAGE */
            if currentAnswer.answer.thumbImage != nil && currentAnswer.gettingImageForAnswerPreview {

                cell.updateImage(image: currentAnswer.answer.thumbImage!)
            } else if currentAnswer.gettingImageForAnswerPreview {
                
                //ignore if already fetching the image, so don't refetch if already getting
            } else {
                answerStack[indexPath.row].gettingImageForAnswerPreview = true
                
                Database.getImage(.AnswerThumbs, fileID: currentAnswer.answer.aID, maxImgSize: maxImgSize, completion: {(_data, error) in
                    if error == nil {
                        let _answerPreviewImage = GlobalFunctions.createImageFromData(_data!)
                        self.answerStack[indexPath.row].answer.thumbImage = _answerPreviewImage
                        
                        DispatchQueue.main.async {
                            cell.updateImage(image: self.answerStack[indexPath.row].answer.thumbImage)
                        }
                    } else {
                        cell.updateImage(image: nil)
                    }
                })
            }
            
            /* GET QUESTION FROM DATABASE - SHOWING ALL ANSWERS FOR ONE USER CASE */
            if selectedUser != nil {
                if currentAnswer.question != nil && currentAnswer.gettingInfoForAnswerPreview {
                    cell.updateLabel(currentAnswer.question!.qTitle, _subtitle: nil)
                } else if currentAnswer.gettingInfoForAnswerPreview {
                    //ignore if already fetching the image, so don't refetch if already getting
                } else {
                    
                    answerStack[indexPath.row].gettingInfoForAnswerPreview = true
                    
                    Database.getQuestion(currentAnswer.answer.qID, completion: { (question, error) in
                        if error != nil {
                            self.answerStack[indexPath.row].question = nil
                        } else {
                            self.answerStack[indexPath.row].question = question
                            cell.updateLabel(question?.qTitle, _subtitle: nil)
                        }
                    })
                }
            }
            /* GET NAME & BIO FROM DATABASE - SHOWING MANY ANSWERS FROM MANY USERS CASE */
            else if answerStack[indexPath.row].user != nil && answerStack[indexPath.row].gettingInfoForAnswerPreview {

                cell.updateLabel(answerStack[indexPath.row].user!.name?.capitalized, _subtitle: answerStack[indexPath.row].user!.shortBio?.capitalized)
            } else if answerStack[indexPath.row].gettingInfoForAnswerPreview {
                
                //ignore if already fetching the image, so don't refetch if already getting
            } else {

                answerStack[indexPath.row].gettingInfoForAnswerPreview = true
                
                Database.getUserSummaryForAnswer(currentAnswer.answer.aID, completion: { (user, error) in
                    if error != nil {
                        self.answerStack[indexPath.row].user = nil
                    } else {
                        self.answerStack[indexPath.row].user = user
                        cell.updateLabel(user?.name?.capitalized, _subtitle: user?.shortBio?.capitalized)
                    }
                })
            }
            
            if indexPath == selectedIndex && indexPath == deselectedIndex {
                //only show answer by selected user - removes other answers from qAnswers array and creates blank dummy tag
                if selectedUser != nil {
                    let selectedQuestion = currentAnswer.question
                    let currentTag = Tag(tagID: currentAnswer.question!.getTag())
                    selectedQuestion?.qAnswers = [currentAnswer.answer.aID]
                    showQuestion(selectedQuestion,
                                 allQuestions: [selectedQuestion],
                                 questionIndex: selectedQuestionIndex,
                                 answerIndex: 0,
                                 selectedTag: currentTag)
                } else {
                    showQuestion(selectedQuestion,
                                 allQuestions: [selectedQuestion],
                                 //allQuestions: allQuestions,
                                 questionIndex: selectedQuestionIndex,
                                 answerIndex: indexPath.row,
                                 selectedTag: selectedTag)
                }
            } else if indexPath == selectedIndex {
                cell.showAnswer(answer: selectedAnswer)
            } else if indexPath == deselectedIndex {
                cell.removeAnswer()
            }
            
            return cell
        
        case .people:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionAnswerReuseIdentifier, for: indexPath) as! FeedAnswerCell
            let _rand = arc4random_uniform(UInt32(_backgroundColors.count))
            
            cell.contentView.backgroundColor = _backgroundColors[Int(_rand)].withAlphaComponent(1.0)

            cell.updateLabel(nil, _subtitle: nil, _image : nil)

            let _user = allUsers[indexPath.row]

            if !_user.uCreated { //search case - get question from database
                Database.getUser(_user.uID!, completion: { (user, error) in
                    if error == nil {
                        cell.updateLabel(user.name?.capitalized, _subtitle: user.shortBio)

                        self.allUsers[indexPath.row] = user

                        if let _uPic = user.profilePic {
                            DispatchQueue.global(qos: .background).async {
                                if let _userImageData = try? Data(contentsOf: URL(string: _uPic)!) {
                                    DispatchQueue.main.async {
                                        self.allUsers[indexPath.row].thumbPicImage = UIImage(data: _userImageData)
                                        cell.updateImage(image : UIImage(data: _userImageData))
                                    }
                                }
                            }
                        }
                    }
                })
            } else {
                cell.updateLabel(_user.name?.capitalized, _subtitle: _user.shortBio)
                cell.updateImage(image: nil)
                if _user.thumbPicImage != nil {
                    cell.updateImage(image : _user.thumbPicImage)
                }
                else if let _uPic = _user.thumbPic {
                    DispatchQueue.global(qos: .background).async {
                        if let _userImageData = try? Data(contentsOf: URL(string: _uPic)!) {
                            DispatchQueue.main.async {
                                self.allUsers[indexPath.row].thumbPicImage = UIImage(data: _userImageData)
                                cell.updateImage(image : UIImage(data: _userImageData))
                            }
                        }
                    }
                }
            }
            return cell
        }
    }
    
    //Did select item at index path
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        
        if let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
            let cellRect = attributes.frame
            initialFrame = collectionView.convert(cellRect, to: collectionView.superview)
        }
        
        switch feedItemType! {
        case .tag:
            selectedTag = allTags[indexPath.row]
        case .question:
            selectedQuestion = allQuestions[indexPath.row]
            selectedQuestionIndex = indexPath.row
        case .people:
            selectedUser = allUsers[indexPath.row]
        case .answer:
            selectedAnswer = allAnswers[indexPath.row]
        }
        
        selectedIndex = indexPath
    }
    
    //Should select item at indexPath
    func collectionView(_ collectionView: UICollectionView,
                        shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

extension FeedVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (feedCollectionView!.frame.width / 2 - 0.5),
                      height: minCellHeight)
    }
}

extension FeedVC: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if presented is QAManagerVC {
            panDismissInteractionController.wireToViewController(QAVC, toViewController: nil, edge: UIRectEdge.left)
            
            let animator = ExpandAnimationController()
            animator.initialFrame = initialFrame
            animator.exitFrame = rectToLeft
            
            return animator
        } else {
            return nil
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is QAManagerVC {
            let animator = PanAnimationController()

            animator.initialFrame = rectToLeft
            animator.exitFrame = rectToRight
            animator.transitionType = .dismiss
            return animator
        } else {
            return nil
        }
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return panPresentInteractionController.interactionInProgress ? panPresentInteractionController : nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return panDismissInteractionController.interactionInProgress ? panDismissInteractionController : nil
    }
}
