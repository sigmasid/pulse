//
//  FiltersOverlay.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/22/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class FiltersOverlay: UIView, UIGestureRecognizerDelegate {
    var Filters: UICollectionView!
    var reuseIdentifier = "FiltersCell"
    var FilterChoices = [Int : UIImage?]()
    
    var currentQuestion : Question? {
        didSet {
            setupFilters()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupFilters() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: self.bounds.width, height: self.bounds.height)
        layout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        layout.itemSize = CGSize(width: self.frame.width, height: self.frame.height)
        
        self.Filters = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        self.Filters.registerClass(FiltersCell.self, forCellWithReuseIdentifier: self.reuseIdentifier)
        self.Filters.backgroundColor = UIColor.clearColor()
        self.Filters.delegate = self
        self.Filters.dataSource = self
        self.Filters.pagingEnabled = true
        self.Filters.showsHorizontalScrollIndicator = false
        self.Filters.canCancelContentTouches = true
        
        self.Filters.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        self.addSubview(self.Filters)
    }
}

extension FiltersOverlay : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentQuestion!.qFilters!.count ?? 0
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int{
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! FiltersCell
        
        if FilterChoices.count > indexPath.row && cell.filterImageView != nil {
            cell.filterImageView!.image = FilterChoices[indexPath.row]!
        } else {
            let _filterID = currentQuestion!.qFilters![indexPath.row]

            Database.getImage(.Filters, fileID: _filterID+".png", maxImgSize: maxImgSize, completion: {(_data, error) in
                if error != nil {
                    print(error?.localizedDescription)
                } else {
                    let _filterImage = UIImage(data: _data!)
                    self.FilterChoices[indexPath.row] = _filterImage
                    cell.filterImageView!.image = _filterImage
                }
            })
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
}


//    func gestureRecognizer(gesture: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer : UIGestureRecognizer) -> Bool {
//        return true
//    }

//    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
//        if let _controlsOverlay = controlsOverlay {
//            print("hit test fired in filters")
//            let _test = _controlsOverlay.hitTest(point, withEvent: event)
//            if _test != nil {
//                print("we found a view")
//            } else {
//                print("returning self")
//            }
//            return _test ?? self
//        } else {
//            print("hit test returned self")
//            return self
//        }
//    }

