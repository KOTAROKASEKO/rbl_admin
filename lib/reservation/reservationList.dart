import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:rbl_admin/reservation/reservationDetail.dart';
import 'package:intl/intl.dart';

class Reservation {
  final String date;
  final String start;
  final String end;
  final String status;
  final String usedMachine;
  final String userId;
  final String reservationId;
  final String treatment;

  Reservation({
    required this.date,
    required this.start,
    required this.end,
    required this.status,
    required this.usedMachine,
    required this.userId,
    required this.reservationId,
    required this.treatment,
  });

  // Factory method to create a Reservation instance from Firestore data
  factory Reservation.fromFirestore(Map<String, dynamic> data, String id) {
    return Reservation(
      treatment: data['treatment'] ?? '',
      reservationId: id,
      date: data['date'] ?? '',
      start: data['start'] ?? '',
      end: data['end'] ?? '',
      status: data['status'] ?? '',
      usedMachine: data['usedMachine'] ?? '',
      userId: data['userId'] ?? '',
    );
  }
}

class ReservationListView extends StatefulWidget {
  @override
  _ReservationListViewState createState() => _ReservationListViewState();
}

class _ReservationListViewState extends State<ReservationListView> {
  final List<Reservation> reservations = [];
  final List<Reservation> filteredReservations =[];
  final List<String> statusOptions = ["pending", "confirmed", "declined",'Any',];
  bool isLoading = true;

  List<String> treatmentOptions = [
    'Any',
    'Hifu',
    'Hydrafacial',
    'Electroporation',
    'Collagenpealing',
    'Hair removal',
    'Botox',
    'Lemon Bottle',
    'Skin Booster',
    'PRP',
  ];

  //search condition===============
  String selectedDateTense = 'future';
  String selectedRadioOption = 'Any';
  String selectedTreatment = 'Any';
  String selectedStatus = 'Any';
  DateTime date = DateTime.now();
  //================================

  DateTime? selectedDate = null;

  @override
  void initState() {
    super.initState();
    fetchReservationsWithDefaultCondition(false);
  }

  Future<void> fetchReservationsWithDefaultCondition(bool isFiltering) async {
    try {
      setState(() {
        reservations.clear();
        filteredReservations.clear();
        isLoading=true;
      });
      if(selectedRadioOption == 'Any'){
        selectedDate=null;
      }
      final List<Reservation> fetchedReservations;
      if(isFiltering){
        var snapshot = await FirebaseFirestore.instance.collection('reservations')//if it is filtering, fetch entire query snapshot
          .get();
        fetchedReservations = snapshot.docs.map((doc) {
          var id = doc.id;
        return Reservation.fromFirestore(doc.data(), id);
      }).toList();
    }else{
      var snapshot = await FirebaseFirestore.instance.collection('reservations')
        .get();
      fetchedReservations = snapshot.docs.map((doc) {
        var id = doc.id;
        return Reservation.fromFirestore(doc.data(), id);
      }).toList();
    }
      setState(() {
        reservations.clear();
        reservations.addAll(fetchedReservations);
      });
      applyFilter();
    } catch (e) {
      print('Error fetching reservations: $e');
    }
  }


  void applyFilter() {
    String status;
    String? date;
    String treatment;

    // Debugging: Print initial values of the filter criteria
    print("Starting applyFilter with:");
    print("selectedDateTense: $selectedDateTense");
    print("selectedTreatment: $selectedTreatment");
    print("selectedDate: $selectedDate");
    print("selectedStatus: $selectedStatus");

    String? formattedSelectedDate;
    try {
      if (selectedDateTense != 'Any' && selectedDate != null) {
        final onlyDayFormat = DateFormat('yyyy-MM-dd');
        formattedSelectedDate = onlyDayFormat.format(selectedDate!);
      }
    } catch (e) {
      print("Error formatting selectedDate: $e");
    }

    for (var reservation in reservations) {
      status = reservation.status;
      date = '${reservation.date}-${reservation.start}';
      treatment = reservation.treatment;

      // Debugging: Print reservation details
      print("\nChecking reservation:");
      print("Status: $status, Date: $date, Treatment: $treatment");

      final dateFormat = DateFormat('yyyy-MM-dd-HH:mm');
      DateTime? parsedDate;
      DateTime? currentDate;
      final onlyDayFormat = DateFormat('yyyy-MM-dd');
      DateTime? parsedDayDate;

      try {
        parsedDate = dateFormat.parse(date);
        parsedDayDate = onlyDayFormat.parse(date);
        final formattedCurrentDate = dateFormat.format(DateTime.now());
        currentDate = dateFormat.parse(formattedCurrentDate);
      } catch (e) {
        print("Error parsing date: $date - $e");
        continue;
      }

      // Debugging: Print parsed dates
      print("Parsed Date: $parsedDate");
      print("Formatted Selected Date: $formattedSelectedDate");
      print("Current Date: $currentDate");

      if (selectedDateTense == 'future') {
        if ((selectedTreatment == treatment || selectedTreatment == 'Any') &&
            (parsedDate.isAfter(currentDate)) &&
            (formattedSelectedDate == null || formattedSelectedDate == onlyDayFormat.format(parsedDayDate)) &&
            (selectedStatus == status || selectedStatus == 'Any')) {
          print("Reservation matches 'future' criteria.");
          filteredReservations.add(reservation);
        } else {
          print("Reservation does not match 'future' criteria.");
          print('1::${(selectedTreatment == treatment || selectedTreatment == 'Any')}');
          print('2::${(parsedDate.isAfter(currentDate))}');
          print('3::${(formattedSelectedDate == null || formattedSelectedDate == onlyDayFormat.format(parsedDayDate))}');
          print('4::${(selectedStatus == status || selectedStatus == 'Any')}');
        }
      } else if (selectedDateTense == 'past') {
        print('$selectedDateTense was selected');
        if ((selectedTreatment == treatment || selectedTreatment == 'Any') &&
            (parsedDate.isBefore(currentDate)) &&
            (formattedSelectedDate == null || formattedSelectedDate == onlyDayFormat.format(parsedDayDate)) &&
            (selectedStatus == status || selectedStatus == 'Any')) {
          print("Reservation matches 'past' criteria.");
          filteredReservations.add(reservation);
        } else {
          print("Reservation does not match 'past' criteria.");
          print('1::${(selectedTreatment == treatment || selectedTreatment == 'Any')}');
          print('2::${(parsedDate.isBefore(currentDate))}');
          print('3::${(formattedSelectedDate == null || formattedSelectedDate == onlyDayFormat.format(parsedDayDate))}');
          print('4::${(selectedStatus == status || selectedStatus == 'Any')}');
        }
      } else if (selectedDateTense == 'Any') {
        if ((selectedTreatment == treatment || selectedTreatment == 'Any') &&
            (formattedSelectedDate == null || formattedSelectedDate == onlyDayFormat.format(parsedDayDate)) &&
            (selectedStatus == status || selectedStatus == 'Any')) {
          print("Reservation matches 'Any' criteria.");
          filteredReservations.add(reservation);
        } else {
          print("Reservation does not match 'Any' criteria.");
        }
      } else {
        print("Invalid selectedDateTense: $selectedDateTense");
      }
    } // End of for loop

    // Debugging: Print final filtered reservations
    print("Filtered Reservations: ${filteredReservations.length}");
    for (var res in filteredReservations) {
      print("Filtered Reservation: ${res.reservationId}");
    }

    setState(() {
      isLoading = false;
      filteredReservations;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservations'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    child: Container(
                      height: 400,
                      width: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 10),
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              return ListView(
                                children: [
                                  // Dropdown menu to pick status
                                  Container(
                                    child: Center(
                                      child: Text(
                                        'Select Status:',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    width: 50,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: selectedStatus,
                                    onChanged: (newValue) {
                                      setState(() {
                                        selectedStatus = newValue!;
                                      });
                                    },
                                    items: statusOptions
                                        .map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                  SizedBox(height: 20),
                                  // Radio buttons to choose future or past record
                                  Container(
                                    child: Center(
                                      child: Text(
                                        'Select time:',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    width: 50,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      RadioListTile<String>(
                                        title: Text('future'),
                                        value: 'future',
                                        groupValue: selectedDateTense,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedDateTense = value!;
                                          });
                                        },
                                      ),
                                      RadioListTile<String>(
                                        title: Text('past'),
                                        value: 'past',
                                        groupValue: selectedDateTense,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedDateTense = value!;
                                          });
                                        },
                                      ),
                                      RadioListTile<String>(
                                        title: Text('Any'),
                                        value: 'Any',
                                        groupValue: selectedDateTense,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedDateTense = value!;
                                          });
                                        },
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 20),

                                  // Toggle button to specify date
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        child: Center(
                                          child: Text(
                                            'Specify a day?',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        width: 150,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                      ),
                                      Switch(
                                        value: selectedRadioOption == 'Specific',
                                        onChanged: (value) {
                                          setState(() {
                                            selectedRadioOption = value ? 'Specific' : 'Any';
                                          });
                                        },
                                      ),
                                    ],
                                  ),

                                  // Show date picker button if toggle is on
                                  if (selectedRadioOption == 'Specific')
                                    ElevatedButton(
                                      onPressed: () async {
                                        final pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: date,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (pickedDate != date) {
                                          setState(() {
                                            selectedDate = pickedDate;
                                          });
                                        }
                                      },
                                      child: Text('Pick a Date'),
                                    ),


                                  SizedBox(height: 20),

                                  // Dropdown menu to pick treatment
                                  Text('Select Treatment:'),
                                  DropdownButton<String>(
                                    value: selectedTreatment,
                                    onChanged: (newValue) {
                                      setState(() {
                                        selectedTreatment = newValue!;
                                      });
                                    },
                                    items: treatmentOptions
                                        .map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),

                                  SizedBox(height: 20),

                                  // Apply button
                                  ElevatedButton(
                                    onPressed: () async{
                                      filteredReservations.clear();
                                      await fetchReservationsWithDefaultCondition(true);
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Apply Filters'),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: isLoading?
          Center(
            child: CircularProgressIndicator(),
          ):
      LiquidPullToRefresh(
        color: Colors.lightGreenAccent,
        animSpeedFactor: 20.0,
        onRefresh:() async{

          await fetchReservationsWithDefaultCondition(false);
          setState(() {

            reservations;
          });
        },
        child: reservationList(),
      ),
    );
  }

  Widget reservationList(){
    return filteredReservations.isEmpty?
    Center(
      child: Text('There is no reservation to show!',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
    )
    :
    ListView.builder(
      itemCount: filteredReservations.length,
      itemBuilder: (context, index) {
        print('there are ${filteredReservations.length}');
        final reservation = filteredReservations[index];
        return ListTile(
          onTap: (){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReservationDetailsPage(reservation: reservation,),
              ),
            );
          },
          leading: getIcon(reservation.status),
          title: Text('Treatment: ${reservation.treatment}'),
          subtitle: Text('${reservation.date} | ${reservation.start} - ${reservation.end}'),
          trailing: Text(reservation.status),
        );
      },
    );
  }
  Widget getIcon(String status){
    if(status == 'pending'){
      return Icon(Icons.alarm,color: Colors.deepPurpleAccent,);
    }else if(status == 'declined'){
      return Icon(Icons.cancel,color: Colors.amber,);
    }else if(status == 'deleted'){
      return Icon(Icons.delete, color: Colors.red,);
    }else if(status == 'confirmed'){
      return Icon(Icons.check_box, color: Colors.green,);
    }
    else{
      return Icon(Icons.error);
    }
  }
}
