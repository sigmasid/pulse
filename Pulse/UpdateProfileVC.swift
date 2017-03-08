//
//  UpdateProfileVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import CoreLocation

class UpdateProfileVC: PulseVC, CLLocationManagerDelegate {
    
    var _currentSetting : Setting! //set by delegate
    fileprivate var isLoaded = false
    
    fileprivate var settingDescription = UILabel()
    fileprivate var settingSection = UIView()
    
    fileprivate lazy var shortTextField = UITextField()
    fileprivate lazy var longTextField = UITextView()
    fileprivate lazy var birthdayPicker = UIDatePicker()
    fileprivate lazy var genderPicker = UIPickerView()
    fileprivate lazy var settingsTable = UITableView()
    fileprivate lazy var options = [String]()
    fileprivate lazy var statusLabel = UILabel()
    fileprivate lazy var locationManager = CLLocationManager()
    fileprivate var location : CLLocation?
    
    fileprivate var updateButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isLoaded {
            settingsTable.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
            
            tabBarHidden = true
            hideKeyboardWhenTappedAround()
            addSettingDescription()
            addSettingSection()

            isLoaded = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeader()
    }
    
    fileprivate func updateHeader() {
        addBackButton()
        headerNav?.setNav(title: "Update Profile")
    }
    
    fileprivate func addSettingDescription() {
        view.addSubview(settingDescription)
        
        settingDescription.translatesAutoresizingMaskIntoConstraints = false
        settingDescription.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: Spacing.m.rawValue).isActive = true
        settingDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        settingDescription.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/10).isActive = true
        settingDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        
        settingDescription.text = _currentSetting.longDescription
        settingDescription.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        settingDescription.numberOfLines = 0
        settingDescription.textColor = UIColor.black
        settingDescription.textAlignment = .center
    }
    
    fileprivate func addSettingSection() {
        view.addSubview(settingSection)
        
        settingSection.translatesAutoresizingMaskIntoConstraints = false
        settingSection.topAnchor.constraint(equalTo: settingDescription.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        settingSection.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        let widthConstraint = settingSection.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
        widthConstraint.isActive = true
        
        switch _currentSetting.type! {
        case .array:
            widthConstraint.isActive = false
            settingSection.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
            settingSection.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            settingSection.layoutIfNeeded()
            addTableView(CGRect(x: 0, y: 0, width: settingSection.frame.width, height: settingSection.frame.height))
        case .bio, .shortBio:
            settingSection.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/8).isActive = true
            settingSection.layoutIfNeeded()
            showBioUpdateView(CGRect(x: 0, y: 0, width: settingSection.frame.width, height: settingSection.frame.height))
        case .email:
            settingSection.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
            settingSection.layoutIfNeeded()
            showNameUpdateView(CGRect(x: 0, y: 0, width: settingSection.frame.width, height: settingSection.frame.height))
        case .name, .password:
            settingSection.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
            settingSection.layoutIfNeeded()
            showNameUpdateView(CGRect(x: 0, y: 0, width: settingSection.frame.width, height: settingSection.frame.height))
        case .gender:
            settingSection.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
            settingSection.layoutIfNeeded()
            showGenderUpdateView(CGRect(x: 0, y: 0, width: settingSection.frame.width, height: settingSection.frame.height))
        case .birthday:
            settingSection.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
            settingSection.layoutIfNeeded()
            showBirthdayUpdateView(CGRect(x: 0, y: 0, width: settingSection.frame.width, height: settingSection.frame.height))
        case .location:
            settingSection.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
            settingSection.layoutIfNeeded()
            showLocationUpdateView(CGRect(x: 0, y: 0, width: settingSection.frame.width, height: settingSection.frame.height))
        default:
            return
        }
        
        if _currentSetting.editable {
            addUpdateButton()
            updateButton.addTarget(self, action: #selector(updateProfile), for: UIControlEvents.touchUpInside)
        }
    }
    
    fileprivate func addTableView(_ _frame: CGRect) {
        settingsTable.frame = _frame
        settingSection.addSubview(settingsTable)
        
        settingsTable.backgroundView = nil
        settingsTable.backgroundColor = UIColor.clear
        settingsTable.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        settingsTable.separatorColor = UIColor.gray.withAlphaComponent(0.7)
        
        settingsTable.showsVerticalScrollIndicator = false
        settingsTable.layoutIfNeeded()
        settingsTable.tableFooterView = UIView()
        
        settingsTable.delegate = self
        settingsTable.dataSource = self
        settingsTable.reloadData()
    }
    
    fileprivate func showNameUpdateView(_ _frame: CGRect) {
        shortTextField = UITextField(frame: CGRect(x: 0, y: 0, width: settingSection.frame.width, height: settingSection.frame.height))
        settingSection.addSubview(shortTextField)
        
        shortTextField.borderStyle = .none
        shortTextField.backgroundColor = UIColor.clear
        shortTextField.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        shortTextField.textColor = UIColor.black
        shortTextField.layer.addSublayer(GlobalFunctions.addBorders(self.shortTextField, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        shortTextField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        shortTextField.attributedPlaceholder = NSAttributedString(string: getValueOrPlaceholder(), attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        
        if _currentSetting.type == .password {
            shortTextField.isSecureTextEntry = true
        } else if _currentSetting.type == .email {
            shortTextField.keyboardType = UIKeyboardType.emailAddress
        }
    }
    
    fileprivate func showBioUpdateView(_ _frame: CGRect) {
        longTextField = UITextView(frame: CGRect(x: 0, y: 0, width: settingSection.frame.width, height: settingSection.frame.height))
        settingSection.addSubview(longTextField)
        
        longTextField.backgroundColor = UIColor.clear
        longTextField.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        longTextField.textColor = UIColor.black
        longTextField.layer.borderColor = UIColor.black.cgColor
        longTextField.layer.borderWidth = 1.0
        longTextField.text = getValueOrPlaceholder()
    }
    
    fileprivate func showGenderUpdateView(_ _frame : CGRect) {
        shortTextField = UITextField(frame: CGRect(x: 0, y: 0, width: settingSection.frame.width, height: settingSection.frame.height))
        settingSection.addSubview(shortTextField)
        
        shortTextField.borderStyle = .none
        shortTextField.backgroundColor = UIColor.clear
        shortTextField.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        shortTextField.textColor = UIColor.black
        shortTextField.layer.addSublayer(GlobalFunctions.addBorders(self.shortTextField, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        shortTextField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        shortTextField.attributedPlaceholder = NSAttributedString(string: getValueOrPlaceholder(), attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        shortTextField.inputView = genderPicker

        genderPicker.dataSource = self
        genderPicker.delegate = self
        genderPicker.backgroundColor = .clear
    }
    
    fileprivate func showLocationUpdateView(_ _frame : CGRect) {
        shortTextField = UITextField(frame: CGRect(x: 0, y: 0, width: settingSection.frame.width, height: settingSection.frame.height))
        settingSection.addSubview(shortTextField)
        
        shortTextField.borderStyle = .none
        shortTextField.backgroundColor = UIColor.clear
        shortTextField.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        shortTextField.textColor = UIColor.black
        shortTextField.layer.addSublayer(GlobalFunctions.addBorders(self.shortTextField, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        shortTextField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        getLocationOrPlaceholder()
        
        setupLocation()
    }
    
    fileprivate func showBirthdayUpdateView(_ _frame: CGRect) {
        shortTextField = UITextField(frame: CGRect(x: 0, y: 0, width: settingSection.frame.width, height: settingSection.frame.height))
        settingSection.addSubview(shortTextField)
        
        birthdayPicker.datePickerMode = .date
        birthdayPicker.minimumDate = (Calendar.current as NSCalendar).date(byAdding: .year, value: -100, to: Date(), options: [])
        birthdayPicker.maximumDate = Date()
        birthdayPicker.addTarget(self, action: #selector(onDatePickerValueChanged), for: UIControlEvents.valueChanged)
        birthdayPicker.backgroundColor = .clear

        shortTextField.borderStyle = .none
        shortTextField.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        shortTextField.textColor = UIColor.black
        shortTextField.layer.addSublayer(GlobalFunctions.addBorders(self.shortTextField, _color: UIColor.black, thickness: IconThickness.thin.rawValue))
        shortTextField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        
        shortTextField.attributedPlaceholder = NSAttributedString(string: getValueOrPlaceholder(), attributes: [NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.7)])
        shortTextField.inputView = birthdayPicker
    }
    
    fileprivate func addUpdateButton() {
        view.addSubview(updateButton)
        
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        updateButton.topAnchor.constraint(equalTo: settingSection.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        updateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        updateButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        updateButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        
        updateButton.layer.cornerRadius = buttonCornerRadius.radius(.regular)
        updateButton.setTitle("Save", for: UIControlState())
        updateButton.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        updateButton.setEnabled()
    }
    
    fileprivate func addStatusLabel() {
        view.addSubview(statusLabel)
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.topAnchor.constraint(equalTo: updateButton.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        statusLabel.widthAnchor.constraint(equalTo: updateButton.widthAnchor, multiplier: 0.7).isActive = true
        
        statusLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        statusLabel.textAlignment = .center
        statusLabel.textColor = UIColor.black
        statusLabel.numberOfLines = 0
    }

    fileprivate func getValueOrPlaceholder() -> String {
        if let _existingValue = User.currentUser?.getValueForStringProperty(_currentSetting.type!.rawValue) {
            if _currentSetting.type == .birthday {
                let formatter = DateFormatter()
                formatter.dateStyle = DateFormatter.Style.medium
                if let placeholderDate = formatter.date(from: _existingValue) {
                    birthdayPicker.date = placeholderDate
                }
            }
            return _existingValue
        } else if let _placeholder = _currentSetting.placeholder {
            return _placeholder
        } else {
            return ""
        }
    }
    
    fileprivate func getLocationOrPlaceholder() {
        User.currentUser?.getLocation(completion: {(city) in
            if let city = city {
                self.shortTextField.text = city
            } else if let _placeholder = self._currentSetting.placeholder {
                self.shortTextField.text = _placeholder
                self.setupLocation()
            } else {
                self.shortTextField.text = nil
            }
        })
    }
    
    /* Location vars */
    /// setup the location tracking defaults
    func setupLocation() {
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 100.0
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        GlobalFunctions.showErrorBlock("Location Error", erMessage: "Error while updating location " + error.localizedDescription)
    }
    
    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler: {(placemarks, error)-> Void in
            if (error != nil) {
                return
            }
            if let _location = manager.location {
                self.location = _location
            }
            
            if let allPlacemarks = placemarks {
                if allPlacemarks.count != 0 {
                    let pm = allPlacemarks[0] as CLPlacemark
                    self.locationManager.stopUpdatingLocation()
                    self.shortTextField.text = pm.locality
                }
            } else {
                self.shortTextField.text = nil
                GlobalFunctions.showErrorBlock("Location Error", erMessage: "Sorry - there was an error getting your location!")
            }
        })
    }
    
    func updateProfile() {
        updateButton.setDisabled()
        let _loading = updateButton.addLoadingIndicator()
        
        switch _currentSetting.type! {
        case .birthday:
            let _birthday = shortTextField.text
            addStatusLabel()
            Database.updateUserProfile(_currentSetting, newValue: _birthday!, completion: {(success, error) in
                if success {
                    self.statusLabel.text = "Profile Updated!"
                    self.goBack()
                } else {
                    self.statusLabel.text = error?.localizedDescription
                }
                self.updateButton.setEnabled()
                self.updateButton.removeLoadingIndicator(_loading)
            })
        case .bio, .shortBio:
            let _bio = longTextField.text
            addStatusLabel()
            Database.updateUserProfile(_currentSetting, newValue: _bio!, completion: {(success, error) in
                if success {
                    self.statusLabel.text = "Profile Updated!"
                    self.goBack()
                } else {
                    self.statusLabel.text = error?.localizedDescription
                }
                self.updateButton.setEnabled()
                self.updateButton.removeLoadingIndicator(_loading)
            })
        case .name:
            let _name = shortTextField.text
            addStatusLabel()

            GlobalFunctions.validateName(_name, completion: {(verified, error) in
                if !verified {
                    self.statusLabel.text = error?.localizedDescription
                } else {
                    Database.updateUserData(UserProfileUpdateType.displayName, value: _name!, completion: { (success, error) in
                        if success {
                            self.statusLabel.text = "Profile Updated!"
                            self.goBack()
                        } else {
                            self.statusLabel.text = error?.localizedDescription
                        }
                    })
                }
                self.updateButton.setEnabled()
                self.updateButton.removeLoadingIndicator(_loading)
            })
        case .email:
            let _email = shortTextField.text
            addStatusLabel()
            
            GlobalFunctions.validateEmail(_email, completion: {(verified, error) in
                if !verified {
                    self.statusLabel.text = error?.localizedDescription
                } else {
                    Database.updateUserProfile(self._currentSetting, newValue: _email!, completion: {(success, error) in
                        if success {
                            self.statusLabel.text = "Profile Updated!"
                            self.goBack()
                        } else {
                            self.statusLabel.text = error?.localizedDescription
                        }
                    })
                }
                self.updateButton.setEnabled()
                self.updateButton.removeLoadingIndicator(_loading)
            })
        case .password:
            let _password = shortTextField.text
            addStatusLabel()
            
            GlobalFunctions.validatePassword(_password, completion: {(verified, error) in
                if !verified {
                    self.statusLabel.text = error?.localizedDescription
                } else {
                    Database.updateUserProfile(self._currentSetting, newValue: _password!, completion: {(success, error) in
                        if success {
                            self.statusLabel.text = "Profile Updated!"
                            self.goBack()
                        } else {
                            self.statusLabel.text = error?.localizedDescription
                        }
                    })
                }
                self.updateButton.setEnabled()
                self.updateButton.removeLoadingIndicator(_loading)
            })
            
        case .gender:
            let _gender = shortTextField.text
            addStatusLabel()
            
            Database.updateUserProfile(self._currentSetting, newValue: _gender!, completion: {(success, error) in
                if success {
                    self.statusLabel.text = "Profile Updated!"
                    self.goBack()
                } else {
                    self.statusLabel.text = error?.localizedDescription
                }
                self.updateButton.setEnabled()
                self.updateButton.removeLoadingIndicator(_loading)

            })
            
        case .location:
            if let location = location {
                Database.updateUserLocation(newValue: location, completion: {(success, error) in
                    if success {
                        self.statusLabel.text = "Profile Updated!"
                        self.goBack()
                    } else {
                        self.statusLabel.text = error?.localizedDescription
                    }
                    
                    self.updateButton.setEnabled()
                    self.updateButton.removeLoadingIndicator(_loading)
                })
            }
            else if let _location = shortTextField.text {
                addStatusLabel()
                
                Database.updateUserProfile(self._currentSetting, newValue: _location, completion: {(success, error) in
                    if success {
                        self.statusLabel.text = "Profile Updated!"
                        self.goBack()
                    } else {
                        self.statusLabel.text = error?.localizedDescription
                    }
                    
                    self.updateButton.setEnabled()
                    self.updateButton.removeLoadingIndicator(_loading)
                })
            }
        default:
            updateButton.setEnabled()
            updateButton.removeLoadingIndicator(_loading)
            return
        }
    }
    
    func onDatePickerValueChanged(_ datePicker : UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.medium
        
        shortTextField.text = formatter.string(from: datePicker.date)
    }
}

extension UpdateProfileVC : UIPickerViewDataSource, UIPickerViewDelegate {
    //MARK: Data Sources
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {
        return _currentSetting.options != nil ? _currentSetting.options!.count : 0
    }
    
    //MARK: Delegates
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return _currentSetting.options?[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        shortTextField.text = _currentSetting.options?[row]
    }
}

extension UpdateProfileVC : UITableViewDelegate, UITableViewDataSource {

    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch _currentSetting.settingID {
        case "items":
            return User.currentUser!.items.count
        case "savedItems":
            return User.currentUser!.savedItems.count
        case "subscriptions":
            return User.currentUser!.subscriptions.count
        default: return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)! as UITableViewCell
        
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.textColor = UIColor.black
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
//        getValueOrPlaceholder((indexPath as NSIndexPath).row, cell : cell)
        
        return cell
    }
}
