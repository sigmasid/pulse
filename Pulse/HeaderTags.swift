//
//  HeaderTags.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/18/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class HeaderTagsCell: UICollectionViewCell, SelectionDelegate {
    public var items = [Item]() {
        didSet {
            if items != oldValue {
                
                items.sort(by: { (first: Item, second: Item) -> Bool in
                    first.createdAt! > second.createdAt!
                })
                
                collectionView?.delegate = self
                collectionView?.dataSource = self
                collectionView?.reloadData()
            }
        }
    }
    
    public weak var delegate: SelectionDelegate!
    public var selectedChannel : Channel!
    
    private var collectionView : UICollectionView!
    let collectionReuseIdentifier = "thumbCell"
    
    ///setup order: first profile image + bio labels, then buttons + scope bar
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.white
        addBottomBorder(color: .pulseGrey)
        setupChannelHeader()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        items = []
        delegate = nil
        selectedChannel = nil
        collectionView = nil
    }
    
    fileprivate func setupChannelHeader() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 5
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.register(HeaderCell.self, forCellWithReuseIdentifier: collectionReuseIdentifier)
        
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xs.rawValue).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        collectionView.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue + Spacing.m.rawValue).isActive = true
        collectionView.layoutIfNeeded()
        
        collectionView.backgroundColor = .white
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    internal func updateOnscreenRows() {
        let visiblePaths = collectionView.indexPathsForVisibleItems
        for indexPath in visiblePaths {
            let cell = collectionView.cellForItem(at: indexPath) as! HeaderCell
            updateCell(cell, atIndexPath: indexPath)
        }
    }
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    internal func updateCell(_ cell: HeaderCell, atIndexPath indexPath: IndexPath) {
        if items[indexPath.row].itemCreated {
            let currentItem = items[indexPath.row]
            cell.updateCell(currentItem.itemTitle.capitalized, _image : currentItem.content as? UIImage)
        }
    }
}

extension HeaderTagsCell: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionReuseIdentifier, for: indexPath) as! HeaderCell
        
        let item = items[indexPath.row]
        cell.updateCell(item.itemTitle.capitalized, _image : item.content as? UIImage)
        cell.tag = indexPath.row
        cell.delegate = self
        
        if item.content == nil, !item.fetchedContent {
            PulseDatabase.getImage(channelID: self.selectedChannel.cID, itemID: item.itemID, fileType: .thumb, maxImgSize: maxImgSize, completion: {[weak self] data, error in
                guard let `self` = self else { return }
                
                if let data = data, let image = UIImage(data: data) {
                    self.items[indexPath.row].content = image
                    
                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                        DispatchQueue.main.async {
                            cell.updateCell(item.itemTitle.capitalized, _image : image)
                        }
                    }
                }
                self.items[indexPath.row].fetchedContent = true //so we don't try to fetch again
            })
        }
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: frame.width / 4,
                      height: IconSizes.medium.rawValue + Spacing.m.rawValue)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        userSelected(item: indexPath.row)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateOnscreenRows()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { updateOnscreenRows() }
    }
    
    internal func userSelected(item : Any) {
        if delegate != nil, let itemIndex = item as? Int {
            let selectedItem = items[itemIndex]
            selectedItem.cID = selectedChannel.cID
            selectedItem.cTitle = selectedChannel.cTitle
            delegate.userSelected(item: selectedItem)
        }
    }
}
