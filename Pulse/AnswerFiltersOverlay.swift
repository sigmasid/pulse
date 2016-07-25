//
//  AnswerFiltersOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/20/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AnswerFiltersOverlay: UIView {
    var answerFilters: UICollectionView!
    var reuseIdentifier = "AnswerFilterCell"
    var answerFilterChoices = [Int : UIImage?]()
    
    var currentQuestion : Question?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        Database.getQuestion("-KLSfdkJklIi-rflTtN9", completion: { (question, error) in
            if error == nil {
                self.currentQuestion = question
                self.answerFilters = UICollectionView(frame: self.frame, collectionViewLayout: AnswerFiltersCollectionViewLayout())
                self.answerFilters.registerClass(AnswerFilterCell.self, forCellWithReuseIdentifier: self.reuseIdentifier)
                self.answerFilters.backgroundColor = UIColor.clearColor()
                self.answerFilters.delegate = self
                self.answerFilters.dataSource = self
                self.addSubview(self.answerFilters)
            }
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension AnswerFiltersOverlay : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionView.collectionViewLayout.invalidateLayout()
        return currentQuestion!.qFilters!.count ?? 0
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int{
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: self.frame.width, height: self.frame.height / 6)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! AnswerFilterCell
//        let _path = Database.getStoragePath(.Questions, itemID: currentQuestion!.qID).child("choices")
//        
//        if answerFilterChoices.count > indexPath.row {
//            cell.filterImageView!.image = answerFilterChoices[indexPath.row]!
//        } else {
//            Database.getImage(_path, fileID: currentQuestion!.qFilters![indexPath.row]+".jpg", maxImgSize: maxImgSize, completion: {(_data, error) in
//                let _filterImage = UIImage(data: _data!)
//                self.answerFilterChoices[indexPath.row] = _filterImage
//                cell.filterImageView!.image = _filterImage
//            })
//        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? AnswerFilterCell {
            
            //get indexpath of item at center of screen and scroll to that indexpath
            let newIndexPath = NSIndexPath(forItem: indexPath.row, inSection: 0)
            print(newIndexPath)

            print(collectionView.bounds)
            collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally , animated: true)
            
            cell.layer.borderColor = UIColor.redColor().CGColor
            cell.filterImageView!.alpha = 1.0
            cell.layer.borderWidth = 4
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? AnswerFilterCell {
            cell.layer.borderColor = UIColor.blackColor().CGColor
            cell.layer.borderWidth = 1
            cell.filterImageView!.alpha = 0.7
        }
    }
}


