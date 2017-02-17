//
//  ChannelHeader.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ChannelHeader: UICollectionReusableView {
    public var experts = [User]() {
        didSet {
            expertsPreview?.delegate = self
            expertsPreview?.dataSource = self
            expertsPreview?.reloadData()
        }
    }
    
    private var expertsPreview : UICollectionView!
    private var expertsLabel = UILabel()
    private var channelImage = UIImageView()
    internal var expertPreviewCount = 5
    let collectionReuseIdentifier = "expertThumbCell"

    ///setup order: first profile image + bio labels, then buttons + scope bar
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        setupChannelHeader()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func updateChannelImage(selectedChannel: Tag) {
        selectedChannel.getTagImage(completion: { image in
            if let image = image {
                self.channelImage.image = image
            }
        })
    }
    
    fileprivate func setupChannelHeader() {
        addSubview(channelImage)
        channelImage.frame = frame
        channelImage.layoutIfNeeded()
        channelImage.contentMode = .scaleAspectFill
        
        addSubview(expertsLabel)
        expertsLabel.text = "FEATURING"
        expertsLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightMedium, color: .black, alignment: .center)
        expertsLabel.translatesAutoresizingMaskIntoConstraints = false
        expertsLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        expertsLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        expertsLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        expertsLabel.layoutIfNeeded()
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 5
        expertsPreview = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        expertsPreview.register(ChannelExpertsPreviewCell.self, forCellWithReuseIdentifier: collectionReuseIdentifier)

        addSubview(expertsPreview)
        expertsPreview.translatesAutoresizingMaskIntoConstraints = false
        expertsPreview.topAnchor.constraint(equalTo: expertsLabel.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        expertsPreview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        expertsPreview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        expertsPreview.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue + Spacing.m.rawValue).isActive = true
        expertsPreview.layoutIfNeeded()
        
        expertsPreview.backgroundColor = .white
        expertsPreview.showsHorizontalScrollIndicator = false
    }
}

extension ChannelHeader: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return experts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionReuseIdentifier, for: indexPath) as! ChannelExpertsPreviewCell
        
        let _user = experts[indexPath.row]
        
        if !_user.uCreated { //search case - get question from database
            Database.getUser(_user.uID!, completion: { (user, error) in
                if error == nil {
                    cell.updateCell(user.name?.capitalized, _image: nil)
                    
                    self.experts[indexPath.row] = user
                    
                    if let _uPic = user.profilePic {
                        DispatchQueue.global(qos: .background).async {
                            if let _userImageData = try? Data(contentsOf: URL(string: _uPic)!) {
                                self.experts[indexPath.row].thumbPicImage = UIImage(data: _userImageData)
                                
                                DispatchQueue.main.async {
                                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                        cell.updateImage(image : UIImage(data: _userImageData))
                                    }
                                }
                            }
                        }
                    }
                }
            })
        } else {
            if _user.thumbPicImage != nil {
                cell.updateCell(_user.name?.capitalized, _image : _user.thumbPicImage)
            } else if let _uPic = _user.thumbPic {
                cell.updateCell(_user.name?.capitalized, _image: nil)

                DispatchQueue.global(qos: .background).async {
                    if let _userImageData = try? Data(contentsOf: URL(string: _uPic)!) {
                        self.experts[indexPath.row].thumbPicImage = UIImage(data: _userImageData)
                        
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            DispatchQueue.main.async {
                                cell.updateCell(_user.name?.capitalized, _image : UIImage(data: _userImageData))
                            }
                        }
                    }
                }
            } else {
                cell.updateCell(_user.name?.capitalized, _image: nil)
            }
        }
        
        
        cell.updateCell(experts[indexPath.row].name, _image: experts[indexPath.row].thumbPicImage)
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
}

