  /**
   * Google Apps Script Web Service for Biometric & GPS Attendance System
   * 
   * -------------------------------------------------------------------
   * CONFIGURATION:
   * - Set your Firebase Project ID below to automatically sync automated 
   *   check-outs back to your Firebase Firestore database.
   * -------------------------------------------------------------------
   */
  var FIREBASE_PROJECT_ID = "biometric-attendance-518df"; // Replace with your actual Firebase Project ID!

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

  function doGet(e) {
    try {
      var action = e.parameter.action;
      
      if (action === "export") {
        var month = e.parameter.month; // 1-12 (Optional)
        var year = e.parameter.year;   // e.g. 2026 (Optional)
        
        var targetMonth, targetYear;
        if (month !== undefined && year !== undefined) {
          targetMonth = parseInt(month, 10) - 1; // 0-indexed in JS
          targetYear = parseInt(year, 10);
        }
        
        // 1. Generate the monthly report to make sure it's up to date
        generateMonthlyReport(targetMonth, targetYear);
        
        // 2. Get the active spreadsheet ID and build export link
        var ss = SpreadsheetApp.getActiveSpreadsheet();
        var id = ss.getId();
        var downloadUrl = "https://docs.google.com/spreadsheets/d/" + id + "/export?format=xlsx";
        
        // 3. Return the download URL as success response
        return ContentService.createTextOutput(JSON.stringify({
          "result": "success",
          "url": downloadUrl
        })).setMimeType(ContentService.MimeType.JSON);
      }
      
      return ContentService.createTextOutput(JSON.stringify({
        "result": "error",
        "error": "Invalid action parameter"
      })).setMimeType(ContentService.MimeType.JSON);
      
    } catch (error) {
      return ContentService.createTextOutput(JSON.stringify({
        "result": "error",
        "error": error.toString()
      })).setMimeType(ContentService.MimeType.JSON);
    }
  }

  function doPost(e) {
    var lock = LockService.getScriptLock();
    lock.tryLock(10000); // 10-second fail-safe delay to prevent concurrent write overlap

    try {
      var ss = SpreadsheetApp.getActiveSpreadsheet();
      var sheet = ss.getSheetByName("Sheet1");
      if (!sheet) {
        sheet = ss.getSheets()[0]; // Fallback to first sheet if Sheet1 is not found
      }

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

      // Convert timestamp with explicit Indian Standard Time (IST) formatting
      var dateObj = new Date(data.timestamp);
      var dateStr = Utilities.formatDate(dateObj, "Asia/Kolkata", "dd/MM/yyyy");
      var timeStr = Utilities.formatDate(dateObj, "Asia/Kolkata", "hh:mm:ss a");

      // Prevent multiple check-in or check-out in same day
      var incomingUid = String(data.uid || data.employeeId || "").trim();
      var incomingType = (data.type === "check_in" ? "CHECK IN" : "CHECK OUT").trim();

      var lastRow = sheet.getLastRow();
      if (lastRow >= 2) {
        var values = sheet.getRange(2, 1, lastRow - 1, 11).getValues();
        for (var i = 0; i < values.length; i++) {
          var row = values[i];
          var cellDate = row[0];
          
          var cellDateObj = parseDateRobustly(cellDate);
          if (cellDateObj) {
            var cellDateStr = cellDateObj.toLocaleDateString();
            var cellUid = String(row[10] || row[2] || "").trim();
            var cellType = String(row[6]).toUpperCase().trim();
            
            if (cellDateStr === dateStr && cellUid === incomingUid) {
              // Check if they are trying to double check-in
              if (incomingType === "CHECK IN" && cellType === "CHECK IN") {
                return ContentService.createTextOutput(JSON.stringify({ 
                  "result": "error", 
                  "error": "Security block: You have already marked CHECK IN today!" 
                })).setMimeType(ContentService.MimeType.JSON);
              }
              // Check if they are trying to double check-out
              if (incomingType === "CHECK OUT" && (cellType === "CHECK OUT" || cellType.indexOf("CHECK OUT") !== -1)) {
                return ContentService.createTextOutput(JSON.stringify({ 
                  "result": "error", 
                  "error": "Security block: You have already marked CHECK OUT today!" 
                })).setMimeType(ContentService.MimeType.JSON);
              }
            }
          }
        }
      }

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

      // Automatically regenerate the Monthly Attendance Report in the background for the specific log month!
      try {
        var dateParts = dateStr.split("/");
        var logMonth = parseInt(dateParts[1], 10) - 1; // 0-indexed
        var logYear = parseInt(dateParts[2], 10);
        generateMonthlyReport(logMonth, logYear);
      } catch (reportError) {
        Logger.log("Error generating report in doPost: " + reportError.toString());
      }

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
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var sheet = ss.getSheetByName("Sheet1");
    if (!sheet) {
      sheet = ss.getSheets()[0]; // Fallback to first sheet if Sheet1 is not found
    }
    var lastRow = sheet.getLastRow();
    if (lastRow < 2) return;

    // Get all data columns (Date, Time, Employee ID, Name, Email, Designation, Type, Device ID, Distance, Verified, UID)
    var dataRange = sheet.getRange(2, 1, lastRow - 1, 11);
    var values = dataRange.getValues();

    var todayStr = Utilities.formatDate(new Date(), "Asia/Kolkata", "dd/MM/yyyy");

    // Track check ins and check outs for today
    var checkIns = {};
    var checkOuts = {};

    for (var i = 0; i < values.length; i++) {
      var row = values[i];
      var cellDate = row[0];

      var rowDateStr = "";
      if (cellDate instanceof Date) {
        rowDateStr = Utilities.formatDate(cellDate, "Asia/Kolkata", "dd/MM/yyyy");
      } else {
        rowDateStr = String(cellDate).trim();
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

        // Force time label to 5:00:00 PM
        var targetTime = new Date();
        targetTime.setHours(17, 0, 0, 0);
        var timeStr = "05:00:00 PM";

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
        if (FIREBASE_PROJECT_ID && FIREBASE_PROJECT_ID !== "biometric-attendance-518df") {
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

    // Automatically regenerate the Monthly Attendance Report after auto-checkout daily job!
    if (checkoutsAddedCount > 0) {
      try {
        var todayParts = todayStr.split("/");
        var todayMonth = parseInt(todayParts[1], 10) - 1; // 0-indexed
        var todayYear = parseInt(todayParts[2], 10);
        generateMonthlyReport(todayMonth, todayYear);
      } catch (reportError) {
        Logger.log("Error generating report in autoCheckOutDaily: " + reportError.toString());
      }
    }

    Logger.log("Auto-Checkout Execution Finished. Total employees auto-checked-out: " + checkoutsAddedCount);
  }

  /**
   * Programmatically installs a daily time-driven trigger to execute autoCheckOutDaily() at 5:00 PM everyday.
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

    // Set up daily cron running at 17:00 (5:00 PM)
    ScriptApp.newTrigger("autoCheckOutDaily")
      .timeBased()
      .everyDays(1)
      .atHour(17) // 17:00 = 5 PM
      .create();

    Logger.log("Success: Registered daily 5:00 PM auto check-out trigger in Google Sheets!");
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
   * Robust date utility to parse date values (strings or Date objects) regardless of sheet locale.
   * Specially designed to handle dd/MM/yyyy (Indian/UK formats) and standard ISO strings.
   */
  function parseDateRobustly(dateCell) {
    if (dateCell instanceof Date) {
      return dateCell;
    }

    if (!dateCell) return null;

    var dateStr = String(dateCell).trim();

    // Try splitting by slash or hyphen
    var parts = dateStr.split(/[\/\-]/);
    if (parts.length >= 3) {
      var p0 = parseInt(parts[0], 10);
      var p1 = parseInt(parts[1], 10);
      var p2 = parseInt(parts[2], 10);

      // Check if the last part is a 4-digit year (dd/MM/yyyy)
      if (parts[2].length === 4) {
        var day = p0;
        var month = p1 - 1; // 0-indexed
        var year = p2;
        var d = new Date(year, month, day);
        if (!isNaN(d.getTime())) return d;
      } else if (parts[0].length === 4) {
        // Check if the first part is a 4-digit year (yyyy/MM/dd)
        var year = p0;
        var month = p1 - 1;
        var day = p2;
        var d = new Date(year, month, day);
        if (!isNaN(d.getTime())) return d;
      }
    }

    // Fallback to standard JS parsing
    var d = new Date(dateStr);
    if (!isNaN(d.getTime())) return d;

    return null;
  }

  /**
   * Helper to format a day, month, and year into dd/MM/yyyy date format string.
   */
  function formatGridDate(day, month, year) {
    var dd = day < 10 ? "0" + day : day;
    var mm = (month + 1) < 10 ? "0" + (month + 1) : (month + 1);
    return dd + "/" + mm + "/" + year;
  }

  /**
   * Core reporting engine that automatically transforms raw transactional logs into a 
   * gorgeous, styled, horizontal Monthly Grid Register (In, Out, and Status columns for the current month).
   * Completely optimized with frozen rows, frozen columns, royal blue headers, and conditional coloring.
   */
  function generateMonthlyReport(targetMonth, targetYear) {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var rawSheet = ss.getSheetByName("Sheet1");
    if (!rawSheet) {
      rawSheet = ss.getSheets()[0]; // Fallback to first sheet if "Sheet1" does not exist
    }

    var lastRow = rawSheet.getLastRow();
    if (lastRow < 2) {
      try {
        SpreadsheetApp.getUi().alert("Error: No attendance data logs found in the active sheet!");
      } catch (uiError) {
        Logger.log("Error: No attendance data logs found in the active sheet!");
      }
      return;
    }

    // Read all logs (Date, Time, Employee ID, Name, Email, Designation, Type, Device ID, Distance, Verified, UID)
    var rawRange = rawSheet.getRange(2, 1, lastRow - 1, 11);
    var rawValues = rawRange.getValues();

    // Default target month and year
    var reportMonth, reportYear;
    if (targetMonth !== undefined && targetYear !== undefined) {
      reportMonth = Number(targetMonth);
      reportYear = Number(targetYear);
    } else {
      // Default to current month and year based on script execution date
      var today = new Date();
      reportMonth = today.getMonth(); // Current month (0-11)
      reportYear = today.getFullYear(); // Current year

      // If there are raw logs, default to the month and year of the LATEST log in the sheet
      if (rawValues.length > 0) {
        var latestRow = rawValues[rawValues.length - 1];
        var latestDateCell = latestRow[0];
        var latestDate = parseDateRobustly(latestDateCell);
        if (latestDate) {
          reportMonth = latestDate.getMonth();
          reportYear = latestDate.getFullYear();
        }
      }
    }

    // Dynamic Sheet Naming matching MM-YYYY
    var mm = (reportMonth + 1) < 10 ? "0" + (reportMonth + 1) : (reportMonth + 1);
    var reportSheetName = "Monthly Report - " + mm + "-" + reportYear;
    var reportSheet = ss.getSheetByName(reportSheetName);
    if (reportSheet) {
      reportSheet.clear();
      reportSheet.clearConditionalFormatRules();
    } else {
      reportSheet = ss.insertSheet(reportSheetName);
    }

    // Calculate total days dynamically for this exact month (28, 29, 30, or 31)
    var numDaysInMonth = new Date(reportYear, reportMonth + 1, 0).getDate();

    // Group logs by Employee and Day of the month
    var employees = {};

    // First Pass: Collect all unique employees who have ever logged attendance
    for (var i = 0; i < rawValues.length; i++) {
      var row = rawValues[i];
      var empId = String(row[2]).trim();
      var name = String(row[3]).trim();
      var designation = String(row[5]).trim();

      if (!empId || empId === "N/A" || empId === "Employee ID" || empId === "undefined") continue;

      if (!employees[empId]) {
        employees[empId] = {
          empId: empId,
          name: name,
          designation: designation,
          days: {} // Day 1 to N calendar grid
        };

        // Seed days grid with default 'A' (Absent) values
        for (var d = 1; d <= numDaysInMonth; d++) {
          employees[empId].days[d] = { checkIn: "—", checkOut: "—", status: "A" };
        }
      } else {
        // Keep the latest non-empty designation or name
        if (name && name !== "N/A") employees[empId].name = name;
        if (designation && designation !== "N/A") employees[empId].designation = designation;
      }
    }

    // Second Pass: Populate logs specifically for the target month
    for (var i = 0; i < rawValues.length; i++) {
      var row = rawValues[i];
      var dateCell = row[0];
      var timeCell = row[1];
      var empId = String(row[2]).trim();
      var type = String(row[6]).toUpperCase().trim();

      if (!empId || !employees[empId]) continue;

      // Robustly parse the log's date and check if it belongs to the report's month and year
      var dateObj = parseDateRobustly(dateCell);
      if (!dateObj) continue;

      // Filter logs so that only records for the target month and year are processed
      if (dateObj.getMonth() !== reportMonth || dateObj.getFullYear() !== reportYear) {
        continue;
      }

      var day = dateObj.getDate();
      var dayData = employees[empId].days[day];

      var timeStr = String(timeCell);
      if (timeCell instanceof Date) {
        timeStr = timeCell.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      }

      if (type === "CHECK IN") {
        dayData.checkIn = timeStr;
        if (dayData.status !== "F") {
          // Parse time to check if late (after 9:50 AM)
          var hours = 0;
          var minutes = 0;
          if (timeCell instanceof Date) {
            hours = timeCell.getHours();
            minutes = timeCell.getMinutes();
          } else {
            // Parse string like "09:55:00 AM" or "10:15" or "14:30"
            var timeMatches = String(timeCell).match(/(\d+):(\d+)(?::(\d+))?\s*(AM|PM)?/i);
            if (timeMatches) {
              hours = parseInt(timeMatches[1], 10);
              minutes = parseInt(timeMatches[2], 10);
              var ampm = timeMatches[4];
              if (ampm && ampm.toUpperCase() === "PM" && hours < 12) hours += 12;
              if (ampm && ampm.toUpperCase() === "AM" && hours === 12) hours = 0;
            }
          }

          var isLate = hours > 9 || (hours === 9 && minutes > 50);
          dayData.status = isLate ? "L" : "P";
        }
      } else if (type === "CHECK OUT") {
        dayData.checkOut = timeStr;
        if (dayData.status !== "F" && dayData.status !== "L") {
          dayData.status = "P"; // Marked Present if not already marked Late or Forgot checkout
        }
      } else if (type === "CHECK OUT (AUTO)") {
        dayData.checkOut = timeStr;
        dayData.status = "F"; // Auto check out / Forgot check out
      }
    }

    // Create beautiful merged double headers
    var headersRow1 = ["Employee ID", "Name", "Designation"];
    var headersRow2 = ["", "", ""];

    for (var d = 1; d <= numDaysInMonth; d++) {
      var dateHeader = formatGridDate(d, reportMonth, reportYear);
      headersRow1.push(dateHeader, "", ""); // Merged Date Header (dd/MM/yyyy)
      headersRow2.push("In", "Out", "Status");
    }

    reportSheet.appendRow(headersRow1);
    reportSheet.appendRow(headersRow2);

    // Merge Day headers in Row 1 horizontally across 3 columns
    for (var d = 1; d <= numDaysInMonth; d++) {
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

      for (var d = 1; d <= numDaysInMonth; d++) {
        var dayGrid = emp.days[d];
        rowData.push(dayGrid.checkIn, dayGrid.checkOut, dayGrid.status);
      }
      rowDataList.push(rowData);
    }

    if (rowDataList.length > 0) {
      reportSheet.getRange(3, 1, rowDataList.length, 3 + numDaysInMonth * 3).setValues(rowDataList);
    }

    // --- Styling and Premium Formatting ---
    var totalCols = 3 + numDaysInMonth * 3;
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

    // Alignment and formatting settings
    if (totalRows > 2) {
      reportSheet.getRange(3, 1, totalRows - 2, 3).setHorizontalAlignment("left"); // Info columns
      
      var gridDataRange = reportSheet.getRange(3, 4, totalRows - 2, totalCols - 3);
      gridDataRange.setHorizontalAlignment("center"); // Timing & status columns
      gridDataRange.setFontWeight("bold"); // Statically make all timing & status values bold!
    }

    // Freeze Headers and employee details columns for high-fidelity scroll experience
    reportSheet.setFrozenRows(2);
    reportSheet.setFrozenColumns(3);

    // Resize columns
    reportSheet.autoResizeColumns(1, 3);
    for (var col = 4; col <= totalCols; col++) {
      reportSheet.setColumnWidth(col, 68); // standard compact width for timestamps & status
    }

    // --- Automatic Conditional Rules Formatting ---
    if (totalRows > 2) {
      var statusRange = reportSheet.getRange(3, 1, totalRows - 2, totalCols);

      // 'P' (Present) -> Soft Green Background
      var ruleP = SpreadsheetApp.newConditionalFormatRule()
        .whenTextEqualTo("P")
        .setBackground("#e6f4ea")
        .setFontColor("#137333")
        .setRanges([statusRange])
        .build();

      // 'F' (Forgot Checkout) -> Soft Red Background
      var ruleF = SpreadsheetApp.newConditionalFormatRule()
        .whenTextEqualTo("F")
        .setBackground("#fce8e6")
        .setFontColor("#c5221f")
        .setRanges([statusRange])
        .build();

      // 'A' (Absent) -> Soft Muted Gray Background
      var ruleA = SpreadsheetApp.newConditionalFormatRule()
        .whenTextEqualTo("A")
        .setBackground("#f1f3f4")
        .setFontColor("#5f6368")
        .setRanges([statusRange])
        .build();

      // 'L' (Late Check-in) -> Soft Orange/Yellow Background
      var ruleL = SpreadsheetApp.newConditionalFormatRule()
        .whenTextEqualTo("L")
        .setBackground("#fff3e0")
        .setFontColor("#e65100")
        .setRanges([statusRange])
        .build();

      var rules = reportSheet.getConditionalFormatRules();
      rules.push(ruleP);
      rules.push(ruleL);
      rules.push(ruleF);
      rules.push(ruleA);
      reportSheet.setConditionalFormatRules(rules);
    }

    try {
      SpreadsheetApp.getUi().alert("Success: Monthly Attendance Grid Report Register generated successfully!");
    } catch (uiError) {
      Logger.log("Report generated successfully in background.");
    }
  }
