//
//  ExploreTagsVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseDatabase

protocol QuestionDelegate : class {
    func showQuestion(_selectedQuestion : Question?, _allQuestions: [Question?], _questionIndex : Int, _selectedTag : Tag)
    func returnToExplore(_:UIViewController)
}

class ExploreTagsVC: UIViewController, QuestionDelegate {
    var allTags = [Tag]()
    var currentTag : Tag!
    var returningToExplore = false
    
    var questionsListener = UInt()

    private let reuseIdentifier = "tagCell"
    
    @IBOutlet weak var ExploreTags: UICollectionView!
    @IBOutlet weak var logoIcon: UIView!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if !returningToExplore {
            loadTagsFromFirebase()
            
            let pulseIcon = Icon(frame: CGRectMake(0,0,self.logoIcon.frame.width, self.logoIcon.frame.height))
            pulseIcon.drawIconBackground(iconBackgroundColor)
            pulseIcon.drawIcon(iconColor, iconThickness: 2)
            logoIcon.addSubview(pulseIcon)
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
        
        QAVC.exploreDelegate = self
        
        self.presentViewController(QAVC, animated: true, completion: nil)
    }
    
    func returnToExplore(_: UIViewController) {
        returningToExplore = true
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showTagDetailSegue") {
            let tagDetailVC = segue.destinationViewController as! TagDetailVC
            tagDetailVC.currentTag = currentTag
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
        cell.backgroundColor = UIColor.whiteColor()
        configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: ExploreTagCell, indexPath: NSIndexPath) {
        cell.tagLabel.text = "#"+currentTag.tagID!.uppercaseString
        
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
        currentTag = allTags[indexPath.row]
        self.performSegueWithIdentifier("showTagDetailSegue", sender: self)
    }
}

extension ExploreTagsVC: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width, height: self.view.frame.height / 3.5)
    }
}
