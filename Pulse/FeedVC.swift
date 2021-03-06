//
//  FeedVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit


class FeedVC: UIViewController {
/**
    fileprivate var isLoaded = false
    fileprivate var panPresentInteractionController = PanEdgeInteractionController()
    fileprivate var panDismissInteractionController = PanEdgeInteractionController()
    
    fileprivate var initialFrame : CGRect!
    fileprivate var QAVC : ContentManagerVC!
    
    fileprivate var searchScope : FeedItemType? = .question
    var minCellHeight : CGFloat = 125

    //Delegate PreviewVC var - if user watches full preview then go to index 1 vs. index 0 in full screen
    var watchedFullPreview: Bool = false
    
    public func getScrollView() -> UICollectionView? {
        return feedCollectionView != nil ? feedCollectionView : nil
    }
    
    struct AnswerPreviewData {
        var user : User?
        var answer : Answer!
        var question : Question?
        var answerCollection = [String]()
        
        var gettingImageForAnswerPreview : Bool = false
        var gettingInfoForAnswerPreview : Bool = false
    }
    
    /* SET BY PARENT */
    var feedDelegate : feedVCDelegate!
    var feedItemType : FeedItemType! {
        didSet {
            minCellHeight = feedItemType == .answer ? 225 : 125
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
                                                       answerCollection: [],
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
                        let cell = feedCollectionView?.dequeueReusableCell(withReuseIdentifier: collectionAnswerReuseIdentifier, for: selectedIndex) as! ItemFullWidthCell
                        //cell.removeAnswer()
                    }
                default: return
                }
            }
        }
    }
    fileprivate var deselectedIndex : IndexPath?

    //var allTags : [Tag]!
    //var allQuestions : [Question?]!
    var allAnswers : [Answer]!
    var allUsers : [User]!
    
    var selectedUser : User!
    //var selectedTag : Tag!
    //var selectedQuestion : Question!
    var selectedAnswer: Answer!
    
    var selectedQuestionIndex = 0
    
    fileprivate var totalItemCount = 0

    fileprivate var answerStack = [AnswerPreviewData]()

    let collectionReuseIdentifier = "FeedTagCell"
    let collectionPeopleReuseIdentifier = "FeedPeopleCell"
    let collectionAnswerReuseIdentifier = "FeedAnswerCell"
    let collectionQuestionReuseIdentifier = "FeedQuestionCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            view.backgroundColor = UIColor(red: 249/255, green: 249/255, blue: 249/255, alpha: 1.0)
            
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
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10        
        
        feedCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        feedCollectionView?.register(FeedTagCell.self, forCellWithReuseIdentifier: collectionReuseIdentifier)
        feedCollectionView?.register(FeedQuestionCell.self, forCellWithReuseIdentifier: collectionQuestionReuseIdentifier)
        feedCollectionView?.register(ItemFullWidthCell.self, forCellWithReuseIdentifier: collectionAnswerReuseIdentifier)
        feedCollectionView?.register(FeedPeopleCell.self, forCellWithReuseIdentifier: collectionPeopleReuseIdentifier)

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
    
    func showQuestion(_ selectedQuestion : Question?, allQuestions : [Question?],
                        answerCollection: [String], questionIndex : Int, answerIndex : Int, selectedTag : Tag) {
        /**
        QAVC = ContentManagerVC()
        
        //need to be set first 
        QAVC.watchedFullPreview = watchedFullPreview
        QAVC.itemCollection = answerCollection
        QAVC.allAnswers = answerStack.map{ (answerData) -> Answer in answerData.answer }
        
        QAVC.selectedTag = selectedTag
        QAVC.allQuestions = allQuestions
        QAVC.currentQuestion = selectedQuestion
        QAVC.questionCounter = questionIndex
        QAVC.answerIndex = answerIndex
        QAVC.openingScreen = .question

        selectedIndex = nil
        
        QAVC.transitioningDelegate = self
        present(QAVC, animated: true, completion: nil)
         **/
    }
    
    func setSelectedIndex(index : IndexPath?) {
        if index != nil && feedItemType! == .answer {
            selectedAnswer = allAnswers[index!.row]
            deselectedIndex = nil
            selectedIndex = index!
        } else {
            selectedIndex = nil
            deselectedIndex = nil
        }
    }
    
    func clearSelected() {
        selectedQuestion = nil
        selectedAnswer = nil
        selectedUser = nil
        selectedTag = nil
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

            //clear the cells and set the item type first
            cell.updateLabel(nil, _subtitle: nil)
            cell.contentView.backgroundColor = .white

            if allQuestions.count > indexPath.row && allQuestions[indexPath.row]!.qTitle != nil {
                guard let _currentQuestion = allQuestions[indexPath.row] else { return cell }

                cell.updateLabel(_currentQuestion.qTitle, _subtitle: _currentQuestion.qTag?.tagTitle?.capitalized ?? nil)
                cell.answerCount.setTitle(String(_currentQuestion.totalAnswers()), for: UIControlState())
                
            } else {
                /**
                Database.getQuestion(allQuestions[indexPath.row]!.qID, completion: { (question, error) in

                    if let question = question {
                        if let tagTitle = question.qTag?.tagTitle  {
                            if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                DispatchQueue.main.async {
                                    cell.updateLabel(question.qTitle, _subtitle: tagTitle.capitalized)
                                    cell.answerCount.setTitle(String(question.totalAnswers()), for: UIControlState())
                                }
                            }
                            self.allQuestions[indexPath.row] = question
                        } else if let tag = self.allQuestions[indexPath.row]?.qTag {
                            if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                DispatchQueue.main.async {
                                    cell.updateLabel(question.qTitle, _subtitle: tag.tagTitle?.capitalized)
                                    cell.answerCount.setTitle(String(question.totalAnswers()), for: UIControlState())
                                }
                            }
                            self.allQuestions[indexPath.row] = question
                            self.allQuestions[indexPath.row]?.qTag = tag

                        } else {
                            if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                DispatchQueue.main.async {
                                    cell.updateLabel(question.qTitle, _subtitle: nil)
                                    cell.answerCount.setTitle(String(question.totalAnswers()), for: UIControlState())
                                }
                            }
                            self.allQuestions[indexPath.row] = question
                        }
                    }
                }) **/
            }
            return cell

        /** FEED ITEM: TAG **/
        case .tag:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionReuseIdentifier, for: indexPath) as! FeedTagCell
            
            cell.contentView.backgroundColor = .white
            cell.updateLabel(nil, _subtitle: nil)

            if allTags.count > indexPath.row && allTags[indexPath.row].tagCreated {
                let _currentTag = allTags[indexPath.row]
                cell.updateLabel(_currentTag.tagTitle, _subtitle: _currentTag.tagDescription)
                cell.answerCount.setTitle(String(_currentTag.totalItemsForTag()), for: UIControlState())
            } else if allTags.count > indexPath.row {
                /**
                Database.getTag(allTags[indexPath.row].tagID!, completion: { (tag, error) in
                    if error == nil {
                        self.allTags[indexPath.row] = tag
                        cell.updateLabel(tag.tagTitle, _subtitle: tag.tagDescription)
                        cell.answerCount.setTitle(String(tag.totalItemsForTag()), for: UIControlState())
                    }
                }) **/
            }
            return cell

        /** FEED ITEM: ANSWER **/
        case .answer:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionAnswerReuseIdentifier, for: indexPath) as! ItemFullWidthCell
            
            cell.contentView.backgroundColor = .white
            cell.updateLabel(nil, _subtitle: nil, _image : nil)
            
            let currentAnswer = answerStack[indexPath.row]
            
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
                        
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            DispatchQueue.main.async {
                                cell.updateImage(image: self.answerStack[indexPath.row].answer.thumbImage)
                            }
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
                    
                    /**
                    Database.getQuestion(currentAnswer.answer.qID, completion: { (question, error) in
                        if error != nil {
                            self.answerStack[indexPath.row].question = nil
                        } else {
                            self.answerStack[indexPath.row].question = question
                            cell.updateLabel(question?.qTitle, _subtitle: nil)
                        }
                    })
                    **/
                }
            }
            /* GET NAME & BIO FROM DATABASE - SHOWING MANY ANSWERS FROM MANY USERS CASE */
            else if answerStack[indexPath.row].user != nil && answerStack[indexPath.row].gettingInfoForAnswerPreview {

                cell.updateLabel(answerStack[indexPath.row].user!.name?.capitalized, _subtitle: answerStack[indexPath.row].user!.shortBio?.capitalized)
            } else if answerStack[indexPath.row].gettingInfoForAnswerPreview {
                
                //ignore if already fetching the image, so don't refetch if already getting
            } else {

                answerStack[indexPath.row].gettingInfoForAnswerPreview = true
                
                /**
                Database.getUserSummaryForAnswer(currentAnswer.answer.aID, completion: { (answer, user, error) in
                    if error != nil {
                        self.answerStack[indexPath.row].user = nil
                    } else {
                        let tempImage = self.answerStack[indexPath.row].answer.thumbImage
                        self.answerStack[indexPath.row].answer = answer
                        self.answerStack[indexPath.row].answer.thumbImage = tempImage
                        
                        self.answerStack[indexPath.row].user = user
                        cell.updateLabel(user?.name?.capitalized, _subtitle: user?.shortBio?.capitalized)
                    }
                })
                **/
            }
            
            if indexPath == selectedIndex && indexPath == deselectedIndex {
                //only show answer by selected user - removes other answers from qAnswers array and creates blank dummy tag
                if selectedUser != nil {
                    let selectedQuestion = currentAnswer.question
                    let currentTag = Tag(tagID: currentAnswer.question!.getTag())
                    //selectedQuestion?.qAnswers = [currentAnswer.answer.aID]
                    showQuestion(selectedQuestion,
                                 allQuestions: [selectedQuestion],
                                 answerCollection: currentAnswer.answerCollection,
                                 questionIndex: selectedQuestionIndex,
                                 answerIndex: 0,
                                 selectedTag: currentTag)
                } else {
                    showQuestion(selectedQuestion,
                                 allQuestions: [selectedQuestion],
                                 answerCollection: currentAnswer.answerCollection,
                                 questionIndex: selectedQuestionIndex,
                                 answerIndex: indexPath.row,
                                 selectedTag: selectedTag == nil ? Tag(tagID: selectedQuestion.getTag()) : selectedTag)
                }
            } else if indexPath == selectedIndex {
                //if answer has more than initial clip, show 'see more at the end'
                watchedFullPreview = false
                /**
                Database.getAnswerCollection(currentAnswer.answer.aID, completion: {(hasDetail, answerCollection) in
                    if hasDetail {
                        cell.showTapForMore = true
                        self.answerStack[indexPath.row].answerCollection = answerCollection!
                    } else {
                        cell.showTapForMore = false
                    }
                }) **/
                
                cell.delegate = self
                //cell.showPreview(answer: selectedAnswer)

            } else if indexPath == deselectedIndex {
                //cell.removeAnswer()
            }
            
            return cell
        
        case .people:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionPeopleReuseIdentifier, for: indexPath) as! FeedPeopleCell
            
            cell.contentView.backgroundColor = .white
            cell.updateLabel(nil, _subtitle: nil, _image : nil)

            let _user = allUsers[indexPath.row]

            if !_user.uCreated { //search case - get question from database
                Database.getUser(_user.uID!, completion: { (user, error) in
                    if let user = user {
                        cell.updateLabel(user.name?.capitalized, _subtitle: user.shortBio)

                        self.allUsers[indexPath.row] = user

                        if let _uPic = user.profilePic {
                            DispatchQueue.global(qos: .background).async {
                                if let _userImageData = try? Data(contentsOf: URL(string: _uPic)!) {
                                    self.allUsers[indexPath.row].thumbPicImage = UIImage(data: _userImageData)

                                    DispatchQueue.main.async {
                                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                            cell.updateImage(image : UIImage(data: _userImageData))
                                        }
                                    }
                                }
                            }
                        }
                    }
                })
            } else {
                cell.updateLabel(_user.name?.capitalized, _subtitle: _user.shortBio)
                if _user.thumbPicImage != nil {
                    cell.updateImage(image : _user.thumbPicImage)
                } else if let _uPic = _user.thumbPic {
                    DispatchQueue.global(qos: .background).async {
                        if let _userImageData = try? Data(contentsOf: URL(string: _uPic)!) {
                            self.allUsers[indexPath.row].thumbPicImage = UIImage(data: _userImageData)
                            
                            if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                DispatchQueue.main.async {
                                    cell.updateImage(image : UIImage(data: _userImageData))
                                }
                            }
                        }
                    }
                }
            }
            return cell
        }
    }
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateQuestionCell(_ cell: FeedQuestionCell, inCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
        if allQuestions.count > indexPath.row && allQuestions[indexPath.row]!.qTitle != nil {
            guard let _currentQuestion = allQuestions[indexPath.row] else { return }
            
            cell.updateLabel(_currentQuestion.qTitle, _subtitle: _currentQuestion.qTag?.tagTitle?.capitalized ?? nil)
            cell.answerCount.setTitle(String(_currentQuestion.totalAnswers()), for: UIControlState())
        }
    }
    
    func updateAnswerCell(_ cell: ItemFullWidthCell, inCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
        if allUsers != nil {
            let _user = allUsers[indexPath.row]
            cell.updateLabel(_user.name?.capitalized, _subtitle: _user.shortBio)
            if _user.thumbPicImage != nil {
                cell.updateImage(image : _user.thumbPicImage)
            }
        }
    }
    
    func updateOnscreenRows() {
        if let visiblePaths = feedCollectionView?.indexPathsForVisibleItems {
            for indexPath in visiblePaths {
                switch feedItemType! {
                case .question:
                    let cell = feedCollectionView?.cellForItem(at: indexPath) as! FeedQuestionCell
                    updateQuestionCell(cell, inCollectionView: feedCollectionView!, atIndexPath: indexPath)
                case .answer:
                    let cell = feedCollectionView?.cellForItem(at: indexPath) as! ItemFullWidthCell
                    updateAnswerCell(cell, inCollectionView: feedCollectionView!, atIndexPath: indexPath)

                default: return
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateOnscreenRows()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { updateOnscreenRows() }
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
        return CGSize(width: (feedCollectionView!.frame.width - 20),
                      height: minCellHeight)
    }
}

extension FeedVC: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if presented is ContentManagerVC {
            panDismissInteractionController.wireToViewController(QAVC, toViewController: nil, edge: UIRectEdge.left)
            
            let animator = ExpandAnimationController()
            animator.initialFrame = initialFrame
            animator.exitFrame = getRectToLeft()
            
            return animator
        } else {
            return nil
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is ContentManagerVC {
            let animator = PanAnimationController()

            animator.initialFrame = getRectToLeft()
            animator.exitFrame = getRectToRight()
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
 **/
}
