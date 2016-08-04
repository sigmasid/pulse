//
//  SettingsTableVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SettingsTableVC: UIViewController, ParentDelegate {
    weak var returnToParentDelegate : ParentDelegate!

    private var _sections : [SettingSection]?
    private var _settings = [[Setting]]()
    
    private lazy var _headerView = UIView()
    private var _loginHeader : LoginHeaderView?

    private var settingsTable = UITableView()
    private let _reuseIdentifier = "SettingsTableCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingsTable.registerClass(SettingsTableCell.self, forCellReuseIdentifier: _reuseIdentifier)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        setDarkBackground()
        addHeader(appTitle: "PULSE", screenTitle: "SETTINGS")
        
        Database.getSections({ (sections , error) in
            self._sections = sections
            for _ in sections {
                self._settings.append([])
            }
            self.sectionsCreated()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func sectionsCreated() {
        view.addSubview(settingsTable)

        settingsTable.translatesAutoresizingMaskIntoConstraints = false
        settingsTable.topAnchor.constraintEqualToAnchor(_headerView.bottomAnchor, constant: Spacing.s.rawValue).active = true
        settingsTable.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        settingsTable.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor, constant: Spacing.s.rawValue).active = true
        settingsTable.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor, constant: -Spacing.s.rawValue).active = true
        
        settingsTable.backgroundView = nil
        settingsTable.backgroundColor = UIColor.clearColor()
        settingsTable.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        settingsTable.separatorColor = UIColor.grayColor().colorWithAlphaComponent(0.7)
        settingsTable.tableFooterView = UIView()
        settingsTable.showsVerticalScrollIndicator = false

        settingsTable.delegate = self
        settingsTable.dataSource = self
        settingsTable.reloadData()
    }
    
    private func addHeader(appTitle appTitle : String, screenTitle : String) {
        view.addSubview(_headerView)
        
        _headerView.translatesAutoresizingMaskIntoConstraints = false
        _headerView.topAnchor.constraintEqualToAnchor(topLayoutGuide.topAnchor, constant: Spacing.xs.rawValue).active = true
        _headerView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        _headerView.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 1/13).active = true
        _headerView.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 1 - (Spacing.m.rawValue/view.frame.width)).active = true
        _headerView.layoutIfNeeded()
        
        _loginHeader = LoginHeaderView(frame: _headerView.frame)
        if let _loginHeader = _loginHeader {
            _loginHeader.setAppTitleLabel(appTitle)
            _loginHeader.setScreenTitleLabel(screenTitle)
            _loginHeader.updateStatusMessage("PROFILE SETTINGS")

            _loginHeader.addGoBack()
            _loginHeader._goBack.addTarget(self, action: #selector(goBack), forControlEvents: UIControlEvents.TouchUpInside)
            
            _headerView.addSubview(_loginHeader)
        }
    }
    
    func goBack() {
        if returnToParentDelegate != nil {
            returnToParentDelegate.returnToParent(self)
        }
    }
    
    func showSettingDetail(selectedSetting : Setting) {
        if selectedSetting.settingID == "logout" {
            Database.signOut({ success in
                if !success {
                    GlobalFunctions.showErrorBlock("Error Logging Out", erMessage: "Sorry there was an error logging out, please try again!")
                }
            })
        } else {
            let updateSetting = UpdateProfileVC()
            updateSetting.returnToParentDelegate = self
            updateSetting._currentSetting = selectedSetting 
            GlobalFunctions.addNewVC(updateSetting, parentVC: self)
        }
    }
    
    func returnToParent(currentVC : UIViewController) {
        GlobalFunctions.dismissVC(currentVC)
    }
}

extension SettingsTableVC : UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return _sections?.count ?? 0
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _sections?[section].sectionSettingsCount ?? 0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let _sectionID = _sections![section].sectionID
        return SectionTypes.getSectionDisplayName(_sectionID)
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.backgroundView?.backgroundColor = UIColor.clearColor()
            header.textLabel!.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
            header.textLabel!.textColor = UIColor.orangeColor()
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let _settingID = _sections![indexPath.section].settings![indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(_reuseIdentifier) as! SettingsTableCell

        if _settings[indexPath.section].count > indexPath.row {
            let _setting = _settings[indexPath.section][indexPath.row]
            cell.textLabel!.text = _setting.display!
            if _setting.type != nil {
                cell._detailTextLabel.text = User.currentUser?.getValueForStringProperty(_setting.type!.rawValue)
            }
            if _setting.editable {
                cell.accessoryType = .DetailButton
            }
        } else {
            Database.getSetting(_settingID, completion: {(_setting, error) in
                cell.textLabel!.text = _setting.display!
                if _setting.type != nil {
                    cell._detailTextLabel.text = User.currentUser?.getValueForStringProperty(_setting.type!.rawValue)
                }
                self._settings[indexPath.section].append(_setting)
                if _setting.editable {
                    cell.accessoryType = .DisclosureIndicator
                }
            })
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let _setting = _settings[indexPath.section][indexPath.row]
        showSettingDetail(_setting)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */


