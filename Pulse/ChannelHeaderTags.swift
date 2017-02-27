//
//  ChannelHeaderTags.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/18/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ChannelHeaderTags: UICollectionReusableView {
    public var items = [Item]() {
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
    let collectionReuseIdentifier = "expertThumbCell"
    
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
        tagsLabel.text = "featuring"
        tagsLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightMedium, color: pulseRed, alignment: .center)
        
        let fontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: tagsLabel.font.pointSize, weight: UIFontWeightMedium)]
        let titleLabelHeight = GlobalFunctions.getLabelSize(title: tagsLabel.text!, width: frame.width, fontAttributes: fontAttributes)
        tagsLabel.frame = CGRect(x: 0, y: 10, width: frame.width, height: titleLabelHeight)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 5
        tagsList = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        tagsList.register(ChannelHeaderCell.self, forCellWithReuseIdentifier: collectionReuseIdentifier)
        
        addSubview(tagsList)
        tagsList.translatesAutoresizingMaskIntoConstraints = false
        tagsList.topAnchor.constraint(equalTo: tagsLabel.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        tagsList.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        tagsList.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        tagsList.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue + Spacing.m.rawValue).isActive = true
        tagsList.layoutIfNeeded()
        
        tagsList.backgroundColor = .white
        tagsList.showsHorizontalScrollIndicator = false
    }
}

extension ChannelHeaderTags: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionReuseIdentifier, for: indexPath) as! ChannelHeaderCell
        
        let item = items[indexPath.row]
        
        if !item.itemCreated { //search case - get question from database
            Database.getItem(item.itemID, completion: { (item, error) in
                if let item = item {
                    cell.updateCell(item.itemTitle.lowercased(), _image: nil)
                    
                    self.items[indexPath.row] = item
                    
                    if let itemURL = item.contentURL {
                        DispatchQueue.global(qos: .background).async {
                            if let imageData = try? Data(contentsOf: itemURL) {
                                self.items[indexPath.row].content = UIImage(data: imageData)
                                
                                DispatchQueue.main.async {
                                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                        cell.updateImage(image : UIImage(data: imageData))
                                    }
                                }
                            }
                        }
                    }
                }
            })
        } else {
            if let itemImage = item.content as? UIImage {
                cell.updateCell(item.itemTitle.lowercased(), _image : itemImage)
            } else if let itemURL = item.contentURL {
                cell.updateCell(item.itemTitle.lowercased(), _image: nil)
                
                DispatchQueue.global(qos: .background).async {
                    if let imageData = try? Data(contentsOf: itemURL) {
                        self.items[indexPath.row].content = UIImage(data: imageData)
                        
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            DispatchQueue.main.async {
                                cell.updateCell(item.itemTitle.capitalized, _image : UIImage(data: imageData))
                            }
                        }
                    }
                }
            } else {
                cell.updateCell(item.itemTitle.capitalized, _image: nil)
            }
        }
                
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
        let selectedItem = items[indexPath.row]
        selectedItem.type = .tag
        delegate.userSelected(item: selectedItem)
    }
}
