//
//  ChannelVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

protocol ChannelDelegate: class {
    func userSelected(user : User)
    func userSelected(tag : Tag)
}

class ChannelVC: UIViewController, ChannelDelegate {

    //set by delegate
    public var selectedChannel : Channel! {
        didSet {
            isFollowingSelectedChannel = User.currentUser?.savedTags != nil && User.currentUser!.savedTagIDs.contains(selectedChannel.cID!) ? true : false

            if !selectedChannel.cCreated {
                Database.getChannel(cID: selectedChannel.cID!, completion: { channel, error in
                    self.selectedChannel = channel
                    self.updateHeader()
                })
            } else if !selectedChannel.cDetailedCreated {
                getChannelItems()
            } else {
                print("setting all items to \(allItems.count)")
                allItems = selectedChannel.items
                updateDataSource()
                updateHeader()
            }
        }
    }
    //end set by delegate
    
    fileprivate var headerNav : PulseNavVC?
    
    fileprivate var toggleFollowButton = PulseButton(size: .medium, type: .addCircle, isRound : true, hasBackground: false, tint: .black)
    fileprivate var isFollowingSelectedChannel : Bool = false {
        didSet {
            isFollowingSelectedChannel ?
                toggleFollowButton.setImage(UIImage(named: "remove-circle")?.withRenderingMode(.alwaysTemplate), for: UIControlState()) :
                toggleFollowButton.setImage(UIImage(named: "add-circle")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        }
    }
    
    fileprivate var allItems = [Item]()
    fileprivate var isLoaded = false
    fileprivate var isLayoutSetup = false
    
    /** Collection View Vars **/
    fileprivate var channel : UICollectionView!
    fileprivate let minCellHeight : CGFloat = 125
    fileprivate let headerHeight : CGFloat = 125
    fileprivate let headerReuseIdentifier = "ChannelHeader"
    fileprivate let questionReuseIdentifier = "QuestionCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            if let nav = navigationController as? PulseNavVC {
                headerNav = nav
            }
            
            view.backgroundColor = .white
            setupScreenLayout()
            definesPresentationContext = true
            
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    internal func getChannelItems() {
        Database.getChannelItems(channel: selectedChannel, completion: { updatedChannel in
            if let updatedChannel = updatedChannel {
                self.selectedChannel = updatedChannel
            }
        })
    }
    
    //Once the channel is set and pulled from database -> reload the datasource for collection view
    func updateDataSource() {
        if !isLayoutSetup {
            setupScreenLayout()
        }
        
        channel.delegate = self
        channel.dataSource = self
        channel.reloadData()
        channel.layoutIfNeeded()
        
        if allItems.count > 0 {
            channel.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        let backButton = PulseButton(size: .small, type: .back, isRound : true, hasBackground: true)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: toggleFollowButton)

        if let nav = headerNav {
            nav.setNav(title: selectedChannel.cTitle ?? "Explore Tag")
            backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
            //toggleFollowButton.addTarget(self, action: #selector(), for: UIControlEvents.touchUpInside)
        } else {
            title = selectedChannel.cTitle ?? "Explore Tag"
        }
    }
    
    /**
    internal func follow() {
        Database.pinTagForUser(selectedTag, completion: {(success, error) in
            if !success {
                GlobalFunctions.showErrorBlock("Error Saving Tag", erMessage: error!.localizedDescription)
            } else {
                self.isFollowingSelectedTag = self.isFollowingSelectedTag ? false : true
            }
        })
    }**/
    
    internal func goBack() {
        let _ = navigationController?.popViewController(animated: true)
    }
    
    internal func userSelected(user: User) {
        let userProfileVC = UserProfileVC()
        navigationController?.pushViewController(userProfileVC, animated: true)
        userProfileVC.selectedUser = user
    }
    
    internal func userSelected(tag: Tag) {
        // TO COME
    }
    
    fileprivate func setupScreenLayout() {
        if !isLayoutSetup {
            let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
            layout.scrollDirection = UICollectionViewScrollDirection.vertical
            layout.minimumLineSpacing = 10
            layout.minimumInteritemSpacing = 10
            
            channel = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
            channel?.register(FeedQuestionCell.self, forCellWithReuseIdentifier: questionReuseIdentifier)
            channel?.register(ChannelHeaderTags.self,
                                            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader ,
                                            withReuseIdentifier: headerReuseIdentifier)
            //channel?.register(ChannelHeader.self,
            //                  forSupplementaryViewOfKind: UICollectionElementKindSectionHeader ,
            //                  withReuseIdentifier: headerReuseIdentifier)
            
            view.addSubview(channel!)
            
            channel.translatesAutoresizingMaskIntoConstraints = false
            channel.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            channel.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            channel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            channel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            channel.layoutIfNeeded()
            
            channel.backgroundColor = .clear
            channel.backgroundView = nil
            channel.showsVerticalScrollIndicator = false
            
            channel?.isMultipleTouchEnabled = true
            isLayoutSetup = true
        }
    }
}

/* COLLECTION VIEW */
extension ChannelVC : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: questionReuseIdentifier,
                                                      for: indexPath) as! FeedQuestionCell
        
        //clear the cells and set the item type first
        cell.updateLabel(nil, _subtitle: nil)
        cell.contentView.backgroundColor = .white
        
        //Already fetched this item
        if allItems.count > indexPath.row, let itemType = allItems[indexPath.row].itemType, let currentItem = allItems[indexPath.row].itemContent {
            switch itemType {
            case .qa:
                if let currentQuestion = currentItem as? Question {
                    cell.updateLabel(currentQuestion.qTitle, _subtitle: currentQuestion.qTag?.tagTitle?.capitalized ?? nil)
                    cell.answerCount.setTitle(String(currentQuestion.totalAnswers()), for: UIControlState())
                }
            case .post: break
            }
        } else if let itemType = allItems[indexPath.row].itemType {
            switch itemType {
            case .qa:
                Database.getQuestion(allItems[indexPath.row].itemID, completion: { (question, error) in
                    if let question = question {
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            DispatchQueue.main.async {
                                cell.updateLabel(question.qTitle, _subtitle: nil)
                                cell.answerCount.setTitle(String(question.totalAnswers()), for: UIControlState())
                            }
                        }
                        self.allItems[indexPath.row].itemContent = question
                    }
                })
            case .post: break
            }

        }
        return cell
    }
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateQuestionCell(_ cell: FeedQuestionCell, inCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
        if allItems.count > indexPath.row, let itemType = allItems[indexPath.row].itemType, let currentItem = allItems[indexPath.row].itemContent {
            switch itemType {
            case .qa:
                if let currentQuestion = currentItem as? Question {
                    cell.updateLabel(currentQuestion.qTitle, _subtitle: currentQuestion.qTag?.tagTitle?.capitalized ?? nil)
                    cell.answerCount.setTitle(String(currentQuestion.totalAnswers()), for: UIControlState())
                }
            case .post:
                break
            }
        }
    }
    
    func updateOnscreenRows() {
        let visiblePaths = channel.indexPathsForVisibleItems
        for indexPath in visiblePaths {
            let cell = channel.cellForItem(at: indexPath) as! FeedQuestionCell
            updateQuestionCell(cell, inCollectionView: channel, atIndexPath: indexPath)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateOnscreenRows()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { updateOnscreenRows() }
    }
    
    //Did select item at index path
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        
        if let selectedQuestion = allItems[indexPath.row].itemContent as? Question {
            let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
            layout.scrollDirection = UICollectionViewScrollDirection.vertical
            layout.minimumLineSpacing = 10
            layout.minimumInteritemSpacing = 10
            
            let answersCollection = AnswersCollectionVC(collectionViewLayout: layout)
            answersCollection.selectedQuestion = selectedQuestion
            answersCollection.allAnswers = selectedQuestion.qAnswers.map({Answer(aID: $0, qID: selectedQuestion.qID)})
            
            navigationController?.pushViewController(answersCollection, animated: true)

        }
        
        
        //channelDelegate.userSelected(type : .question, item : allQuestions[indexPath.row])
    }
    
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! ChannelHeaderTags
            headerView.backgroundColor = .white
            headerView.tags = selectedChannel.tags
            //headerView.experts = selectedChannel.experts
            headerView.delegate = self
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
    }
}

extension ChannelVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (channel.frame.width - 20), height: minCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: channel.frame.width, height: headerHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 1.0, bottom: 1.0, right: 1.0)
    }
}
