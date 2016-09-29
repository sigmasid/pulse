//
//  UpdateProfileVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class UpdateProfileVC: UIViewController {
    
    var _currentSetting : Setting! //set by delegate
    fileprivate var _loaded = false
    fileprivate var _reuseIdentifier = "activityCell"
    
    weak var returnToParentDelegate : ParentDelegate!
    
    fileprivate var _headerView = UIView()
    fileprivate var _loginHeader : LoginHeaderView?
    fileprivate var _settingDescription = UILabel()
    fileprivate var _settingSection = UIView()
    
    fileprivate lazy var _shortTextField = UITextField()
    fileprivate lazy var _longTextField = UITextView()
    fileprivate lazy var _birthdayPicker = UIDatePicker()
    fileprivate lazy var settingsTable = UITableView()
    fileprivate lazy var _entries = [String]()
    fileprivate lazy var _statusLabel = UILabel()
    
    fileprivate var updateButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        settingsTable.register(UITableViewCell.self, forCellReuseIdentifier: _reuseIdentifier)

        if !_loaded {
            setDarkBackground()
            hideKeyboardWhenTappedAround()
            addHeader(appTitle: "PULSE", screenTitle: "PROFILE")
            addSettingDescription()
            addSettingSection()

            _loaded = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func addHeader(appTitle : String, screenTitle : String) {
        view.addSubview(_headerView)
        
        _headerView.translatesAutoresizingMaskIntoConstraints = false
        _headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: Spacing.xs.rawValue).isActive = true
        _headerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        _headerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/12).isActive = true
        _headerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        _headerView.layoutIfNeeded()
        
        _loginHeader = LoginHeaderView(frame: _headerView.frame)
        if let _loginHeader = _loginHeader {
            _loginHeader.setAppTitleLabel(_message: appTitle)
            _loginHeader.setScreenTitleLabel(_message: screenTitle)
            _loginHeader.updateStatusMessage(_message: _currentSetting.display?.uppercased())
            _loginHeader.addGoBack()
            _loginHeader._goBack.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
            
            _headerView.addSubview(_loginHeader)
        }
    }
    
    fileprivate func addSettingDescription() {
        view.addSubview(_settingDescription)
        
        _settingDescription.translatesAutoresizingMaskIntoConstraints = false
        _settingDescription.topAnchor.constraint(equalTo: _headerView.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        _settingDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        _settingDescription.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/10).isActive = true
        _settingDescription.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        
        _settingDescription.text = _currentSetting.longDescription
        _settingDescription.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        _settingDescription.numberOfLines = 0
        _settingDescription.textColor = UIColor.white
        _settingDescription.textAlignment = .center
    }
    
    fileprivate func addSettingSection() {
        view.addSubview(_settingSection)
        
        _settingSection.translatesAutoresizingMaskIntoConstraints = false
        _settingSection.topAnchor.constraint(equalTo: _settingDescription.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        _settingSection.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        let widthConstraint = _settingSection.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
        widthConstraint.isActive = true
        
        switch _currentSetting.type! {
        case .array:
            widthConstraint.isActive = false
            _settingSection.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
            _settingSection.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            _settingSection.layoutIfNeeded()
            addTableView(CGRect(x: 0, y: 0, width: _settingSection.frame.width, height: _settingSection.frame.height))
        case .bio, .shortBio:
            _settingSection.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/8).isActive = true
            _settingSection.layoutIfNeeded()
            showBioUpdateView(CGRect(x: 0, y: 0, width: _settingSection.frame.width, height: _settingSection.frame.height))
            if _currentSetting.editable {
                addUpdateButton()
                updateButton.addTarget(self, action: #selector(updateProfile), for: UIControlEvents.touchUpInside)
            }
        case .email:
            _settingSection.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
            _settingSection.layoutIfNeeded()
            showNameUpdateView(CGRect(x: 0, y: 0, width: _settingSection.frame.width, height: _settingSection.frame.height))
            if _currentSetting.editable {
                addUpdateButton()
                updateButton.addTarget(self, action: #selector(updateProfile), for: UIControlEvents.touchUpInside)
            }
        case .gender, .name, .password:
            _settingSection.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
            _settingSection.layoutIfNeeded()
            showNameUpdateView(CGRect(x: 0, y: 0, width: _settingSection.frame.width, height: _settingSection.frame.height))
            if _currentSetting.editable {
                addUpdateButton()
                updateButton.addTarget(self, action: #selector(updateProfile), for: UIControlEvents.touchUpInside)
            }
        case .birthday:
            _settingSection.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
            _settingSection.layoutIfNeeded()
            showBirthdayUpdateView(CGRect(x: 0, y: 0, width: _settingSection.frame.width, height: _settingSection.frame.height))
            if _currentSetting.editable {
                addUpdateButton()
                updateButton.addTarget(self, action: #selector(updateProfile), for: UIControlEvents.touchUpInside)
            }
        default:
            return
        }
    }
    
    fileprivate func addTableView(_ _frame: CGRect) {
        settingsTable.frame = _frame
        _settingSection.addSubview(settingsTable)
        
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
        _shortTextField = UITextField(frame: CGRect(x: 0, y: 0, width: _settingSection.frame.width, height: _settingSection.frame.height))
        _settingSection.addSubview(_shortTextField)
        
        _shortTextField.borderStyle = .none
        _shortTextField.backgroundColor = UIColor.clear
        _shortTextField.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        _shortTextField.textColor = UIColor.white
        _shortTextField.layer.addSublayer(GlobalFunctions.addBorders(self._shortTextField, _color: UIColor.white, thickness: IconThickness.thin.rawValue))
        _shortTextField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        _shortTextField.attributedPlaceholder = NSAttributedString(string: getValueOrPlaceholder(), attributes: [NSForegroundColorAttributeName: UIColor.white.withAlphaComponent(0.7)])
        
        if _currentSetting.type == .password {
            _shortTextField.isSecureTextEntry = true
        } else if _currentSetting.type == .email {
            _shortTextField.keyboardType = UIKeyboardType.emailAddress
        }
    }
    
    fileprivate func showBioUpdateView(_ _frame: CGRect) {
        _longTextField = UITextView(frame: CGRect(x: 0, y: 0, width: _settingSection.frame.width, height: _settingSection.frame.height))
        _settingSection.addSubview(_longTextField)
        
        _longTextField.backgroundColor = UIColor.clear
        _longTextField.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        _longTextField.textColor = UIColor.white
        _longTextField.layer.borderColor = UIColor.white.cgColor
        _longTextField.layer.borderWidth = 1.0
        _longTextField.text = getValueOrPlaceholder()
    }
    
    fileprivate func showBirthdayUpdateView(_ _frame: CGRect) {
        _shortTextField = UITextField(frame: CGRect(x: 0, y: 0, width: _settingSection.frame.width, height: _settingSection.frame.height))
        _settingSection.addSubview(_shortTextField)
        
        _birthdayPicker.datePickerMode = .date
        _birthdayPicker.minimumDate = (Calendar.current as NSCalendar).date(byAdding: .year, value: -100, to: Date(), options: [])
        _birthdayPicker.maximumDate = Date()
        _birthdayPicker.addTarget(self, action: #selector(onDatePickerValueChanged), for: UIControlEvents.valueChanged)
        
        _shortTextField.borderStyle = .none
        _shortTextField.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        _shortTextField.textColor = UIColor.white
        _shortTextField.layer.addSublayer(GlobalFunctions.addBorders(self._shortTextField, _color: UIColor.white, thickness: IconThickness.thin.rawValue))
        _shortTextField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        
        _shortTextField.attributedPlaceholder = NSAttributedString(string: getValueOrPlaceholder(), attributes: [NSForegroundColorAttributeName: UIColor.white.withAlphaComponent(0.7)])
        _shortTextField.inputView = _birthdayPicker
    }
    
    fileprivate func addUpdateButton() {
        view.addSubview(updateButton)
        
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        updateButton.topAnchor.constraint(equalTo: _settingSection.bottomAnchor, constant: Spacing.l.rawValue).isActive = true
        updateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        updateButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/16).isActive = true
        updateButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        
        updateButton.layer.cornerRadius = buttonCornerRadius.radius(.regular)
        updateButton.setTitle("Save", for: UIControlState())
        updateButton.titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        updateButton.setEnabled()
    }
    
    fileprivate func addStatusLabel() {
        view.addSubview(_statusLabel)
        
        _statusLabel.translatesAutoresizingMaskIntoConstraints = false
        _statusLabel.topAnchor.constraint(equalTo: updateButton.bottomAnchor, constant: Spacing.xs.rawValue).isActive = true
        _statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        _statusLabel.widthAnchor.constraint(equalTo: updateButton.widthAnchor, multiplier: 0.7).isActive = true
        
        _statusLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        _statusLabel.textAlignment = .center
        _statusLabel.textColor = UIColor.white
        _statusLabel.numberOfLines = 0
    }

    fileprivate func getValueOrPlaceholder() -> String {
        if let _existingValue = User.currentUser?.getValueForStringProperty(_currentSetting.type!.rawValue) {
            if _currentSetting.type == .birthday {
                let formatter = DateFormatter()
                formatter.dateStyle = DateFormatter.Style.medium
                if let _placeholderDate = formatter.date(from: _existingValue) {
                    _birthdayPicker.date = _placeholderDate
                }
            }
            return _existingValue
        } else if let _placeholder = _currentSetting.placeholder {
            return _placeholder
        } else {
            return ""
        }
    }
    
    fileprivate func getValueOrPlaceholder(_ indexRow : Int, cell : UITableViewCell) {
        switch _currentSetting.settingID {
        case "answers":
            cell.textLabel!.text = nil
        case "savedQuestions": return
//            Database.getQuestion(User.currentUser!.savedQuestions![indexRow], completion: {(question, error) in
//                if error != nil {
//                    cell.textLabel!.text  = nil
//                } else {
//                    cell.textLabel!.text = question.qTitle
//                }
//            })
        case "savedTags": return
//            Database.getTag(User.currentUser!.savedTags![indexRow], completion: {(tag, error) in
//                if error != nil {
//                    cell.textLabel!.text = nil
//                } else {
//                    cell.textLabel!.text = tag.tagID
//                }
//            })
        default: return
        }
    }

    func updateProfile() {
        updateButton.setDisabled()
        let _loading = updateButton.addLoadingIndicator()
        
        switch _currentSetting.type! {
        case .birthday:
            let _birthday = _shortTextField.text
            addStatusLabel()
            Database.updateUserProfile(_currentSetting, newValue: _birthday!, completion: {(success, error) in
                if success {
                    self._statusLabel.text = "Profile Updated!"
                } else {
                    self._statusLabel.text = error?.localizedDescription
                }
                self.updateButton.setEnabled()
                self.updateButton.removeLoadingIndicator(_loading)
            })
        case .bio, .shortBio:
            let _bio = _longTextField.text
            addStatusLabel()
            Database.updateUserProfile(_currentSetting, newValue: _bio!, completion: {(success, error) in
                if success {
                    self._statusLabel.text = "Profile Updated!"
                } else {
                    self._statusLabel.text = error?.localizedDescription
                }
                self.updateButton.setEnabled()
                self.updateButton.removeLoadingIndicator(_loading)
            })
        case .name:
            let _name = _shortTextField.text
            addStatusLabel()

            GlobalFunctions.validateName(_name, completion: {(verified, error) in
                if !verified {
                    self._statusLabel.text = error?.localizedDescription
                } else {
                    Database.updateUserData(UserProfileUpdateType.displayName, value: _name!, completion: { (success, error) in
                        if success {
                            self._statusLabel.text = "Profile Updated!"
                        } else {
                            self._statusLabel.text = error?.localizedDescription
                        }
                    })
                }
                self.updateButton.setEnabled()
                self.updateButton.removeLoadingIndicator(_loading)
            })
        case .email:
            let _email = _shortTextField.text
            addStatusLabel()
            
            GlobalFunctions.validateEmail(_email, completion: {(verified, error) in
                if !verified {
                    self._statusLabel.text = error?.localizedDescription
                } else {
                    Database.updateUserProfile(self._currentSetting, newValue: _email!, completion: {(success, error) in
                        if success {
                            self._statusLabel.text = "Profile Updated!"
                        } else {
                            self._statusLabel.text = error?.localizedDescription
                        }
                    })
                }
                self.updateButton.setEnabled()
                self.updateButton.removeLoadingIndicator(_loading)
            })
        case .password:
            let _password = _shortTextField.text
            addStatusLabel()
            
            GlobalFunctions.validatePassword(_password, completion: {(verified, error) in
                if !verified {
                    self._statusLabel.text = error?.localizedDescription
                } else {
                    Database.updateUserProfile(self._currentSetting, newValue: _password!, completion: {(success, error) in
                        if success {
                            self._statusLabel.text = "Profile Updated!"
                        } else {
                            self._statusLabel.text = error?.localizedDescription
                        }
                    })
                }
                self.updateButton.setEnabled()
                self.updateButton.removeLoadingIndicator(_loading)
            })
        default:
            updateButton.setEnabled()
            updateButton.removeLoadingIndicator(_loading)
            return
        }
    }
    
    func onDatePickerValueChanged(_ datePicker : UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.medium
        
        _shortTextField.text = formatter.string(from: datePicker.date)
    }
    
    func goBack() {
        if returnToParentDelegate != nil {
            returnToParentDelegate.returnToParent(self)
        }
    }
    
}

extension UpdateProfileVC : UITableViewDelegate, UITableViewDataSource {

    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch _currentSetting.settingID {
        case "answers":
            return User.currentUser!.answers?.count ?? 0
        case "savedQuestions":
            return User.currentUser!.savedQuestions.count
        case "savedTags":
            return User.currentUser!.savedTags.count
        default: return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: _reuseIdentifier)! as UITableViewCell
        
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        getValueOrPlaceholder((indexPath as NSIndexPath).row, cell : cell)
        
        return cell
    }
}
