//
//  HeadercollectionView.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/8/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class HeaderChannelsCell: UICollectionViewCell {
    public var channels = [Channel]() {
        didSet {
            print("did set channels")
            collectionView?.delegate = self
            collectionView?.dataSource = self
            collectionView?.reloadData()
        }
    }
    public var delegate: ChannelDelegate!
    public var selectedChannel : Channel!
    
    private var collectionView : UICollectionView!
    let collectionReuseIdentifier = "expertThumbCell"
    
    ///setup order: first profile image + bio labels, then buttons + scope bar
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        addBottomBorder()
        setupChannelHeader()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
}

extension HeaderChannelsCell: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return channels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionReuseIdentifier, for: indexPath) as! HeaderCell
        
        let channel = channels[indexPath.row]
        cell.updateCell(channel.cTitle?.capitalized, _image : nil)
        Database.getChannelImage(channelID: channel.cID, fileType: .thumb, maxImgSize: maxImgSize, completion: { data, error in
            if let data = data {
                self.channels[indexPath.row].cPreviewImage = UIImage(data: data)
                
                if collectionView.indexPath(for: cell)?.row == indexPath.row {
                    DispatchQueue.main.async {
                        cell.updateCell(channel.cTitle?.capitalized, _image : UIImage(data: data))
                    }
                }
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
        return CGSize(width: frame.width / 4.5,
                      height: IconSizes.medium.rawValue + Spacing.m.rawValue)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //delegate.userSelected(channel: channels[indexPath.row])
    }
}
