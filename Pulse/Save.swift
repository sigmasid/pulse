//
//  Heart.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/5/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class Save: UIView {

    private var _saveImage = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _saveImage.frame = frame
        addSubview(_saveImage)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func toggle(mode : SaveType) {
        switch mode {
        case .Save:
            _saveImage.image = UIImage(named: "save")
            let xForm = CGAffineTransformScale(CGAffineTransformIdentity, 2.0, 2.0)
            UIView.animateWithDuration(0.25, animations: { self._saveImage.transform = xForm } , completion: {(value: Bool) in
                self._saveImage.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0)
            })
        case .Unsave:
            _saveImage.image = UIImage(named: "unsave")
            let xForm = CGAffineTransformScale(CGAffineTransformIdentity, 2.0, 2.0)
            UIView.animateWithDuration(0.25, animations: { self._saveImage.transform = xForm } , completion: {(value: Bool) in
                self._saveImage.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0)
            })
        }
    }
}
