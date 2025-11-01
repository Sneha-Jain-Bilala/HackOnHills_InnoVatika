import 'dart:async';
import 'dart:convert';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:innovatika/database/informer_hardware.dart';
import 'package:innovatika/database/informer_plant.dart';
import 'package:innovatika/widget/appbar.dart';
import 'package:innovatika/widget/loading.dart';
import 'package:intl/intl.dart';
import 'package:realm/realm.dart';

class ViewDevice extends StatefulWidget {
  final Hardware hardware;
  const ViewDevice({super.key, required this.hardware});

  @override
  State<ViewDevice> createState() => _ViewDeviceState();
}

class _ViewDeviceState extends State<ViewDevice> {
  int moisture = 0;
  double temperature = 0;
  double humidity = 0;
  Timer? _timer;
  bool isLoading = true;
  late var jsonData;
  String _message = "Moderately Wet";

  String moistureToPercentage(int rawValue) {
    // Define your calibrated min/max values from the dry/wet tests
    const int dryValue = 3000; // Sensor reading in completely dry soil
    const int wetValue = 1500; // Sensor reading in water

    // Constrain the input value to the calibrated range
    int constrainedValue = rawValue.clamp(wetValue, dryValue);

    // Map the value to percentage (0-100%)
    // Note: We invert the percentage since higher sensor values mean lower moisture
    int percentage =
        ((dryValue - constrainedValue) / (dryValue - wetValue) * 100).round();

    // Constrain to 0-100 range and return with % symbol
    return percentage.clamp(0, 100).toString() + "%";
  }

  Future<PlantInformer?> fetchPlantById(int plantId) async {
    // Open a Realm instance
    var config =
        await Realm.open(Configuration.local(([PlantInformer.schema])));

    // Fetch the plant with the given ID from MongoDB Realm
    var plant = config.find<PlantInformer>(plantId);
    return plant;
  }

  Future<void> _fetchFromSheet() async {
    try {
      final response = await http.get(
        Uri.parse(
            "https://script.google.com/macros/s/AKfycbzoO_SOCkgTWcRVDM7_ThDG_eycGDlhuo1HPiPf3dfIbadwagZb8D8ltpmMWCrAXpwH7g/exec?apiKey=sWs3PQl051D7WtKBYSzpdQV591YZEErV&deviceId=${widget.hardware.devName}&isFetch=True"),
      );
      if (response.statusCode == 200) {
        // Parse the latest two rows
        // For example, parse JSON and extract the needed columns

        setState(() {
          jsonData = jsonDecode(response.body);
          moisture = int.parse(jsonData["data"][0]["moisture"].toString());
          temperature =
              double.parse(jsonData["data"][0]["temperature"].toString());
          humidity = double.parse(jsonData["data"][0]["humidity"].toString());
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      // Handle error
    }
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _fetchFromSheet());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (moisture > 1400 && moisture < 1800) {
      _message = "Very Wet";
    } else if (moisture > 1801 && moisture < 2100) {
      _message = "Moderately Wet";
    } else if (moisture > 2101 && moisture < 2400) {
      _message = "Moderately Moist";
    } else if (moisture > 2401 && moisture < 2700) {
      _message = "Dry";
    } else if (moisture > 2701 && moisture < 3200) {
      _message = "Very Dry";
    }
    return Scaffold(
      appBar: commonApp(
        context: context,
        title: widget.hardware.name,
      ),
      body: FutureBuilder(
        future: fetchPlantById(widget.hardware.plantAssociated),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return emptyLoading("No Plants found");
          }
          if (snapshot.hasData) {
            var plant = snapshot.data;
            if (plant == null) {
              return emptyLoading("No Plants found");
            }
            // if (widget.hardware.id == widget.hardware.plantAssociated) {
            return isLoading
                ? LoadingDeviceAnimation()
                : ListView(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Card(
                                color: Colors.green.shade50,
                                elevation: 5,
                                shadowColor: Colors.black54,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            child: Image.asset(
                                              'assets/images/soil_m.png',
                                              fit: BoxFit.cover,
                                              width: 50,
                                              height: 50,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    "${moistureToPercentage(moisture)}",
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'BebasNeue',
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                SizedBox(height: 5),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'MOISTURE',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'BebasNeue',
                                          letterSpacing: 1,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Card(
                                color: Colors.green.shade50,
                                elevation: 5,
                                shadowColor: Colors.black54,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          transform: Matrix4.translationValues(
                                              -10.0, 0.0, 0.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            child: Image.asset(
                                              'assets/images/drop_r.png',
                                              fit: BoxFit.cover,
                                              width: 70,
                                              height: 70,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                transform:
                                                    Matrix4.translationValues(
                                                        -10.0, 0.0, 0.0),
                                                child: AnimatedRadialGauge(
                                                  duration: const Duration(
                                                      seconds: 1),
                                                  curve: Curves.elasticOut,
                                                  radius: 80,
                                                  value: humidity,
                                                  axis: GaugeAxis(
                                                      min: 0,
                                                      max: 100,
                                                      degrees: 180,
                                                      style:
                                                          const GaugeAxisStyle(
                                                        thickness: 20,
                                                        background:
                                                            Color(0xFFDFE2EC),
                                                        segmentSpacing: 4,
                                                      ),
                                                      pointer:
                                                          GaugePointer.needle(
                                                        width: 20,
                                                        height: 30,
                                                        borderRadius: 16,
                                                        color:
                                                            Color(0xFF193663),
                                                      ),
                                                      progressBar:
                                                          const GaugeProgressBar
                                                              .rounded(
                                                        color:
                                                            Colors.transparent,
                                                      ),
                                                      segments: [
                                                        const GaugeSegment(
                                                          from: 0,
                                                          to: 33.3,
                                                          color: Colors.green,
                                                          cornerRadius:
                                                              Radius.zero,
                                                        ),
                                                        const GaugeSegment(
                                                          from: 33.3,
                                                          to: 66.6,
                                                          color: Colors.orange,
                                                          cornerRadius:
                                                              Radius.zero,
                                                        ),
                                                        const GaugeSegment(
                                                          from: 66.6,
                                                          to: 100,
                                                          color: Colors.red,
                                                          cornerRadius:
                                                              Radius.zero,
                                                        ),
                                                      ]),
                                                ),
                                              ),
                                              SizedBox(height: 5),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'HUMIDITY',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'BebasNeue',
                                          letterSpacing: 1,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Card(
                                color: Colors.green.shade50,
                                elevation: 5,
                                shadowColor: Colors.black54,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            child: Image.asset(
                                              'assets/images/temp.png',
                                              fit: BoxFit.cover,
                                              width: 70,
                                              height: 70,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    temperature
                                                            .toInt()
                                                            .toString()
                                                            .toUpperCase() +
                                                        "°C",
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'BebasNeue',
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                SizedBox(height: 5),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'TEMPERATURE',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'BebasNeue',
                                          letterSpacing: 1,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Card(
                                color: Colors.green.shade50,
                                elevation: 5,
                                shadowColor: Colors.black54,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            child: Image.asset(
                                              'assets/images/health.png',
                                              fit: BoxFit.cover,
                                              width: 50,
                                              height: 50,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    _message,
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'BebasNeue',
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                SizedBox(height: 5),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'HEALTH',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'BebasNeue',
                                          letterSpacing: 1,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border(
                            left: BorderSide(color: Colors.black),
                            right: BorderSide(color: Colors.black),
                            top: BorderSide(color: Colors.black),
                          ),
                        ),
                        margin: EdgeInsets.only(left: 18, right: 18),
                        child: Text(
                          "Historical Data",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 18, right: 18),
                        height: (MediaQuery.of(context).size.height / 2.4),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.black),
                            right: BorderSide(color: Colors.black),
                            bottom: BorderSide(color: Colors.black),
                          ),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: ScrollPhysics(),
                          itemCount: jsonData["data"].length,
                          itemBuilder: (context, index) {
                            var item = jsonData["data"][index];
                            return ListTile(
                              title: Text(
                                  "Moisture: ${moistureToPercentage(moisture)}"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Temperature: ${item["temperature"]}"),
                                  Text("Humidity: ${item["humidity"]}"),
                                ],
                              ),
                              trailing: Text(
                                DateFormat('yyyy-MM-dd – kk:mm').format(
                                  DateTime.parse(item["timestamp"]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        height: 50,
                      ),
                    ],
                  );
            // } else {
            //   return emptyLoading("Not Found!");
            // }
          } else {
            return LoadingDeviceAnimation();
          }
        },
      ),
    );
  }
}
