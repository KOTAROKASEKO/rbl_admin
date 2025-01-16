import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rbl_admin/USER%20ID/userId.dart';

class Firebaseapi {
  
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initNotification() async {
    
    await _firebaseMessaging.requestPermission();
    final FCMToken = await _firebaseMessaging.getToken();
    print('FCMToken: $FCMToken');
    FirebaseFirestore.instance.collection('userData').doc(AccountId.userId).set({'token': FCMToken}, SetOptions(merge: true));
  }

  static Future<void> sendNotificationToAdmins(String title, String body, String targetUid) async {
  try {
    // Fetch admin tokens
    final String token = await fetchTargetUserTokens(targetUid);

    // Loop through each token and send a notification
    await sendPushMessage(token, title, body);
    
    print('Notifications sent to all admins');
  } catch (e) {
    print('Error sending notifications to admins: $e');
  }
}

  static Future<String> fetchTargetUserTokens(String targetUserId) async {
      try {
        String fcmToken ='';
        DocumentSnapshot reference = await FirebaseFirestore.instance.collection('userData').doc(targetUserId).get();
        fcmToken = reference['token'];
        return fcmToken;
      }catch(e){
        print('error happened during the fetch : $e');
        return 'error';
      }
    }

  static Future<void> sendPushMessage(String token, String title, String body) async {

    final jsonString = await rootBundle.loadString('assets/firebase-adminsdk.json');
    final jsonKey = jsonDecode(jsonString);
    final credentials = ServiceAccountCredentials.fromJson(jsonKey);
    // Define the required Google API scopes for FCM
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    // Create an authenticated client using OAuth 2.0
    AuthClient authClient = await clientViaServiceAccount(credentials, scopes);

    // Firebase Cloud Messaging HTTP v1 URL (replace YOUR_PROJECT_ID)
    const url = 'https://fcm.googleapis.com/v1/projects/rblmalaysia/messages:send';

    // Create the payload for the notification
    final payload = {
      'message': {
        'token': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'message': 'There is an update in reservation!'
        },
      },
    };

    // Send the HTTP POST request
    final response = await authClient.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    // Handle the response
    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification: ${response.body}');
    }

    // Close the authenticated client
    authClient.close();
  }
}
