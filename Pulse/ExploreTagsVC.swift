//
//  ExploreTagsVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseDatabase

protocol ExploreDelegate : class {
    func showQuestion(_selectedQuestion : Question?, _allQuestions: [Question?], _questionIndex : Int, _selectedTag : Tag)
    func showTagDetail(_selectedTag : Tag)
}

protocol ParentDelegate : class {
    func returnToParent(_:UIViewController)
}

class ExploreTagsVC: UIViewController, ExploreDelegate, ParentDelegate {
    private var _allTags = [Tag]()
    private var _currentTag : Tag?
    private var _loadedBackgroundView = false
    var returningToExplore = false
    
    private var _backgroundVC : AccountLoginManagerVC!
    private let _reuseIdentifier = "tagCell"
    
    @IBOutlet weak var ExploreTags: UICollectionView!
    @IBOutlet weak var logoIcon: UIView!
    
    private var _panCurrentPointY : CGFloat = 0
    private var _isBackgroundVCVisible = false
    
    private var currentSavedTagIndex : NSIndexPath? {
        didSet {
            if (savedTags?.append(currentSavedTagIndex!) == nil) {
                savedTags = [currentSavedTagIndex!]
            }
            ExploreTags.reloadItemsAtIndexPaths([currentSavedTagIndex!])
        }
    }
    
    private var currentRemovedTagIndex : NSIndexPath? {
        didSet {
            if let _removalIndex = savedTags?.indexOf(currentRemovedTagIndex!) {
                savedTags?.removeAtIndex(_removalIndex)
            }
            ExploreTags.reloadItemsAtIndexPaths([currentRemovedTagIndex!])
        }
    }
    
    private var savedTags : [NSIndexPath]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        _panGesture.minimumNumberOfTouches = 1
        view.addGestureRecognizer(_panGesture)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if !returningToExplore {
            loadTagsFromFirebase()
            
            let pulseIcon = Icon(frame: CGRectMake(0,0,logoIcon.frame.width, logoIcon.frame.height))
            pulseIcon.drawIconBackground(iconBackgroundColor)
            pulseIcon.drawIcon(iconColor, iconThickness: 2)
            logoIcon.addSubview(pulseIcon)
            
            if !_loadedBackgroundView {
                let _bounds = self.view.bounds
                _backgroundVC = AccountLoginManagerVC()
                _backgroundVC.view.frame = CGRectMake(_bounds.minX, -_bounds.height, _bounds.width, _bounds.height)
                _loadedBackgroundView = true
                GlobalFunctions.addNewVC(_backgroundVC, parentVC: self)
            }
        } else {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func loadTagsFromFirebase() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        Database.getAllTags() { (tags , error) in
            if error != nil {
                print(error!.description)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            } else {
                self._allTags = tags
                self.ExploreTags.delegate = self
                self.ExploreTags.dataSource = self
                self.ExploreTags.reloadData()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }
    }
    
    func showQuestion(_selectedQuestion : Question?, _allQuestions : [Question?], _questionIndex : Int, _selectedTag : Tag) {
        let detailVC = FeedVC()
        detailVC.view.frame = view.bounds
        detailVC.pageType = .Detail
        detailVC.feedItemType = .Answer
        detailVC.currentTag = _selectedTag
        detailVC.currentQuestion = _selectedQuestion
        
        detailVC.returnToParentDelegate = self
        GlobalFunctions.addNewVC(detailVC, parentVC: self)
        
//        let QAVC = QAManagerVC()
//        QAVC.selectedTag = _selectedTag
//        QAVC.allQuestions = _allQuestions
//        QAVC.currentQuestion = _selectedQuestion
//        QAVC.questionCounter = _questionIndex
//        QAVC.view.frame = view.bounds
//        
//        QAVC.returnToParentDelegate = self
//        GlobalFunctions.addNewVC(QAVC, parentVC: self)
    }
    
    func showTagDetail(_selectedTag : Tag) {
        let detailVC = FeedVC()
        detailVC.view.frame = view.bounds
        detailVC.pageType = .Home

//        detailVC.pageType = .Detail
        detailVC.feedItemType = .Question
//        detailVC.currentTag = _selectedTag

        detailVC.returnToParentDelegate = self
        GlobalFunctions.addNewVC(detailVC, parentVC: self)
    }
    
    func showTagDetailTap(sender : UITapGestureRecognizer) {
        let _tagToShow = _allTags[sender.view!.tag]
        showTagDetail(_tagToShow)
    }
    
    func moveAccountPage(_directionToMove: AnimationStyle) {
        GlobalFunctions.moveView(_backgroundVC.view, animationStyle: _directionToMove, parentView: view)
    }
    
    func returnToParent(currentVC : UIViewController) {
        returningToExplore = true
        GlobalFunctions.dismissVC(currentVC)
    }
    
    ///Save / Unsave tag and update user profile
    func handleLongPress(longPress : UILongPressGestureRecognizer) {
        if longPress.state == UIGestureRecognizerState.Began {
            let point = longPress.locationInView(ExploreTags)
            let index = ExploreTags.indexPathForItemAtPoint(point)
            
            if let _index = index {
                let _tag = _allTags[_index.row]

                if User.currentUser?.savedTags != nil && User.currentUser!.savedTags[_tag.tagID!] != nil {
                    Database.pinTagForUser(_allTags[_index.row], completion: {(success, error) in
                        if !success {
                            GlobalFunctions.showErrorBlock("Error Pinning Tag", erMessage: error!.localizedDescription)
                        }  else {
                            self.currentRemovedTagIndex = _index
                        }
                    })
                } else {
                    Database.pinTagForUser(_allTags[_index.row], completion: {(success, error) in
                        if !success {
                            GlobalFunctions.showErrorBlock("Error Pinning Tag", erMessage: error!.localizedDescription)
                        }  else {
                            self.currentSavedTagIndex = _index
                        }
                    })
                }
            }
        }
    }
    
    func handlePan(pan : UIPanGestureRecognizer) {
        let _ = pan.view!.center.x
        if (pan.state == UIGestureRecognizerState.Began) {
            let translation = pan.translationInView(view)
            _panCurrentPointY = pan.view!.frame.origin.y + translation.y
        }
        else if (pan.state == UIGestureRecognizerState.Ended) {
            let translation = pan.translationInView(view)

            switch translation {
            case _ where _panCurrentPointY > _backgroundVC.view.bounds.height / 3:
                moveAccountPage(.VerticalDown)
                _isBackgroundVCVisible = true

                _panCurrentPointY = 0
            case _ where _panCurrentPointY < -(_backgroundVC.view.bounds.height / 3):
                moveAccountPage(.VerticalUp)
                _isBackgroundVCVisible = false

                _panCurrentPointY = 0
            default:
                if !_isBackgroundVCVisible {
                    moveAccountPage(.VerticalUp)
                    _panCurrentPointY = 0
                } else {
                    moveAccountPage(.VerticalDown)
                    _panCurrentPointY = 0
                }

            }
        } else {
            let translation = pan.translationInView(_backgroundVC.view)
            if _isBackgroundVCVisible {
                if translation.y < 0 {
                    _backgroundVC.view.center = CGPoint(x: _backgroundVC.view.center.x, y: _backgroundVC.view.center.y + translation.y)
                    _panCurrentPointY = _panCurrentPointY + translation.y
                    pan.setTranslation(CGPointZero, inView: _backgroundVC.view)
                } else {
                    //don't allow pan up when account page is showing
                }
            }
            else if (translation.y > 0 || translation.y < 0) {
                _backgroundVC.view.center = CGPoint(x: _backgroundVC.view.center.x, y: _backgroundVC.view.center.y + translation.y)
                _panCurrentPointY = _panCurrentPointY + translation.y
                pan.setTranslation(CGPointZero, inView: _backgroundVC.view)
            }
        }
    }
}

extension ExploreTagsVC : UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _allTags.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int{
        return 1
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 150)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(_reuseIdentifier, forIndexPath: indexPath) as! ExploreTagCell
        
        cell.delegate = self
        _currentTag = _allTags[indexPath.row]
        cell.currentTag = _allTags[indexPath.row]
        configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: ExploreTagCell, indexPath: NSIndexPath) {
        if let _currentTag = _currentTag {
            cell.tagLabel.text = "#"+_currentTag.tagID!.uppercaseString
            
            let tapLabel = UITapGestureRecognizer(target: self, action: #selector(showTagDetailTap(_:)))
            cell.tagLabel.userInteractionEnabled = true
            cell.tagLabel.tag = indexPath.row
            cell.tagLabel.addGestureRecognizer(tapLabel)
            
            let _longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            _longPress.minimumPressDuration = 0.5
            cell.tagLabel.addGestureRecognizer(_longPress)
            
            if let _tagImage = _currentTag.previewImage {
                Database.getTagImage(_tagImage, maxImgSize: maxImgSize, completion: {(data, error) in
                    if error != nil {
                        print (error?.localizedDescription)
                    } else {
                        cell.tagImage.image = UIImage(data: data!)
                        cell.tagImage.contentMode = UIViewContentMode.ScaleAspectFill
                    }
                })
            }
            
            if savedTags != nil && savedTags!.contains(indexPath) {
                cell.toggleSaveTagIcon(.Save)
            } else if User.currentUser?.savedTags != nil && User.currentUser!.savedTags[_currentTag.tagID!] != nil {
                cell.toggleSaveTagIcon(.Save)
            }
            else {
                cell.keepSaveTagHidden()
            }
        }

    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        UNCOMMENT TO MAKE FULL TAG ROW CLICKABLE
//        currentTag = allTags[indexPath.row]
//        showTagDetail(currentTag)
    }
}

extension ExploreTagsVC: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.height / 3)
    }
}
