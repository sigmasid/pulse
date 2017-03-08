//
//  SettingsTableVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreLocation

class SettingsTableVC: PulseVC, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    fileprivate var sections : [SettingSection]?
    fileprivate var settings = [[Setting]]()
    fileprivate var selectedSettingRow : IndexPath?
    fileprivate var settingsTable = UITableView()
    
    fileprivate var isLoaded = false
    
    //Update Profile Image
    internal lazy var panDismissCameraInteractionController = PanContainerInteractionController()
    fileprivate lazy var cameraVC : CameraVC = CameraVC()
    
    //View for Profile Image
    internal var profilePicView = UIView()
    internal var profilePicButton = UIButton()
    internal var profilePic = PulseButton(size: .large, type: .blank, isRound: true, hasBackground: false)

    public var settingSection : String! {
        didSet {
            addUserProfilePic()
            Database.getSectionsSection(sectionName: settingSection, completion: { (section , error) in
                if error == nil, let section = section {
                    self.sections = [section]
                    for _ in self.sections! {
                        self.settings.append([])
                    }
                    self.settingsTable.delegate = self
                    self.settingsTable.dataSource = self
                    self.settingsTable.reloadData()
                }
            })
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //force refresh of the selected row
        if selectedSettingRow != nil {
            settingsTable.reloadRows(at: [selectedSettingRow!], with: .fade)
            selectedSettingRow = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        headerNav?.isNavigationBarHidden = false
        tabBarHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isLoaded {
            updateHeader()
            setupLayout()
            
            view.backgroundColor = UIColor.white
            settingsTable.register(SettingsTableCell.self, forCellReuseIdentifier: reuseIdentifier)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func updateHeader() {
        addBackButton()
        headerNav?.setNav(title: "Update Profile")
    }
    
    func showSettingDetail(_ selectedSetting : Setting) {
        let updateSetting = UpdateProfileVC()
        updateSetting._currentSetting = selectedSetting
        navigationController?.pushViewController(updateSetting, animated: true)
    }
    
    internal func updateHeaderImage(img : Data) {
        //add profile pic or use default image
        User.currentUser?.thumbPicImage = UIImage(data: img)
        profilePic.setImage(User.currentUser?.thumbPicImage, for: .normal)
        profilePic.makeRound()
    }
    
    internal func addUserProfilePic() {
        if let thumbPic = User.currentUser?.thumbPicImage {
            profilePic.setImage(thumbPic, for: .normal)
            profilePic.makeRound()
        } else if let _userImageURL = User.currentUser?.thumbPic, let url = URL(string: _userImageURL) {
            DispatchQueue.global().async {
                if let _userImageData = try? Data(contentsOf: url) {
                    User.currentUser?.thumbPicImage = UIImage(data: _userImageData)
                    DispatchQueue.main.async(execute: {
                        self.profilePic.setImage(User.currentUser?.thumbPicImage, for: .normal)
                        self.profilePic.makeRound()
                    })
                }
            }
        }
        
    }
}

extension SettingsTableVC : UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections?[section].sectionSettingsCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let _sectionID = sections![section].sectionID
        return SectionTypes.getSectionDisplayName(_sectionID)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.backgroundView?.backgroundColor = UIColor.clear
            header.textLabel!.setFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: .pulseBlue, alignment: .left)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let _settingID = sections![(indexPath as NSIndexPath).section].settings![(indexPath as NSIndexPath).row]
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! SettingsTableCell

        if settings[(indexPath as NSIndexPath).section].count > (indexPath as NSIndexPath).row {
            let _setting = settings[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
            cell._settingNameLabel.text = _setting.display!
            if _setting.type == .location {
                User.currentUser?.getLocation(completion: {(city) in
                    cell._detailTextLabel.text = city
                })
            }
                
            else if _setting.type != nil {
                cell._detailTextLabel.text = User.currentUser?.getValueForStringProperty(_setting.type!.rawValue)
            }
            
            if _setting.editable {
                cell.accessoryType = .disclosureIndicator
            }
        } else {
            Database.getSetting(_settingID, completion: {(_setting, error) in
                if error == nil, let _setting = _setting {
                    cell._settingNameLabel.text = _setting.display!
                    if _setting.type != nil && _setting.type != .location {
                        cell._detailTextLabel.text = User.currentUser?.getValueForStringProperty(_setting.type!.rawValue)
                    } else if _setting.type == .location {
                        User.currentUser?.getLocation(completion: { location in
                            cell._detailTextLabel.text = location
                        })
                    }
                    self.settings[(indexPath as NSIndexPath).section].append(_setting)
                    if _setting.editable {
                        cell.accessoryType = .disclosureIndicator
                    }
                }
            })
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let _setting = settings[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
        selectedSettingRow = indexPath
        showSettingDetail(_setting)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.medium.rawValue
    }
}

extension SettingsTableVC: CameraDelegate {
    /* CAMERA FUNCTIONS & DELEGATE METHODS */
    func showCamera() {
        guard let nav = navigationController else { return }
        
        cameraVC.delegate = self
        cameraVC.screenTitle = "smile!"
        
        panDismissCameraInteractionController.wireToViewController(cameraVC, toViewController: nil, parentViewController: nav, modal: true)
        panDismissCameraInteractionController.delegate = self
        
        present(cameraVC, animated: true, completion: nil)
    }
    
    func doneRecording(_: URL?, image: UIImage?, location: CLLocation?, assetType : CreatedAssetType?) {
        guard let imageData = image?.mediumQualityJPEGNSData else { return }
        
        cameraVC.toggleLoading(show: true, message: "saving! just a sec...")
        
        Database.uploadProfileImage(imageData, completion: {(URL, error) in
            if error != nil {
                GlobalFunctions.showErrorBlock("Sorry!", erMessage: "There was an error saving the photo. Please try again")
            } else {
                UIView.animate(withDuration: 0.1, animations: { self.cameraVC.view.alpha = 0.0 } ,
                               completion: {(value: Bool) in
                                self.cameraVC.toggleLoading(show: false, message: nil)
                                
                                //update the header
                                self.updateHeaderImage(img: imageData)
                                self.cameraVC.dismiss(animated: true, completion: nil)
                })
            }
        })
    }
    
    func userDismissedCamera() {
        cameraVC.dismiss(animated: true, completion: nil)
    }
    
    func showAlbumPicker() {
        let albumPicker = UIImagePickerController()
        
        albumPicker.delegate = self
        albumPicker.allowsEditing = false
        albumPicker.sourceType = .photoLibrary
        albumPicker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
        
        cameraVC.present(albumPicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        picker.dismiss(animated: true, completion: nil)
        
        cameraVC.toggleLoading(show: true, message: "saving! just a sec...")
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            let pickedImageData = pickedImage.highQualityJPEGNSData
            
            Database.uploadProfileImage(pickedImageData, completion: {(URL, error) in
                if error != nil {
                    self.cameraVC.toggleLoading(show: false, message: nil)
                } else {
                    UIView.animate(withDuration: 0.2, animations: { self.cameraVC.view.alpha = 0.0 } ,
                                   completion: {(value: Bool) in
                                    
                                    self.updateHeaderImage(img: pickedImageData)
                                    self.cameraVC.dismiss(animated: true, completion: nil)
                    })
                }
            })
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

//layout functions
extension SettingsTableVC {
    func setupLayout() {
        view.addSubview(settingsTable)
        view.addSubview(profilePicView)
        
        profilePicView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 150)
        profilePicView.addShadow()

        settingsTable.translatesAutoresizingMaskIntoConstraints = false
        settingsTable.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        settingsTable.topAnchor.constraint(equalTo: profilePicView.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        settingsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        settingsTable.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        settingsTable.layoutIfNeeded()
        
        settingsTable.backgroundView = nil
        settingsTable.backgroundColor = UIColor.clear
        settingsTable.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        settingsTable.separatorColor = UIColor.lightGray
        settingsTable.tableFooterView = UIView() //removes extra rows at bottom
        settingsTable.showsVerticalScrollIndicator = false
        
        settingsTable.isScrollEnabled = false
        automaticallyAdjustsScrollViewInsets = false
        
        setupProfileSummaryLayout()
    }
    
    fileprivate func setupProfileSummaryLayout() {
        profilePicView.addSubview(profilePic)
        profilePicView.addSubview(profilePicButton)
        
        profilePic.translatesAutoresizingMaskIntoConstraints = false
        profilePic.widthAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        profilePic.heightAnchor.constraint(equalToConstant: IconSizes.large.rawValue).isActive = true
        profilePic.centerYAnchor.constraint(equalTo: profilePicView.centerYAnchor, constant: -Spacing.xs.rawValue).isActive = true
        profilePic.centerXAnchor.constraint(equalTo: profilePicView.centerXAnchor).isActive = true
        profilePic.layoutIfNeeded()
        
        profilePicButton.translatesAutoresizingMaskIntoConstraints = false
        profilePicButton.topAnchor.constraint(equalTo: profilePic.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        profilePicButton.centerXAnchor.constraint(equalTo: profilePic.centerXAnchor).isActive = true
        profilePicButton.heightAnchor.constraint(equalToConstant: Spacing.s.rawValue).isActive = true
        profilePicButton.setButtonFont(FontSizes.body2.rawValue, weight: UIFontWeightRegular, color: .lightGray, alignment: .center)
        profilePicButton.setTitle("edit image", for: .normal)
        
        profilePicButton.backgroundColor = .clear
        profilePicButton.layoutIfNeeded()
        
        profilePic.imageView?.contentMode = .scaleAspectFill
        profilePic.imageView?.frame = profilePicButton.bounds
        profilePic.imageView?.clipsToBounds = true
        profilePic.clipsToBounds = true

        profilePic.addTarget(self, action: #selector(showCamera), for: .touchUpInside)
        profilePicButton.addTarget(self, action: #selector(showCamera), for: .touchUpInside)
    }
}
