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
}

class ChannelVC: UIViewController, ChannelDelegate {

    //set by delegate
    public var selectedTag : Tag! {
        didSet {
            isFollowingSelectedTag = User.currentUser?.savedTags != nil && User.currentUser!.savedTagIDs.contains(selectedTag.tagID!) ? true : false

            if !selectedTag.tagCreated {
                Database.getTag(selectedTag.tagID!, completion: { tag, error in
                    self.selectedTag = tag
                    self.updateHeader()
                    
                    if error == nil && tag.totalQuestionsForTag() > 0 {
                        self.selectedTag = tag
                        self.allQuestions = self.selectedTag.questions
                        self.updateDataSource()
                    }
                })
            } else {
                allQuestions = selectedTag.questions
                updateDataSource()
                updateHeader()
            }
        }
    }
    //end set by delegate
    
    fileprivate var headerNav : PulseNavVC?
    
    fileprivate var toggleFollowButton = PulseButton(size: .medium, type: .addCircle, isRound : true, hasBackground: false, tint: .black)
    fileprivate var isFollowingSelectedTag : Bool = false {
        didSet {
            isFollowingSelectedTag ?
                toggleFollowButton.setImage(UIImage(named: "remove-circle")?.withRenderingMode(.alwaysTemplate), for: UIControlState()) :
                toggleFollowButton.setImage(UIImage(named: "add-circle")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        }
    }
    
    fileprivate var allQuestions = [Question]()
    fileprivate var isLoaded = false
    fileprivate var isLayoutSetup = false
    
    /** Collection View Vars **/
    fileprivate var channel : UICollectionView!
    fileprivate let minCellHeight : CGFloat = 125
    fileprivate let headerHeight : CGFloat = 100
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
    
    //Once the channel is set and pulled from database -> reload the datasource for collection view
    func updateDataSource() {
        if !isLayoutSetup {
            setupScreenLayout()
        }
        
        channel.delegate = self
        channel.dataSource = self
        channel.reloadData()
        channel.layoutIfNeeded()
        
        if allQuestions.count > 0 {
            channel.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        let backButton = PulseButton(size: .small, type: .back, isRound : true, hasBackground: true)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: toggleFollowButton)

        if let nav = headerNav {
            nav.setNav(title: self.selectedTag.tagTitle ?? "Explore Tag", image: nil)
            backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
            toggleFollowButton.addTarget(self, action: #selector(follow), for: UIControlEvents.touchUpInside)
        } else {
            title = self.selectedTag.tagTitle ?? "Explore Tag"
        }
    }
    
    internal func follow() {
        Database.pinTagForUser(selectedTag, completion: {(success, error) in
            if !success {
                GlobalFunctions.showErrorBlock("Error Saving Tag", erMessage: error!.localizedDescription)
            } else {
                self.isFollowingSelectedTag = self.isFollowingSelectedTag ? false : true
            }
        })
    }
    
    internal func goBack() {
        let _ = navigationController?.popViewController(animated: true)
    }
    
    internal func userSelected(user: User) {
        let userProfileVC = UserProfileVC()
        navigationController?.pushViewController(userProfileVC, animated: true)
        userProfileVC.selectedUser = user
    }
    
    fileprivate func setupScreenLayout() {
        if !isLayoutSetup {
            let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
            layout.scrollDirection = UICollectionViewScrollDirection.vertical
            layout.minimumLineSpacing = 10
            layout.minimumInteritemSpacing = 10
            
            channel = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
            channel?.register(FeedQuestionCell.self, forCellWithReuseIdentifier: questionReuseIdentifier)
            channel?.register(ChannelHeader.self,
                                            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader ,
                                            withReuseIdentifier: headerReuseIdentifier)
            
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
        return allQuestions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: questionReuseIdentifier,
                                                      for: indexPath) as! FeedQuestionCell
        
        //clear the cells and set the item type first
        cell.updateLabel(nil, _subtitle: nil)
        cell.contentView.backgroundColor = .white
        
        if allQuestions.count > indexPath.row && allQuestions[indexPath.row].qTitle != nil {
            let _currentQuestion = allQuestions[indexPath.row]
            
            cell.updateLabel(_currentQuestion.qTitle, _subtitle: _currentQuestion.qTag?.tagTitle?.capitalized ?? nil)
            cell.answerCount.setTitle(String(_currentQuestion.totalAnswers()), for: UIControlState())
            
        } else {
            Database.getQuestion(allQuestions[indexPath.row].qID, completion: { (question, error) in
                if let question = question {
                    if let tagTitle = question.qTag?.tagTitle  {
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            DispatchQueue.main.async {
                                cell.updateLabel(question.qTitle, _subtitle: tagTitle.capitalized)
                                cell.answerCount.setTitle(String(question.totalAnswers()), for: UIControlState())
                            }
                        }
                        self.allQuestions[indexPath.row] = question
                    } else if let tag = self.allQuestions[indexPath.row].qTag {
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            DispatchQueue.main.async {
                                cell.updateLabel(question.qTitle, _subtitle: tag.tagTitle?.capitalized)
                                cell.answerCount.setTitle(String(question.totalAnswers()), for: UIControlState())
                            }
                        }
                        self.allQuestions[indexPath.row] = question
                        self.allQuestions[indexPath.row].qTag = tag
                        
                    } else {
                        if collectionView.indexPath(for: cell)?.row == indexPath.row {
                            DispatchQueue.main.async {
                                cell.updateLabel(question.qTitle, _subtitle: nil)
                                cell.answerCount.setTitle(String(question.totalAnswers()), for: UIControlState())
                            }
                        }
                        self.allQuestions[indexPath.row] = question
                    }
                }
            })
        }
        return cell
    }
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateQuestionCell(_ cell: FeedQuestionCell, inCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
        if allQuestions.count > indexPath.row && allQuestions[indexPath.row].qTitle != nil {
            let _currentQuestion = allQuestions[indexPath.row]
            
            cell.updateLabel(_currentQuestion.qTitle, _subtitle: _currentQuestion.qTag?.tagTitle?.capitalized ?? nil)
            cell.answerCount.setTitle(String(_currentQuestion.totalAnswers()), for: UIControlState())
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
        //channelDelegate.userSelected(type : .question, item : allQuestions[indexPath.row])
    }
    
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! ChannelHeader
            headerView.backgroundColor = .white
            headerView.experts = selectedTag.experts
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
}
