//
//  BrowseUsersVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/17/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class BrowseUsersVC: PulseVC, HeaderDelegate {
    //Main data source var -
    public var allUsers = [PulseUser]()
    public weak var delegate : SelectionDelegate!
    
    //set by delegate
    public var selectedChannel : Channel! {
        didSet {
            guard selectedChannel != nil else { return }
            
            if allUsers.isEmpty {
                PulseDatabase.getChannelContributors(channelID: selectedChannel.cID, completion: {(success, users) in
                    self.allUsers = users
                    self.updateDataSource()
                })
            } else {
                updateDataSource()
            }
        }
    }
    //end set by delegate
    
    /** Collection View Vars **/
    internal var collectionView : UICollectionView!
    fileprivate let minCellHeight : CGFloat = 225
    /** End Collection View **/
    
    private var cleanupComplete = false
    
    //once allUsers var is set reload the data
    func updateDataSource() {
        if !isLayoutSetup {
            setupLayout()
            
            tabBarHidden = true
            isLayoutSetup = true
        }
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.reloadData()
        collectionView?.layoutIfNeeded()
    }
    
    fileprivate var isLayoutSetup = false
    
    deinit {
        performCleanup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isLayoutSetup {
            setupLayout()
            
            tabBarHidden = true
            isLayoutSetup = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        updateHeader()
    }
    
    private func performCleanup() {
        if !cleanupComplete {
            cleanupComplete = true
            delegate = nil
            selectedChannel = nil
            collectionView = nil
            allUsers.removeAll()
        }
    }
    
    private func setupLayout() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        let _ = PulseFlowLayout.configureLayout(collectionView: collectionView, minimumLineSpacing: 10, itemSpacing: 10, stickyHeader: true)
        
        collectionView?.register(EmptyCell.self, forCellWithReuseIdentifier: emptyReuseIdentifier)
        collectionView?.register(ItemHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        collectionView?.register(BrowseContentCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        view.addSubview(collectionView)
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        //is in nav controller
        addBackButton()
        headerNav?.setNav(title: "Featured Contributors", subtitle: selectedChannel.cTitle)
        headerNav?.updateBackgroundImage(image: selectedChannel.getNavImage())
        headerNav?.followScrollView(collectionView, delay: 25.0)
    }

    internal func clickedHeaderMenu() {

        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        menu.addAction(UIAlertAction(title: "become Contributor", style: .default, handler: {[weak self] (action: UIAlertAction!) in
            guard let `self` = self else { return }
            let becomeContributorVC = BecomeContributorVC()
            becomeContributorVC.selectedChannel = self.selectedChannel
            
            self.navigationController?.pushViewController(becomeContributorVC, animated: true)
        }))
        
        menu.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            menu.dismiss(animated: true, completion: nil)
        }))
        
        present(menu, animated: true, completion: nil)
    }
}

extension BrowseUsersVC : UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allUsers.count == 0 ? 1 : allUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if allUsers.count > 0, let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
            let cellRect = attributes.frame
            initialFrame = collectionView.convert(cellRect, to: collectionView.superview)
        }
        
        if delegate != nil {
            delegate.userSelected(item: allUsers[indexPath.row])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard allUsers.count > 0 else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emptyReuseIdentifier, for: indexPath) as! EmptyCell
            cell.setMessage(message: "no contributors yet!", color: .black)
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BrowseContentCell
        
        cell.contentView.backgroundColor = .white
        cell.updateLabel(nil, _subtitle: nil, _image : nil)
        
        let currentUser = allUsers[indexPath.row]
        
        if !currentUser.uCreated {
            // Get the user details
            PulseDatabase.getUser(currentUser.uID!, completion: {[weak self] (user, error) in
                guard let `self` = self else { return }
                if let user = user {
                    self.allUsers[indexPath.row] = user
                    
                    DispatchQueue.main.async {
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            cell.updateLabel(user.name?.capitalized, _subtitle: user.shortBio?.capitalized)
                        }
                    }
                    
                    DispatchQueue.global(qos: .background).async {
                        if let imageString = user.thumbPic, let imageURL = URL(string: imageString), let _imageData = try? Data(contentsOf: imageURL) {
                            self.allUsers[indexPath.row].thumbPicImage = UIImage(data: _imageData)
                            
                            DispatchQueue.main.async {
                                if collectionView.indexPath(for: cell)?.row == indexPath.row {
                                    cell.updateImage(image: self.allUsers[indexPath.row].thumbPicImage)
                                }
                            }
                        }
                    }
                    
                }
            })
            
        } else if currentUser.uCreated, currentUser.thumbPicImage != nil  {
            
            cell.updateImage(image: currentUser.thumbPicImage)
            
        } else if currentUser.uCreated {
            
            cell.updateLabel(currentUser.name?.capitalized, _subtitle: currentUser.shortBio?.capitalized)

            DispatchQueue.global(qos: .background).async {
                if let imageString = currentUser.thumbPic, let imageURL = URL(string: imageString), let _imageData = try? Data(contentsOf: imageURL) {
                    self.allUsers[indexPath.row].thumbPicImage = UIImage(data: _imageData)
                    
                    DispatchQueue.main.async {
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            cell.updateImage(image: self.allUsers[indexPath.row].thumbPicImage)
                        }
                    }
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! ItemHeader
            headerView.backgroundColor = .white
            headerView.delegate = self
            headerView.updateLabel(selectedChannel.cTitle == "" ? "browse contributors"  : "meet contributors in \(selectedChannel.cTitle!)")
            
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
        return UICollectionReusableView()
    }
}

extension BrowseUsersVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if allUsers.count == 0 {
            return CGSize(width: view.frame.width, height: view.frame.height - skinnyHeaderHeight)
        }
        return CGSize(width: (view.frame.width - 30) / 2, height: minCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: skinnyHeaderHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if allUsers.count == 0 {
            return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0, right: 0.0)
        }
        return UIEdgeInsets(top: 10.0, left: 10.0, bottom: 0.0, right: 10.0)
    }
}

/* UPDATE ON SCREEN ROWS WHEN SCROLL STOPS */
extension BrowseUsersVC  {
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateBrowseContentCell(_ cell: BrowseContentCell, atIndexPath indexPath: IndexPath) {
        if allUsers[indexPath.row].uCreated  {
            let user = allUsers[indexPath.row]
            cell.updateLabel(user.name?.capitalized, _subtitle: user.shortBio?.capitalized)
        }
        
        if let image = allUsers[indexPath.row].thumbPicImage {
            cell.updateImage(image: image)
        }
    }
    
    func updateOnscreenRows() {
        if let visiblePaths = collectionView?.indexPathsForVisibleItems {
            for indexPath in visiblePaths {
                let cell = collectionView?.cellForItem(at: indexPath) as! BrowseContentCell
                updateBrowseContentCell(cell, atIndexPath: indexPath)
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateOnscreenRows()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { updateOnscreenRows() }
    }
}

extension BrowseUsersVC: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if presented is ContentManagerVC {
            let animator = ExpandAnimationController()
            animator.initialFrame = initialFrame
            animator.exitFrame = getRectToLeft()
            
            return animator
        } else {
            return nil
        }
    }
}
