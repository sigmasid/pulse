//
//  QuickBrowseVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/8/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class QuickBrowseVC: UIViewController {
    public weak var delegate : ItemDetailDelegate?
    internal var collectionViewLayout: QuickBrowseLayout!
    internal var collectionView: UICollectionView!
    fileprivate var controlsView : UIView!
    
    fileprivate var reuseIdentifier = "QuickBrowseCell"
    fileprivate var centerIndex = 0
    fileprivate var isLoaded = false
    
    internal var pageWidth: CGFloat {
        return collectionViewLayout.itemSize.width + collectionViewLayout.minimumLineSpacing
    }
    
    internal var contentOffset: CGFloat {
        return collectionView.contentOffset.x + collectionView.contentInset.left
    }
    
    fileprivate var closeButton = PulseButton(size: .small, type: .close, isRound: true, hasBackground: false, tint: .white)
    fileprivate var animationsCount = 0
    fileprivate var seeAll = PulseButton(title: "see all", isRound: false, hasShadow: false, buttonColor: .clear, textColor: .white)
    
    /* set by parent */
    public var selectedChannel : Channel!
    
    public var allItems = [Item]() {
        didSet {
            itemStack.removeAll()
            itemStack = [ItemMetaData](repeating: ItemMetaData(), count: allItems.count)
        }
    }
    
    internal var itemStack = [ItemMetaData]()

    deinit {
        delegate = nil
        collectionView = nil
        selectedChannel = nil
        collectionViewLayout = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        view.backgroundColor = .clear
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .coverVertical
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isLoaded {
            addCollectionView()
            setupLayout()
            isLoaded = true
        }
    }
    
    internal func addCollectionView() {
        collectionView = UICollectionView(frame: CGRect(x: 0, y: view.bounds.height * (2/3) + IconSizes.small.rawValue,
                                                        width: view.bounds.width, height: view.bounds.height * (1/3) - IconSizes.small.rawValue),
                                          collectionViewLayout: UICollectionViewFlowLayout())
        
        collectionViewLayout = QuickBrowseLayout.configureLayout(collectionView: collectionView,
                                                       itemSize:   CGSize(width: collectionView.bounds.width * 0.3, height: collectionView.bounds.height - 10),
                                                       minimumLineSpacing: collectionView.bounds.width * 0.05)
        collectionView?.register(QuickBrowseCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        view.addSubview(collectionView)
        
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        collectionView?.layoutIfNeeded()
        collectionView?.reloadData()
    }
    
    fileprivate func setupLayout() {
        controlsView = UIView(frame: CGRect(x: 0, y: view.bounds.height * (2/3), width: view.bounds.width, height: IconSizes.small.rawValue))
        view.addSubview(controlsView)
        controlsView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        controlsView.addSubview(closeButton)
        controlsView.addSubview(seeAll)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        closeButton.centerYAnchor.constraint(equalTo: controlsView.centerYAnchor).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: IconSizes.small.rawValue).isActive = true
        closeButton.layoutIfNeeded()
        
        seeAll.translatesAutoresizingMaskIntoConstraints = false
        seeAll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        seeAll.heightAnchor.constraint(equalTo: controlsView.heightAnchor).isActive = true
        seeAll.centerYAnchor.constraint(equalTo: controlsView.centerYAnchor).isActive = true

        seeAll.setButtonFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: .white, alignment: .left)
        
        seeAll.addTarget(self, action: #selector(userClickedSeeAll), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
    }
    
    internal func close() {
        delegate?.userClosedQuickBrowse()
    }
    
    internal func scrollToPage(index: Int, animated: Bool) {
        collectionView.isUserInteractionEnabled = false
        animationsCount += 1
        
        let pageOffset = CGFloat(index) * self.pageWidth - self.collectionView.contentInset.left
        collectionView.setContentOffset(CGPoint(x: pageOffset, y: 0), animated: true)
        
        centerIndex = index
    }
    
    internal func userClickedSeeAll() {
        delegate?.userClickedSeeAll(items: allItems)
    }
}

extension QuickBrowseVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allItems.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int{
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 0.0, bottom: 10.0, right: 0.0)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! QuickBrowseCell
            
        cell.updateLabel(nil)
        cell.updateImage(image: nil)

        let currentItem = allItems[indexPath.row]
        
        /* GET PREVIEW IMAGE FROM STORAGE */
        if currentItem.contentType == .postcard {
            
            cell.updatePostcard(text: currentItem.itemTitle)
            
        } else if currentItem.content != nil && !itemStack[indexPath.row].gettingImageForPreview {
            
            cell.updateImage(image: currentItem.content)
            
        } else if itemStack[indexPath.row].gettingImageForPreview {
            
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            itemStack[indexPath.row].gettingImageForPreview = true
            
            PulseDatabase.getImage(channelID: selectedChannel.cID, itemID: currentItem.itemID, fileType: .thumb, maxImgSize: MAX_IMAGE_FILESIZE, completion: {[weak self] (_data, error) in
                guard let `self` = self else { return }
                if error == nil {
                    
                    let _previewImage = GlobalFunctions.createImageFromData(_data!)
                    self.allItems[indexPath.row].content = _previewImage
                    
                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                        DispatchQueue.main.async {
                            cell.updateImage(image: self.allItems[indexPath.row].content)
                        }
                    }
                } else {
                    cell.updateImage(image: nil)
                }
            })
        }
        
        //Already fetched this item
        if allItems[indexPath.row].itemCreated, let user = allItems[indexPath.row].user  {

            cell.updateLabel(user.name?.capitalized)
            
        } else if itemStack[indexPath.row].gettingInfoForPreview {
            
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            itemStack[indexPath.row].gettingInfoForPreview = true
            
            PulseDatabase.getItem(allItems[indexPath.row].itemID, completion: {[weak self] (item, error) in
                guard let `self` = self else { return }
                
                if let item = item {
                    
                    item.tag = self.allItems[indexPath.row].tag
                    self.allItems[indexPath.row] = item
                    
                    if item.contentType == .postcard { cell.updatePostcard(text: item.itemTitle) }
                    
                    // Get the user details
                    PulseDatabase.getUser(item.itemUserID, completion: {[weak self] (user, error) in
                        guard let `self` = self else { return }
                        if let user = user {
                            self.allItems[indexPath.row].user = user
                            DispatchQueue.main.async {
                                if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                    
                                    cell.updateLabel(user.name?.capitalized)
                                    
                                }
                            }
                        }
                    })
                }
            })
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if collectionView.isDragging || collectionView.isDecelerating || collectionView.isTracking {
            return
        }
        
        if indexPath.row == centerIndex {
            delegate?.userSelected(indexPath)
        } else {
            self.scrollToPage(index: indexPath.row, animated: true)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        centerIndex = Int(self.contentOffset / self.pageWidth)
        updateOnscreenRows()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if animationsCount - 1 == 0 {
            collectionView.isUserInteractionEnabled = true
        }
    }
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateQuickBrowseCell(_ cell: QuickBrowseCell, atIndexPath indexPath: IndexPath) {
        if let user = allItems[indexPath.row].user  {
            cell.updateLabel(user.name?.capitalized)
        }
        
        if let image = allItems[indexPath.row].content {
            cell.updateImage(image: image)
        }
    }
    
    func updateOnscreenRows() {
        if let visiblePaths = collectionView?.indexPathsForVisibleItems {
            for indexPath in visiblePaths {
                let cell = collectionView?.cellForItem(at: indexPath) as! QuickBrowseCell
                updateQuickBrowseCell(cell, atIndexPath: indexPath)
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { updateOnscreenRows() }
    }
}
