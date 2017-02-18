//
//  AnswersCollectionVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/17/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

private let reuseIdentifier = "AnswerCell"

class AnswersCollection: UICollectionView, previewDelegate {
    //Delegate PreviewVC var - if user watches full preview then go to index 1 vs. index 0 in full screen
    var watchedFullPreview: Bool = false
    /** End Delegate Vars **/
    
    //Main data source var -
    public var allAnswers = [Answer]() {
        didSet {
            print("will set fired with \(allAnswers.count)")
            updateAnswerStack(answers: allAnswers)
            reloadData()
        }
    }
    public var selectedUser: User?

    //this ensures we are not fetching twice and also caches the data
    fileprivate var answerStack = [AnswerPreviewData]()
    struct AnswerPreviewData {
        var user : User?
        var answer : Answer!
        var question : Question?
        var answerCollection = [String]()
        
        var gettingImageForAnswerPreview : Bool = false
        var gettingInfoForAnswerPreview : Bool = false
    }
    fileprivate var selectedAnswer: Answer!
    
    /** Collection View Vars **/
    fileprivate let minCellHeight : CGFloat = 225
    fileprivate let headerHeight : CGFloat = 225
    
    fileprivate var initialFrame = CGRect.zero
    fileprivate var selectedIndex : IndexPath? {
        didSet {
            if selectedIndex != nil {
                reloadItems(at: [selectedIndex!])
                if deselectedIndex != nil && deselectedIndex != selectedIndex {
                    reloadItems(at: [deselectedIndex!])
                }
            }
        }
        willSet {
            if selectedIndex != nil {
                deselectedIndex = selectedIndex
            }
            
            if newValue == nil, let selectedIndex = selectedIndex {
                let cell = dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: selectedIndex) as! FeedAnswerCell
                cell.removeAnswer()
            }
        }
    }
    fileprivate var deselectedIndex : IndexPath?
    /** End Declarations **/

    internal func updateAnswerStack(answers: [Answer]) {
        for (index, answer) in answers.enumerated() {
            let currentAnswerData = AnswerPreviewData(user: nil,
                                                      answer: answer,
                                                      question: nil,
                                                      answerCollection: [],
                                                      gettingImageForAnswerPreview: false,
                                                      gettingInfoForAnswerPreview: false)
            answerStack.insert(currentAnswerData, at: index)
        }
    }
    
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        self.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("number of items in section are \(allAnswers.count)")
        return allAnswers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
            let cellRect = attributes.frame
            initialFrame = collectionView.convert(cellRect, to: collectionView.superview)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("cell for item at fired")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FeedAnswerCell
        
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
        
        /** GET NAME & BIO FROM DATABASE - SHOWING MANY ANSWERS FROM MANY USERS CASE **/
        else if answerStack[indexPath.row].user != nil && answerStack[indexPath.row].gettingInfoForAnswerPreview {
            
            cell.updateLabel(answerStack[indexPath.row].user!.name?.capitalized, _subtitle: answerStack[indexPath.row].user!.shortBio?.capitalized)
        } else if answerStack[indexPath.row].gettingInfoForAnswerPreview {
            
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            
            answerStack[indexPath.row].gettingInfoForAnswerPreview = true
            
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
        }
        
        if indexPath == selectedIndex && indexPath == deselectedIndex {
            //only show answer by selected user - removes other answers from qAnswers array and creates blank dummy tag
            //implement delegate show answer
        } else if indexPath == selectedIndex {
            //if answer has more than initial clip, show 'see more at the end'
            watchedFullPreview = false
            
            Database.getAnswerCollection(currentAnswer.answer.aID, completion: {(hasDetail, answerCollection) in
                if hasDetail {
                    cell.showTapForMore = true
                    self.answerStack[indexPath.row].answerCollection = answerCollection!
                } else {
                    cell.showTapForMore = false
                }
            })
            
            cell.delegate = self
            cell.showAnswer(answer: selectedAnswer)
            
        } else if indexPath == deselectedIndex {
            cell.removeAnswer()
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: reuseIdentifier, for: indexPath) as! UserProfileHeader
            headerView.backgroundColor = .white
            headerView.updateUserDetails(selectedUser: selectedUser!)
            
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
    }
}

extension AnswersCollection: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (frame.width - 20), height: minCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: frame.width, height: headerHeight)
    }
}

/* COLLECTION VIEW */
extension AnswersCollection  {
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateAnswerCell(_ cell: FeedAnswerCell, atIndexPath indexPath: IndexPath) {
        //to come
    }
    
    func updateOnscreenRows() {
        let visiblePaths = indexPathsForVisibleItems
        for indexPath in visiblePaths {
            let cell = cellForItem(at: indexPath) as! FeedAnswerCell
            updateAnswerCell(cell, atIndexPath: indexPath)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateOnscreenRows()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { updateOnscreenRows() }
    }
    
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
