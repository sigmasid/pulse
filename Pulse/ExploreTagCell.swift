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
    
    var loadingStatus = LoadMoreStatus.haveMore 
    var questionsShown = 5
    let questionsIncrement = 5
    
    var _totalQuestions : Int!
    var questionsList = [Question?]()
    
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
    
    func loadMoreQuestions(indexPath  : NSIndexPath) {
        if questionsShown == _totalQuestions {
            loadingStatus = .Finished
            return
        } else if questionsShown + questionsIncrement < _totalQuestions {
            questionsShown += questionsIncrement
            ExploreQuestions.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Left, animated: true)
            ExploreQuestions.reloadData()
            return
        } else {
            questionsShown += _totalQuestions - questionsShown
            ExploreQuestions.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Left, animated: true)
            loadingStatus = .Finished
            return
        }
    }
}

extension ExploreTagCell: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return questionsShown
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(questionReuseIdentifier, forIndexPath: indexPath) as! ExploreQuestionCell

        if self.questionsList.count > indexPath.row {
            let _currentQuestion = self.questionsList[indexPath.row]
            cell.qTitle.text = _currentQuestion?.qTitle
        } else {
            let questionRef = databaseRef.child("questions/\(self.currentTag.questions![indexPath.row])")
            questionRef.observeSingleEventOfType(.Value, withBlock: { snap in
                let _currentQuestion = Question(qID: snap.key, snapshot: snap)
                self.questionsList.append(_currentQuestion)
                cell.qTitle.text = _currentQuestion.qTitle
            })
        }
        
        if ( indexPath.row == questionsShown - 1) {
            if loadingStatus == .haveMore {
                self.performSelector(#selector(ExploreTagCell.loadMoreQuestions), withObject: indexPath, afterDelay: 0)
            }
        }
        return cell
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int{
        return 1
    }
}