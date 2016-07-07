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
    func showQuestion(_selectedQuestion : Question?, _allQuestions: [Question?], _questionIndex : Int)
}

class ExploreTagsVC: UIViewController, QuestionDelegate {
    var allTags = [Tag]()
    var currentTag : Tag!
    
    var questionsListener = UInt()
    var tagsListener = UInt()

    private let reuseIdentifier = "tagCell"
    
    @IBOutlet weak var ExploreTags: UICollectionView!
    @IBOutlet weak var logoIcon: UIView!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        loadTagsFromFirebase()
        
        let iconColor = UIColor( red: 255/255, green: 255/255, blue:255/255, alpha: 1.0 )
        let iconBackgroundColor = UIColor( red: 237/255, green: 19/255, blue:90/255, alpha: 1.0 )
        let pulseIcon = Icon(frame: CGRectMake(0,0,self.logoIcon.frame.width, self.logoIcon.frame.height))
        pulseIcon.drawIconBackground(iconBackgroundColor)
        pulseIcon.drawIcon(iconColor, iconThickness: 2)
        logoIcon.addSubview(pulseIcon)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        databaseRef.removeObserverWithHandle(tagsListener)
        databaseRef.removeObserverWithHandle(questionsListener)
    }
    
    func loadTagsFromFirebase() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
//        Database.getAllTags() { (tags , error) in
//            if error != nil {
//                print(error!.description)
//                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
//            } else {
//                self.allTags = tags
//                self.ExploreTags.delegate = self
//                self.ExploreTags.dataSource = self
//                self.ExploreTags.reloadData()
//                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
//            }
//        }
        tagsListener = databaseRef.child("tags").observeEventType(.Value, withBlock: { snapshot in
            for item in snapshot.children {
                let child = item as! FIRDataSnapshot
                self.currentTag = Tag(tagID: child.key, snapshot: child)
                self.allTags.append(self.currentTag)
            }
            self.ExploreTags.delegate = self
            self.ExploreTags.dataSource = self
            self.ExploreTags.reloadData()
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })
    }
    
    func showQuestion(_selectedQuestion : Question?, _allQuestions : [Question?], _questionIndex : Int) {
        let QAVC = QAManagerVC()
        QAVC.selectedTag = currentTag
        QAVC.allQuestions = _allQuestions
        QAVC.currentQuestion = _selectedQuestion
        QAVC.questionCounter = _questionIndex
        QAVC.view.frame = self.view.frame
        
        self.presentViewController(QAVC, animated: true, completion: nil)
    }
    
    func addNewVC(newVC: UIViewController) {
        self.addChildViewController(newVC)
        newVC.view.frame = self.view.frame
        self.view.addSubview(newVC.view)
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
        let _currentTag = allTags[indexPath.row]
        
        cell.currentTag = _currentTag
        cell.backgroundColor = UIColor.whiteColor()
        configureCell(cell, currentTag: _currentTag, indexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: ExploreTagCell, currentTag: Tag, indexPath: NSIndexPath) {
        cell.tagLabel.text = "#"+currentTag.tagID!.uppercaseString
        
        if let _tagImage = currentTag.previewImage {
            let downloadRef = storageRef.child("tags/\(_tagImage)")
            let _ = downloadRef.dataWithMaxSize(600 * 800) { (data, error) -> Void in //need to image size
                if (error != nil) {
                    print(error.debugDescription) //surface error
                } else {
                    cell.tagImage.image = UIImage(data: data!)
                    cell.tagImage.contentMode = UIViewContentMode.ScaleAspectFill
                }
            }
        }
    }
}

extension ExploreTagsVC: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width, height: self.view.frame.height / 3.5)
    }
}
