//
//  ExploreTagsVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ExploreTagsVC: UIViewController {
    var allTags = [Tag]()
    var currentTag : Tag!
    
    var questionsListener = UInt()
    var tagsListener = UInt()

    private let reuseIdentifier = "tagCell"
    
    @IBOutlet weak var ExploreTags: UICollectionView!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadTagsFromFirebase()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        databaseRef.removeObserverWithHandle(tagsListener)
        databaseRef.removeObserverWithHandle(questionsListener)
    }
    
    func loadTagsFromFirebase() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
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
        return CGSize(width: self.view.frame.width, height: self.view.frame.height / 3)
        
    }
}
