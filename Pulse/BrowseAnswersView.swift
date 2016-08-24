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
    private var answersForQuestion : [Answer?]!

    private var gettingImageForCell : [Bool]!
    private var gettingInfoForCell : [Bool]!
    private var isfirstTimeTransform = true
    
    private var cellWidth : CGFloat = 0
    private var spacerBetweenCells : CGFloat = 0
    
    /* set by parent */
    var currentQuestion : Question?
    var currentTag : Tag?
    weak var delegate : answerDetailDelegate!
    
    private var topHeaderView = UIView()
    private var addAnswerButton = UIButton()
    private var sortAnswersButton = UIButton()
    
    private var _questionLabel = UILabel()
    private var _tagLabel = UILabel()
    private var _answerCount = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, _currentQuestion : Question, _currentTag : Tag) {
        self.init(frame: frame)
        
        currentQuestion = _currentQuestion
        currentTag = _currentTag
        
        gettingImageForCell = [Bool](count: currentQuestion!.totalAnswers(), repeatedValue: false)
        gettingInfoForCell = [Bool](count: currentQuestion!.totalAnswers(), repeatedValue: false)
        browseAnswerPreviewImages = [UIImage?](count: currentQuestion!.totalAnswers(), repeatedValue: nil)
        usersForAnswerPreviews = [User?](count: currentQuestion!.totalAnswers(), repeatedValue: nil)
        
        backgroundColor = UIColor.init(red: 35 / 255, green: 31 / 255, blue: 32 / 255, alpha: 0.9)
        
        setupTopHeader()
        setupSortAnswersButton()
        setupAddAnswerButton()
        setupCollectionView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupTopHeader() {
        addSubview(topHeaderView)
        
        topHeaderView.translatesAutoresizingMaskIntoConstraints = false
        topHeaderView.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        topHeaderView.heightAnchor.constraintEqualToAnchor(heightAnchor, multiplier: 0.15).active = true
        topHeaderView.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        topHeaderView.leadingAnchor.constraintEqualToAnchor(leadingAnchor).active = true
        topHeaderView.layoutIfNeeded()
        
        topHeaderView.backgroundColor = UIColor.whiteColor()
        
        addSubview(_answerCount)
        addSubview(_questionLabel)
        addSubview(_tagLabel)

        _answerCount.translatesAutoresizingMaskIntoConstraints = false
        _answerCount.widthAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
        _answerCount.heightAnchor.constraintEqualToAnchor(_answerCount.widthAnchor).active = true
        _answerCount.centerYAnchor.constraintEqualToAnchor(topHeaderView.centerYAnchor).active = true
        _answerCount.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -Spacing.s.rawValue).active = true
        _answerCount.layoutIfNeeded()
        
        _answerCount.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 10, 0)
        _answerCount.titleLabel!.font = UIFont.systemFontOfSize(FontSizes.Headline.rawValue, weight: UIFontWeightBold)
        _answerCount.titleLabel!.textColor = UIColor.whiteColor()
        _answerCount.titleLabel!.textAlignment = .Center
        _answerCount.setBackgroundImage(UIImage(named: "count-label"), forState: .Normal)
        _answerCount.imageView?.contentMode = .ScaleAspectFit
        
        _questionLabel.translatesAutoresizingMaskIntoConstraints = false
        _questionLabel.leadingAnchor.constraintEqualToAnchor(topHeaderView.leadingAnchor, constant: Spacing.s.rawValue).active = true
        _questionLabel.topAnchor.constraintEqualToAnchor(_answerCount.topAnchor).active = true
        _questionLabel.trailingAnchor.constraintEqualToAnchor(_answerCount.leadingAnchor, constant: -Spacing.s.rawValue).active = true
        _questionLabel.font = UIFont.systemFontOfSize(FontSizes.Headline.rawValue, weight: UIFontWeightRegular)
        _questionLabel.textColor = UIColor.blackColor()
        _questionLabel.textAlignment = .Left
        _questionLabel.text = currentQuestion?.qTitle
        _questionLabel.numberOfLines = 0
        _questionLabel.layoutIfNeeded()
        
        _tagLabel.translatesAutoresizingMaskIntoConstraints = false
        _tagLabel.leadingAnchor.constraintEqualToAnchor(topHeaderView.leadingAnchor, constant: Spacing.s.rawValue).active = true
        _tagLabel.topAnchor.constraintEqualToAnchor(_questionLabel.bottomAnchor).active = true
        _tagLabel.trailingAnchor.constraintEqualToAnchor(_answerCount.leadingAnchor, constant: -Spacing.s.rawValue).active = true
        _tagLabel.font = UIFont.systemFontOfSize(FontSizes.Body.rawValue, weight: UIFontWeightBold)
        _tagLabel.textColor = UIColor.blackColor()
        _tagLabel.textAlignment = .Left
        
        if let _currentTagTile = currentTag?.tagID {
            _tagLabel.text = "#\(_currentTagTile)"
        }
        
        if let _answerCountText = currentQuestion?.totalAnswers() {
            _answerCount.setTitle(String(_answerCountText), forState: .Normal)
        }
    }
    
    private func setupAddAnswerButton() {
        addSubview(addAnswerButton)
        
        addAnswerButton.translatesAutoresizingMaskIntoConstraints = false
        addAnswerButton.widthAnchor.constraintEqualToConstant(IconSizes.Medium.rawValue).active = true
        addAnswerButton.heightAnchor.constraintEqualToAnchor(addAnswerButton.widthAnchor).active = true
        addAnswerButton.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -Spacing.s.rawValue).active = true
        addAnswerButton.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: -Spacing.s.rawValue).active = true
        addAnswerButton.layoutIfNeeded()
        
        addAnswerButton.makeRound()
        addAnswerButton.backgroundColor = iconBackgroundColor
        addAnswerButton.setTitle("ADD ANSWER", forState: .Normal)
        addAnswerButton.titleLabel?.numberOfLines = 0
        addAnswerButton.titleLabel?.lineBreakMode = .ByWordWrapping
        addAnswerButton.titleLabel?.textAlignment = .Center
        addAnswerButton.titleLabel?.font = UIFont.systemFontOfSize(FontSizes.Caption2.rawValue, weight: UIFontWeightBold)
        addAnswerButton.addTarget(self, action: #selector(userClickedAddAnswer), forControlEvents: UIControlEvents.TouchDown)

    }
    
    private func setupSortAnswersButton() {
        addSubview(sortAnswersButton)
        
        sortAnswersButton.translatesAutoresizingMaskIntoConstraints = false
        sortAnswersButton.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -Spacing.s.rawValue).active = true
        sortAnswersButton.topAnchor.constraintEqualToAnchor(topHeaderView.bottomAnchor, constant: Spacing.s.rawValue).active = true
        sortAnswersButton.layoutIfNeeded()
        
        sortAnswersButton.backgroundColor = UIColor.clearColor()
        sortAnswersButton.setImage(UIImage(named: "down-arrow"), forState: .Normal)
        sortAnswersButton.imageEdgeInsets = UIEdgeInsetsMake(5, -10, 5, 5)

        sortAnswersButton.titleLabel?.textColor = UIColor.whiteColor()
        sortAnswersButton.titleLabel?.textAlignment = .Right

        sortAnswersButton.setTitle("newest", forState: .Normal)
        sortAnswersButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        sortAnswersButton.titleLabel?.font = UIFont.systemFontOfSize(FontSizes.Headline.rawValue, weight: UIFontWeightBlack)
    }
    
    private func setupCollectionView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        
        browseAnswers = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
        browseAnswers?.registerClass(BrowseAnswersCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        addSubview(browseAnswers!)
        
        browseAnswers?.translatesAutoresizingMaskIntoConstraints = false
        browseAnswers?.topAnchor.constraintEqualToAnchor(sortAnswersButton.bottomAnchor, constant: Spacing.m.rawValue).active = true
        browseAnswers?.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        browseAnswers?.leadingAnchor.constraintEqualToAnchor(leadingAnchor).active = true
        browseAnswers?.bottomAnchor.constraintEqualToAnchor(addAnswerButton.topAnchor, constant: -Spacing.m.rawValue).active = true
        browseAnswers?.layoutIfNeeded()
        
        cellWidth = browseAnswers.bounds.width * 0.6
        spacerBetweenCells = browseAnswers.bounds.width * 0.05
        
        browseAnswers?.backgroundColor = UIColor.clearColor()
        browseAnswers?.showsHorizontalScrollIndicator = false
        
        browseAnswers?.delegate = self
        browseAnswers?.dataSource = self
        browseAnswers?.reloadData()
    }
    
    func userClickedAddAnswer() {
        delegate.userClickedAddAnswer()
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

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! BrowseAnswersCell
        
        if (indexPath.row == 0 && isfirstTimeTransform) {
            // make a bool and set YES initially, this check will prevent fist load transform
            isfirstTimeTransform = false
        } else {
            cell.transform = CGAffineTransformMakeScale(0.8, 0.8)
        }
            
        /* GET QUESTION PREVIEW IMAGE FROM STORAGE */
        if browseAnswerPreviewImages[indexPath.row] != nil && gettingImageForCell[indexPath.row] == true {
            cell.answerPreviewImage!.image = browseAnswerPreviewImages[indexPath.row]!
        } else if gettingImageForCell[indexPath.row] {
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            gettingImageForCell[indexPath.row] = true

            Database.getImage(.AnswerThumbs, fileID: currentQuestion!.qAnswers![indexPath.row], maxImgSize: maxImgSize, completion: {(_data, error) in
                if error != nil {
                    cell.answerPreviewImage?.backgroundColor = UIColor.redColor() /* NEED TO CHANGE */
                } else {
                    
                    let _answerPreviewImage = GlobalFunctions.createImageFromData(_data!)
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
                    cell.answerPreviewName!.text = nil
                    cell.answerPreviewBio!.text = nil
                    self.usersForAnswerPreviews.insert(nil, atIndex: indexPath.row)
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
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: CGFloat(cellWidth), height: collectionView.bounds.height)
    }
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return spacerBetweenCells
    }
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, collectionView.bounds.width * 0.2, 0, collectionView.bounds.width * 0.2)
    }
    
    //center the incoming cell -- doesn't work w/ paging enabled
    func scrollViewWillEndDragging(scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                                targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let pageWidth : Float = Float(cellWidth + spacerBetweenCells) // width + space
        
        let currentOffset = Float(scrollView.contentOffset.x)
        let targetOffset = Float(targetContentOffset.memory.x)
        var newTargetOffset : Float = 0
        
        if (targetOffset > currentOffset) {
            newTargetOffset = ceilf(currentOffset / pageWidth) * pageWidth
        } else {
            newTargetOffset = floorf(currentOffset / pageWidth) * pageWidth
        }
        
        if (newTargetOffset < 0) {
            newTargetOffset = 0
        } else if (newTargetOffset > Float(scrollView.contentSize.width)) {
            newTargetOffset = Float(scrollView.contentSize.width)
        }

        targetContentOffset.memory.x = CGFloat(currentOffset)
        scrollView.setContentOffset(CGPointMake(CGFloat(newTargetOffset), scrollView.contentOffset.y), animated: true)
        
        let index : Int = Int(newTargetOffset / pageWidth)
        
        if (index == 0) { // If first index
            let cell = browseAnswers.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0))
            UIView.animateWithDuration(0.2) {
                cell!.transform = CGAffineTransformIdentity
            }
            
            let nextCell = browseAnswers.cellForItemAtIndexPath(NSIndexPath(forItem: index + 1, inSection: 0))
            UIView.animateWithDuration(0.2) {
                nextCell!.transform = CGAffineTransformMakeScale(0.8, 0.8)
            }
        } else {
            if let cell = browseAnswers.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0)) {
                UIView.animateWithDuration(0.2) {
                    cell.transform = CGAffineTransformIdentity
                }
            }

            if let priorCell = browseAnswers.cellForItemAtIndexPath(NSIndexPath(forItem: index - 1, inSection: 0)) {
                UIView.animateWithDuration(0.2) {
                    priorCell.transform = CGAffineTransformMakeScale(0.8, 0.8)
                }
            }
            
            if let nextCell = browseAnswers.cellForItemAtIndexPath(NSIndexPath(forItem: index + 1, inSection: 0)) {
                UIView.animateWithDuration(0.2) {
                    nextCell.transform = CGAffineTransformMakeScale(0.8, 0.8)
                }
            }
        }
    }
}

//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: collectionView.bounds.width * 0.2, height: collectionView.bounds.height)
//    }

//    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView   {
//
//        if (kind ==  UICollectionElementKindSectionHeader) {
//            reusableSupplementaryView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier, forIndexPath: indexPath)
//            reusableSupplementaryView?.backgroundColor = UIColor.clearColor()
//        }
//        return reusableSupplementaryView!
//    }
//
