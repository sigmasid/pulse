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

class SettingsTableVC: PulseVC {
    fileprivate var sections = [SettingSection]()
    fileprivate var settings = [[Setting]]()
    fileprivate var selectedSettingRow : IndexPath?
    fileprivate var settingsTable = UITableView()
    
    //Update Profile Image
    fileprivate var inputVC : InputVC!
    
    //View for Profile Image
    internal var profilePicView = UIView()
    internal var profilePicButton = UIButton()
    internal var profilePic = PulseButton(size: .large, type: .blank, isRound: true, hasBackground: false)
    
    private var cleanupComplete = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader()

        //force refresh of the selected row
        if selectedSettingRow != nil {
            settingsTable.reloadRows(at: [selectedSettingRow!], with: .fade)
            selectedSettingRow = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            headerNav?.isNavigationBarHidden = false
            tabBarHidden = true
            setupLayout()

            addUserProfilePic()
            loadSettingSections()
            
            settingsTable.register(SettingsTableCell.self, forCellReuseIdentifier: reuseIdentifier)

            isLoaded = true
        }
    }
    
    override func goBack() {
        performCleanup()
        super.goBack()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        performCleanup()
    }
    
    private func performCleanup() {
        if !cleanupComplete {
            if inputVC != nil {
                inputVC.performCleanup()
            }
            cleanupComplete = true
        }
    }
    
    fileprivate func updateHeader() {
        addBackButton()
        headerNav?.setNav(title: "Update Profile")
    }
    
    fileprivate func loadSettingSections() {
        PulseDatabase.getSettingsSections(completion: {[weak self] (sections , error) in
            guard let `self` = self else { return }
            self.sections = sections
            for _ in self.sections {
                self.settings.append([])
            }
            self.settingsTable.delegate = self
            self.settingsTable.dataSource = self
            self.settingsTable.reloadData()
        })
    }
    
    func showSettingDetail(_ selectedSetting : Setting) {
        let updateSetting = UpdateProfileVC()
        updateSetting._currentSetting = selectedSetting
        navigationController?.pushViewController(updateSetting, animated: true)
    }
    
    internal func updateHeaderImage(img : UIImage) {
        //add profile pic or use default image
        DispatchQueue.main.async {
            PulseUser.currentUser.thumbPicImage = img
            self.profilePic.setImage(img, for: .normal)
            self.profilePic.makeRound()
        }
    }
    
    internal func addUserProfilePic() {
        if let thumbPic = PulseUser.currentUser.thumbPicImage {
            profilePic.setImage(thumbPic, for: .normal)
            profilePic.makeRound()
        } else if let _userImageURL = PulseUser.currentUser.thumbPic, let url = URL(string: _userImageURL) {
            DispatchQueue.global().async {
                if let _userImageData = try? Data(contentsOf: url) {
                    PulseUser.currentUser.thumbPicImage = UIImage(data: _userImageData)
                    DispatchQueue.main.async(execute: {
                        self.profilePic.setImage(PulseUser.currentUser.thumbPicImage, for: .normal)
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
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].sectionSettingsCount
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let _sectionID = sections[section].sectionID
        return SectionTypes.getSectionDisplayName(_sectionID)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.backgroundView?.backgroundColor = .white
            header.textLabel!.setFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: .pulseBlue, alignment: .left)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let settingID = sections[(indexPath as NSIndexPath).section].settings[(indexPath as NSIndexPath).row]
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! SettingsTableCell

        if settings[(indexPath as NSIndexPath).section].count > (indexPath as NSIndexPath).row {
            let _setting = settings[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
            cell.settingNameLabel.text = _setting.display!
            if _setting.type == .location {
                PulseUser.currentUser.getLocation(completion: {(city) in
                    cell.detailLabel.text = city
                })
            }
                
            else if _setting.type != nil {
                cell.detailLabel.text = PulseUser.currentUser.getValueForStringProperty(_setting.type!.rawValue)
            }
            
            if _setting.editable {
                cell.accessoryType = .disclosureIndicator
            }
        } else {
            PulseDatabase.getSetting(settingID, completion: {[weak self] (_setting, error) in
                guard let `self` = self else { return }

                if error == nil, let _setting = _setting {
                    cell.settingNameLabel.text = _setting.display!
                    if _setting.type != nil && _setting.type != .location {
                        cell.detailLabel.text = PulseUser.currentUser.getValueForStringProperty(_setting.type!.rawValue)
                    } else if _setting.type == .location {
                        PulseUser.currentUser.getLocation(completion: { location in
                            cell.detailLabel.text = location
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

extension SettingsTableVC: InputMasterDelegate {
    /* CAMERA FUNCTIONS & DELEGATE METHODS */
    func showCamera() {
        if inputVC == nil {
            inputVC = InputVC(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            inputVC.inputDelegate = self
            inputVC.cameraMode = .stillImage
            inputVC.captureSize = .square
            inputVC.transitioningDelegate = self
            inputVC.cameraTitle = "smile!"
            inputVC.albumShowsVideo = false
        }
        
        present(inputVC, animated: true, completion: nil)
    }
    
    func capturedItem(url _: URL?, image: UIImage?, location: CLLocation?, assetType : CreatedAssetType?) {
        guard let image = image else { return }
        
        //toggleLoading(show: true, message: "saving! just a sec...")
        
        UIView.animate(withDuration: 0.2, animations: { self.inputVC.view.alpha = 0.0; self.toggleLoading(show: true, message: "saving! just a sec...") }, completion: {(value: Bool) in
            self.inputVC.view.alpha = 1.0
            self.inputVC.dismiss(animated: true, completion: nil)
        })
        
        PulseDatabase.uploadProfileImage(image, completion: {[weak self] (URL, error) in
            guard let `self` = self else { return }
            if error != nil {
                GlobalFunctions.showAlertBlock("Sorry!", erMessage: "There was an error saving the photo. Please try again")
            } else {
                self.updateHeaderImage(img: image)
                self.toggleLoading(show: false, message: nil)
            }
        })
    }
    
    func dismissInput() {
        inputVC.dismiss(animated: true, completion: nil)
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
        settingsTable.topAnchor.constraint(equalTo: profilePicView.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        settingsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        settingsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.xs.rawValue).isActive = true
        settingsTable.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        settingsTable.layoutIfNeeded()
        
        settingsTable.backgroundView = nil
        settingsTable.backgroundColor = .white
        settingsTable.separatorStyle = .singleLine
        settingsTable.separatorColor = .pulseGrey
        settingsTable.tableFooterView = UIView() //removes extra rows at bottom
        settingsTable.showsVerticalScrollIndicator = false
        
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
