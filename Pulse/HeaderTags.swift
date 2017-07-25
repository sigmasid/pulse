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
        collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xxs.rawValue).isActive = true
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
            cell.updateTitle(title: items[indexPath.row].itemTitle.capitalized)
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
        cell.updateTitle(title: item.itemTitle.capitalized)
        cell.tag = indexPath.row
        cell.delegate = self
        cell.updateImage(image : nil)

        PulseDatabase.getCachedSeriesImage(channelID: selectedChannel.cID, itemID: item.itemID, fileType: .thumb, completion: {image in
            DispatchQueue.main.async {
                cell.updateImage(image : image)
            }
        })
                
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
