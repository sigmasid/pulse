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
    func userClickedMenu()
}

protocol SelectionDelegate: class {
    func userSelected(item : Any)
}

protocol ParentDelegate: class {
    func dismiss(_ viewController : UIViewController)
}

protocol ItemCellDelegate : class {
    func clickedItemButton(itemRow : Int)
}

protocol CameraDelegate : class {
    func doneRecording(_: URL?, image: UIImage?, location: CLLocation?, assetType : CreatedAssetType?)
    func userDismissedCamera()
    func showAlbumPicker()
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
    func doneUploadingAnswer(_: UIViewController)
    
    func userDismissedRecording(_: UIViewController, recordedItems : [Item])
    func minItemsShown()
    func askUserQuestion()
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
