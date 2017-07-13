//
//  HeadercollectionView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/8/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class HeaderChannelsCell: UICollectionViewCell, SelectionDelegate {
    public var channels = [Channel]() {
        didSet {
            if channels.count != oldValue.count {
                collectionView?.delegate = self
                collectionView?.dataSource = self
                collectionView?.reloadData()
            }
        }
    }
    public weak var delegate: SelectionDelegate!
    public var selectedChannel : Channel!
    
    private var collectionView : UICollectionView!
    let collectionReuseIdentifier = "contributorThumbCell"
    
    ///setup order: first profile image + bio labels, then buttons + scope bar
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        addBottomBorder(color: .pulseGrey)
        setupChannelHeader()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        channels = []
        delegate = nil
        collectionView = nil
        selectedChannel = nil
    }
    
    fileprivate func setupChannelHeader() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 5
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.register(HeaderCell.self, forCellWithReuseIdentifier: collectionReuseIdentifier)
        
        contentView.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xs.rawValue).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        collectionView.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue + Spacing.m.rawValue).isActive = true
        collectionView.layoutIfNeeded()
        
        collectionView.backgroundColor = .white
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    internal func userSelected(item : Any) {
        if delegate != nil, let itemIndex = item as? Int {
            delegate.userSelected(item: channels[itemIndex])
        }
    }
}

extension HeaderChannelsCell: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return channels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionReuseIdentifier, for: indexPath) as! HeaderCell
        cell.delegate = self
        cell.tag = indexPath.row
        
        let channel = channels[indexPath.row]
        cell.updateTitle(title: channel.cTitle)
        
        PulseDatabase.getCachedChannelImage(channelID: channel.cID, fileType: .thumb, completion: {image in
            DispatchQueue.main.async {
                cell.updateImage(image: image)
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
}
