/**
 * Google Apps Script Web Service for Biometric & GPS Attendance System
 * 
 * -------------------------------------------------------------------
 * CONFIGURATION:
 * - Set your Firebase Project ID below to automatically sync automated 
 *   check-outs back to your Firebase Firestore database.
 * -------------------------------------------------------------------
 */
var FIREBASE_PROJECT_ID = "YOUR_FIREBASE_PROJECT_ID"; // Replace with your actual Firebase Project ID!

/**
 * INSTRUCTIONS FOR DEPLOYMENT:
 * 1. Create a new Google Sheet in your Google Drive.
 * 2. In the Google Sheet, go to Extensions > Apps Script in the menu.
 * 3. Clear any existing code in the editor, copy this entire script and paste it.
 * 4. Configure your FIREBASE_PROJECT_ID at the top.
 * 5. Click the Save icon (floppy disk) or press Ctrl+S.
 * 6. Click the "Deploy" button in the top right corner and choose "New deployment".
 * 7. Configure:
 *    - Select type: Web app
 *    - Description: Biometric Attendance Webhook
 *    - Execute as: Me (your-email@gmail.com)
 *    - Who has access: Anyone (This is required for the mobile app to post logs)
 * 8. Click "Deploy". Authorize Access and confirm your Google account.
 * 9. Copy the generated "Web app URL" (ends with /exec) and save it in your App settings.
 * 10. SETUP AUTO-CHECKOUT RUNNER: In the Apps Script editor toolbar, select 'createDailyTrigger' 
 *     from the function dropdown list and click 'Run'. This automatically registers the 6 PM daily job!
 * -------------------------------------------------------------------
 */

function doPost(e) {
  var lock = LockService.getScriptLock();
  lock.tryLock(10000); // 10-second fail-safe delay to prevent concurrent write overlap
  
  try {
    var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
    
    // Auto-create spreadsheet columns headers if sheet is empty
    if (sheet.getLastRow() === 0) {
      sheet.appendRow([
        "Date", 
        "Time", 
        "Employee ID", 
        "Name", 
        "Email", 
        "Designation", 
        "Type", 
        "Device ID", 
        "Distance (m)", 
        "Verified",
        "UID"
      ]);
      
      // Apply style to headers
      sheet.getRange(1, 1, 1, 11).setFontWeight("bold");
      sheet.getRange(1, 1, 1, 11).setBackground("#e2e8f0");
      sheet.setFrozenRows(1);
    }
    
    // Parse the incoming JSON post payload
    var data = JSON.parse(e.postData.contents);
    
    // Convert timestamp
    var dateObj = new Date(data.timestamp);
    var dateStr = dateObj.toLocaleDateString();
    var timeStr = dateObj.toLocaleTimeString();
    
    // Append attendance row record
    sheet.appendRow([
      dateStr,
      timeStr,
      data.employeeId || "N/A",
      data.name,
      data.email,
      data.designation,
      data.type === "check_in" ? "CHECK IN" : "CHECK OUT",
      data.deviceId,
      data.distance ? Number(data.distance).toFixed(1) : "0.0",
      data.verified ? "Yes" : "No",
      data.uid || "N/A"
    ]);
    
    return ContentService.createTextOutput(JSON.stringify({ "result": "success" }))
      .setMimeType(ContentService.MimeType.JSON);
      
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({ "result": "error", "error": error.toString() }))
      .setMimeType(ContentService.MimeType.JSON);
  } finally {
    lock.releaseLock(); // Safely unlock sheet for next write calls
  }
}

/**
 * Scans the Google Sheet at 6 PM every day. For any employee who has checked in 
 * today but has not checked out, it automatically appends a CHECK OUT (AUTO) row,
 * highlights it in red, and posts the transaction back to the Firebase Firestore database.
 */
function autoCheckOutDaily() {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var lastRow = sheet.getLastRow();
  if (lastRow < 2) return;
  
  // Get all data columns (Date, Time, Employee ID, Name, Email, Designation, Type, Device ID, Distance, Verified, UID)
  var dataRange = sheet.getRange(2, 1, lastRow - 1, 11);
  var values = dataRange.getValues();
  
  var todayStr = new Date().toLocaleDateString();
  
  // Track check ins and check outs for today
  var checkIns = {};
  var checkOuts = {};
  
  for (var i = 0; i < values.length; i++) {
    var row = values[i];
    var cellDate = row[0];
    
    var rowDateStr = "";
    if (cellDate instanceof Date) {
      rowDateStr = cellDate.toLocaleDateString();
    } else {
      rowDateStr = String(cellDate);
    }
    
    // Only analyze attendance records created today
    if (rowDateStr === todayStr) {
      var uid = String(row[10] || row[2]).trim(); // Use UID column if available, else employee code
      var empId = String(row[2]).trim();
      var type = String(row[6]).toUpperCase().trim();
      
      if (type === "CHECK IN") {
        checkIns[uid] = {
          uid: uid,
          empId: empId,
          name: row[3],
          email: row[4],
          designation: row[5],
          deviceId: row[7],
          distance: row[8],
          verified: row[9]
        };
      } else if (type === "CHECK OUT" || type.indexOf("CHECK OUT") !== -1) {
        checkOuts[uid] = true;
      }
    }
  }
  
  // Detect missing check-outs
  var checkoutsAddedCount = 0;
  for (var uid in checkIns) {
    if (!checkOuts[uid]) {
      var checkInRecord = checkIns[uid];
      
      // Force time label to 6:00:00 PM
      var targetTime = new Date();
      targetTime.setHours(18, 0, 0, 0);
      var timeStr = targetTime.toLocaleTimeString();
      
      // 1. Add check out record in Google Sheet
      var newRow = [
        todayStr,
        timeStr,
        checkInRecord.empId,
        checkInRecord.name,
        checkInRecord.email,
        checkInRecord.designation,
        "CHECK OUT (AUTO)",
        "SYSTEM",
        "0.0",
        "No",
        checkInRecord.uid
      ];
      
      sheet.appendRow(newRow);
      var appendedRowIndex = sheet.getLastRow();
      
      // Apply beautiful distinct warning color (soft red background, red bold text)
      var targetRowRange = sheet.getRange(appendedRowIndex, 1, 1, 11);
      targetRowRange.setBackground("#fee2e2");
      targetRowRange.setFontColor("#ef4444");
      targetRowRange.setFontWeight("bold");
      
      checkoutsAddedCount++;
      
      // 2. Sync record back to Firestore database using Firestore REST API
      if (FIREBASE_PROJECT_ID && FIREBASE_PROJECT_ID !== "YOUR_FIREBASE_PROJECT_ID") {
        try {
          var firestoreUrl = "https://firestore.googleapis.com/v1/projects/" + FIREBASE_PROJECT_ID + "/databases/(default)/documents/attendance";
          var payload = {
            "fields": {
              "uid": { "stringValue": checkInRecord.uid },
              "name": { "stringValue": checkInRecord.name },
              "email": { "stringValue": checkInRecord.email },
              "designation": { "stringValue": checkInRecord.designation },
              "employeeId": { "stringValue": checkInRecord.empId },
              "timestamp": { "timestampValue": targetTime.toISOString() },
              "type": { "stringValue": "check_out" },
              "deviceId": { "stringValue": "SYSTEM_AUTO" },
              "latitude": { "doubleValue": 0.0 },
              "longitude": { "doubleValue": 0.0 },
              "distance": { "doubleValue": 0.0 },
              "verified": { "booleanValue": false },
              "isAutoCheckout": { "booleanValue": true }
            }
          };
          
          var options = {
            "method": "post",
            "contentType": "application/json",
            "payload": JSON.stringify(payload),
            "muteHttpExceptions": true
          };
          
          var response = UrlFetchApp.fetch(firestoreUrl, options);
          Logger.log("Firestore Sync Result: " + response.getContentText());
        } catch (dbError) {
          Logger.log("Error syncing auto-checkout to Firestore: " + dbError.toString());
        }
      }
    }
  }
  
  Logger.log("Auto-Checkout Execution Finished. Total employees auto-checked-out: " + checkoutsAddedCount);
}

/**
 * Programmatically installs a daily time-driven trigger to execute autoCheckOutDaily() at 6:00 PM everyday.
 * Select 'createDailyTrigger' and click 'Run' to configure this automated job instantly.
 */
function createDailyTrigger() {
  // Clear any existing duplicates
  var triggers = ScriptApp.getProjectTriggers();
  for (var i = 0; i < triggers.length; i++) {
    if (triggers[i].getHandlerFunction() === "autoCheckOutDaily") {
      ScriptApp.deleteTrigger(triggers[i]);
    }
  }
  
  // Set up daily cron running at 18:00 (6:00 PM)
  ScriptApp.newTrigger("autoCheckOutDaily")
    .timeBased()
    .everyDays(1)
    .atHour(18) // 18:00 = 6 PM
    .create();
    
  Logger.log("Success: Registered daily 6:00 PM auto check-out trigger in Google Sheets!");
}

/**
 * Automatically loads a custom admin toolbar menu called "📅 Attendance Admin"
 * when the Google Sheet is opened. Allows administrators to generate reports with one click!
 */
function onOpen() {
  var ui = SpreadsheetApp.getUi();
  ui.createMenu("📅 Attendance Admin")
      .addItem("Generate Horizontal Monthly Report", "generateMonthlyReport")
      .addToUi();
}

/**
 * Robust date utility to extract the day of the month (1-31) from date strings or objects.
 */
function getDayFromDate(dateValue) {
  var d = new Date(dateValue);
  if (!isNaN(d.getTime())) {
    return d.getDate(); // Returns 1-31
  }
  
  // Try string splitting in case of non-standard date strings
  var parts = String(dateValue).split("/");
  if (parts.length >= 2) {
    var dayVal = parseInt(parts[1], 10);
    if (!isNaN(dayVal)) return dayVal;
  }
  return null;
}

/**
 * Core reporting engine that automatically transforms raw transactional logs into a 
 * gorgeous, styled, horizontal Monthly Grid Register (In, Out, and Status columns for all 31 days).
 * Completely optimized with frozen rows, frozen columns, royal blue headers, and conditional coloring.
 */
function generateMonthlyReport() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var rawSheet = ss.getActiveSheet();
  
  // Safe fail-safe check to prevent administrators from running the script while inside the report tab
  if (rawSheet.getName().indexOf("Report") !== -1) {
    rawSheet = ss.getSheets()[0]; // Fallback to raw logs data sheet
  }
  
  var lastRow = rawSheet.getLastRow();
  if (lastRow < 2) {
    SpreadsheetApp.getUi().alert("Error: No attendance data logs found in the active sheet!");
    return;
  }
  
  // Create or reset the report sheet
  var reportSheetName = "Monthly Attendance Report";
  var reportSheet = ss.getSheetByName(reportSheetName);
  if (reportSheet) {
    reportSheet.clear();
    reportSheet.clearConditionalFormatRules();
  } else {
    reportSheet = ss.insertSheet(reportSheetName);
  }
  
  // Read all logs (Date, Time, Employee ID, Name, Email, Designation, Type, Device ID, Distance, Verified, UID)
  var rawRange = rawSheet.getRange(2, 1, lastRow - 1, 11);
  var rawValues = rawRange.getValues();
  
  // Group logs by Employee and Day of the month
  var employees = {};
  
  for (var i = 0; i < rawValues.length; i++) {
    var row = rawValues[i];
    var dateCell = row[0];
    var timeCell = row[1];
    var empId = String(row[2]).trim();
    var name = String(row[3]).trim();
    var designation = String(row[5]).trim();
    var type = String(row[6]).toUpperCase().trim();
    
    if (!empId || empId === "N/A" || empId === "Employee ID" || empId === "undefined") continue;
    
    var day = getDayFromDate(dateCell);
    if (!day || day < 1 || day > 31) continue;
    
    if (!employees[empId]) {
      employees[empId] = {
        empId: empId,
        name: name,
        designation: designation,
        days: {} // Day 1 to 31 grid
      };
      
      // Seed days grid with default empty values
      for (var d = 1; d <= 31; d++) {
        employees[empId].days[d] = { checkIn: "—", checkOut: "—", status: "" };
      }
    }
    
    // Always preserve latest non-empty designations or names
    if (name && name !== "N/A") employees[empId].name = name;
    if (designation && designation !== "N/A") employees[empId].designation = designation;
    
    var timeStr = String(timeCell);
    if (timeCell instanceof Date) {
      timeStr = timeCell.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }
    
    var dayData = employees[empId].days[day];
    if (type === "CHECK IN") {
      dayData.checkIn = timeStr;
      if (dayData.status !== "F") dayData.status = "P"; // Marked Present
    } else if (type === "CHECK OUT") {
      dayData.checkOut = timeStr;
      if (dayData.status !== "F") dayData.status = "P"; // Marked Present
    } else if (type === "CHECK OUT (AUTO)") {
      dayData.checkOut = timeStr;
      dayData.status = "F"; // Auto check out triggered
    }
  }
  
  // Create beautiful merged double headers
  var headersRow1 = ["Employee ID", "Name", "Designation"];
  var headersRow2 = ["", "", ""];
  
  for (var d = 1; d <= 31; d++) {
    headersRow1.push("Day " + d, "", ""); // Merged Day span
    headersRow2.push("In", "Out", "Status");
  }
  
  reportSheet.appendRow(headersRow1);
  reportSheet.appendRow(headersRow2);
  
  // Merge Day headers in Row 1 horizontally across 3 columns
  for (var d = 1; d <= 31; d++) {
    var startCol = 4 + (d - 1) * 3;
    reportSheet.getRange(1, startCol, 1, 3).merge();
  }
  
  // Merge Employee ID, Name, Designation headers vertically
  reportSheet.getRange("A1:A2").merge();
  reportSheet.getRange("B1:B2").merge();
  reportSheet.getRange("C1:C2").merge();
  
  // Populate grid with employee data rows
  var employeeIds = Object.keys(employees);
  var rowDataList = [];
  
  for (var k = 0; k < employeeIds.length; k++) {
    var emp = employees[employeeIds[k]];
    var rowData = [emp.empId, emp.name, emp.designation];
    
    for (var d = 1; d <= 31; d++) {
      var dayGrid = emp.days[d];
      rowData.push(dayGrid.checkIn, dayGrid.checkOut, dayGrid.status);
    }
    rowDataList.push(rowData);
  }
  
  if (rowDataList.length > 0) {
    reportSheet.getRange(3, 1, rowDataList.length, 3 + 31 * 3).setValues(rowDataList);
  }
  
  // --- Styling and Premium Formatting ---
  var totalCols = 3 + 31 * 3;
  var totalRows = reportSheet.getLastRow();
  
  // Primary header row colors (Royal Blue)
  var headerRange = reportSheet.getRange(1, 1, 2, totalCols);
  headerRange.setFontWeight("bold");
  headerRange.setBackground("#2563eb"); // Premium modern blue
  headerRange.setFontColor("#ffffff");
  headerRange.setHorizontalAlignment("center");
  headerRange.setVerticalAlignment("middle");
  
  // Clean grid borders
  reportSheet.getRange(1, 1, totalRows, totalCols).setBorder(
    true, true, true, true, true, true, 
    "#e2e8f0", SpreadsheetApp.BorderStyle.SOLID
  );
  
  // Alignment settings
  reportSheet.getRange(3, 1, totalRows - 2, 3).setHorizontalAlignment("left"); // Info columns
  reportSheet.getRange(3, 4, totalRows - 2, totalCols - 3).setHorizontalAlignment("center"); // Timing columns
  
  // Freeze Headers and employee details columns for high-fidelity scroll experience
  reportSheet.setFrozenRows(2);
  reportSheet.setFrozenColumns(3);
  
  // Resize columns
  reportSheet.autoResizeColumns(1, 3);
  for (var col = 4; col <= totalCols; col++) {
    reportSheet.setColumnWidth(col, 65); // standard compact width
  }
  
  // --- Automatic Conditional Rules Formatting ---
  var statusRange = reportSheet.getRange(3, 1, totalRows - 2, totalCols);
  
  // 'P' (Present) -> Soft Green Background
  var ruleP = SpreadsheetApp.newConditionalFormatRule()
      .whenTextEqualTo("P")
      .setBackground("#e6f4ea")
      .setFontColor("#137333")
      .setFontWeight("bold")
      .setRanges([statusRange])
      .build();
      
  // 'F' (Forgot Checkout) -> Soft Red Background
  var ruleF = SpreadsheetApp.newConditionalFormatRule()
      .whenTextEqualTo("F")
      .setBackground("#fce8e6")
      .setFontColor("#c5221f")
      .setFontWeight("bold")
      .setRanges([statusRange])
      .build();
      
  var rules = reportSheet.getConditionalFormatRules();
  rules.push(ruleP);
  rules.push(ruleF);
  reportSheet.setConditionalFormatRules(rules);
  
  SpreadsheetApp.getUi().alert("Success: Monthly Attendance Grid Report Register generated successfully!");
}
