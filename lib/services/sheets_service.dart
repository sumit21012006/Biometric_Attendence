import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biometric/models/attendance_record.dart';

class SheetsService {
  // Post attendance record details to Google Sheets web app URL
  Future<bool> sendRecordToSheet(String webAppUrl, AttendanceRecord record) async {
    if (webAppUrl.isEmpty) {
      print('Sheets Service: Web App URL is empty, skipping Sheet sync.');
      return false;
    }

    try {
      final Map<String, dynamic> payload = {
        'uid': record.uid,
        'name': record.name,
        'email': record.email,
        'designation': record.designation,
        'employeeId': record.employeeId,
        'timestamp': record.timestamp.toIso8601String(),
        'type': record.type,
        'deviceId': record.deviceId,
        'latitude': record.latitude,
        'longitude': record.longitude,
        'distance': record.distance,
        'verified': record.verified,
      };

      print('Sheets Service: Sending payload to $webAppUrl');
      
      final client = http.Client();
      final request = http.Request('POST', Uri.parse(webAppUrl))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(payload);
      request.followRedirects = false;

      final streamedResponse = await client.send(request);
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 302) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          print('Sheets Service: Following POST redirect to $redirectUrl');
          response = await http.post(
            Uri.parse(redirectUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          );
        }
      }
      
      client.close();

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['result'] == 'success') {
          print('Sheets Service: Data successfully synced to Google Sheet.');
          return true;
        } else {
          print('Sheets Service: Apps Script error: ${responseBody['error']}');
          return false;
        }
      } else {
        print('Sheets Service: Failed with HTTP status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Sheets Service: Network error syncing to Google Sheets: $e');
      return false;
    }
  }
}
