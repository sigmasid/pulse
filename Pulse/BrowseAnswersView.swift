//
//  BrowseAnswersView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/8/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class BrowseAnswersView: UIView {
    
    fileprivate var browseAnswers: UICollectionView!
    fileprivate var reuseIdentifier = "BrowseAnswersCell"
    fileprivate var browseAnswerPreviewImages : [UIImage?]!
    fileprivate var usersForAnswerPreviews : [User?]!
    fileprivate var answersForQuestion : [Answer?]!

    fileprivate var gettingImageForCell : [Bool]!
    fileprivate var gettingInfoForCell : [Bool]!
    fileprivate var isfirstTimeTransform = true
    
    fileprivate var cellWidth : CGFloat = 0
    fileprivate var spacerBetweenCells : CGFloat = 0
    
    /* set by parent */
    var currentQuestion : Question?
    var currentTag : Tag?
    weak var delegate : answerDetailDelegate!
    
    fileprivate var topHeaderView = UIView()
    fileprivate var addAnswerButton = UIButton()
    fileprivate var sortAnswersButton = UIButton()
    
    fileprivate var _questionLabel = UILabel()
    fileprivate var _tagLabel = UILabel()
    fileprivate var _answerCount = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, _currentQuestion : Question, _currentTag : Tag) {
        self.init(frame: frame)
        
        currentQuestion = _currentQuestion
        currentTag = _currentTag
        
        gettingImageForCell = [Bool](repeating: false, count: currentQuestion!.totalAnswers())
        gettingInfoForCell = [Bool](repeating: false, count: currentQuestion!.totalAnswers())
        browseAnswerPreviewImages = [UIImage?](repeating: nil, count: currentQuestion!.totalAnswers())
        usersForAnswerPreviews = [User?](repeating: nil, count: currentQuestion!.totalAnswers())
        
        backgroundColor = UIColor.init(red: 35 / 255, green: 31 / 255, blue: 32 / 255, alpha: 0.9)
        
        setupTopHeader()
        setupSortAnswersButton()
        setupAddAnswerButton()
        setupCollectionView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func setupTopHeader() {
        addSubview(topHeaderView)
        
        topHeaderView.translatesAutoresizingMaskIntoConstraints = false
        topHeaderView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        topHeaderView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.15).isActive = true
        topHeaderView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        topHeaderView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        topHeaderView.layoutIfNeeded()
        
        topHeaderView.backgroundColor = UIColor.white
        
        addSubview(_answerCount)
        addSubview(_questionLabel)
        addSubview(_tagLabel)

        _answerCount.translatesAutoresizingMaskIntoConstraints = false
        _answerCount.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        _answerCount.heightAnchor.constraint(equalTo: _answerCount.widthAnchor).isActive = true
        _answerCount.centerYAnchor.constraint(equalTo: topHeaderView.centerYAnchor).isActive = true
        _answerCount.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        _answerCount.layoutIfNeeded()
        
        _answerCount.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 10, 0)
        _answerCount.titleLabel!.font = UIFont.systemFont(ofSize: FontSizes.headline.rawValue, weight: UIFontWeightBold)
        _answerCount.titleLabel!.textColor = UIColor.white
        _answerCount.titleLabel!.textAlignment = .center
        _answerCount.setBackgroundImage(UIImage(named: "count-label"), for: UIControlState())
        _answerCount.imageView?.contentMode = .scaleAspectFit
        
        _questionLabel.translatesAutoresizingMaskIntoConstraints = false
        _questionLabel.leadingAnchor.constraint(equalTo: topHeaderView.leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        _questionLabel.topAnchor.constraint(equalTo: _answerCount.topAnchor, constant: -Spacing.xs.rawValue).isActive = true
        _questionLabel.trailingAnchor.constraint(equalTo: _answerCount.leadingAnchor, constant: -Spacing.s.rawValue).isActive = true
        
        _questionLabel.font = UIFont.systemFont(ofSize: FontSizes.headline.rawValue, weight: UIFontWeightRegular)
        _questionLabel.textColor = UIColor.black
        _questionLabel.textAlignment = .left
        _questionLabel.text = currentQuestion?.qTitle
        _questionLabel.numberOfLines = 0
        _questionLabel.layoutIfNeeded()
        
        _tagLabel.translatesAutoresizingMaskIntoConstraints = false
        _tagLabel.leadingAnchor.constraint(equalTo: topHeaderView.leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        _tagLabel.topAnchor.constraint(equalTo: _questionLabel.bottomAnchor).isActive = true
        _tagLabel.trailingAnchor.constraint(equalTo: _answerCount.leadingAnchor, constant: -Spacing.s.rawValue).isActive = true
        _tagLabel.font = UIFont.systemFont(ofSize: FontSizes.body.rawValue, weight: UIFontWeightBold)
        _tagLabel.textColor = UIColor.black
        _tagLabel.textAlignment = .left
        
        if let _currentTagTile = currentTag?.tagID {
            _tagLabel.text = "#\(_currentTagTile)"
        }
        
        if let _answerCountText = currentQuestion?.totalAnswers() {
            _answerCount.setTitle(String(_answerCountText), for: UIControlState())
        }
    }
    
    fileprivate func setupAddAnswerButton() {
        addSubview(addAnswerButton)
        
        addAnswerButton.translatesAutoresizingMaskIntoConstraints = false
        addAnswerButton.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        addAnswerButton.heightAnchor.constraint(equalTo: addAnswerButton.widthAnchor).isActive = true
        addAnswerButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        addAnswerButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.s.rawValue).isActive = true
        addAnswerButton.layoutIfNeeded()
        
        addAnswerButton.makeRound()
        addAnswerButton.backgroundColor = iconBackgroundColor
        addAnswerButton.setTitle("ADD ANSWER", for: UIControlState())
        addAnswerButton.titleLabel?.numberOfLines = 0
        addAnswerButton.titleLabel?.lineBreakMode = .byWordWrapping
        addAnswerButton.titleLabel?.textAlignment = .center
        addAnswerButton.titleLabel?.font = UIFont.systemFont(ofSize: FontSizes.caption2.rawValue, weight: UIFontWeightBold)
        addAnswerButton.addTarget(self, action: #selector(userClickedAddAnswer), for: UIControlEvents.touchDown)

    }
    
    fileprivate func setupSortAnswersButton() {
        addSubview(sortAnswersButton)
        
        sortAnswersButton.translatesAutoresizingMaskIntoConstraints = false
        sortAnswersButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        sortAnswersButton.topAnchor.constraint(equalTo: topHeaderView.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        sortAnswersButton.layoutIfNeeded()
        
        sortAnswersButton.backgroundColor = UIColor.clear
        sortAnswersButton.setImage(UIImage(named: "down-arrow"), for: UIControlState())
        sortAnswersButton.imageEdgeInsets = UIEdgeInsetsMake(5, -10, 5, 5)

        sortAnswersButton.titleLabel?.textColor = UIColor.white
        sortAnswersButton.titleLabel?.textAlignment = .right

        sortAnswersButton.setTitle("newest", for: UIControlState())
        sortAnswersButton.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        sortAnswersButton.titleLabel?.font = UIFont.systemFont(ofSize: FontSizes.headline.rawValue, weight: UIFontWeightBlack)
    }
    
    fileprivate func setupCollectionView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        
        browseAnswers = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        browseAnswers?.register(BrowseAnswersCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        addSubview(browseAnswers!)
        
        browseAnswers?.translatesAutoresizingMaskIntoConstraints = false
        browseAnswers?.topAnchor.constraint(equalTo: sortAnswersButton.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        browseAnswers?.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        browseAnswers?.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        browseAnswers?.bottomAnchor.constraint(equalTo: addAnswerButton.topAnchor, constant: -Spacing.m.rawValue).isActive = true
        browseAnswers?.layoutIfNeeded()
        
        cellWidth = browseAnswers.bounds.width * 0.6
        spacerBetweenCells = browseAnswers.bounds.width * 0.05
        
        browseAnswers?.backgroundColor = UIColor.clear
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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionView.collectionViewLayout.invalidateLayout()
        return currentQuestion!.totalAnswers()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int{
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BrowseAnswersCell
        
        if ((indexPath as NSIndexPath).row == 0 && isfirstTimeTransform) {
            // make a bool and set YES initially, this check will prevent fist load transform
            isfirstTimeTransform = false
        } else {
            cell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
            
        /* GET QUESTION PREVIEW IMAGE FROM STORAGE */
        if browseAnswerPreviewImages[(indexPath as NSIndexPath).row] != nil && gettingImageForCell[(indexPath as NSIndexPath).row] == true {
            cell.answerPreviewImage!.image = browseAnswerPreviewImages[(indexPath as NSIndexPath).row]!
        } else if gettingImageForCell[(indexPath as NSIndexPath).row] {
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            gettingImageForCell[(indexPath as NSIndexPath).row] = true

            Database.getImage(.AnswerThumbs, fileID: currentQuestion!.qAnswers![(indexPath as NSIndexPath).row], maxImgSize: maxImgSize, completion: {(_data, error) in
                if error != nil {
                    cell.answerPreviewImage?.backgroundColor = UIColor.red /* NEED TO CHANGE */
                } else {
                    
                    let _answerPreviewImage = GlobalFunctions.createImageFromData(_data!)
                    self.browseAnswerPreviewImages.insert(_answerPreviewImage, at: (indexPath as NSIndexPath).row)
                    cell.answerPreviewImage!.image = _answerPreviewImage
                }
            })
        }
        
        /* GET NAME & BIO FROM DATABASE */
        if usersForAnswerPreviews.count > (indexPath as NSIndexPath).row && gettingInfoForCell[(indexPath as NSIndexPath).row] == true {
            cell.answerPreviewName!.text = usersForAnswerPreviews[(indexPath as NSIndexPath).row]!.name
            cell.answerPreviewBio!.text = usersForAnswerPreviews[(indexPath as NSIndexPath).row]!.shortBio

        } else if gettingInfoForCell[(indexPath as NSIndexPath).row] {
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            gettingInfoForCell[(indexPath as NSIndexPath).row] = true
            
            Database.getUserSummaryForAnswer(currentQuestion!.qAnswers![(indexPath as NSIndexPath).row], completion: { (user, error) in
                if error != nil {
                    cell.answerPreviewName!.text = nil
                    cell.answerPreviewBio!.text = nil
                    self.usersForAnswerPreviews.insert(nil, at: (indexPath as NSIndexPath).row)
                } else {
                    cell.answerPreviewName!.text = user?.name
                    cell.answerPreviewBio!.text = user?.shortBio
                    self.usersForAnswerPreviews.insert(user, at: (indexPath as NSIndexPath).row)
                }
            })
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate.userSelectedFromExploreQuestions(indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: CGFloat(cellWidth), height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return spacerBetweenCells
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, collectionView.bounds.width * 0.2, 0, collectionView.bounds.width * 0.2)
    }
    
    //center the incoming cell -- doesn't work w/ paging enabled
    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                                targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let pageWidth : Float = Float(cellWidth + spacerBetweenCells) // width + space
        
        let currentOffset = Float(scrollView.contentOffset.x)
        let targetOffset = Float(targetContentOffset.pointee.x)
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

        targetContentOffset.pointee.x = CGFloat(currentOffset)
        scrollView.setContentOffset(CGPoint(x: CGFloat(newTargetOffset), y: scrollView.contentOffset.y), animated: true)
        
        let index : Int = Int(newTargetOffset / pageWidth)
        
        if (index == 0) { // If first index
            let cell = browseAnswers.cellForItem(at: IndexPath(item: index, section: 0))
            UIView.animate(withDuration: 0.2, animations: {
                cell!.transform = CGAffineTransform.identity
            }) 
            
            let nextCell = browseAnswers.cellForItem(at: IndexPath(item: index + 1, section: 0))
            UIView.animate(withDuration: 0.2, animations: {
                nextCell!.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) 
        } else {
            if let cell = browseAnswers.cellForItem(at: IndexPath(item: index, section: 0)) {
                UIView.animate(withDuration: 0.2, animations: {
                    cell.transform = CGAffineTransform.identity
                }) 
            }

            if let priorCell = browseAnswers.cellForItem(at: IndexPath(item: index - 1, section: 0)) {
                UIView.animate(withDuration: 0.2, animations: {
                    priorCell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }) 
            }
            
            if let nextCell = browseAnswers.cellForItem(at: IndexPath(item: index + 1, section: 0)) {
                UIView.animate(withDuration: 0.2, animations: {
                    nextCell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }) 
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
