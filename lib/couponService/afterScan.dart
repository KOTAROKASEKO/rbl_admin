import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rbl_admin/firebaseApi/FirebaseApi.dart';

// ignore: must_be_immutable
class afterScan extends StatefulWidget {
  String code;
  afterScan({required this.code});
  afterScanState createState() => afterScanState();
}

class afterScanState extends State<afterScan> {
  late String couponId;//couponId
  late String userId;//userId
  int? discountAmount;
  String? discountType;
  bool isLoading = true;
  bool isValidCode = false;
  DateTime? expiryDate;
  String invalidReason = '';


  TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    breakDownCode();
    fetchCouponDetails(couponId);
  }

  Future<void> redeemCoupon() async {

    try{
      DocumentReference reference = FirebaseFirestore.instance.collection('userData').doc(userId).collection('coupons').doc(couponId);
      reference.update({
        'isUsed':true,
      });
      DocumentReference coupons = FirebaseFirestore.instance.collection('coupons').doc(couponId);
      coupons.update({
        'whoUsed': FieldValue.arrayUnion([userId]),
      });
      showDialog(context: context, builder: (context) {
        return Container(
          child: Image.asset('assets/confirm.jpeg'),
        );
      },);
    }catch(e){
      print('failed to redeem the coupon');
    }
  }

  Future<String?> getFcmToken() async {
    try {
      // Firestoreから指定されたIDのドキュメントを取得
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('userData')
          .doc(userId)
          .get();

      // ドキュメントデータが存在するか確認
      if (snapshot.exists && snapshot.data() != null) {
        String? fcmToken = snapshot.data()!['token'] as String?;
        Firebaseapi.sendNotificationToAdmins('coupon was used!', 'happy to see you!', userId);
        return fcmToken;
      } else {
        print('ドキュメントが存在しません');
        return null;
      }
    } catch (e) {
      // エラー処理
      print('エラーが発生しました: $e');
      return null;
    }
  }

  int calculateFinalPrice(String originalPriceString, int? value, String? type) {
    if (originalPriceString.isEmpty || value == null || type == null) {
      return 0; // Default to 0 if inputs are invalid
    }

    try {
      int originalPrice = int.parse(originalPriceString);
      int amount = value;

      if (type == 'ratio discount') {
        // Calculate percentage discount
        return (originalPrice * (100 - amount) ~/ 100); // Integer division
      } else {
        // Subtract fixed amount
        return originalPrice - amount;
      }
    } catch (e) {
      print('Error in calculation: $e');
      return 0; // Default to 0 if parsing fails
    }
  }

  void breakDownCode() {
    List<String> ids = widget.code.split('_'); // Extract individual IDs String
    couponId = ids[0];
    userId = ids[1];
    print('id1 is $couponId and id2 is $userId');
  }

  Future<bool> validity(String link) async{
    try{
      DocumentSnapshot _collection = await FirebaseFirestore.instance
          .collection('userData')
          .doc(userId)
          .collection('coupons')
          .doc(couponId)
          .get();

      DateTime now = DateTime.now();
      bool isUsed = _collection['isUsed'] ?? false;
      if (now.isBefore(expiryDate!) && !isUsed) {
        setState(() {
          isValidCode = true;
          isLoading = false;
        });
        return true;
      } else {
        if(!(now.isBefore(expiryDate!))){
          invalidReason = 'it has expired already!';
        }else if(isUsed){
          invalidReason = 'the coupon was already used';
        }
        setState(() {
          invalidReason;
          isValidCode = false;
          isLoading = false;
        });
        return false;
      }
    }catch(e){
      print('error happened during getting coupon data:$e');
      return false;
    }
  }

  Future<void> fetchCouponDetails(String id) async {
    try {
      DocumentSnapshot _collection = await FirebaseFirestore.instance.collection('coupons').doc(id).get(); 

      discountAmount = _collection['discountValue'];
      discountType = _collection['discountType'];
      expiryDate = (_collection['validUntil'] as Timestamp).toDate();

      await validity(couponId);
    } catch (e) {
      print('Error fetching coupon details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    if(isLoading){
      return Scaffold(body:Center(child:CircularProgressIndicator()));
      //finish loading but the code is invalid
    }else if(!isLoading&&!isValidCode){
      return Scaffold(body:Center(child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
          children:[Text('coupon is invalid'),Text(invalidReason)]),));
    }else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Coupon Data'),
        ),
        body: Center(
            child: widget.code == '' || discountAmount == null ||
                discountType == null
                ? const Text('Unknown error occurred')
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Discount: $discountAmount'),
                      discountType == 'subtraction'
                          ? const Text('RM Discount')
                          : const Text('% Discount'),
                    ],
                  ),
                  Padding(
                    padding: (EdgeInsets.all(10)),
                    child: TextField(
                      controller: _priceController,
                      decoration: InputDecoration(
                          hintText: 'Enter the original price'),
                      onChanged: (value) {
                        setState(() {});
                      },
                      keyboardType: TextInputType
                          .number, // Allow only numeric input
                    ),),
                  SizedBox(height: 10),
                  Text(
                    'Final price: ${calculateFinalPrice(
                        _priceController.text, discountAmount, discountType)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    child: Container(
                      width: 200,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        color: Colors.blue,
                      ),
                      child: Center(child: Text('redeem')),
                    ),
                    onTap: () async {
                      await redeemCoupon();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            )),
      );
    }
  }
}
