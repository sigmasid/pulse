//
//  BrowseAnswersView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/8/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class BrowseAnswersView: UIView {
    private var browseAnswers: UICollectionView!
    private var reuseIdentifier = "BrowseAnswersCell"
    private var browseAnswerPreviewImages : [UIImage?]!
    private var usersForAnswerPreviews : [User?]!

    private var gettingImageForCell : [Bool]!
    private var gettingInfoForCell : [Bool]!
    
    weak var delegate : answerDetailDelegate!
    
    /* set by parent */
    var currentQuestion : Question?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, _currentQuestion : Question) {
        self.init(frame: frame)
        
        currentQuestion = _currentQuestion
        gettingImageForCell = [Bool](count: currentQuestion!.totalAnswers(), repeatedValue: false)
        gettingInfoForCell = [Bool](count: currentQuestion!.totalAnswers(), repeatedValue: false)
        browseAnswerPreviewImages = [UIImage?](count: currentQuestion!.totalAnswers(), repeatedValue: nil)
        usersForAnswerPreviews = [User?](count: currentQuestion!.totalAnswers(), repeatedValue: nil)
        
        let _layout = BrowseAnswersLayout()
        _layout.radius = bounds.height
        let itemSize = CGSize(width: bounds.width / 1.75, height: bounds.height * (2/3))
        _layout.itemSize = itemSize
        
        browseAnswers = UICollectionView(frame: bounds, collectionViewLayout: _layout)
        browseAnswers.registerClass(BrowseAnswersCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        browseAnswers.delegate = self
        browseAnswers.dataSource = self
        browseAnswers.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
        
        addSubview(browseAnswers)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension BrowseAnswersView : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionView.collectionViewLayout.invalidateLayout()
        return currentQuestion!.totalAnswers()
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int{
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: bounds.width, height: bounds.height)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! BrowseAnswersCell
        
        /* GET QUESTION PREVIEW IMAGE FROM STORAGE */
        if browseAnswerPreviewImages[indexPath.row] != nil && gettingImageForCell[indexPath.row] == true {
            cell.answerPreviewImage!.image = browseAnswerPreviewImages[indexPath.row]!
        } else if gettingImageForCell[indexPath.row] {
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            gettingImageForCell[indexPath.row] = true

            Database.getImage(.AnswerThumbs, fileID: currentQuestion!.qAnswers![indexPath.row]+".jpg", maxImgSize: maxImgSize, completion: {(_data, error) in
                if error != nil {
                    cell.answerPreviewImage?.backgroundColor = UIColor.redColor()
                } else {
                    let _answerPreviewImage = UIImage(data: _data!)
                    self.browseAnswerPreviewImages.insert(_answerPreviewImage, atIndex: indexPath.row)
                    cell.answerPreviewImage!.image = _answerPreviewImage
                }
            })
        }
        
        /* GET NAME & BIO FROM DATABASE */
        if usersForAnswerPreviews.count > indexPath.row && gettingInfoForCell[indexPath.row] == true {
            cell.answerPreviewName!.text = usersForAnswerPreviews[indexPath.row]!.name
            cell.answerPreviewBio!.text = usersForAnswerPreviews[indexPath.row]!.shortBio

        } else if gettingInfoForCell[indexPath.row] {
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            gettingInfoForCell[indexPath.row] = true
            
            Database.getUserSummaryForAnswer(currentQuestion!.qAnswers![indexPath.row], completion: { (user, error) in
                if error != nil {
                    cell.answerPreviewImage?.backgroundColor = UIColor.redColor()
                } else {
                    cell.answerPreviewName!.text = user?.name
                    cell.answerPreviewBio!.text = user?.shortBio
                    self.usersForAnswerPreviews.insert(user, atIndex: indexPath.row)
                }
            })
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        delegate.userSelectedFromExploreQuestions(indexPath)
    }
}
