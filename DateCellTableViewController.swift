//
//  DateCellTableViewController.swift
//  DateCell
//
//  Created by Kohei Hayakawa on 2/6/15.
//  Copyright (c) 2015 Kohei Hayakawa. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


class DateCellTableViewController: UITableViewController {
    
    let kPickerAnimationDuration = 0.40 // duration for the animation to slide the date picker into view
    let kDatePickerTag           = 99   // view tag identifiying the date picker view
    
    let kTitleKey = "title" // key for obtaining the data source item's title
    let kDateKey  = "date"  // key for obtaining the data source item's date value
    
    // keep track of which rows have date cells
    let kDateStartRow = 1
    let kDateEndRow   = 2
    
    let kDateCellID       = "dateCell";       // the cells with the start or end date
    let kDatePickerCellID = "datePickerCell"; // the cell containing the date picker
    let kOtherCellID      = "otherCell";      // the remaining cells at the end

    var dataArray: [[String: AnyObject]] = []
    var dateFormatter = DateFormatter()
    
    // keep track which indexPath points to the cell with UIDatePicker
    var datePickerIndexPath: IndexPath?
    
    var pickerCellRowHeight: CGFloat = 216
    
    @IBOutlet var pickerView: UIDatePicker!

    override func viewDidLoad() {
        super.viewDidLoad()

        // setup our data source
        let itemOne = [kTitleKey : "Tap a cell to change its date:"]
        let itemTwo = [kTitleKey : "Start Date", kDateKey : Date()] as [String : Any]
        let itemThree = [kTitleKey : "End Date", kDateKey : Date()] as [String : Any]
        let itemFour = [kTitleKey : "(other item1)"]
        let itemFive = [kTitleKey : "(other item2)"]
        dataArray = [itemOne as Dictionary<String, AnyObject>, itemTwo as Dictionary<String, AnyObject>, itemThree as Dictionary<String, AnyObject>, itemFour as Dictionary<String, AnyObject>, itemFive as Dictionary<String, AnyObject>]
        
        dateFormatter.dateStyle = .short // show short-style date format
        dateFormatter.timeStyle = .short
        
        // if the local changes while in the background, we need to be notified so we can update the date
        // format in the table view cells
        //
        NotificationCenter.default.addObserver(self, selector: #selector(DateCellTableViewController.localeChanged(_:)), name: NSLocale.currentLocaleDidChangeNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Locale
    
    /*! Responds to region format or locale changes.
    */
    func localeChanged(_ notif: Notification) {
    // the user changed the locale (region format) in Settings, so we are notified here to
    // update the date format in the table view cells
    //
        tableView.reloadData()
    }
    

    /*! Determines if the given indexPath has a cell below it with a UIDatePicker.
    
    @param indexPath The indexPath to check if its cell has a UIDatePicker below it.
    */
    func hasPickerForIndexPath(_ indexPath: IndexPath) -> Bool {
        var hasDatePicker = false
        
        let targetedRow = (indexPath as NSIndexPath).row + 1
        
        let checkDatePickerCell = tableView.cellForRow(at: IndexPath(row: targetedRow, section: 0))
        let checkDatePicker = checkDatePickerCell?.viewWithTag(kDatePickerTag)
        
        hasDatePicker = checkDatePicker != nil
        return hasDatePicker
    }

    /*! Updates the UIDatePicker's value to match with the date of the cell above it.
    */
    func updateDatePicker() {
        if let indexPath = datePickerIndexPath {
            let associatedDatePickerCell = tableView.cellForRow(at: indexPath)
            if let targetedDatePicker = associatedDatePickerCell?.viewWithTag(kDatePickerTag) as! UIDatePicker? {
                let itemData = dataArray[(self.datePickerIndexPath! as NSIndexPath).row - 1]
                targetedDatePicker.setDate(itemData[kDateKey] as! Date, animated: false)
            }
        }
    }
    
    /*! Determines if the UITableViewController has a UIDatePicker in any of its cells.
    */
    func hasInlineDatePicker() -> Bool {
        return datePickerIndexPath != nil
    }
    
    /*! Determines if the given indexPath points to a cell that contains the UIDatePicker.
    
    @param indexPath The indexPath to check if it represents a cell with the UIDatePicker.
    */
    func indexPathHasPicker(_ indexPath: IndexPath) -> Bool {
        return hasInlineDatePicker() && (datePickerIndexPath as NSIndexPath?)?.row == (indexPath as NSIndexPath).row
    }

    /*! Determines if the given indexPath points to a cell that contains the start/end dates.
    
    @param indexPath The indexPath to check if it represents start/end date cell.
    */
    func indexPathHasDate(_ indexPath: IndexPath) -> Bool {
        var hasDate = false
        
        if ((indexPath as NSIndexPath).row == kDateStartRow) || ((indexPath as NSIndexPath).row == kDateEndRow || (hasInlineDatePicker() && ((indexPath as NSIndexPath).row == kDateEndRow + 1))) {
            hasDate = true
        }
        return hasDate
    }

    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (indexPathHasPicker(indexPath) ? pickerCellRowHeight : tableView.rowHeight)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
  
        if hasInlineDatePicker() {
            // we have a date picker, so allow for it in the number of rows in this section
            return dataArray.count + 1;
        }
        
        return dataArray.count;
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        var cellID = kOtherCellID
        
        if indexPathHasPicker(indexPath) {
            // the indexPath is the one containing the inline date picker
            cellID = kDatePickerCellID     // the current/opened date picker cell
        } else if indexPathHasDate(indexPath) {
            // the indexPath is one that contains the date information
            cellID = kDateCellID       // the start/end date cells
        }
        
        cell = tableView.dequeueReusableCell(withIdentifier: cellID)
    
        if (indexPath as NSIndexPath).row == 0 {
            // we decide here that first cell in the table is not selectable (it's just an indicator)
            cell?.selectionStyle = .none;
        }
        
        // if we have a date picker open whose cell is above the cell we want to update,
        // then we have one more cell than the model allows
        //
        var modelRow = (indexPath as NSIndexPath).row
        if (datePickerIndexPath != nil && (datePickerIndexPath as NSIndexPath?)?.row <= (indexPath as NSIndexPath).row) {
            modelRow -= 1
        }
        
        let itemData = dataArray[modelRow]
        
        if cellID == kDateCellID {
            // we have either start or end date cells, populate their date field
            //
            cell?.textLabel?.text = itemData[kTitleKey] as? String
            cell?.detailTextLabel?.text = self.dateFormatter.string(from: itemData[kDateKey] as! Date)
        } else if cellID == kOtherCellID {
            // this cell is a non-date cell, just assign it's text label
            //
            cell?.textLabel?.text = itemData[kTitleKey] as? String
        }
        
        return cell!
    }
    
    /*! Adds or removes a UIDatePicker cell below the given indexPath.
    
    @param indexPath The indexPath to reveal the UIDatePicker.
    */
    func toggleDatePickerForSelectedIndexPath(_ indexPath: IndexPath) {
        
        tableView.beginUpdates()
        
        let indexPaths = [IndexPath(row: (indexPath as NSIndexPath).row + 1, section: 0)]
        
        // check if 'indexPath' has an attached date picker below it
        if hasPickerForIndexPath(indexPath) {
            // found a picker below it, so remove it
            tableView.deleteRows(at: indexPaths, with: .fade)
        } else {
            // didn't find a picker below it, so we should insert it
            tableView.insertRows(at: indexPaths, with: .fade)
        }
        tableView.endUpdates()
    }

    /*! Reveals the date picker inline for the given indexPath, called by "didSelectRowAtIndexPath".
    
    @param indexPath The indexPath to reveal the UIDatePicker.
    */
    func displayInlineDatePickerForRowAtIndexPath(_ indexPath: IndexPath) {
        
        // display the date picker inline with the table content
        tableView.beginUpdates()
        
        var before = false // indicates if the date picker is below "indexPath", help us determine which row to reveal
        if hasInlineDatePicker() {
            before = (datePickerIndexPath as NSIndexPath?)?.row < (indexPath as NSIndexPath).row
        }
        
        let sameCellClicked = ((datePickerIndexPath as NSIndexPath?)?.row == (indexPath as NSIndexPath).row + 1)
        
        // remove any date picker cell if it exists
        if self.hasInlineDatePicker() {
            tableView.deleteRows(at: [IndexPath(row: (datePickerIndexPath! as NSIndexPath).row, section: 0)], with: .fade)
            datePickerIndexPath = nil
        }
        
        if !sameCellClicked {
            // hide the old date picker and display the new one
            let rowToReveal = (before ? (indexPath as NSIndexPath).row - 1 : (indexPath as NSIndexPath).row)
            let indexPathToReveal = IndexPath(row: rowToReveal, section: 0)
            
            toggleDatePickerForSelectedIndexPath(indexPathToReveal)
            datePickerIndexPath = IndexPath(row: (indexPathToReveal as NSIndexPath).row + 1, section: 0)
        }
        
        // always deselect the row containing the start or end date
        tableView.deselectRow(at: indexPath, animated:true)
        
        tableView.endUpdates()
        
        // inform our date picker of the current date to match the current cell
        updateDatePicker()
    }
    
    /*! Reveals the UIDatePicker as an external slide-in view, iOS 6.1.x and earlier, called by "didSelectRowAtIndexPath".
    
    @param indexPath The indexPath used to display the UIDatePicker.
    */
    /*
    func displayExternalDatePickerForRowAtIndexPath(indexPath: NSIndexPath) {
        
        // first update the date picker's date value according to our model
        let itemData: AnyObject = self.dataArray[indexPath.row]
        self.pickerView.setDate(itemData.valueForKey(kDateKey) as NSDate, animated: true)
        
        // the date picker might already be showing, so don't add it to our view
        if self.pickerView.superview == nil {
            var startFrame = self.pickerView.frame
            var endFrame = self.pickerView.frame
            
            // the start position is below the bottom of the visible frame
            startFrame.origin.y = CGRectGetHeight(self.view.frame)
            
            // the end position is slid up by the height of the view
            endFrame.origin.y = startFrame.origin.y - CGRectGetHeight(endFrame)
            
            self.pickerView.frame = startFrame
            
            self.view.addSubview(self.pickerView)
            
            // animate the date picker into view
            UIView.animateWithDuration(kPickerAnimationDuration, animations: { self.pickerView.frame = endFrame }, completion: {(value: Bool) in
                // add the "Done" button to the nav bar
                //self.navigationItem.rightBarButtonItem = self.doneButton
            })
        }
    }
    */
    
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath)
        if cell?.reuseIdentifier == kDateCellID {
            displayInlineDatePickerForRowAtIndexPath(indexPath)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    
    // MARK: - Actions
    
    /*! User chose to change the date by changing the values inside the UIDatePicker.
    
    @param sender The sender for this action: UIDatePicker.
    */
    
    
    @IBAction func dateAction(_ sender: UIDatePicker) {
        
        var targetedCellIndexPath: IndexPath?
        
        if self.hasInlineDatePicker() {
            // inline date picker: update the cell's date "above" the date picker cell
            //
            targetedCellIndexPath = IndexPath(row: (datePickerIndexPath! as NSIndexPath).row - 1, section: 0)
        } else {
            // external date picker: update the current "selected" cell's date
            targetedCellIndexPath = tableView.indexPathForSelectedRow!
        }
        
        let cell = tableView.cellForRow(at: targetedCellIndexPath!)
        let targetedDatePicker = sender
        
        // update our data model
        var itemData = dataArray[(targetedCellIndexPath! as NSIndexPath).row]
        itemData[kDateKey] = targetedDatePicker.date as AnyObject?
        dataArray[(targetedCellIndexPath! as NSIndexPath).row] = itemData
        
        // update the cell's date string
        cell?.detailTextLabel?.text = dateFormatter.string(from: targetedDatePicker.date)
        

    }

}
