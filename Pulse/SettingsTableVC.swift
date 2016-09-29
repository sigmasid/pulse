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

    fileprivate var _sections : [SettingSection]?
    fileprivate var _settings = [[Setting]]()
    
    fileprivate lazy var _headerView = UIView()
    fileprivate var _loginHeader : LoginHeaderView?

    fileprivate var settingsTable = UITableView()
    fileprivate let _reuseIdentifier = "SettingsTableCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingsTable.register(SettingsTableCell.self, forCellReuseIdentifier: _reuseIdentifier)
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
        settingsTable.topAnchor.constraint(equalTo: _headerView.bottomAnchor, constant: Spacing.s.rawValue).isActive = true
        settingsTable.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        settingsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.s.rawValue).isActive = true
        settingsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.s.rawValue).isActive = true
        
        settingsTable.backgroundView = nil
        settingsTable.backgroundColor = UIColor.clear
        settingsTable.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        settingsTable.separatorColor = UIColor.gray.withAlphaComponent(0.7)
        settingsTable.tableFooterView = UIView()
        settingsTable.showsVerticalScrollIndicator = false

        settingsTable.delegate = self
        settingsTable.dataSource = self
        settingsTable.reloadData()
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
            _loginHeader.updateStatusMessage(_message: "PROFILE SETTINGS")

            _loginHeader.addGoBack()
            _loginHeader._goBack.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
            
            _headerView.addSubview(_loginHeader)
        }
    }
    
    func goBack() {
        if returnToParentDelegate != nil {
            returnToParentDelegate.returnToParent(self)
        }
    }
    
    func showSettingDetail(_ selectedSetting : Setting) {
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
    
    func returnToParent(_ currentVC : UIViewController) {
        GlobalFunctions.dismissVC(currentVC)
    }
}

extension SettingsTableVC : UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return _sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _sections?[section].sectionSettingsCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let _sectionID = _sections![section].sectionID
        return SectionTypes.getSectionDisplayName(_sectionID)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.backgroundView?.backgroundColor = UIColor.clear
            header.textLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
            header.textLabel!.textColor = UIColor.orange
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let _settingID = _sections![(indexPath as NSIndexPath).section].settings![(indexPath as NSIndexPath).row]
        let cell = tableView.dequeueReusableCell(withIdentifier: _reuseIdentifier) as! SettingsTableCell

        if _settings[(indexPath as NSIndexPath).section].count > (indexPath as NSIndexPath).row {
            let _setting = _settings[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
            cell.textLabel!.text = _setting.display!
            if _setting.type != nil {
                cell._detailTextLabel.text = User.currentUser?.getValueForStringProperty(_setting.type!.rawValue)
            }
            if _setting.editable {
                cell.accessoryType = .disclosureIndicator
            }
        } else {
            Database.getSetting(_settingID, completion: {(_setting, error) in
                cell.textLabel!.text = _setting.display!
                if _setting.type != nil {
                    cell._detailTextLabel.text = User.currentUser?.getValueForStringProperty(_setting.type!.rawValue)
                }
                self._settings[(indexPath as NSIndexPath).section].append(_setting)
                if _setting.editable {
                    cell.accessoryType = .disclosureIndicator
                }
            })
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let _setting = _settings[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
        showSettingDetail(_setting)
        tableView.deselectRow(at: indexPath, animated: true)
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


