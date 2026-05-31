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
