//
//  AlbumPickerVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 8/16/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class AlbumPickerVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private var imageView: UIImageView!
    weak var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker!.delegate = self
        imagePicker!.allowsEditing = false
        imagePicker!.sourceType = .PhotoLibrary
        
        presentViewController(imagePicker!, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .ScaleAspectFit
            imageView.image = pickedImage
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
