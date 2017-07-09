//
//  InputVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/28/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit
import CoreLocation

class InputVC: UIPageViewController {
    fileprivate lazy var cameraVC : CameraVC! = CameraVC()
    fileprivate lazy var albumVC : PulseAlbumVC! = PulseAlbumVC()
    fileprivate lazy var notecardVC : TextInputVC! = TextInputVC()
    
    /** PUBLIC SETTERS **/
    public var albumShowsVideo : Bool = true
    public var showTextInput : Bool = false
    public var cameraMode :  CameraOutputMode = .videoWithMic {
        didSet {
            if isLoaded {
                cameraVC.cameraMode = cameraMode
            }
        }
    }
    public var cameraTitle : String = "tap shutter to take photo, hold to record video" {
        didSet {
            if isLoaded {
                cameraVC.updateOverlayTitle(title: cameraTitle)
            }
        }
    }
    public var captureSize : AssetSize = .fullScreen {
        didSet {
            if isLoaded, captureSize != oldValue {
                cameraVC.captureSize = captureSize
                albumVC.captureSize = captureSize
            }
        }
    }
    public var inputDelegate : InputMasterDelegate!
    /** END SETTERS **/
    
    private var isLoaded = false
    private var cleanupComplete = false
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    deinit {
        if cameraVC != nil {
            cameraVC.performCleanup()
        }
        if albumVC != nil {
            albumVC.performCleanup()
        }
        
        if notecardVC != nil {
            notecardVC.performCleanup()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            dataSource = self
            delegate = self
            
            cameraVC.delegate = self
            cameraVC.cameraMode = cameraMode
            cameraVC.screenTitle = cameraTitle
            cameraVC.captureSize = captureSize
            cameraVC.showTextInput = showTextInput
                
            albumVC.shouldAllowVideo = albumShowsVideo
            albumVC.delegate = self
            albumVC.captureSize = captureSize
            
            if showTextInput {
                notecardVC.delegate = self
            }
            
            setViewControllers([cameraVC], direction: .reverse, animated: true, completion: nil)
            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollToViewController(viewController: cameraVC, direction: .forward, animated: false)
    }
    
    public func performCleanup() {
        if !cleanupComplete {
            cameraVC.performCleanup()
            albumVC.performCleanup()
            
            cameraVC = nil
            albumVC = nil
            
            inputDelegate = nil
            cleanupComplete = true
            isLoaded = false
        }
    }
    
    public func updateAlpha() {
        albumVC.view.alpha = 1.0
        cameraVC.view.alpha = 1.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    internal func scrollToViewController(viewController: UIViewController, direction: UIPageViewControllerNavigationDirection = .forward, animated: Bool = true) {
        setViewControllers([viewController], direction: direction, animated: animated, completion: { (finished) -> Void in })
    }
}

extension InputVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if viewController is CameraVC {
            return showTextInput ? notecardVC : nil
        } else if viewController is PulseAlbumVC {
            return cameraVC
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if viewController is CameraVC {
            return albumVC
        } else if viewController is TextInputVC {
            return cameraVC
        }
        return nil
    }
}

extension InputVC: InputItemDelegate {
    func capturedItem(item: Any?, location: CLLocation?, assetType: CreatedAssetType) {
        inputDelegate.capturedItem(item: item, location: location, assetType: assetType)
    }
    
    func dismissInput() {
        inputDelegate.dismissInput()
    }
    
    func switchInput(to: InputMode, from: InputMode) {
        if from == .album, to == .camera {
            scrollToViewController(viewController: cameraVC, direction: .forward)
        } else if from == .camera, to == .album {
            scrollToViewController(viewController: albumVC, direction: .reverse)
        } else if from == .camera, to == .text {
            scrollToViewController(viewController: notecardVC, direction: .forward)
        } else if from == .text, to == .camera {
            scrollToViewController(viewController: cameraVC, direction: .reverse)
        }
    }
}
