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
    var tagSelected : Tag?
    
    var handle: UInt!
    var numberOfCells = 10
    var loadingStatus = false

    private let reuseIdentifier = "tagCell"
    
    @IBOutlet weak var ExploreTags: UICollectionView!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadTagsFromFirebase()
    }
    
    func loadTagsFromFirebase() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        handle = databaseRef.child("tags").observeEventType(.Value, withBlock: { snapshot in
            for item in snapshot.children {
                let child = item as! FIRDataSnapshot
                let _previewImage = child.childSnapshotForPath("previewImage").value as? String
                let currentTag = Tag(tagID: child.key)
                currentTag.previewImage = _previewImage
                self.allTags.append(currentTag)
            }
            self.ExploreTags.reloadData()
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })
    }
}

extension ExploreTagsVC : UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(allTags.count)
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
        configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: ExploreTagCell, indexPath: NSIndexPath) {
        let currentTag = allTags[indexPath.row]
        cell.tagLabel.text = "#"+currentTag.tagID!.uppercaseString
        
        let downloadRef = storageRef.child("tags/\(currentTag.previewImage!)")
        let _ = downloadRef.dataWithMaxSize(1200 * 2200) { (data, error) -> Void in
            if (error != nil) {
                print(error.debugDescription)
            } else {
                cell.tagImage.image = UIImage(data: data!)
                cell.tagImage.contentMode = UIViewContentMode.ScaleAspectFill
            }
        }
    }
}

extension ExploreTagsVC: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 150)
    }
}
