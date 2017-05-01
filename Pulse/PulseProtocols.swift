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

protocol ParentDelegate: class {
    func dismissVC(_ viewController : UIViewController)
}

protocol ParentTextViewDelegate {
    func dismiss(_ view : UIView)
    func buttonClicked(_ text: String, sender: UIView)
}

protocol ItemCellDelegate : class {
    func clickedUserButton(itemRow : Int)
    func clickedMenuButton(itemRow : Int)
}

protocol CameraDelegate : class {
    func doneRecording(isCapturing : Bool, url : URL?, image: UIImage?, location: CLLocation?, assetType : CreatedAssetType?)
    func userDismissedCamera()
    func showAlbumPicker()
}

protocol InterviewDelegate : class {
    func doneInterviewQuestion(success: Bool)
}

protocol UserProfileDelegate: class {
    func showMenu()
}

//Used by Preview VC to indicate that user watched full preview -> so full screen goes to index + 1
protocol PreviewDelegate: class {
    var  watchedFullPreview : Bool { get set }
}

protocol ContentDelegate: class {
    func noItemsToShow(_ : UIViewController)
    func removeIntro()
    func askUserToLogin(_: UIViewController)
    func loginSuccess(_ : UIViewController)
    func doneUploadingItem(_: UIViewController, success: Bool)
    
    func userDismissedRecording(_: UIViewController, recordedItems : [Item])
    func loadMoreFromTag()
    func addMoreItems(_ : UIViewController, recordedItems : [Item], isCover : Bool)
    func userClickedSeeAll(items : [Item])
    func userClickedProfileDetail()
}

protocol BrowseContentDelegate: class {
    func showItemDetail(allItems: [Item], index: Int, itemCollection: [Item], selectedItem : Item, watchedPreview : Bool)
    func addNewItem(selectedItem : Item)
}

//Used to dismiss a modal 
protocol ModalDelegate : class {
    func userClosedModal(_ viewController : UIViewController)
}
