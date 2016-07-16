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
    var allTags = [Tag]()
    var currentTag : Tag!
    var returningToExplore = false
    var showAccountVC : AccountPageVC!
    
    var questionsListener = UInt()

    private let reuseIdentifier = "tagCell"
    
    @IBOutlet weak var ExploreTags: UICollectionView!
    @IBOutlet weak var logoIcon: UIView!
    
    private var panCurrentPointY : CGFloat = 0
    private var isAccountPageVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        _panGesture.minimumNumberOfTouches = 1
        self.view.addGestureRecognizer(_panGesture)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if !returningToExplore {
            loadTagsFromFirebase()
            
            let pulseIcon = Icon(frame: CGRectMake(0,0,self.logoIcon.frame.width, self.logoIcon.frame.height))
            pulseIcon.drawIconBackground(iconBackgroundColor)
            pulseIcon.drawIcon(iconColor, iconThickness: 2)
            logoIcon.addSubview(pulseIcon)

            let _bounds = self.view.bounds
            showAccountVC = storyboard!.instantiateViewControllerWithIdentifier("AccountPageVC") as? AccountPageVC
            showAccountVC.view.frame = CGRectMake(_bounds.minX, -_bounds.height, _bounds.width, _bounds.height)
            self.view.addSubview(showAccountVC.view)
        } else {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        databaseRef.removeObserverWithHandle(questionsListener)
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
                self.allTags = tags
                self.ExploreTags.delegate = self
                self.ExploreTags.dataSource = self
                self.ExploreTags.reloadData()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }
    }
    
    func showQuestion(_selectedQuestion : Question?, _allQuestions : [Question?], _questionIndex : Int, _selectedTag : Tag) {
        let QAVC = QAManagerVC()
        QAVC.selectedTag = _selectedTag
        QAVC.allQuestions = _allQuestions
        QAVC.currentQuestion = _selectedQuestion
        QAVC.questionCounter = _questionIndex
        QAVC.view.frame = self.view.bounds
        
        QAVC.returnToParentDelegate = self
        GlobalFunctions.addNewVC(QAVC, parentVC: self)
    }
    
    func showTagDetail(_selectedTag : Tag) {
        if let tagDetailVC = storyboard!.instantiateViewControllerWithIdentifier("tagDetailVC") as? TagDetailVC {
            tagDetailVC.currentTag = _selectedTag
            tagDetailVC.view.frame = self.view.bounds
        
            tagDetailVC.returnToParentDelegate = self
            GlobalFunctions.addNewVC(tagDetailVC, parentVC: self)
        }
    }
    
    func showTagDetailTap(sender : UITapGestureRecognizer) {
        let _tagToShow = allTags[sender.view!.tag]
        showTagDetail(_tagToShow)
    }
    
    func moveAccountPage(_directionToMove: AnimationStyle) {
        if showAccountVC != nil {
            GlobalFunctions.moveView(showAccountVC.view, animationStyle: _directionToMove, parentView: self.view)
        }
    }
    
    func returnToParent(currentVC : UIViewController) {
        returningToExplore = true
        GlobalFunctions.dismissVC(currentVC)
    }
    
    func handlePan(pan : UIPanGestureRecognizer) {
        let _ = pan.view!.center.x
        if (pan.state == UIGestureRecognizerState.Began) {
            let translation = pan.translationInView(self.view)
            panCurrentPointY = pan.view!.frame.origin.y + translation.y
        }
        else if (pan.state == UIGestureRecognizerState.Ended) {
            let translation = pan.translationInView(self.view)

            switch translation {
            case _ where panCurrentPointY > showAccountVC.view.bounds.height / 3:
                moveAccountPage(.VerticalDown)
                isAccountPageVisible = true
                panCurrentPointY = 0
            case _ where panCurrentPointY < -(showAccountVC.view.bounds.height / 3):
                moveAccountPage(.VerticalUp)
                isAccountPageVisible = false
                panCurrentPointY = 0
            default:
                if !isAccountPageVisible {
                    moveAccountPage(.VerticalUp)
                    panCurrentPointY = 0
                } else {
                    moveAccountPage(.VerticalDown)
                    panCurrentPointY = 0
                }

            }
        } else {
            let translation = pan.translationInView(showAccountVC.view)

            if (translation.y > 0 || translation.y < 0) {
                showAccountVC.view.center = CGPoint(x: showAccountVC.view.center.x, y: showAccountVC.view.center.y + translation.y)
                panCurrentPointY = panCurrentPointY + translation.y
                pan.setTranslation(CGPointZero, inView: showAccountVC.view)
            }
        }
    }
}

extension ExploreTagsVC : UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allTags.count
        
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int{
        return 1
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 150)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ExploreTagCell
        
        cell.delegate = self
        currentTag = allTags[indexPath.row]
        
        cell.currentTag = currentTag
        configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: ExploreTagCell, indexPath: NSIndexPath) {
        cell.tagLabel.text = "#"+currentTag.tagID!.uppercaseString
        
        let tapLabel = UITapGestureRecognizer(target: self, action: #selector(ExploreTagsVC.showTagDetailTap(_:)))
        cell.tagLabel.userInteractionEnabled = true
        cell.tagLabel.tag = indexPath.row
        cell.tagLabel.addGestureRecognizer(tapLabel)
        
        if let _tagImage = currentTag.previewImage {
            Database.getTagImage(_tagImage, maxImgSize: maxImgSize, completion: {(data, error) in
                if error != nil {
                    print (error?.localizedDescription)
                } else {
                    cell.tagImage.image = UIImage(data: data!)
                    cell.tagImage.contentMode = UIViewContentMode.ScaleAspectFill
                }
            })
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
        return CGSize(width: self.view.frame.width, height: self.view.frame.height / 3)
    }
}
