//
//  Heart.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/5/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class Saved: UIView {

    fileprivate var _saveImage = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _saveImage.frame = frame
        addSubview(_saveImage)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func toggle(_ mode : SaveType) {
        switch mode {
        case .save:
            _saveImage.image = UIImage(named: "save")
            let xForm = CGAffineTransform.identity.scaledBy(x: 2.0, y: 2.0)
            UIView.animate(withDuration: 0.25, animations: { self._saveImage.transform = xForm } , completion: {(value: Bool) in
                self._saveImage.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
            })
        case .unsave:
            _saveImage.image = UIImage(named: "unsave")
            let xForm = CGAffineTransform.identity.scaledBy(x: 2.0, y: 2.0)
            UIView.animate(withDuration: 0.25, animations: { self._saveImage.transform = xForm } , completion: {(value: Bool) in
                self._saveImage.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
            })
        }
    }
}
