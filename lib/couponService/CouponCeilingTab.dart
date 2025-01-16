import 'package:flutter/material.dart';
import 'package:rbl_admin/couponService/CouponCreate.dart';
import 'package:rbl_admin/couponService/scanQRView.dart';

class CouponTab extends StatefulWidget{
  CouponTabView createState() => CouponTabView();
}

class CouponTabView extends State<CouponTab>{
  @override
  Widget build(BuildContext context) { 
    return MaterialApp( 
      home: DefaultTabController( 
      length: 3, // タブの数 
  child: Scaffold( 
    appBar: AppBar(
      title: Text('Coupon',style: TextStyle(fontFamily: 'juliousSans'),),
      bottom: const TabBar( 
        tabs: [ 
          Tab(
            icon: Icon(Icons.home), 
            child: Text('Make',style: TextStyle(fontFamily: 'juliousSans'))), 
          Tab(
            icon: Icon(Icons.qr_code_scanner_rounded), 
            child: Text('Scan',style: TextStyle(fontFamily: 'juliousSans'))), 
          Tab(
            icon: Icon(Icons.stacked_bar_chart), 
            child: Text('Statistic',style: TextStyle(fontFamily: 'juliousSans'))), 
            ], 
          ),
        ),
        body: TabBarView( 
          children: [ 
            const CouponCreateView(),
            QRcodeView(),
            const Center(child: Text('設定タブ')), 
            ], 
          ), 
        ), 
      ), 
    ); 
  }
}