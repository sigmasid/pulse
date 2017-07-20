//
//  LoadingVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 12/19/16.
//  Copyright © 2016 - Present Think Apart. All rights reserved.
//

import UIKit

class LoadingVC: UIViewController {
    fileprivate var loadingView : LoadingView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingView = LoadingView(frame: view.bounds, backgroundColor: UIColor.white)
        loadingView?.addIcon(IconSizes.medium, _iconColor: UIColor.black, _iconBackgroundColor: nil)
        loadingView?.addMessage("Loading...")
        
        view.addSubview(loadingView!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        if loadingView != nil {
            loadingView?.removeFromSuperview()
            loadingView = nil
        }
    }
}
