//
//  SettingsTableVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 7/28/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit

class SettingsTableVC: UIViewController {
    
    private var _settingsLoaded = false
    private var _settings : Settings!
    @IBOutlet weak var settingsTable: UITableView!
    private let _reuseIdentifier = "SettingsTableCell"
    
    enum SettingTypes : String {
        case activity = "activity"
        case personalInfo = "personalInfo"
        
        static func getSettingType(index : Int) -> SettingTypes? {
            switch index {
            case 0: return .activity
            case 1: return .personalInfo
            default: return nil
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Database.getSettings({ (settings , error) in
            self._settings = settings
            self.settingsCreated()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func settingsCreated() {
        settingsTable.delegate = self
        settingsTable.dataSource = self
        settingsTable.reloadData()
    }
}

extension SettingsTableVC : UITableViewDelegate, UITableViewDataSource {

    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return _settings.sectionCount!
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch _settings.sections[section]! {
        case SettingTypes.activity.rawValue: return _settings.activity!.count
        case SettingTypes.personalInfo.rawValue: return _settings.personalInfo!.count
        default: return 0
        }
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let _settingType = SettingTypes.getSettingType(indexPath.section)
        let cell = tableView.dequeueReusableCellWithIdentifier(_reuseIdentifier, forIndexPath: indexPath)

        switch _settingType! {
        case .activity: cell.textLabel?.text = _settings.activity![indexPath.row]
        case .personalInfo: cell.textLabel?.text = _settings.personalInfo![indexPath.row]
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


