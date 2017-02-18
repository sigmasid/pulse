//
//  UserProfileVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 2/16/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

protocol UserProfileDelegate: class {
    func askQuestion()
    func sendMessage()
    func shareProfile()
}

class UserProfileVC: UIViewController, UserProfileDelegate, previewDelegate {
    
    /** Delegate Vars **/
    public var selectedUser : User! {
        didSet {
            if !selectedUser.uCreated {
                Database.getUser(selectedUser.uID!, completion: {(user, error) in
                    if error == nil {
                        self.selectedUser = user
                        self.updateHeader()
                    }
                })
            } else if !selectedUser.uDetailedCreated {
                getDetailUserProfile()
            } else {
                allAnswers = selectedUser.answers
                updateDataSource()
            }
            
            if selectedUser.thumbPicImage == nil {
                getUserProfilePic()
            }
        }
    }
    
    //Delegate PreviewVC var - if user watches full preview then go to index 1 vs. index 0 in full screen
    var watchedFullPreview: Bool = false
    /** End Delegate Vars **/

    fileprivate var headerNav : PulseNavVC?
    fileprivate var QAVC : QAManagerVC!
    fileprivate var selectedAnswer: Answer!

    fileprivate var allAnswers = [Answer]()
    fileprivate var isLoaded = false
    fileprivate var isLayoutSetup = false
    
    /** Collection View Vars **/
    fileprivate var profile : UICollectionView!
    fileprivate let minCellHeight : CGFloat = 225
    fileprivate let headerHeight : CGFloat = 225
    fileprivate let headerReuseIdentifier = "UserProfileHeader"
    fileprivate let answerReuseIdentifier = "FeedAnswerCell"
    
    /** Transition Vars **/
    fileprivate var initialFrame = CGRect.zero
    fileprivate var panPresentInteractionController = PanEdgeInteractionController()
    fileprivate var panDismissInteractionController = PanEdgeInteractionController()
    
    fileprivate var activityController: UIActivityViewController? //Used for share screen
    
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
            updateHeader()
            definesPresentationContext = true

            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard selectedUser != nil else { return }
        updateHeader()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    internal func getDetailUserProfile() {
        Database.getDetailedUserProfile(user: selectedUser, completion: { updatedUser in
            let userImage = self.selectedUser.thumbPicImage
            
            self.selectedUser = updatedUser
            self.selectedUser.thumbPicImage = userImage
        })
    }
    
    internal func getUserProfilePic() {
        Database.getProfilePicForUser(user: selectedUser, completion: { profileImage in
            self.selectedUser.thumbPicImage = profileImage
            
            if self.profile != nil {
                for view in self.profile.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionHeader) {
                    view.setNeedsDisplay()
                }
            }
        })
    }
    
    //Once the channel is set and pulled from database -> reload the datasource for collection view
    internal func updateDataSource() {
        if !isLayoutSetup {
            setupScreenLayout()
        }
        
        for (index, answer) in allAnswers.enumerated() {
            let currentAnswerData = AnswerPreviewData(answer: answer,
                                                      question: nil,
                                                      answerCollection: [],
                                                      gettingImageForAnswerPreview: false,
                                                      gettingInfoForAnswerPreview: false)
            answerStack.insert(currentAnswerData, at: index)
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
            nav.setNav(title: self.selectedUser.name ?? "Explore User")
            backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
        }
    }
    
    internal func goBack() {
        let _ = navigationController?.popViewController(animated: true)
    }
    
    /** Start Delegate Functions **/
    func askQuestion() {
        let questionVC = AskQuestionVC()
        questionVC.selectedUser = selectedUser
        navigationController?.pushViewController(questionVC, animated: true)
    }
    
    func shareProfile() {
        selectedUser.createShareLink(completion: { link in
            guard let link = link else { return }
            self.activityController = GlobalFunctions.shareContent(shareType: "person",
                                                                   shareText: self.selectedUser.name ?? "",
                                                                   shareLink: link, presenter: self)
        })
    }
    
    func sendMessage() {
        let messageVC = MessageVC()
        messageVC.toUser = selectedUser
        
        if let selectedUserImage = selectedUser.thumbPicImage {
            messageVC.toUserImage = selectedUserImage
        }
        
        navigationController?.pushViewController(messageVC, animated: true)
    }
    /** End Delegate Functions **/
    
    
    fileprivate func setupScreenLayout() {
        if !isLayoutSetup {
            let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
            layout.scrollDirection = UICollectionViewScrollDirection.vertical
            layout.minimumLineSpacing = 10
            layout.minimumInteritemSpacing = 10
            
            profile = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
            profile.register(FeedAnswerCell.self, forCellWithReuseIdentifier: answerReuseIdentifier)
            profile.register(UserProfileHeader.self,
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
        let QAVC = QAManagerVC()
        
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
    }
    
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! UserProfileHeader
            headerView.backgroundColor = .white
            headerView.updateUserDetails(selectedUser: selectedUser)
            headerView.profileDelegate = self
            
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
