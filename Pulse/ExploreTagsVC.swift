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
    func showQuestion(_ _selectedQuestion : Question?, _allQuestions: [Question?], _questionIndex : Int, _selectedTag : Tag)
    func showTagDetail(_ _selectedTag : Tag)
}

protocol ParentDelegate : class {
    func returnToParent(_:UIViewController)
}

class ExploreTagsVC: UIViewController, ExploreDelegate, ParentDelegate {
    fileprivate var _allTags = [Tag]()
    fileprivate var _currentTag : Tag?
    fileprivate var _loadedBackgroundView = false
    var returningToExplore = false
    
    fileprivate var _backgroundVC : AccountLoginManagerVC!
    fileprivate let _reuseIdentifier = "tagCell"
    
    @IBOutlet weak var ExploreTags: UICollectionView!
    @IBOutlet weak var logoIcon: UIView!
    
    fileprivate var _panCurrentPointY : CGFloat = 0
    fileprivate var _isBackgroundVCVisible = false
    
    fileprivate var currentSavedTagIndex : IndexPath? {
        didSet {
            if (savedTags?.append(currentSavedTagIndex!) == nil) {
                savedTags = [currentSavedTagIndex!]
            }
            ExploreTags.reloadItems(at: [currentSavedTagIndex!])
        }
    }
    
    fileprivate var currentRemovedTagIndex : IndexPath? {
        didSet {
            if let _removalIndex = savedTags?.index(of: currentRemovedTagIndex!) {
                savedTags?.remove(at: _removalIndex)
            }
            ExploreTags.reloadItems(at: [currentRemovedTagIndex!])
        }
    }
    
    fileprivate var savedTags : [IndexPath]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        _panGesture.minimumNumberOfTouches = 1
        view.addGestureRecognizer(_panGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !returningToExplore {
            loadTagsFromFirebase()
            
            let pulseIcon = Icon(frame: CGRect(x: 0,y: 0,width: logoIcon.frame.width, height: logoIcon.frame.height))
            pulseIcon.drawIconBackground(iconBackgroundColor)
            pulseIcon.drawIcon(iconColor, iconThickness: 2)
            logoIcon.addSubview(pulseIcon)
            
            if !_loadedBackgroundView {
                let _bounds = self.view.bounds
                _backgroundVC = AccountLoginManagerVC()
                _backgroundVC.view.frame = CGRect(x: _bounds.minX, y: -_bounds.height, width: _bounds.width, height: _bounds.height)
                _loadedBackgroundView = true
                GlobalFunctions.addNewVC(_backgroundVC, parentVC: self)
            }
        } else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func loadTagsFromFirebase() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        Database.getExploreTags() { (tags , error) in
            if error != nil {
                print(error!.description)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            } else {
                self._allTags = tags
                self.ExploreTags.delegate = self
                self.ExploreTags.dataSource = self
                self.ExploreTags.reloadData()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
    
    func showQuestion(_ _selectedQuestion : Question?, _allQuestions : [Question?], _questionIndex : Int, _selectedTag : Tag) {
        let detailVC = FeedVC()
        detailVC.view.frame = view.bounds
        detailVC.feedItemType = .answer
        detailVC.selectedTag = _selectedTag
        detailVC.selectedQuestion = _selectedQuestion
        
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
    
    func showTagDetail(_ _selectedTag : Tag) {
        let detailVC = FeedVC()
        detailVC.view.frame = view.bounds

//        detailVC.pageType = .Detail
        detailVC.feedItemType = .question
//        detailVC.currentTag = _selectedTag

        GlobalFunctions.addNewVC(detailVC, parentVC: self)
    }
    
    func showTagDetailTap(_ sender : UITapGestureRecognizer) {
        let _tagToShow = _allTags[sender.view!.tag]
        showTagDetail(_tagToShow)
    }
    
    func moveAccountPage(_ _directionToMove: AnimationStyle) {
        GlobalFunctions.moveView(_backgroundVC.view, animationStyle: _directionToMove, parentView: view)
    }
    
    func returnToParent(_ currentVC : UIViewController) {
        returningToExplore = true
        GlobalFunctions.dismissVC(currentVC)
    }
    
    ///Save / Unsave tag and update user profile
    func handleLongPress(_ longPress : UILongPressGestureRecognizer) {
        if longPress.state == UIGestureRecognizerState.began {
            let point = longPress.location(in: ExploreTags)
            let index = ExploreTags.indexPathForItem(at: point)
            
            if let _index = index {
                let _tag = _allTags[(_index as NSIndexPath).row]

                if User.currentUser?.savedTags != nil && User.currentUser!.savedTags[_tag.tagID!] != nil {
                    Database.pinTagForUser(_allTags[(_index as NSIndexPath).row], completion: {(success, error) in
                        if !success {
                            GlobalFunctions.showErrorBlock("Error Pinning Tag", erMessage: error!.localizedDescription)
                        }  else {
                            self.currentRemovedTagIndex = _index
                        }
                    })
                } else {
                    Database.pinTagForUser(_allTags[(_index as NSIndexPath).row], completion: {(success, error) in
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
    
    func handlePan(_ pan : UIPanGestureRecognizer) {
        let _ = pan.view!.center.x
        if (pan.state == UIGestureRecognizerState.began) {
            let translation = pan.translation(in: view)
            _panCurrentPointY = pan.view!.frame.origin.y + translation.y
        }
        else if (pan.state == UIGestureRecognizerState.ended) {
            let translation = pan.translation(in: view)

            switch translation {
            case _ where _panCurrentPointY > _backgroundVC.view.bounds.height / 3:
                moveAccountPage(.verticalDown)
                _isBackgroundVCVisible = true

                _panCurrentPointY = 0
            case _ where _panCurrentPointY < -(_backgroundVC.view.bounds.height / 3):
                moveAccountPage(.verticalUp)
                _isBackgroundVCVisible = false

                _panCurrentPointY = 0
            default:
                if !_isBackgroundVCVisible {
                    moveAccountPage(.verticalUp)
                    _panCurrentPointY = 0
                } else {
                    moveAccountPage(.verticalDown)
                    _panCurrentPointY = 0
                }

            }
        } else {
            let translation = pan.translation(in: _backgroundVC.view)
            if _isBackgroundVCVisible {
                if translation.y < 0 {
                    _backgroundVC.view.center = CGPoint(x: _backgroundVC.view.center.x, y: _backgroundVC.view.center.y + translation.y)
                    _panCurrentPointY = _panCurrentPointY + translation.y
                    pan.setTranslation(CGPoint.zero, in: _backgroundVC.view)
                } else {
                    //don't allow pan up when account page is showing
                }
            }
            else if (translation.y > 0 || translation.y < 0) {
                _backgroundVC.view.center = CGPoint(x: _backgroundVC.view.center.x, y: _backgroundVC.view.center.y + translation.y)
                _panCurrentPointY = _panCurrentPointY + translation.y
                pan.setTranslation(CGPoint.zero, in: _backgroundVC.view)
            }
        }
    }
}

extension ExploreTagsVC : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _allTags.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int{
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 150)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: _reuseIdentifier, for: indexPath) as! ExploreTagCell
        
        cell.delegate = self
        _currentTag = _allTags[(indexPath as NSIndexPath).row]
        cell.currentTag = _allTags[(indexPath as NSIndexPath).row]
        configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: ExploreTagCell, indexPath: IndexPath) {
        if let _currentTag = _currentTag {
            cell.tagLabel.text = "#"+_currentTag.tagID!.uppercased()
            
            let tapLabel = UITapGestureRecognizer(target: self, action: #selector(showTagDetailTap(_:)))
            cell.tagLabel.isUserInteractionEnabled = true
            cell.tagLabel.tag = (indexPath as NSIndexPath).row
            cell.tagLabel.addGestureRecognizer(tapLabel)
            
            let _longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            _longPress.minimumPressDuration = 0.5
            cell.tagLabel.addGestureRecognizer(_longPress)
            
            if let _tagImage = _currentTag.previewImage {
                Database.getTagImage(_tagImage, maxImgSize: maxImgSize, completion: {(data, error) in
                    if error == nil {
                        cell.tagImage.image = UIImage(data: data!)
                        cell.tagImage.contentMode = UIViewContentMode.scaleAspectFill
                    }
                })
            }
            
            if savedTags != nil && savedTags!.contains(indexPath) {
                cell.toggleSaveTagIcon(.save)
            } else if User.currentUser?.savedTags != nil && User.currentUser!.savedTags[_currentTag.tagID!] != nil {
                cell.toggleSaveTagIcon(.save)
            }
            else {
                cell.keepSaveTagHidden()
            }
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        UNCOMMENT TO MAKE FULL TAG ROW CLICKABLE
//        currentTag = allTags[indexPath.row]
//        showTagDetail(currentTag)
    }
}

extension ExploreTagsVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.height / 3)
    }
}
