//
//  SettingsTableVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SettingsTableVC: UIViewController {
    
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
        
        settingsTable.showsVerticalScrollIndicator = false
        settingsTable.layoutIfNeeded()
        
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
            _loginHeader.addGoBack()
            _loginHeader._goBack.addTarget(self, action: #selector(goBack), forControlEvents: UIControlEvents.TouchUpInside)
            
            _headerView.addSubview(_loginHeader)
        }
    }
    
    func goBack() {
        
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
        return _sectionID
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
            cell.detailTextLabel?.text = User.currentUser?.getValueForStringProperty(_setting.settingID)
        } else {
            Database.getSetting(_settingID, completion: {(setting, error) in
                cell.textLabel!.text = setting.display!
                cell.detailTextLabel?.text = User.currentUser?.getValueForStringProperty(setting.settingID)
                self._settings[indexPath.section].append(setting)
            })
        }
        return cell
    }
}


    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */


