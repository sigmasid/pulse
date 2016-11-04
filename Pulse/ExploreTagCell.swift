//
//  tagExploreCell.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseDatabase
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


class ExploreTagCell: UICollectionViewCell {
    
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var tagImage: UIImageView!
    fileprivate var saveIcon : Save?

    @IBOutlet weak var ExploreQuestions: UICollectionView!
    weak var delegate : ExploreDelegate!
    weak var footerView : QuestionFooterCellView!

    var questionToShow = 6
    
    var _totalQuestions : Int!
    var _allQuestions = [Question?]()
    
    var _reachedEnd : CGFloat! {
        didSet {
            if (_reachedEnd <= 0 ) {
                footerView.isHidden = true
                delegate.showTagDetail(currentTag)
            } else if (_reachedEnd <= 20 ){
                footerView.isHidden = true
                ExploreQuestions.scrollToItem(at: ExploreQuestions.indexPathsForVisibleItems.first!, at: UICollectionViewScrollPosition.left, animated: true)
            }
        }
    }
    
    var currentTag : Tag! {
        didSet {
            if currentTag.totalQuestionsForTag() > 0 {
                _totalQuestions = currentTag.totalQuestionsForTag()
                ExploreQuestions.dataSource = self
                ExploreQuestions.delegate = self
                ExploreQuestions.backgroundColor = UIColor.clear
                
                let _longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
                _longPress.minimumPressDuration = 0.5
                ExploreQuestions.addGestureRecognizer(_longPress)
            }
        }
    }
    
    fileprivate var currentSavedQuestionIndex : IndexPath? {
        didSet {
            if (savedQuestions?.append(currentSavedQuestionIndex!) == nil) {
                savedQuestions = [currentSavedQuestionIndex!]
            }
            ExploreQuestions.reloadItems(at: [currentSavedQuestionIndex!])
        }
    }
    
    fileprivate var currentRemovedQuestionIndex : IndexPath? {
        didSet {
            if let _removalIndex = savedQuestions?.index(of: currentRemovedQuestionIndex!) {
                savedQuestions?.remove(at: _removalIndex)
            }
            ExploreQuestions.reloadItems(at: [currentRemovedQuestionIndex!])
        }
    }
    
    fileprivate var savedQuestions : [IndexPath]?
    fileprivate let questionReuseIdentifier = "questionCell"
    fileprivate let questionFooterReuseIdentifier = "questionCellFooter"
    
    func handleLongPress(_ longPress : UIPanGestureRecognizer) {
        if longPress.state == UIGestureRecognizerState.began {
            let point = longPress.location(in: ExploreQuestions)
            let index = ExploreQuestions.indexPathForItem(at: point)
            
            if let _index = index {
                if let question = _allQuestions[(_index as NSIndexPath).row] {
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
    
    func toggleSaveTagIcon(_ mode : SaveType) {
        saveIcon = Save(frame: CGRect(x: 0, y: 0, width: IconSizes.xSmall.rawValue / 2, height: IconSizes.xSmall.rawValue / 2))
        saveIcon?.toggle(mode)
        addSubview(saveIcon!)
        
        saveIcon!.translatesAutoresizingMaskIntoConstraints = false
        saveIcon!.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        saveIcon!.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xs.rawValue).isActive = true
        saveIcon?.layoutIfNeeded()
    }
    
    
    func keepSaveTagHidden() {
        if saveIcon != nil {
            saveIcon!.removeFromSuperview()
        }
    }
}

extension ExploreTagCell: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(_totalQuestions, questionToShow)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: questionReuseIdentifier, for: indexPath) as! ExploreQuestionCell
        cell.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.3 )

        if _allQuestions.count > (indexPath as NSIndexPath).row {
            let _currentQuestion = _allQuestions[(indexPath as NSIndexPath).row]
            cell.qTitle.text = _currentQuestion?.qTitle
            if savedQuestions != nil && savedQuestions!.contains(indexPath) {
                cell.toggleSaveIcon(.save)
            } else if User.currentUser?.savedQuestions != nil && User.currentUser!.savedQuestions[_currentQuestion!.qID] != nil {
                cell.toggleSaveIcon(.save)
            }
            else {
                cell.keepSaveHidden()
            }
        } else {
            Database.getQuestion(currentTag.questions![(indexPath as NSIndexPath).row]!.qID, completion: { (question, error) in
                if let question = question {
                    self._allQuestions.append(question)
                    cell.qTitle.text = question.qTitle
                    if self.savedQuestions != nil && self.savedQuestions!.contains(indexPath) {
                        cell.toggleSaveIcon(.save)
                    } else if User.currentUser?.savedQuestions != nil && User.currentUser!.savedQuestions[question.qID] != nil {
                        cell.toggleSaveIcon(.save)
                    }
                    else {
                        cell.keepSaveHidden()
                    }
                }
            })
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let _selectedQuestion = _allQuestions[(indexPath as NSIndexPath).row]
        delegate.showQuestion(_selectedQuestion, _allQuestions: _allQuestions, _questionIndex: (indexPath as NSIndexPath).row, _selectedTag : currentTag)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView   {
        if (kind ==  UICollectionElementKindSectionFooter) {
            footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: questionFooterReuseIdentifier, for: indexPath) as! QuestionFooterCellView
            footerView.isHidden = false
        }
        return footerView
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int{
        return 1
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let currentOffset = scrollView.contentOffset.x
        let maximumOffset = scrollView.contentSize.width - scrollView.frame.size.width
        
        _reachedEnd = maximumOffset - currentOffset
    }
}

extension ExploreTagCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width / 3, height: collectionView.frame.height)
    }
}
