//
//  UserProfileVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class UserProfileVC: UIViewController, previewDelegate {
    
    //set by delegate
    var profileDelegate : feedVCDelegate!
    public var selectedUser : User! {
        didSet {
            if !selectedUser.uCreated {
                Database.getUser(selectedUser.uID!, completion: {(user, error) in
                    if error == nil {
                        self.selectedUser = user
                        
                        Database.getProfilePicForUser(user: user, completion: { profileImage in
                            user.thumbPicImage = profileImage
                            self.updateHeader()
                        })
                    }
                })
            } else {
                updateHeader()
            }
            
            
        }
    }
    //end set by delegate
    
    //Delegate PreviewVC var - if user watches full preview then go to index 1 vs. index 0 in full screen
    var watchedFullPreview: Bool = false
    
    fileprivate var headerNav : PulseNavVC?
    fileprivate var QAVC : QAManagerVC!
    var selectedAnswer: Answer!

    fileprivate var allAnswers = [Answer]()
    fileprivate var isLoaded = false
    fileprivate var isLayoutSetup = false
    
    /** Collection View Vars **/
    fileprivate var profile : UICollectionView!
    fileprivate let minCellHeight : CGFloat = 225
    fileprivate let headerHeight : CGFloat = 225
    fileprivate let headerReuseIdentifier = "ChannelHeader"
    fileprivate let answerReuseIdentifier = "FeedAnswerCell"
    
    /** Transition Vars **/
    fileprivate var initialFrame = CGRect.zero
    fileprivate var panPresentInteractionController = PanEdgeInteractionController()
    fileprivate var panDismissInteractionController = PanEdgeInteractionController()
    
    fileprivate var answerStack = [AnswerPreviewData]()
    struct AnswerPreviewData {
        var answer : Answer!
        var question : Question?
        var answerCollection = [String]()
        
        var gettingImageForAnswerPreview : Bool = false
        var gettingInfoForAnswerPreview : Bool = false
    }
    
    fileprivate var selectedIndex : IndexPath? {
        didSet {
            if selectedIndex != nil {
                profile.reloadItems(at: [selectedIndex!])
                if deselectedIndex != nil && deselectedIndex != selectedIndex {
                    profile.reloadItems(at: [deselectedIndex!])
                }
            }
        }
        willSet {
            if selectedIndex != nil {
                deselectedIndex = selectedIndex
            }
            
            if newValue == nil, let selectedIndex = selectedIndex {
                let cell = profile.dequeueReusableCell(withReuseIdentifier: answerReuseIdentifier, for: selectedIndex) as! FeedAnswerCell
                cell.removeAnswer()
            }
        }
    }
    fileprivate var deselectedIndex : IndexPath?
    
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //Once the channel is set and pulled from database -> reload the datasource for collection view
    func updateDataSource() {
        if !isLayoutSetup {
            setupScreenLayout()
        }
        
        profile.delegate = self
        profile.dataSource = self
        profile.reloadData()
        profile.layoutIfNeeded()
    }
    
    //Update Nav Header
    fileprivate func updateHeader() {
        let backButton = PulseButton(size: .small, type: .back, isRound : true, hasBackground: true)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        if let nav = headerNav {
            nav.setNav(navTitle: nil, screenTitle: self.selectedUser.name ?? "Explore User", screenImage: nil)
            backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
        } else {
            title = self.selectedUser.name ?? "Explore Tag"
        }
    }

    
    internal func goBack() {
        let _ = navigationController?.popViewController(animated: true)
    }
    
    fileprivate func setupScreenLayout() {
        if !isLayoutSetup {
            let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
            layout.scrollDirection = UICollectionViewScrollDirection.vertical
            layout.minimumLineSpacing = 10
            layout.minimumInteritemSpacing = 10
            
            profile = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
            profile.register(FeedQuestionCell.self, forCellWithReuseIdentifier: answerReuseIdentifier)
            profile.register(ChannelHeader.self,
                              forSupplementaryViewOfKind: UICollectionElementKindSectionHeader ,
                              withReuseIdentifier: headerReuseIdentifier)
            
            view.addSubview(profile)
            
            profile.translatesAutoresizingMaskIntoConstraints = false
            profile.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            profile.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            profile.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            profile.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            profile.layoutIfNeeded()
            
            profile.backgroundColor = .clear
            profile.backgroundView = nil
            profile.showsVerticalScrollIndicator = false
            
            profile.isMultipleTouchEnabled = true
            isLayoutSetup = true
        }
    }
}

/* COLLECTION VIEW */
extension UserProfileVC : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allAnswers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: answerReuseIdentifier, for: indexPath) as! FeedAnswerCell
        let _rand = arc4random_uniform(UInt32(_backgroundColors.count))
        
        cell.contentView.backgroundColor = .white
        cell.updateLabel(nil, _subtitle: nil, _image : nil)
        
        let currentAnswer = answerStack[indexPath.row]
        
        /* GET ANSWER PREVIEW IMAGE FROM STORAGE */
        if currentAnswer.answer.thumbImage != nil && currentAnswer.gettingImageForAnswerPreview {
            
            cell.updateImage(image: currentAnswer.answer.thumbImage!)
        } else if currentAnswer.gettingImageForAnswerPreview {
            
            //ignore if already fetching the image, so don't refetch if already getting
        } else {
            answerStack[indexPath.row].gettingImageForAnswerPreview = true
            
            Database.getImage(.AnswerThumbs, fileID: currentAnswer.answer.aID, maxImgSize: maxImgSize, completion: {(_data, error) in
                if error == nil {
                    let _answerPreviewImage = GlobalFunctions.createImageFromData(_data!)
                    self.answerStack[indexPath.row].answer.thumbImage = _answerPreviewImage
                    
                    if collectionView.indexPath(for: cell)?.row == indexPath.row {
                        DispatchQueue.main.async {
                            cell.updateImage(image: self.answerStack[indexPath.row].answer.thumbImage)
                        }
                    }
                } else {
                    cell.updateImage(image: nil)
                }
            })
        }
        
        /* GET QUESTION FROM DATABASE - SHOWING ALL ANSWERS FOR ONE USER CASE */
        if selectedUser != nil {
            if currentAnswer.question != nil && currentAnswer.gettingInfoForAnswerPreview {
                cell.updateLabel(currentAnswer.question!.qTitle, _subtitle: nil)
            } else if currentAnswer.gettingInfoForAnswerPreview {
                //ignore if already fetching the image, so don't refetch if already getting
            } else {
                
                answerStack[indexPath.row].gettingInfoForAnswerPreview = true
                
                Database.getQuestion(currentAnswer.answer.qID, completion: { (question, error) in
                    if error != nil {
                        self.answerStack[indexPath.row].question = nil
                    } else {
                        self.answerStack[indexPath.row].question = question
                        cell.updateLabel(question?.qTitle, _subtitle: nil)
                    }
                })
            }
        } else if answerStack[indexPath.row].gettingInfoForAnswerPreview {
            
            //ignore if already fetching the image, so don't refetch if already getting
        }
        
        if indexPath == selectedIndex && indexPath == deselectedIndex {
            //only show answer by selected user - removes other answers from qAnswers array and creates blank dummy tag
            if selectedUser != nil {
                let selectedQuestion = currentAnswer.question
                selectedQuestion?.qAnswers = [currentAnswer.answer.aID]
                showQuestion(selectedQuestion,
                             answerCollection: currentAnswer.answerCollection,
                             selectedTag: Tag(tagID: currentAnswer.question!.getTag()))
            }
        } else if indexPath == selectedIndex {
            //if answer has more than initial clip, show 'see more at the end'
            watchedFullPreview = false
            
            Database.getAnswerCollection(currentAnswer.answer.aID, completion: {(hasDetail, answerCollection) in
                if hasDetail {
                    cell.showTapForMore = true
                    self.answerStack[indexPath.row].answerCollection = answerCollection!
                } else {
                    cell.showTapForMore = false
                }
            })
            
            cell.delegate = self
            cell.showAnswer(answer: selectedAnswer)
            
        } else if indexPath == deselectedIndex {
            cell.removeAnswer()
        }
        
        return cell
    }
    
    func showQuestion(_ selectedQuestion : Question?, answerCollection: [String], selectedTag : Tag) {
        QAVC = QAManagerVC()
        
        //need to be set first
        QAVC.watchedFullPreview = watchedFullPreview
        QAVC.answerCollection = answerCollection
        QAVC.allAnswers = answerStack.map{ (answerData) -> Answer in answerData.answer }
        
        QAVC.selectedTag = selectedTag
        QAVC.allQuestions = [selectedQuestion]
        QAVC.currentQuestion = selectedQuestion
        QAVC.openingScreen = .question
        
        selectedIndex = nil
        
        QAVC.transitioningDelegate = self
        present(QAVC, animated: true, completion: nil)
    }
    
    func setSelectedIndex(index : IndexPath?) {
        if index != nil {
            selectedAnswer = allAnswers[index!.row]
            deselectedIndex = nil
            selectedIndex = index!
        }
    }
    
    //reload data isn't called on existing cells so this makes sure visible cells always have data in them
    func updateAnswerCell(_ cell: FeedAnswerCell, inCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
        //to come
    }
    
    func updateOnscreenRows() {
        let visiblePaths = profile.indexPathsForVisibleItems
        for indexPath in visiblePaths {
            let cell = profile.cellForItem(at: indexPath) as! FeedAnswerCell
            updateAnswerCell(cell, inCollectionView: profile, atIndexPath: indexPath)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateOnscreenRows()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { updateOnscreenRows() }
    }
    
    //Did select item at index path
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
            let cellRect = attributes.frame
            initialFrame = collectionView.convert(cellRect, to: collectionView.superview)
        }
        profileDelegate.userSelected(type : .answer, item : allAnswers[indexPath.row])
    }
    
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: "ProfileHeader", for: indexPath) as! UserProfileHeader
            
            headerView.backgroundColor = .white
            headerView.updateUserDetails(selectedUser: selectedUser)
        
            return headerView
            
        default: assert(false, "Unexpected element kind")
        }
    }
}

extension UserProfileVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (profile.frame.width - 20), height: minCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: profile.frame.width, height: headerHeight)
    }
}

extension UserProfileVC: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if presented is QAManagerVC {
            panDismissInteractionController.wireToViewController(QAVC, toViewController: nil, edge: UIRectEdge.left)
            
            let animator = ExpandAnimationController()
            animator.initialFrame = initialFrame
            animator.exitFrame = getRectToLeft()
            
            return animator
        } else {
            return nil
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is QAManagerVC {
            let animator = PanAnimationController()
            
            animator.initialFrame = getRectToLeft()
            animator.exitFrame = getRectToRight()
            animator.transitionType = .dismiss
            return animator
        } else {
            return nil
        }
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return panPresentInteractionController.interactionInProgress ? panPresentInteractionController : nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return panDismissInteractionController.interactionInProgress ? panDismissInteractionController : nil
    }
}
