//
//  tagExploreCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ExploreTagCell: UICollectionViewCell {
    
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var tagImage: UIImageView!
    private var saveIcon : Save?

    @IBOutlet weak var ExploreQuestions: UICollectionView!
    weak var delegate : ExploreDelegate!
    weak var footerView : QuestionFooterCellView!

    var questionToShow = 6
    
    var _totalQuestions : Int!
    var _allQuestions = [Question?]()
    
    var _reachedEnd : CGFloat! {
        didSet {
            if (_reachedEnd <= 0 ) {
                footerView.hidden = true
                delegate.showTagDetail(currentTag)
            } else if (_reachedEnd <= 20 ){
                footerView.hidden = true
                ExploreQuestions.scrollToItemAtIndexPath(ExploreQuestions.indexPathsForVisibleItems().first!, atScrollPosition: UICollectionViewScrollPosition.Left, animated: true)
            }
        }
    }
    
    var currentTag : Tag! {
        didSet {
            if currentTag.totalQuestionsForTag() > 0 {
                _totalQuestions = currentTag.totalQuestionsForTag()
                ExploreQuestions.dataSource = self
                ExploreQuestions.delegate = self
                ExploreQuestions.backgroundColor = UIColor.clearColor()
                
                let _longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
                _longPress.minimumPressDuration = 0.5
                ExploreQuestions.addGestureRecognizer(_longPress)
            }
        }
    }
    
    private var currentSavedQuestionIndex : NSIndexPath? {
        didSet {
            if (savedQuestions?.append(currentSavedQuestionIndex!) == nil) {
                savedQuestions = [currentSavedQuestionIndex!]
            }
            ExploreQuestions.reloadItemsAtIndexPaths([currentSavedQuestionIndex!])
        }
    }
    
    private var currentRemovedQuestionIndex : NSIndexPath? {
        didSet {
            if let _removalIndex = savedQuestions?.indexOf(currentRemovedQuestionIndex!) {
                savedQuestions?.removeAtIndex(_removalIndex)
            }
            ExploreQuestions.reloadItemsAtIndexPaths([currentRemovedQuestionIndex!])
        }
    }
    
    private var savedQuestions : [NSIndexPath]?
    private let questionReuseIdentifier = "questionCell"
    private let questionFooterReuseIdentifier = "questionCellFooter"
    
    func handleLongPress(longPress : UIPanGestureRecognizer) {
        if longPress.state == UIGestureRecognizerState.Began {
            let point = longPress.locationInView(ExploreQuestions)
            let index = ExploreQuestions.indexPathForItemAtPoint(point)
            
            if let _index = index {
                if let question = _allQuestions[_index.row] {
                    if User.currentUser?.savedQuestions != nil && User.currentUser!.savedQuestions[question.qID] != nil {
                        Database.saveQuestion(question.qID, completion: {(success, error) in
                            if !success {
                                GlobalFunctions.showErrorBlock("Error Saving Question", erMessage: error!.localizedDescription)
                            } else {
                                self.currentRemovedQuestionIndex = _index
                            }
                        })
                    } else {
                        Database.saveQuestion(question.qID, completion: {(success, error) in
                            if !success {
                                GlobalFunctions.showErrorBlock("Error Removing Question", erMessage: error!.localizedDescription)
                            } else {
                                self.currentSavedQuestionIndex = _index
                            }
                        })
                    }
                }
            }
        }
    }
    
    func toggleSaveTagIcon(mode : SaveType) {
        saveIcon = Save(frame: CGRectMake(0, 0, IconSizes.XSmall.rawValue / 2, IconSizes.XSmall.rawValue / 2))
        saveIcon?.toggle(mode)
        addSubview(saveIcon!)
        
        saveIcon!.translatesAutoresizingMaskIntoConstraints = false
        saveIcon!.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -Spacing.s.rawValue).active = true
        saveIcon!.topAnchor.constraintEqualToAnchor(topAnchor, constant: Spacing.xs.rawValue).active = true
        saveIcon?.layoutIfNeeded()
    }
    
    
    func keepSaveTagHidden() {
        if saveIcon != nil {
            saveIcon!.removeFromSuperview()
        }
    }
}

extension ExploreTagCell: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(_totalQuestions, questionToShow)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(questionReuseIdentifier, forIndexPath: indexPath) as! ExploreQuestionCell
        cell.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.3 )

        if _allQuestions.count > indexPath.row {
            let _currentQuestion = _allQuestions[indexPath.row]
            cell.qTitle.text = _currentQuestion?.qTitle
            if savedQuestions != nil && savedQuestions!.contains(indexPath) {
                cell.toggleSaveIcon(.Save)
            } else if User.currentUser?.savedQuestions != nil && User.currentUser!.savedQuestions[_currentQuestion!.qID] != nil {
                cell.toggleSaveIcon(.Save)
            }
            else {
                cell.keepSaveHidden()
            }
        } else {
            Database.getQuestion(currentTag.questions![indexPath.row], completion: { (question, error) in
                if error == nil {
                    self._allQuestions.append(question)
                    cell.qTitle.text = question.qTitle
                    if self.savedQuestions != nil && self.savedQuestions!.contains(indexPath) {
                        cell.toggleSaveIcon(.Save)
                    } else if User.currentUser?.savedQuestions != nil && User.currentUser!.savedQuestions[question.qID] != nil {
                        cell.toggleSaveIcon(.Save)
                    }
                    else {
                        cell.keepSaveHidden()
                    }
                }
            })
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let _selectedQuestion = _allQuestions[indexPath.row]
        delegate.showQuestion(_selectedQuestion, _allQuestions: _allQuestions, _questionIndex: indexPath.row, _selectedTag : currentTag)
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView   {
        if (kind ==  UICollectionElementKindSectionFooter) {
            footerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: questionFooterReuseIdentifier, forIndexPath: indexPath) as! QuestionFooterCellView
            footerView.hidden = false
        }
        return footerView
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int{
        return 1
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let currentOffset = scrollView.contentOffset.x
        let maximumOffset = scrollView.contentSize.width - scrollView.frame.size.width
        
        _reachedEnd = maximumOffset - currentOffset
    }
}

extension ExploreTagCell: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width / 3, height: collectionView.frame.height)
    }
}