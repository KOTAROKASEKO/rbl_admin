// U S E R   I D
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AccountId{

  // C U R R E N T   U S E R   I D 
  //===========================================
  static late String userId;
  //===========================================
  
static Future<void> initUserId() async {
  print('===========================================');
  print('= I N I T I A L I S I N G   U S E R   I D =');
  print('===========================================');
  final FirebaseAuth auth = FirebaseAuth.instance;

  if (auth.currentUser == null) {
    print('user is null');
    userId = '';
  } else {
    userId = auth.currentUser!.uid;
  }
}

  // T O G G L E    T O   S I G N   I N 
  static void setLoginStatusToSignedIn() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', true);
  }

  // T O G G L E   T O    S I G N E D   O U T
  static void setLoginStatusToSignedOut() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', false);
  }

  // L O G I N   S T A T U S   G E T T E R   
  static Future <bool> getUserLogInStatus() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn')??false;
    return isLoggedIn;
  }

  static Future<void> createUser() async{
    final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
    await _firebaseMessaging.requestPermission();
    final FCMToken = await _firebaseMessaging.getToken();
    final CollectionReference users = FirebaseFirestore.instance.collection('admins');

      return users .doc(userId) // ユーザーIDをドキュメントIDとして使用 
      .set({
        'uid': userId,
        'token':FCMToken,
      })
      .then((value) => print("User Added")) 
      .catchError((error) => print("Failed to add user: $error")); 
  }
}