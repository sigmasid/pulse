//
//  QuickBrowseVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/8/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class QuickBrowseVC: UICollectionViewController {
    
    fileprivate var headerReuseIdentifier = "QuickBrowseHeader"
    fileprivate var reuseIdentifier = "QuickBrowseCell"
    fileprivate var isfirstTimeTransform = true
    
    fileprivate var cellWidth : CGFloat = 0
    fileprivate var spacerBetweenCells : CGFloat = 0
    
    /* set by parent */
    var selectedItem : Item!
    var selectedChannel : Channel!
    
    public var allItems = [Item]() {
        didSet {
            itemStack.removeAll()
            itemStack = [ItemMetaData](repeating: ItemMetaData(), count: allItems.count)
        }
    }
    internal var itemStack = [ItemMetaData]()
    weak var delegate : ItemDetailDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.register(ItemHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        collectionView?.register(BrowseCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView?.showsHorizontalScrollIndicator = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        view.backgroundColor = .white
        collectionView?.backgroundColor = .white
    }
    
    func userClickedAddAnswer() {
        delegate.userClickedAddItem()
    }
}


extension QuickBrowseVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (view.frame.width - 30) / 2, height: collectionView.frame.height * 0.7)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, collectionView.bounds.width * 0.2, 0, collectionView.bounds.width * 0.2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}

extension QuickBrowseVC {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionView.collectionViewLayout.invalidateLayout()
        return allItems.count
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int{
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BrowseCell
        
        if ((indexPath as NSIndexPath).row == 0 && isfirstTimeTransform) {
            // make a bool and set YES initially, this check will prevent fist load transform
            isfirstTimeTransform = false
        } else {
            cell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
            
        cell.contentView.backgroundColor = .white
        cell.updateLabel(nil, _subtitle: nil, _image : nil)
        
        let currentItem = allItems[indexPath.row]
        
        /* GET PREVIEW IMAGE FROM STORAGE */
        if currentItem.content != nil && !itemStack[indexPath.row].gettingImageForPreview {
            
            cell.updateImage(image: currentItem.content as? UIImage)
        } else if itemStack[indexPath.row].gettingImageForPreview {
            
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            itemStack[indexPath.row].gettingImageForPreview = true
            
            Database.getImage(channelID: selectedChannel.cID, itemID: currentItem.itemID, fileType: .thumb, maxImgSize: maxImgSize, completion: {(_data, error) in
                if error == nil {
                    let _previewImage = GlobalFunctions.createImageFromData(_data!)
                    self.allItems[indexPath.row].content = _previewImage
                    
                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                        DispatchQueue.main.async {
                            cell.updateImage(image: self.allItems[indexPath.row].content as? UIImage)
                        }
                    }
                } else {
                    cell.updateImage(image: nil)
                }
            })
        }
        
        //Already fetched this item
        if allItems[indexPath.row].itemCreated, let user = allItems[indexPath.row].user  {
            
            cell.updateLabel(user.name?.capitalized, _subtitle: user.shortBio?.capitalized)
            
        } else if itemStack[indexPath.row].gettingInfoForPreview {
            
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            itemStack[indexPath.row].gettingInfoForPreview = true
            
            Database.getItem(allItems[indexPath.row].itemID, completion: { (item, error) in
                
                if let item = item {
                    
                    item.tag = self.allItems[indexPath.row].tag
                    self.allItems[indexPath.row] = item
                    
                    // Get the user details
                    Database.getUser(item.itemUserID, completion: {(user, error) in
                        if let user = user {
                            self.allItems[indexPath.row].user = user
                            DispatchQueue.main.async {
                                if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                    
                                    cell.updateLabel(user.name?.capitalized, _subtitle: user.shortBio?.capitalized)
                                    
                                }
                            }
                        }
                    })
                }
            })
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate.userSelectedFromExploreQuestions(indexPath)
    }
    
    //center the incoming cell -- doesn't work w/ paging enabled
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let pageWidth : Float = Float(cellWidth + 10) // width + space
        
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
            let cell = collectionView?.cellForItem(at: IndexPath(item: index, section: 0))
            UIView.animate(withDuration: 0.2, animations: {
                cell!.transform = CGAffineTransform.identity
            }) 
            
            let nextCell = collectionView?.cellForItem(at: IndexPath(item: index + 1, section: 0))
            UIView.animate(withDuration: 0.2, animations: {
                nextCell!.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) 
        } else {
            if let cell = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) {
                UIView.animate(withDuration: 0.2, animations: {
                    cell.transform = CGAffineTransform.identity
                }) 
            }

            if let priorCell = collectionView?.cellForItem(at: IndexPath(item: index - 1, section: 0)) {
                UIView.animate(withDuration: 0.2, animations: {
                    priorCell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }) 
            }
            
            if let nextCell = collectionView?.cellForItem(at: IndexPath(item: index + 1, section: 0)) {
                UIView.animate(withDuration: 0.2, animations: {
                    nextCell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }) 
            }
        }
    }
}
