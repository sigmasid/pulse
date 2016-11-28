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
//        layout.itemSize = CGSize(width: self.bounds.width, height: self.bounds.height)
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        layout.itemSize = CGSize(width: self.frame.width, height: self.frame.height)
        
        Filters = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        Filters.register(FiltersCell.self, forCellWithReuseIdentifier: self.reuseIdentifier)
        Filters.backgroundColor = UIColor.clear
        Filters.delegate = self
        Filters.dataSource = self
        Filters.isPagingEnabled = true
        Filters.showsHorizontalScrollIndicator = false
        Filters.canCancelContentTouches = true
        
        Filters.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        addSubview(Filters)
    }
}

extension FiltersOverlay : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentQuestion!.qFilters.count 
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int{
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FiltersCell
        
        if FilterChoices.count > (indexPath as NSIndexPath).row && cell.filterImageView != nil {
            cell.filterImageView!.image = FilterChoices[(indexPath as NSIndexPath).row]!
        } else {
            let _filterID = currentQuestion!.qFilters[(indexPath as NSIndexPath).row]

            Database.getImage(.Filters, fileID: _filterID+".png", maxImgSize: maxImgSize, completion: {(_data, error) in
                if error == nil {
                    let _filterImage = UIImage(data: _data!)
                    self.FilterChoices[(indexPath as NSIndexPath).row] = _filterImage
                    cell.filterImageView!.image = _filterImage
                }
            })
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
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

