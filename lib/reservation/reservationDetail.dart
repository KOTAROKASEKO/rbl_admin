import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:rbl_admin/firebaseApi/FirebaseApi.dart';
import 'package:rbl_admin/reservation/reservationList.dart';


class ReservationDetailsPage extends StatefulWidget {
  final Reservation reservation;

  const ReservationDetailsPage({Key? key, required this.reservation}) : super(key: key);

  @override
  _ReservationDetailsPageState createState() => _ReservationDetailsPageState();
}

class _ReservationDetailsPageState extends State<ReservationDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? name;
  String? gender;
  int? phoneNumber;
  DateTime? dob;
  String? status;
  String? id;
  String? treatment;
  String? usedMachine;
  String? DateOfReservation;
  String? startTime;
  String? reservationId;
  bool isLoading = false;

  Future<void> fetchData() async {
    try {
      final reservationDoc = await _firestore.collection('reservations').doc(widget.reservation.reservationId).get();
      final userDoc = await _firestore.collection('userData').doc(widget.reservation.userId).get();

      if (reservationDoc.exists && userDoc.exists) {

        setState(() {
          name = userDoc.data()?['name'];
          id = userDoc.data()?['userId'];
          phoneNumber = userDoc.data()?['phoneNum'];
          gender = userDoc.data()?['gender'];
          dob = (userDoc.data()?['dob'] as Timestamp?)?.toDate();
          status = reservationDoc.data()?['status'];
          treatment = reservationDoc.data()?['treatment'];
          DateOfReservation = reservationDoc.data()?['date'];
          startTime = reservationDoc.data()?['start'];
          usedMachine = reservationDoc.data()?['usedMachine'];
          reservationId = reservationDoc.id;
        });

      } else {
        print('Reservation or user data not found.');
        // Consider showing an error message to the user
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> cancelSameRequest() async{

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('reservations')
      .where('usedMachine', isEqualTo: usedMachine)
      .where('date', isEqualTo: DateOfReservation)
      .where('start', isEqualTo: startTime)
      .where('status',isEqualTo: 'pending')
      .get();

    for (var doc in snapshot.docs) {
      if(!(doc.id == reservationId)){
        cancelReservation(doc.id);
      }
    }
  }
  

  Future<void> confirmReservation(String reservationid) async {
    try {
      setState(() {
        isLoading=true;
      });
      
      await _firestore
          .collection('reservations')
          .doc(reservationid)
          .update({'status': 'confirmed'});

      await Firebaseapi.sendNotificationToAdmins('Reservation', 'Your Reservation was confirmed', id!);
      //cancell reservation that was made for the same slot, same time, sane nachine
      await cancelSameRequest();
      Navigator.of(context).pop();
    } catch (e) {
      print('Error confirming reservation: $e');
      // Consider showing an error message to the user
    }
  }

  Future<void> cancelReservation(String reservationid) async {
    try {
      
      await _firestore
          .collection('reservations')
          .doc(reservationid)
          .update({'status': 'declined'});
          await Firebaseapi.sendNotificationToAdmins('Request declined', 'We are sorry, we couldn\'t confirm your reservation', id!);
      
    } catch (e) {
      print('Error confirming reservation: $e');
      // Consider showing an error message to the user
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Widget _buildUserDetailsRow(String title, String? value) {
    return Row(children: [Text('$title: $value')]);
  }

  Widget _buildUserDetailsSection() {
    return Column(children: [
      const Text('About the user'),
      _buildUserDetailsRow('Name', name),
      _buildUserDetailsRow('Gender', gender),
      _buildUserDetailsRow('Phone Number', phoneNumber.toString()),
      _buildUserDetailsRow('Date of Birth', dob.toString()),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Details'),
      ),
      body:isLoading?
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            Text('trying to update'),
          ],
        ),
      )
      :
      LiquidPullToRefresh(
        onRefresh: fetchData,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(children: [Text('Machine: ${widget.reservation.usedMachine}', style: const TextStyle(fontSize: 20))]),
                Row(children: [Text('Date: ${widget.reservation.date}', style: const TextStyle(fontSize: 20))]),
                Row(children: [Text('Start Time: ${widget.reservation.start}', style: const TextStyle(fontSize: 20))]),
                Row(children: [Text('End Time: ${widget.reservation.end}', style: const TextStyle(fontSize: 20))]),
                _buildUserDetailsSection(),
                Row(children: [Text('Status: ${widget.reservation.status}', style: const TextStyle(fontSize: 20))]),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:[
                  GestureDetector(
                  child: Container(
                    width: 100,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(child: Text('Confirm')),
                  ),
                  onTap: () async {
                    showDialog(
                      context: context, // Ensure you have access to the context
                      builder: (BuildContext context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            width: 200,
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 10),
                                Text('Warning!',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                                Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Text(
                                    'Confirming this reservation will cancel other reservations that use same machine at same time, same day',
                                    textAlign: TextAlign.center,
                                    maxLines: 5,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).pop(); // Close the dialog on 'No'
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.amberAccent,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        padding: EdgeInsets.all(10),
                                        child: Text(
                                          'No',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        await confirmReservation(widget.reservation.reservationId);
                                        Navigator.of(context).pop(); // Close the dialog on 'Yes'
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color.fromARGB(255, 142, 177, 255),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        padding: EdgeInsets.all(10),
                                        child: Text(
                                          'Yes',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                  GestureDetector(
                    child: Container(
                      width: 100,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(child: Text('cancel')),
                    ),
                    onTap: () async{
                      await cancelReservation(widget.reservation.reservationId);
                      Navigator.of(context).pop();
                    },
                  ),
                ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}