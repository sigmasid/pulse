//
//  ChannelHeader.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class HeaderContributors: UICollectionReusableView {
    public var contributors = [PulseUser]() {
        didSet {
            contributorsPreview?.delegate = self
            contributorsPreview?.dataSource = self
            contributorsPreview?.reloadData()
        }
    }
    public var delegate: SelectionDelegate!
    
    private var contributorsPreview : UICollectionView!
    private var contributorsLabel = UILabel()
    let collectionReuseIdentifier = "contributorThumbCell"

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
        addSubview(contributorsLabel)
        contributorsLabel.text = "featuring"
        contributorsLabel.setFont(FontSizes.caption.rawValue, weight: UIFontWeightMedium, color: .pulseRed, alignment: .center)

        let fontAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: contributorsLabel.font.pointSize, weight: UIFontWeightMedium)]
        let titleLabelHeight = GlobalFunctions.getLabelSize(title: contributorsLabel.text!, width: frame.width, fontAttributes: fontAttributes)
        contributorsLabel.frame = CGRect(x: 0, y: 10, width: frame.width, height: titleLabelHeight)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 5
        contributorsPreview = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        contributorsPreview.register(HeaderCell.self, forCellWithReuseIdentifier: collectionReuseIdentifier)

        addSubview(contributorsPreview)
        contributorsPreview.translatesAutoresizingMaskIntoConstraints = false
        contributorsPreview.topAnchor.constraint(equalTo: contributorsLabel.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        contributorsPreview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        contributorsPreview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        contributorsPreview.heightAnchor.constraint(equalToConstant: IconSizes.medium.rawValue + Spacing.m.rawValue).isActive = true
        contributorsPreview.layoutIfNeeded()
        
        contributorsPreview.backgroundColor = .white
        contributorsPreview.showsHorizontalScrollIndicator = false
    }
}

extension HeaderContributors: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contributors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionReuseIdentifier, for: indexPath) as! HeaderCell
        
        let _user = contributors[indexPath.row]
        
        if !_user.uCreated { //search case - get question from database
            PulseDatabase.getUser(_user.uID!, completion: { (user, error) in
                if let user = user {
                    cell.updateCell(user.name?.capitalized, _image: nil)
                    
                    self.contributors[indexPath.row] = user
                    
                    if let _uPic = user.profilePic {
                        DispatchQueue.global(qos: .background).async {
                            if let _userImageData = try? Data(contentsOf: URL(string: _uPic)!) {
                                self.contributors[indexPath.row].thumbPicImage = UIImage(data: _userImageData)
                                
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
                        self.contributors[indexPath.row].thumbPicImage = UIImage(data: _userImageData)
                        
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
        delegate.userSelected(item: contributors[indexPath.row])
    }
}

