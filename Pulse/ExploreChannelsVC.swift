//
//  ExploreChannelsVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/18/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class ExploreChannelsVC: UIViewController {
    
    // Set by MasterTabVC
    public var tabDelegate : tabVCDelegate!
    
    fileprivate var headerNav : PulseNavVC?
    fileprivate var loadingView : LoadingView?
    fileprivate var allChannels = [Channel]() {
        didSet {
            updateDataSource()
        }
    }

    fileprivate var channelCollection : UICollectionView!
    fileprivate var isLayoutSetup = false
    fileprivate var isLoaded = false
    fileprivate var reuseIdentifier = "channelCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {

            setupScreenLayout()
            updateRootScopeSelection()
            
            view.backgroundColor = .white
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let nav = navigationController as? PulseNavVC {
            headerNav = nav
            headerNav?.setNav(title: "Explore Channels")
            headerNav?.updateBackgroundImage(image: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func setupScreenLayout() {
        if !isLayoutSetup {
            let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
            layout.scrollDirection = UICollectionViewScrollDirection.vertical
            layout.minimumLineSpacing = 20
            layout.minimumInteritemSpacing = 20
            
            channelCollection = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
            channelCollection.register(ExploreChannelsCell.self, forCellWithReuseIdentifier: reuseIdentifier)
            view.addSubview(channelCollection)
            
            channelCollection.translatesAutoresizingMaskIntoConstraints = false
            channelCollection.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
            channelCollection.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
            channelCollection.topAnchor.constraint(equalTo: view.topAnchor, constant: Spacing.xs.rawValue).isActive = true
            channelCollection.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            
            channelCollection.backgroundColor = .white
            channelCollection.showsVerticalScrollIndicator = false
            
            channelCollection.isMultipleTouchEnabled = true
            isLayoutSetup = true
        }
    }
    
    fileprivate func updateRootScopeSelection() {
        Database.getExploreChannels({ channels, error in
            if error == nil {
                self.allChannels = channels
                
                if !self.isLoaded {
                    if self.tabDelegate != nil { self.tabDelegate.removeLoading() }
                    self.isLoaded = true
                }
            }
        })
    }
    
    
    
    func updateDataSource() {
        if !isLayoutSetup {
            setupScreenLayout()
        }
        
        channelCollection.delegate = self
        channelCollection.dataSource = self
        channelCollection.reloadData()
        channelCollection.layoutIfNeeded()
        
        if allChannels.count > 0 {
            channelCollection.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
    }
}

extension ExploreChannelsVC : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allChannels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ExploreChannelsCell
        let channel = allChannels[indexPath.row]
        cell.updateCell(channel.cTitle, subtitle: channel.cDescription)
        
        if channel.cPreviewImage != nil {
            cell.updateImage(image: channel.cPreviewImage)
        } else if let urlPath = channel.cImageURL, let url = URL(string: urlPath) {
            DispatchQueue.global().async {
                if let channelImage = try? Data(contentsOf: url) {
                    channel.cPreviewImage = UIImage(data: channelImage)
                    DispatchQueue.main.async(execute: {
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            cell.updateImage(image: channel.cPreviewImage)
                        }
                    })
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let channelVC = ChannelVC()
        let selectedChannel = allChannels[indexPath.row]
        navigationController?.pushViewController(channelVC, animated: true)
        channelVC.selectedChannel = selectedChannel
    }
}

extension ExploreChannelsVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 175)
    }
}
