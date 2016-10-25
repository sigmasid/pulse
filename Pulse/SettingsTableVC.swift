//
//  SettingsTableVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SettingsTableVC: UIViewController {
    fileprivate var _sections : [SettingSection]?
    fileprivate var _settings = [[Setting]]()
    fileprivate var _selectedSettingRow : IndexPath?

    fileprivate var settingsTable = UITableView()
    fileprivate let _reuseIdentifier = "SettingsTableCell"
    
    fileprivate var isLoaded = false
    
    public var settingSection : String! {
        didSet {
            Database.getSectionsSection(sectionName: settingSection, completion: { (section , error) in
                if error == nil {
                    self._sections = [section]
                    for _ in self._sections! {
                        self._settings.append([])
                    }
                    self.settingsTable.delegate = self
                    self.settingsTable.dataSource = self
                    self.settingsTable.reloadData()                }
            })
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //force refresh of the selected row
        if _selectedSettingRow != nil {
            settingsTable.reloadRows(at: [_selectedSettingRow!], with: .fade)
            _selectedSettingRow = nil
        }
    }
    
    override func viewDidLayoutSubviews() {
        if !isLoaded {
            updateHeader()
            setupTable()
            
            view.backgroundColor = UIColor.white
            settingsTable.register(SettingsTableCell.self, forCellReuseIdentifier: _reuseIdentifier)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func updateHeader() {
        let backButton = NavVC.getButton(type: .back)
        backButton.addTarget(self, action: #selector(goBack), for: UIControlEvents.touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        if let nav = navigationController as? NavVC {
            nav.updateTitle(title: "Update Profile")
        } else {
            title = "Update Profile"
        }
    }
    
    
    func goBack() {
        let _ = navigationController?.popViewController(animated: true)
    }
    
    func setupTable() {
        view.addSubview(settingsTable)
        
        settingsTable.translatesAutoresizingMaskIntoConstraints = false
        settingsTable.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        settingsTable.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
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
        //        settingsTable.rowHeight = UITableViewAutomaticDimension //supposed to give dynamic height but doesn't work

    }
    
    func showSettingDetail(_ selectedSetting : Setting) {
        let updateSetting = UpdateProfileVC()
        updateSetting._currentSetting = selectedSetting
        navigationController?.pushViewController(updateSetting, animated: true)
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
            header.textLabel!.setFont(FontSizes.body2.rawValue, weight: UIFontWeightBold, color: pulseBlue, alignment: .left)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let _settingID = _sections![(indexPath as NSIndexPath).section].settings![(indexPath as NSIndexPath).row]
        let cell = tableView.dequeueReusableCell(withIdentifier: _reuseIdentifier) as! SettingsTableCell

        if _settings[(indexPath as NSIndexPath).section].count > (indexPath as NSIndexPath).row {
            let _setting = _settings[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
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
                cell._settingNameLabel.text = _setting.display!
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
        _selectedSettingRow = indexPath
        showSettingDetail(_setting)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IconSizes.medium.rawValue
    }
}
