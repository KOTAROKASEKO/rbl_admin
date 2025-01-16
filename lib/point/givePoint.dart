import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: must_be_immutable
class givePoint extends StatefulWidget{
  final String code;
  givePoint({required this.code});
  givePointState createState() => givePointState();
}

class givePointState extends State<givePoint>{
  TextEditingController _priceController = TextEditingController();
  bool isLoading = false;

  Future<void> givePoint(int price) async{
    try{
      final uid = widget.code;

      final userDataRef = FirebaseFirestore.instance.collection('userData').doc(uid);
      final userDataSnapshot = await userDataRef.get();
      if (userDataSnapshot.exists) {
        final currentPurchasePoint = userDataSnapshot.data()?['purchasePoint'] ?? 0;
        final currentPoint = userDataSnapshot.data()?['point'] ?? 0;
        // Rate exchange between RBL point and RM
        final updatedPurchasePoint = currentPurchasePoint + price;
        final updatedPoint = currentPoint + price;

        await userDataRef.update({
          'purchasePoint': updatedPurchasePoint,
          'point':updatedPoint,
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Successfully gave $price points')
            ),
        );
      } else {
        await userDataRef.set({'purchasePoint': price});
      }
      Navigator.of(context).pop(); // Go back to previous screen
    }catch(e){
      print('Error giving point: $e');
    }
  }

  Widget build(BuildContext context){
    if(isLoading){
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }else {
      return Scaffold(
        appBar: AppBar(
          title: Text('Give Point'),
        ),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Please enter the price', style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20),),
                  SizedBox(height: 50,),
                  Padding(
                      padding: (EdgeInsets.symmetric(horizontal: 50)),
                      child: TextField(
                          keyboardType: TextInputType.number,

                          maxLines: 1,
                          controller: _priceController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(

                              borderRadius: BorderRadius.all(
                                  Radius.circular(10)),
                            ),
                            hintText: 'Enter the price',
                          ),
                          onChanged: (value) {
                            setState(() {});
                          }
                      )),
                  SizedBox(height: 50,),
                  GestureDetector(
                    onTap: () async {
                      int? price = int.parse(_priceController.text);
                      // ignore: unnecessary_null_comparison
                      if (price == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Please enter a valid price'))
                        );
                      } else {
                        setState(() {
                          isLoading = true;
                        });
                        await givePoint(price);
                      }
                    },
                    child: Container(
                      width: 200,
                      height: 50,
                      child: Center(
                        child: Text('Confrim', style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        color: Colors.blue,
                      ),
                    ),
                  )
                ]
            )
        ),
      );
    }
  }
}