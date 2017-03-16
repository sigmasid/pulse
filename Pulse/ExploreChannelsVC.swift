//
//  ExploreChannelsVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/18/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

protocol ExploreChannelsDelegate: class {
    func userClickedSubscribe(senderTag: Int)
}

class ExploreChannelsVC: PulseVC, ExploreChannelsDelegate, ModalDelegate {
    
    // Set by MasterTabVC
    public var universalLink : URL!
    
    fileprivate var searchButton : PulseButton = PulseButton(size: .small, type: .search, isRound : true, background: .white, tint: .black)

    fileprivate var allChannels = [Channel]() {
        didSet {
            updateDataSource()
        }
    }

    fileprivate var channelCollection : UICollectionView!
    fileprivate var isLayoutSetup = false
    
    override func viewDidLayoutSubviews() {
        if !isLayoutSetup {
            toggleLoading(show: true, message: "Loading...", showIcon: true)
            setupScreenLayout()
            updateRootScopeSelection()
            isLayoutSetup = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader()
        updateOnscreenRows()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func setupScreenLayout() {
        if !isLayoutSetup {
            
            channelCollection = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
            let _ = PulseFlowLayout.configureLayout(collectionView: channelCollection, minimumLineSpacing: 10, itemSpacing: 10, stickyHeader: true)
            channelCollection.register(ExploreChannelsCell.self, forCellWithReuseIdentifier: reuseIdentifier)
            
            view.addSubview(channelCollection)

            searchButton.addTarget(self, action: #selector(userClickedSearch), for: UIControlEvents.touchUpInside)
            
            isLayoutSetup = true
        }
    }
    
    fileprivate func updateHeader() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: searchButton)
        
        tabBarHidden = false
        headerNav?.updateBackgroundImage(image: nil)
        headerNav?.setNav(title: "Explore Channels")
    }
    
    fileprivate func updateRootScopeSelection() {
        Database.getExploreChannels({ channels, error in
            if error == nil {
                self.allChannels = channels
                self.toggleLoading(show: false, message: nil)
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
    }
    
    func userClickedSearch() {
        let searchNavVC = PulseNavVC(navigationBarClass: PulseNavBar.self, toolbarClass: nil)
        let searchVC = SearchVC()
        searchNavVC.modalTransitionStyle = .crossDissolve

        searchVC.modalDelegate = self
        searchNavVC.viewControllers = [searchVC]
        
        navigationController?.present(searchNavVC, animated: true, completion: nil)
    }
    
    func userClosedModal(_ viewController : UIViewController) {
        dismiss(animated: true, completion: { _ in })
    }
    
    func userClickedSubscribe(senderTag: Int) {
        let selectedChannel = allChannels[senderTag]
        
        Database.subscribeChannel(selectedChannel, completion: {(success, error) in
            if !success {
                GlobalFunctions.showErrorBlock("Error Subscribing Tag", erMessage: error!.localizedDescription)
            } else {
                if let cell = self.channelCollection.cellForItem(at: IndexPath(item: senderTag, section: 0)) as? ExploreChannelsCell {
                    DispatchQueue.main.async {
                        if let user = User.currentUser, user.isSubscribedToChannel(cID: selectedChannel.cID) {
                            cell.updateSubscribe(type: .unfollow, tag: senderTag)
                        } else {
                            cell.updateSubscribe(type: .follow, tag: senderTag)
                        }
                    }
                }
            }
        })
    }
}

extension ExploreChannelsVC : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allChannels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ExploreChannelsCell
        cell.delegate = self
        
        let channel = allChannels[indexPath.row]
        cell.updateCell(channel.cTitle, subtitle: channel.cDescription)
        
        if let user = User.currentUser {
            user.isSubscribedToChannel(cID: channel.cID) ? cell.updateSubscribe(type: .unfollow, tag: indexPath.row) : cell.updateSubscribe(type: .follow, tag: indexPath.row)
        }

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
    
    func updateOnscreenRows() {
        if channelCollection != nil {
            let visiblePaths = channelCollection.indexPathsForVisibleItems
            for indexPath in visiblePaths {
                if let cell = channelCollection.cellForItem(at: indexPath) as? ExploreChannelsCell, let user = User.currentUser{
                    user.isSubscribedToChannel(cID: allChannels[indexPath.row].cID) ? cell.updateSubscribe(type: .unfollow, tag: indexPath.row) : cell.updateSubscribe(type: .follow, tag: indexPath.row)
                }
            }
        }
    }
}

extension ExploreChannelsVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width - 20, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 10.0, bottom: 1.0, right: 10.0)
    }
}

/** HANDLE DYNAMIC LINKS
extension ExploreVC {
     func handleLink() {
     
     selectedUser = nil
     selectedTag = nil
     selectedQuestion = nil
     exploreContainer.clearSelected()
     
     if let universalLink = universalLink, let link = URLComponents(url: universalLink, resolvingAgainstBaseURL: true) {
     
     let urlComponents = link.path.components(separatedBy: "/").dropFirst()
     
     guard let linkType = urlComponents.first else { return }
     
     switch linkType {
     case "u":
     let uID = urlComponents[2]
     userSelected(type: .people, item: User(uID: uID))
     
     case "c":
     let tagID = urlComponents[2]
     userSelected(type: .tag, item: Tag(tagID: tagID))
     
     case "q":
     let qID = urlComponents[2]
     userSelected(type: .question, item: Question(qID: qID))
     
     default:
     loadRoot()
     }
     
     if !isLoaded {
     if tabDelegate != nil { tabDelegate.removeLoading() }
     isLoaded = true
     self.universalLink = nil
     
     }
     }
     }
} **/
