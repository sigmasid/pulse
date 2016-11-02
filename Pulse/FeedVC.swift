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
            switch feedItemType! {
            case .tag:
                totalItemCount = allTags.count
            case .question:
                totalItemCount = allQuestions.count
            case .answer:
                totalItemCount = allAnswers.count

                gettingImageForCell = [Bool](repeating: false, count: totalItemCount)
                gettingInfoForCell = [Bool](repeating: false, count: totalItemCount)
                usersForAnswerPreviews = [User?](repeating: nil, count: totalItemCount)
                questionsForAnswerPreviews = [Question?](repeating: nil, count: totalItemCount)
            case .people:
                totalItemCount = allUsers.count
            }
            
            feedCollectionView?.delegate = self
            feedCollectionView?.dataSource = self
            feedCollectionView?.reloadData()
            
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
    
    fileprivate var totalItemCount = 0

    /* cache questions & answers that have been shown */
    fileprivate var gettingImageForCell : [Bool]!
    fileprivate var gettingInfoForCell : [Bool]!
    fileprivate var usersForAnswerPreviews : [User?]!
    fileprivate var questionsForAnswerPreviews : [Question?]!

    let collectionReuseIdentifier = "FeedCell"
    
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionReuseIdentifier, for: indexPath) as! FeedCell
        let _rand = arc4random_uniform(UInt32(_backgroundColors.count))
    
        cell.contentView.backgroundColor = _backgroundColors[Int(_rand)].withAlphaComponent(1.0)
        
        switch feedItemType! {
            
        /** FEED ITEM: QUESTION **/
        case .question:
            
            //clear the cells and set the item type first
            if cell.itemType == nil || cell.itemType != feedItemType {
                cell.itemType = .question
            }
            cell.updateLabel(nil, _subtitle: nil)
            cell.showAnswerCount()

            if allQuestions.count > indexPath.row && allQuestions[indexPath.row]!.qCreated {
                guard let _currentQuestion = allQuestions[indexPath.row] else { break }
                print("getting existing question with \(_currentQuestion.qID)")

                if let tagID = _currentQuestion.qTagID {
                    cell.updateLabel(_currentQuestion.qTitle, _subtitle: "#\(tagID.uppercased())")
                } else {
                    cell.updateLabel(_currentQuestion.qTitle, _subtitle: nil)
                }
                
                if _currentQuestion.hasAnswers() {
                    cell.answerCount.setTitle(String(_currentQuestion.totalAnswers()), for: UIControlState())
                } else {
                    cell.hideAnswerCount()
                }
            } else {
                print("getting question from database")
                Database.getQuestion(allQuestions[indexPath.row]!.qID, completion: { (question, error) in
                    if error == nil {
                        print("question title is \(question.qID)")
                        if let tagID = question.qTagID {
                            cell.updateLabel(question.qTitle, _subtitle: "#\(tagID.uppercased())")
                        } else {
                            cell.updateLabel(question.qTitle, _subtitle: nil)
                        }
                        self.allQuestions[indexPath.row] = question
                        cell.answerCount.setTitle(String(question.totalAnswers()), for: UIControlState())
                    }
                })
            }
            
        /** FEED ITEM: TAG **/
        case .tag:
            if cell.itemType == nil || cell.itemType != feedItemType {
                cell.itemType = .tag
            }
            cell.updateLabel(nil, _subtitle: nil)
            cell.showAnswerCount()

            if allTags.count > indexPath.row && allTags[indexPath.row].tagCreated {
                let _currentTag = allTags[indexPath.row]
                cell.updateLabel(_currentTag.tagID, _subtitle: _currentTag.tagDescription)
                cell.answerCount.setTitle(String(_currentTag.totalQuestionsForTag()), for: UIControlState())
            } else if allTags.count > indexPath.row {

                Database.getTag(allTags[indexPath.row].tagID!, completion: { (tag, error) in
                    if error == nil {
                        self.allTags[indexPath.row] = tag
                        cell.updateLabel(tag.tagID, _subtitle: tag.tagDescription)
                        cell.answerCount.setTitle(String(tag.totalQuestionsForTag()), for: UIControlState())
                    }
                })
            }
            
        /** FEED ITEM: ANSWER **/
        case .answer:
            if cell.itemType == nil || cell.itemType != feedItemType {
                cell.itemType = .answer
            }
            
            cell.hideAnswerCount()
            let _answer = allAnswers[indexPath.row]

            /* GET ANSWER PREVIEW IMAGE FROM STORAGE */
            if _answer.thumbImage != nil && gettingImageForCell[indexPath.row] == true {
                cell.updateImage(image: _answer.thumbImage!)
            } else if gettingImageForCell[indexPath.row] {
                //ignore if already fetching the image, so don't refetch if already getting
            } else {
                gettingImageForCell[indexPath.row] = true
                cell.updateImage(image: nil)
                
                Database.getImage(.AnswerThumbs, fileID: allAnswers[indexPath.row].aID, maxImgSize: maxImgSize, completion: {(_data, error) in
                    if error == nil {
                        let _answerPreviewImage = GlobalFunctions.createImageFromData(_data!)
                        self.allAnswers[indexPath.row].thumbImage = _answerPreviewImage
                        cell.updateImage(image: _answerPreviewImage)
                    } else {
                        cell.updateImage(image: nil)
                    }
                })
            }
            
            /* GET QUESTION FROM DATABASE - SHOWING ALL ANSWERS FOR ONE USER CASE */
            if selectedUser != nil {
                if questionsForAnswerPreviews.count > indexPath.row && gettingInfoForCell[indexPath.row] == true {
                    if let _question = questionsForAnswerPreviews[indexPath.row] {
                        cell.updateLabel(_question.qTitle, _subtitle: nil)
                    }
                } else if gettingInfoForCell[indexPath.row] {
                    //ignore if already fetching the image, so don't refetch if already getting
                } else {
                    cell.updateLabel(nil, _subtitle: nil)
                    gettingInfoForCell[indexPath.row] = true
                    
                    Database.getQuestion(allAnswers[indexPath.row].qID, completion: { (question, error) in
                        if error != nil {
                            self.questionsForAnswerPreviews[indexPath.row] = nil
                        } else {
                            cell.updateLabel(question.qTitle, _subtitle: nil)
                            self.questionsForAnswerPreviews[indexPath.row] = question
                        }
                    })
                }
            }
            /* GET NAME & BIO FROM DATABASE - SHOWING MANY ANSWERS CASE */
            else if usersForAnswerPreviews.count > indexPath.row && gettingInfoForCell[indexPath.row] == true {
                cell.hideAnswerCount()
                if let _user = usersForAnswerPreviews[indexPath.row] {
                    cell.updateLabel(_user.name?.capitalized, _subtitle: _user.shortBio?.capitalized)
                }
            } else if gettingInfoForCell[indexPath.row] {
                //ignore if already fetching the image, so don't refetch if already getting
            } else {
                cell.updateLabel(nil, _subtitle: nil)
                gettingInfoForCell[indexPath.row] = true
                
                Database.getUserSummaryForAnswer(allAnswers[indexPath.row].aID, completion: { (user, error) in
                    if error != nil {
                        self.usersForAnswerPreviews[indexPath.row] = nil
                    } else {
                        cell.updateLabel(user?.name?.capitalized, _subtitle: user?.shortBio?.capitalized)
                        self.usersForAnswerPreviews[indexPath.row] = user
                    }
                })
            }
            
            if indexPath == selectedIndex && indexPath == deselectedIndex {
                //only show answer by selected user - removes other answers from qAnswers array and creates blank tag
                if selectedUser != nil {
                    let selectedQuestion = questionsForAnswerPreviews[indexPath.row]
                    let currentTag = Tag(tagID: "ANSWERS")
                    selectedQuestion?.qAnswers = [allAnswers[indexPath.row].aID]
                    showQuestion(selectedQuestion, allQuestions: [selectedQuestion], questionIndex: 0, answerIndex: 0, selectedTag: currentTag)
                } else {
                    showQuestion(selectedQuestion, allQuestions: [selectedQuestion], questionIndex: 0, answerIndex: indexPath.row, selectedTag: selectedTag)
                }
            } else if indexPath == selectedIndex {
                cell.showAnswer(selectedAnswer.aID)
            } else if indexPath == deselectedIndex {
                cell.removeAnswer()
            }
            
        case .people:
            if cell.itemType == nil || cell.itemType != feedItemType {
                cell.itemType = .people
            }
            cell.updateLabel(nil, _subtitle: nil, _image : nil)
            cell.hideAnswerCount()

            let _user = allUsers[indexPath.row]

            if !_user.uCreated { //search case - get question from database
                Database.getUser(_user.uID!, completion: { (user, error) in
                    if error == nil {
                        cell.titleLabel.text = user.name
                        cell.subtitleLabel.text = user.shortBio
                        self.allUsers[indexPath.row] = user

                        if let _uPic = user.thumbPic {
                            DispatchQueue.global(qos: .background).async {
                                if let _userImageData = try? Data(contentsOf: URL(string: _uPic)!) {
                                    DispatchQueue.main.async {
                                        self.allUsers[indexPath.row].thumbPicImage = UIImage(data: _userImageData)
                                        cell.updateImage(image : UIImage(data: _userImageData), isThumbnail : true)
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
                    cell.updateImage(image : _user.thumbPicImage, isThumbnail : true)
                }
                else if let _uPic = _user.thumbPic {
                    DispatchQueue.global(qos: .background).async {
                        if let _userImageData = try? Data(contentsOf: URL(string: _uPic)!) {
                            DispatchQueue.main.async {
                                self.allUsers[indexPath.row].thumbPicImage = UIImage(data: _userImageData)
                                cell.updateImage(image : UIImage(data: _userImageData), isThumbnail : true)
                            }
                        }
                    }
                }
            }
        }
        return cell
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
}

extension FeedVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (feedCollectionView!.frame.width / 2 - 0.5),
                      height: max(minCellHeight , feedCollectionView!.frame.height / 3))
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
