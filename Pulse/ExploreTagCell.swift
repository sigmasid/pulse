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
    
    @IBOutlet weak var ExploreQuestions: UICollectionView!
    weak var delegate : ExploreDelegate!
    weak var footerView : QuestionFooterCellView!

    var questionToShow = 6
    
    var _totalQuestions : Int!
    var _allQuestions = [Question?]()
    
    var _reachedEnd : CGFloat! {
        didSet {
            print(_reachedEnd)
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
            if currentTag.totalQuestionsForTag() != nil {
                _totalQuestions = currentTag.totalQuestionsForTag()
                ExploreQuestions.dataSource = self
                ExploreQuestions.delegate = self
                ExploreQuestions.backgroundColor = UIColor.clearColor()
            }
        }
    }
    
    private let questionReuseIdentifier = "questionCell"
    private let questionFooterReuseIdentifier = "questionCellFooter"
}

extension ExploreTagCell: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(_totalQuestions, questionToShow)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(questionReuseIdentifier, forIndexPath: indexPath) as! ExploreQuestionCell
        cell.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.3 )

        if self._allQuestions.count > indexPath.row {
            let _currentQuestion = self._allQuestions[indexPath.row]
            cell.qTitle.text = _currentQuestion?.qTitle
        } else {
            Database.getQuestion(currentTag.questions![indexPath.row], completion: { (question, error) in
                if error == nil {
                    self._allQuestions.append(question)
                    cell.qTitle.text = question.qTitle
                }
            })
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let _selectedQuestion = self._allQuestions[indexPath.row]
        delegate.showQuestion(_selectedQuestion, _allQuestions: self._allQuestions, _questionIndex: indexPath.row, _selectedTag : currentTag)
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