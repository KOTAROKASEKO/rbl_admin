import 'package:cloud_firestore/cloud_firestore.dart';

class couponCloudService{
  
  static Future<void> addCouponToAllUsers(String couponId) async {
    try{
      FirebaseFirestore firestore = FirebaseFirestore.instance;
    final usersCollection = firestore.collection('userData');

    // Fetch all users
    final QuerySnapshot usersSnapshot = await usersCollection.get();

    // Iterate and add coupon
    WriteBatch batch = firestore.batch();
    for (var userDoc in usersSnapshot.docs) {
      DocumentReference userCouponRef = userDoc.reference.collection('coupons').doc(couponId);
      batch.set(userCouponRef, {'isUsed': false});
    }
    // Commit batch
    await batch.commit();
    print("Coupon added to all users");

    }catch(e){
      print('error happened during adding to users${e}');
    }
  }
}