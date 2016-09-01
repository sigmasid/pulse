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
    private var _loaded = false
    private var _reuseIdentifier = "activityCell"
    
    weak var returnToParentDelegate : ParentDelegate!
    
    private var _headerView = UIView()
    private var _loginHeader : LoginHeaderView?
    private var _settingDescription = UILabel()
    private var _settingSection = UIView()
    
    private lazy var _shortTextField = UITextField()
    private lazy var _longTextField = UITextView()
    private lazy var _birthdayPicker = UIDatePicker()
    private lazy var settingsTable = UITableView()
    private lazy var _entries = [String]()
    private lazy var _statusLabel = UILabel()
    
    private var updateButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        settingsTable.registerClass(UITableViewCell.self, forCellReuseIdentifier: _reuseIdentifier)

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
    
    private func addHeader(appTitle appTitle : String, screenTitle : String) {
        view.addSubview(_headerView)
        
        _headerView.translatesAutoresizingMaskIntoConstraints = false
        _headerView.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: Spacing.xs.rawValue).active = true
        _headerView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        _headerView.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 1/12).active = true
        _headerView.widthAnchor.constraintEqualToAnchor(view.widthAnchor).active = true
        _headerView.layoutIfNeeded()
        
        _loginHeader = LoginHeaderView(frame: _headerView.frame)
        if let _loginHeader = _loginHeader {
            _loginHeader.setAppTitleLabel(appTitle)
            _loginHeader.setScreenTitleLabel(screenTitle)
            _loginHeader.updateStatusMessage(_currentSetting.display?.uppercaseString)
            _loginHeader.addGoBack()
            _loginHeader._goBack.addTarget(self, action: #selector(goBack), forControlEvents: UIControlEvents.TouchUpInside)
            
            _headerView.addSubview(_loginHeader)
        }
    }
    
    private func addSettingDescription() {
        view.addSubview(_settingDescription)
        
        _settingDescription.translatesAutoresizingMaskIntoConstraints = false
        _settingDescription.topAnchor.constraintEqualToAnchor(_headerView.bottomAnchor, constant: Spacing.l.rawValue).active = true
        _settingDescription.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        _settingDescription.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 1/10).active = true
        _settingDescription.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.8).active = true
        
        _settingDescription.text = _currentSetting.longDescription
        _settingDescription.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        _settingDescription.numberOfLines = 0
        _settingDescription.textColor = .whiteColor()
        _settingDescription.textAlignment = .Center
    }
    
    private func addSettingSection() {
        view.addSubview(_settingSection)
        
        _settingSection.translatesAutoresizingMaskIntoConstraints = false
        _settingSection.topAnchor.constraintEqualToAnchor(_settingDescription.bottomAnchor, constant: Spacing.l.rawValue).active = true
        _settingSection.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        let widthConstraint = _settingSection.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.7)
        widthConstraint.active = true
        
        switch _currentSetting.type! {
        case .array:
            widthConstraint.active = false
            _settingSection.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.9).active = true
            _settingSection.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
            _settingSection.layoutIfNeeded()
            addTableView(CGRectMake(0, 0, _settingSection.frame.width, _settingSection.frame.height))
        case .bio, .shortBio:
            _settingSection.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 1/8).active = true
            _settingSection.layoutIfNeeded()
            showBioUpdateView(CGRectMake(0, 0, _settingSection.frame.width, _settingSection.frame.height))
            if _currentSetting.editable {
                addUpdateButton()
                updateButton.addTarget(self, action: #selector(updateProfile), forControlEvents: UIControlEvents.TouchUpInside)
            }
        case .email:
            _settingSection.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 1/16).active = true
            _settingSection.layoutIfNeeded()
            showNameUpdateView(CGRectMake(0, 0, _settingSection.frame.width, _settingSection.frame.height))
            if _currentSetting.editable {
                addUpdateButton()
                updateButton.addTarget(self, action: #selector(updateProfile), forControlEvents: UIControlEvents.TouchUpInside)
            }
        case .gender, .name, .password:
            _settingSection.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 1/16).active = true
            _settingSection.layoutIfNeeded()
            showNameUpdateView(CGRectMake(0, 0, _settingSection.frame.width, _settingSection.frame.height))
            if _currentSetting.editable {
                addUpdateButton()
                updateButton.addTarget(self, action: #selector(updateProfile), forControlEvents: UIControlEvents.TouchUpInside)
            }
        case .birthday:
            _settingSection.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 1/16).active = true
            _settingSection.layoutIfNeeded()
            showBirthdayUpdateView(CGRectMake(0, 0, _settingSection.frame.width, _settingSection.frame.height))
            if _currentSetting.editable {
                addUpdateButton()
                updateButton.addTarget(self, action: #selector(updateProfile), forControlEvents: UIControlEvents.TouchUpInside)
            }
        default:
            return
        }
    }
    
    private func addTableView(_frame: CGRect) {
        settingsTable.frame = _frame
        _settingSection.addSubview(settingsTable)
        
        settingsTable.backgroundView = nil
        settingsTable.backgroundColor = UIColor.clearColor()
        settingsTable.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        settingsTable.separatorColor = UIColor.grayColor().colorWithAlphaComponent(0.7)
        
        settingsTable.showsVerticalScrollIndicator = false
        settingsTable.layoutIfNeeded()
        settingsTable.tableFooterView = UIView()
        
        settingsTable.delegate = self
        settingsTable.dataSource = self
        settingsTable.reloadData()
    }
    
    private func showNameUpdateView(_frame: CGRect) {
        _shortTextField = UITextField(frame: CGRectMake(0, 0, _settingSection.frame.width, _settingSection.frame.height))
        _settingSection.addSubview(_shortTextField)
        
        _shortTextField.borderStyle = .None
        _shortTextField.backgroundColor = UIColor.clearColor()
        _shortTextField.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        _shortTextField.textColor = .whiteColor()
        _shortTextField.layer.addSublayer(GlobalFunctions.addBorders(self._shortTextField, _color: UIColor.whiteColor(), thickness: IconThickness.Thin.rawValue))
        _shortTextField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        _shortTextField.attributedPlaceholder = NSAttributedString(string: getValueOrPlaceholder(), attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
        
        if _currentSetting.type == .password {
            _shortTextField.secureTextEntry = true
        } else if _currentSetting.type == .email {
            _shortTextField.keyboardType = UIKeyboardType.EmailAddress
        }
    }
    
    private func showBioUpdateView(_frame: CGRect) {
        _longTextField = UITextView(frame: CGRectMake(0, 0, _settingSection.frame.width, _settingSection.frame.height))
        _settingSection.addSubview(_longTextField)
        
        _longTextField.backgroundColor = UIColor.clearColor()
        _longTextField.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        _longTextField.textColor = .whiteColor()
        _longTextField.layer.borderColor = UIColor.whiteColor().CGColor
        _longTextField.layer.borderWidth = 1.0
        _longTextField.text = getValueOrPlaceholder()
    }
    
    private func showBirthdayUpdateView(_frame: CGRect) {
        _shortTextField = UITextField(frame: CGRectMake(0, 0, _settingSection.frame.width, _settingSection.frame.height))
        _settingSection.addSubview(_shortTextField)
        
        _birthdayPicker.datePickerMode = .Date
        _birthdayPicker.minimumDate = NSCalendar.currentCalendar().dateByAddingUnit(.Year, value: -100, toDate: NSDate(), options: [])
        _birthdayPicker.maximumDate = NSDate()
        _birthdayPicker.addTarget(self, action: #selector(onDatePickerValueChanged), forControlEvents: UIControlEvents.ValueChanged)
        
        _shortTextField.borderStyle = .None
        _shortTextField.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        _shortTextField.textColor = .whiteColor()
        _shortTextField.layer.addSublayer(GlobalFunctions.addBorders(self._shortTextField, _color: UIColor.whiteColor(), thickness: IconThickness.Thin.rawValue))
        _shortTextField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        
        _shortTextField.attributedPlaceholder = NSAttributedString(string: getValueOrPlaceholder(), attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.7)])
        _shortTextField.inputView = _birthdayPicker
    }
    
    private func addUpdateButton() {
        view.addSubview(updateButton)
        
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        updateButton.topAnchor.constraintEqualToAnchor(_settingSection.bottomAnchor, constant: Spacing.l.rawValue).active = true
        updateButton.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        updateButton.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 1/16).active = true
        updateButton.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.7).active = true
        
        updateButton.layer.cornerRadius = buttonCornerRadius.radius(.regular)
        updateButton.setTitle("Save", forState: UIControlState.Normal)
        updateButton.titleLabel!.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        updateButton.setEnabled()
    }
    
    private func addStatusLabel() {
        view.addSubview(_statusLabel)
        
        _statusLabel.translatesAutoresizingMaskIntoConstraints = false
        _statusLabel.topAnchor.constraintEqualToAnchor(updateButton.bottomAnchor, constant: Spacing.xs.rawValue).active = true
        _statusLabel.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        _statusLabel.widthAnchor.constraintEqualToAnchor(updateButton.widthAnchor, multiplier: 0.7).active = true
        
        _statusLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        _statusLabel.textAlignment = .Center
        _statusLabel.textColor = UIColor.whiteColor()
        _statusLabel.numberOfLines = 0
    }

    private func getValueOrPlaceholder() -> String {
        if let _existingValue = User.currentUser?.getValueForStringProperty(_currentSetting.type!.rawValue) {
            if _currentSetting.type == .birthday {
                let formatter = NSDateFormatter()
                formatter.dateStyle = NSDateFormatterStyle.MediumStyle
                if let _placeholderDate = formatter.dateFromString(_existingValue) {
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
    
    private func getValueOrPlaceholder(indexRow : Int, cell : UITableViewCell) {
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
            Database.updateUserProfile(_currentSetting, newValue: _bio, completion: {(success, error) in
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
    
    func onDatePickerValueChanged(datePicker : UIDatePicker) {
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        
        _shortTextField.text = formatter.stringFromDate(datePicker.date)
    }
    
    func goBack() {
        if returnToParentDelegate != nil {
            returnToParentDelegate.returnToParent(self)
        }
    }
    
}

extension UpdateProfileVC : UITableViewDelegate, UITableViewDataSource {

    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch _currentSetting.settingID {
        case "answers":
            return User.currentUser!.answers?.count ?? 0
        case "savedQuestions":
            return User.currentUser!.savedQuestions.count ?? 0
        case "savedTags":
            return User.currentUser!.savedTags.count ?? 0
        default: return 0
        }
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(_reuseIdentifier)! as UITableViewCell
        
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.textLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        getValueOrPlaceholder(indexPath.row, cell : cell)
        
        return cell
    }
}
