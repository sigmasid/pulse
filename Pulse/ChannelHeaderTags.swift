//
//  ChannelHeaderTags.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/18/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ChannelHeaderTags: UICollectionReusableView {
    public var tags = [Tag]() {
        didSet {
            tagsList?.delegate = self
            tagsList?.dataSource = self
            tagsList?.reloadData()
        }
    }
    public var delegate: ChannelDelegate!
    
    private var tagsList : UICollectionView!
    private var tagsLabel = UILabel()
    internal var tagCount = 10
    let collectionReuseIdentifier = "tagCell"
    
    ///setup order: first profile image + bio labels, then buttons + scope bar
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        addShadow()
        setupChannelHeader()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func setupChannelHeader() {
       
        addSubview(tagsLabel)
        tagsLabel.text = "trending"
        
        tagsLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightMedium, color: .black, alignment: .center)
        tagsLabel.translatesAutoresizingMaskIntoConstraints = false
        tagsLabel.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xs.rawValue).isActive = true
        tagsLabel.heightAnchor.constraint(equalToConstant: Spacing.s.rawValue).isActive = true
        
        tagsLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        tagsLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        tagsLabel.layoutIfNeeded()
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 5
        tagsList = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        tagsList.register(ChannelHeaderTagCell.self, forCellWithReuseIdentifier: collectionReuseIdentifier)
        
        addSubview(tagsList)
        tagsList.translatesAutoresizingMaskIntoConstraints = false
        tagsList.topAnchor.constraint(equalTo: tagsLabel.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        tagsList.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        tagsList.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        tagsList.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        tagsList.layoutIfNeeded()
        
        tagsList.backgroundColor = .white
        tagsList.showsHorizontalScrollIndicator = false
    }
}

extension ChannelHeaderTags: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionReuseIdentifier, for: indexPath) as! ChannelHeaderTagCell
        
        let _tag = tags[indexPath.row]
        cell.updateCell(title: _tag.tagTitle)
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: frame.width / 3,
                      height: IconSizes.small.rawValue)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate.userSelected(tag: tags[indexPath.row])
    }
}
