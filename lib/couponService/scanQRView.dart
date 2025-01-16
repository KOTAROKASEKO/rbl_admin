import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rbl_admin/couponService/afterScan.dart';

import '../point/givePoint.dart';

class QRcodeView extends StatefulWidget{
  QRcodeViewState createState() => QRcodeViewState();
}

class QRcodeViewState extends State<QRcodeView>{
  Widget build(BuildContext context){
    return Scaffold(
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
        ),
        onDetect: (capture){
          print('detected!!: $capture');
          final List<Barcode> barcodes = capture.barcodes;
          final Uint8List? image = capture.image;

          for(final barcode in barcodes){
            print('${barcode.rawValue}');
          }
          try{
          if(image == null){
            bool? isQrCoupon = barcodes.first.rawValue?.contains('_');
            if(isQrCoupon!){
              print('the content of the qr code: ${barcodes.first.rawValue}');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => afterScan(code : barcodes.first.rawValue??''),
                ),
              );
            }else{
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => givePoint(code : barcodes.first.rawValue??''),
                ),
              );
              print('not a qr coupon');
            }

          }
          }catch(e){
            print('error happened during capture$e');
          }
        },
      ),
    );
  }
}