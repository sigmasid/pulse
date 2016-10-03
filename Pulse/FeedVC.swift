//
//  FeedVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

protocol feedVCDelegate: class {
    func userSelectedTag(_ : Tag)
}

protocol searchVCDelegate: class {
    func userClickedSearch()
    func userCancelledSearch()
}

class FeedVC: UIViewController {
    
    fileprivate var isLoaded = false
    fileprivate var panPresentInteractionController = PanEdgeInteractionController()
    fileprivate var panDismissInteractionController = PanEdgeInteractionController()
    
    fileprivate var initialFrame : CGRect!
    fileprivate var rectToRight : CGRect!
    fileprivate var rectToLeft : CGRect!
    fileprivate var QAVC : QAManagerVC!
    
    var feedDelegate : feedVCDelegate!
    var searchDelegate : searchVCDelegate!
    
    var feedItemType : FeedItemType! {
        didSet {
            self.updateDataSource = true
        }
    }
    
    var updateDataSource : Bool = false {
        didSet {
            switch feedItemType! {
            case .tag:
                totalItemCount = allTags.count
            case .question:
                totalItemCount = allQuestions.count
            case .answer:
                totalItemCount = allAnswers.count

                gettingImageForCell = [Bool](repeating: false, count: totalItemCount)
                gettingInfoForCell = [Bool](repeating: false, count: totalItemCount)
                browseAnswerPreviewImages = [UIImage?](repeating: nil, count: totalItemCount)
                usersForAnswerPreviews = [User?](repeating: nil, count: totalItemCount)
            }
            
            FeedCollectionView?.delegate = self
            FeedCollectionView?.dataSource = self
            FeedCollectionView?.reloadData()
            FeedCollectionView?.layoutIfNeeded()
        }
    }
    
    fileprivate var FeedCollectionView : UICollectionView?
    
    fileprivate var selectedIndex : IndexPath? {
        didSet {
            if selectedIndex != nil && feedItemType! == .question {
                FeedCollectionView?.reloadItems(at: [selectedIndex!])
                if deselectedIndex != nil && deselectedIndex != selectedIndex {
                    FeedCollectionView?.reloadItems(at: [deselectedIndex!])
                }
            } else if selectedIndex != nil && feedItemType! == .tag {
                selectedIndex = nil
                if feedDelegate != nil {
                    feedDelegate.userSelectedTag(currentTag)
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
    
    var currentTag : Tag!
    var currentQuestion : Question!
    
    fileprivate var totalItemCount = 0

    /* cache questions & answers that have been shown */
    fileprivate var gettingImageForCell : [Bool]!
    fileprivate var gettingInfoForCell : [Bool]!
    fileprivate var browseAnswerPreviewImages : [UIImage?]!
    fileprivate var usersForAnswerPreviews : [User?]!
    
    let collectionReuseIdentifier = "FeedCell"
    let collectionHeaderReuseIdentifier = "SearchHeaderCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            rectToLeft = view.frame
            rectToLeft.origin.x = view.frame.minX - view.frame.size.width
            
            rectToRight = view.frame
            rectToRight.origin.x = view.frame.maxX
            
            setupScreenLayout()
            
            isLoaded = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        let offset = CGPoint(x : 0, y : searchBarHeight)
        FeedCollectionView?.setContentOffset(offset, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    fileprivate func setupScreenLayout() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.vertical
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        FeedCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        FeedCollectionView?.register(FeedCell.self, forCellWithReuseIdentifier: collectionReuseIdentifier)
        FeedCollectionView?.register(SearchHeaderCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: collectionHeaderReuseIdentifier)

        view.addSubview(FeedCollectionView!)
        
        FeedCollectionView?.translatesAutoresizingMaskIntoConstraints = false
        FeedCollectionView?.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        FeedCollectionView?.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        FeedCollectionView?.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        FeedCollectionView?.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        FeedCollectionView?.layoutIfNeeded()
        
        FeedCollectionView?.backgroundColor = UIColor.clear
        FeedCollectionView?.backgroundView = nil
        FeedCollectionView?.showsVerticalScrollIndicator = false
        FeedCollectionView?.isPagingEnabled = true
        
        let offset = CGPoint(x : 0, y : searchBarHeight)
        FeedCollectionView?.setContentOffset(offset, animated: true)
    }
    
    func showQuestion(_ _selectedQuestion : Question?, _allQuestions : [Question?], _questionIndex : Int, _selectedTag : Tag) {
        QAVC = QAManagerVC()
        QAVC.selectedTag = _selectedTag
        QAVC.allQuestions = _allQuestions
        QAVC.currentQuestion = _selectedQuestion
        QAVC.questionCounter = _questionIndex
        selectedIndex = nil
        
        QAVC.transitioningDelegate = self
        present(QAVC, animated: true, completion: nil)
    }
    
    func showSearch() {
        let searchVC = SearchVC()
        
        GlobalFunctions.addNewVC(searchVC, parentVC: self)
        
        if searchDelegate != nil {
            searchDelegate.userClickedSearch()
        }
    }
}

/* COLLECTION VIEW */
extension FeedVC : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalItemCount
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int{
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionReuseIdentifier, for: indexPath) as! FeedCell
        let _rand = arc4random_uniform(UInt32(_backgroundColors.count))
    
        cell.contentView.backgroundColor = _backgroundColors[Int(_rand)]
        
        if feedItemType! == .question {
            if cell.itemType == nil || cell.itemType != feedItemType {
                cell.itemType = .question
            }
            cell.updateLabel(nil, _subtitle: nil)

            if allQuestions.count > indexPath.row && allQuestions[indexPath.row]!.qTitle != nil {
                if let _currentQuestion = allQuestions[indexPath.row] {
                    if let tagID = _currentQuestion.qTagID {
                        cell.updateLabel(_currentQuestion.qTitle, _subtitle: "#\(tagID.uppercased())")
                    } else {
                        cell.updateLabel(_currentQuestion.qTitle, _subtitle: nil)
                    }
                    cell.answerCount.setTitle(String(_currentQuestion.totalAnswers()), for: UIControlState())
                }
            } else {
                Database.getQuestion(currentTag.questions![indexPath.row]!.qID, completion: { (question, error) in
                    if error == nil {
                        if let tagID = self.currentTag.questions![indexPath.row]!.qTagID {
                            cell.updateLabel(question.qTitle, _subtitle: "#\(tagID.uppercased())")
                        } else {
                            cell.updateLabel(question.qTitle, _subtitle: nil)
                        }
                        self.allQuestions[indexPath.row] = question
                        cell.answerCount.setTitle(String(question.totalAnswers()), for: UIControlState())
                    }
                })
            }
            
            if indexPath == selectedIndex && indexPath == deselectedIndex {
                if let _selectedQuestion = allQuestions[indexPath.row] {
                    showQuestion(_selectedQuestion, _allQuestions: allQuestions, _questionIndex: indexPath.row, _selectedTag: currentTag)
                }
            } else if indexPath == selectedIndex {
                if let _selectedQuestion = allQuestions[indexPath.row] {
                    if _selectedQuestion.hasAnswers() {
                        cell.showQuestion(_selectedQuestion)
                    }
                }
            } else if indexPath == deselectedIndex {
                cell.removeAnswer()
            }
            
        } else if feedItemType == .tag {
            if cell.itemType == nil || cell.itemType != feedItemType {
                cell.itemType = .tag
            }
            cell.updateLabel(nil, _subtitle: nil)
            
            if allTags.count > indexPath.row {
                let _currentTag = allTags[indexPath.row]
                cell.updateLabel("#\(_currentTag.tagID!.uppercased())", _subtitle: _currentTag.tagDescription)
                cell.answerCount.setTitle(String(_currentTag.totalQuestionsForTag()), for: UIControlState())
            }
        }
        else if feedItemType == .answer {
            if cell.itemType == nil || cell.itemType != feedItemType {
                cell.itemType = .answer
            }
            
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
                        cell.previewImage.backgroundColor = UIColor.red
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
                //  showQuestion(_selectedQuestion, _allQuestions: _allQuestions, _questionIndex: indexPath.row, _selectedTag: currentTag, _frame : _translatedFrame)
            } else if indexPath == selectedIndex {
                let _selectedAnswerID = currentQuestion.qAnswers![indexPath.row]
                cell.showAnswer(_selectedAnswerID)
            } else if indexPath == deselectedIndex {
                cell.removeAnswer()
            }
        }
        return cell
    }
    
    //Did select item at
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        
        if let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
            let cellRect = attributes.frame
            initialFrame = collectionView.convert(cellRect, to: collectionView.superview)
        }
        
        if feedItemType == .tag {
            currentTag = allTags[indexPath.row]
        } else if feedItemType == .question && currentTag == nil {
            if let _selectedQuestion = allQuestions[indexPath.row] {
                currentTag = Tag(tagID: "EXPLORE", questions: [Question(qID: _selectedQuestion.qID)])
            }
        }
        selectedIndex = indexPath
    }
    
    //Should select item at
    func collectionView(_ collectionView: UICollectionView,
                        shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    //Header cell
    func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: collectionHeaderReuseIdentifier,
                                                                             for: indexPath) as! SearchHeaderCell
            headerView.showSearchField.addTarget(self, action: #selector(showSearch), for: .touchUpInside)
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
    }
    
    //Size for header
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: searchBarHeight)
    }
}

extension FeedVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (FeedCollectionView!.frame.width / 2 - 0.5), height: max(minCellHeight , FeedCollectionView!.frame.height / 3))
    }
}

extension FeedVC: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
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
