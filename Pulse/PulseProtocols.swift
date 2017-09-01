//
//  PulseProtocols.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 3/10/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

protocol HeaderDelegate: class {
    func clickedHeaderMenu()
}

protocol SelectionDelegate: class {
    func userSelected(item : Any)
}

protocol ParentTextViewDelegate: class {
    func dismiss(_ view : UIView)
    func addTextDone(_ text: String, sender: UIView)
}

protocol ItemDetailDelegate : class {
    func userClickedProfile()
    func userClickedBrowseItems()
    func userSelected(_ index : IndexPath)
    func votedItem(_ _vote : VoteType)
    func userClickedSendMessage()
    func userClosedQuickBrowse()
    func userClickedNextItem()
    func userClickedSeeAll(items : [Item])
    func userClickedHeaderMenu()
}

protocol ItemCellDelegate : class {
    func clickedUserButton(itemRow : Int)
    func clickedMenuButton(itemRow : Int)
}

public protocol ImageTrimmerDelegate : class {
    func capturedItem(image: UIImage?)
    func dismissedTrimmer() 
}

public protocol VideoTrimmerDelegate: class {
    func dismissedTrimmer()
    func exportedAsset(url: URL?)
}

protocol InputItemDelegate : InputMasterDelegate {
    func switchInput(to: InputMode, from: InputMode)
    func dimAlpha()
    func updateAlpha()
}

protocol InputMasterDelegate: class {
    func dismissInput()
    func capturedItem(item : Any?, location: CLLocation?, assetType : CreatedAssetType)
}

protocol RecordedTextViewDelegate {
    func charsRemaining(count: Int)
}

protocol AddCoverDelegate: class {
    func dismissAddCover()
    func addCover(image: UIImage, title: String, location: CLLocation?, assetType : CreatedAssetType)
}

protocol PanAnimationDelegate : class {
    func panCompleted(success: Bool, fromVC: UIViewController?)
}

protocol CompletedRecordingDelegate : class {
    func doneRecording(success: Bool)
}

protocol UserProfileDelegate: class {
    func showMenu()
    func editProfile()
}

protocol ListItemDelegate {
    func userClickedListItem(itemID: String)
}

protocol ListDelegate : ListItemDelegate {
    func addListItem(title : String)
    func showMenuFor(itemID: String)
}

protocol ContentDelegate: class {
    func noItemsToShow(_ : UIViewController)
    func removeIntro()
    func doneUploadingItem(_: UIViewController, item: Item, success: Bool)
    
    func userDismissedRecording(_: UIViewController, recordedItems : [Item])
    func loadMoreFromTag()
    func addMoreItems(_ : UIViewController, recordedItems : [Item])
    func userClickedSeeAll(items : [Item])
    func userClickedProfileDetail()
}

protocol BrowseContentDelegate: class {
    func showItemDetail(allItems: [Item], index: Int, itemCollection: [Item], selectedItem : Item)
    func addNewItem(selectedItem : Item)
}

//Used to dismiss a modal 
protocol ModalDelegate : class {
    func userClosedModal(_ viewController : UIViewController)
}

protocol CameraManagerProtocol: class {
    func didReachMaxRecording(_ fileURL : URL?, image: UIImage?, error : NSError?)
}

protocol LoadingDelegate : class {
    func clickedRefresh()
}

protocol PreviewPlayerItemDelegate: class {
    func itemStatusReady()
}

protocol FirstLaunchDelegate {
    func doneWithIntro(mode: IntroType)
}

protocol MasterTabDelegate : class {
    func setTab(to: TabType)
    func userUpdated()
}

/**
 The state of the navigation bar
 - collapsed: the navigation bar is fully collapsed
 - expanded: the navigation bar is fully visible
 - scrolling: the navigation bar is transitioning to either `Collapsed` or `Scrolling`
 */

public protocol PulseNavControllerDelegate: NSObjectProtocol {
    /**
     Called when the state of the navigation bar changes
     */
    func scrollingNavigationController(_ controller: PulseNavVC, didChangeState state: NavigationBarState)
    
    /**
     Called when the state of the navigation bar is about to change
     */
    func scrollingNavigationController(_ controller: PulseNavVC, willChangeState state: NavigationBarState)
}


