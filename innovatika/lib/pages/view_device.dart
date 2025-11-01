import 'dart:async';
import 'dart:convert';
import 'dart:ui'; // Import for ImageFilter
import 'package:gauge_indicator/gauge_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:innovatika/database/informer_hardware.dart';
import 'package:innovatika/database/informer_plant.dart';
import 'package:innovatika/widget/appbar.dart';
import 'package:innovatika/widget/loading.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart'; // Import for Lottie
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
  var jsonData; // CHANGED: Removed 'late' to allow for null checks before initialization.
  String _message = "Moderately Wet";

  // Define earthy/pastel text colors (consistent with other files)
  static const Color _darkBrown = Color(0xFF4E342E);
  static const Color _mediumBrown = Color(0xFF6D4C41);
  static const Color _darkGreen = Color(0xFF2E7D32);
  static const Color _lightPastelGreen = Color(0xFFA5D6A7);
  static const Color _lightBlue = Color(0xFF0277BD);
  static const Color _lightRed = Color(0xFFC62828);

  // New function to return a double for the gauge
  double moistureToPercentage(int rawValue) {
    // Define your calibrated min/max values from the dry/wet tests
    const int dryValue = 3000; // Sensor reading in completely dry soil
    const int wetValue = 1500; // Sensor reading in water

    // Constrain the input value to the calibrated range
    int constrainedValue = rawValue.clamp(wetValue, dryValue);

    // Map the value to percentage (0-100%)
    // Note: We invert the percentage since higher sensor values mean lower moisture
    double percentage =
        ((dryValue - constrainedValue) / (dryValue - wetValue) * 100);

    // Constrain to 0-100 range and return
    return percentage.clamp(0, 100);
  }

  Future<PlantInformer?> fetchPlantById(int plantId) async {
    // Open a Realm instance
    var config = await Realm.open(
      Configuration.local(([PlantInformer.schema])),
    );

    // Fetch the plant with the given ID from MongoDB Realm
    var plant = config.find<PlantInformer>(plantId);
    return plant;
  }

  Future<void> _fetchFromSheet() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://script.google.com/macros/s/AKfycbzoO_SOCkgTWcRVDM7_ThDG_eycGDlhuo1HPiPf3dfIbadwagZb8D8ltpmMWCrAXpwH7g/exec?apiKey=sWs3PQl051D7WtKBYSzpdQV591YZEErV&deviceId=${widget.hardware.devName}&isFetch=True",
        ),
      );
      if (response.statusCode == 200) {
        // Parse the latest two rows
        if (mounted) {
          setState(() {
            jsonData = jsonDecode(response.body);
            moisture = int.parse(jsonData["data"][0]["moisture"].toString());
            temperature = double.parse(
              jsonData["data"][0]["temperature"].toString(),
            );
            humidity = double.parse(jsonData["data"][0]["humidity"].toString());

            // Set loading to false *after* first successful fetch
            if (isLoading) {
              isLoading = false;
            }
          });
        }
      }
    } catch (e) {
      print(e);
      // Handle error
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch immediately on init
    _fetchFromSheet();
    // Then set the timer
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _fetchFromSheet());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Helper to get Lottie animation based on health
  String _getHealthAnimation(String message) {
    switch (message) {
      case "Very Wet":
        // Assuming you have a lottie file for "too much water"
        return "assets/animation/watering-plant.json";
      case "Dry":
      case "Very Dry":
        // Assuming you have a lottie file for a sad/dry plant
        return "assets/animation/sad-plant.json";
      case "Moderately Wet":
      case "Moderately Moist":
      default:
        // Assuming you have a lottie file for a happy plant
        return "assets/animation/happy-plant.json";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update health message
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

    double moisturePercent = moistureToPercentage(moisture);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // Pastel garden gradient
          colors: [
            Color(0xFFE8F5E9), // Pastel Green
            Color(0xFFFFFDE7), // Pastel Yellow/Cream
            Color(0xFFE3F2FD), // Pastel Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Make scaffold transparent
        extendBodyBehindAppBar: true, // Extend body behind app bar
        appBar: commonApp(context: context, title: widget.hardware.name),
        body: FutureBuilder(
          future: fetchPlantById(widget.hardware.plantAssociated),
          builder: (context, snapshot) {
            if (isLoading) {
              // Use the glassmorphism loader
              return _buildAnimatedLoader();
            }

            if (!snapshot.hasData && !isLoading) {
              return Center(
                child: _buildGlassInfoCard(
                  child: Text(
                    "No Plant Associated",
                    style: TextStyle(
                      color: _darkBrown,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasData) {
              var plant = snapshot.data;
              if (plant == null) {
                return Center(
                  child: _buildGlassInfoCard(
                    child: Text(
                      "Plant Not Found",
                      style: TextStyle(
                        color: _darkBrown,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }

              return SafeArea(
                child: ListView(
                  padding: EdgeInsets.all(12),
                  children: [
                    // Animated Grid for sensor data
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9, // Adjust aspect ratio
                      children: [
                        // Moisture Card
                        _buildGlassCard(
                          title: "Moisture",
                          icon: 'assets/images/soil_m.png',
                          child: _buildMoistureGauge(moisturePercent),
                        ),

                        // Humidity Card
                        _buildGlassCard(
                          title: "Humidity",
                          icon: 'assets/images/drop_r.png',
                          child: _buildHumidityGauge(humidity),
                        ),

                        // Temperature Card
                        _buildGlassCard(
                          title: "Temperature",
                          icon: 'assets/images/temp.png',
                          child: _buildTemperatureDisplay(temperature),
                        ),

                        // Health Card
                        _buildGlassCard(
                          title: "Health",
                          icon: 'assets/images/health.png',
                          child: _buildHealthDisplay(_message),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Historical Data
                    _buildGlassCard(
                      title: "Historical Data",
                      child: Container(
                        height: (MediaQuery.of(context).size.height / 2.5),
                        // CHANGED: This null check is now safe because jsonData is no longer 'late'
                        child: jsonData == null
                            ? Center(
                                child: Text(
                                  "No history",
                                  style: TextStyle(color: _mediumBrown),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: jsonData["data"].length,
                                itemBuilder: (context, index) {
                                  var item = jsonData["data"][index];
                                  double histMoisture = moistureToPercentage(
                                    int.parse(item["moisture"].toString()),
                                  );
                                  return ListTile(
                                    leading: Icon(
                                      Icons.history,
                                      color: _darkBrown,
                                    ),
                                    title: Text(
                                      "Moisture: ${histMoisture.toStringAsFixed(0)}%",
                                      style: TextStyle(
                                        color: _darkBrown,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Temp: ${item["temperature"]}°C  |  Humidity: ${item["humidity"]}%",
                                      style: TextStyle(color: _mediumBrown),
                                    ),
                                    trailing: Text(
                                      DateFormat('kk:mm').format(
                                        DateTime.parse(item["timestamp"]),
                                      ),
                                      style: TextStyle(color: _mediumBrown),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Fallback loader
              return _buildAnimatedLoader();
            }
          },
        ),
      ),
    );
  }

  // --- Reusable Glassmorphism Widgets ---

  Widget _buildGlassInfoCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    String? icon,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Card Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) Image.asset(icon, width: 50, height: 50),
                  if (icon != null) SizedBox(width: 8),
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      color: _darkBrown,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'BebasNeue',
                      letterSpacing: 1,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              // Card Body
              // Place the child without flex so the card can shrink-wrap when
              // used inside scrollable/unbounded parents.
              Align(alignment: Alignment.center, child: child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLoader() {
    return LottieBuilder.asset("assets/animation/3-step-plant.json");
  }

  // --- Specific Card Content Widgets ---

  Widget _buildMoistureGauge(double value) {
    // value is 0-100
    Color barColor;
    if (value < 30) {
      barColor = _lightRed;
    } else if (value < 70) {
      barColor = _lightPastelGreen;
    } else {
      barColor = _lightBlue;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // CHANGED: Keep the bar at a fixed height and allow its width to
        // animate according to available width. Avoid using Flexible here so
        // the parent can remain shrink-wrapped in unbounded containers.
        LayoutBuilder(
          builder: (context, constraints) {
            final double maxW = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;
            final double barWidth = maxW * (value / 100);
            return Container(
              // Background of the bar
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFDFE2EC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  // Animated bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    width: barWidth < 0 ? 0 : barWidth,
                    height: 20,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        SizedBox(height: 10),
        Text(
          "${value.toStringAsFixed(0)}%",
          style: TextStyle(
            color: _darkBrown,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'BebasNeue',
          ),
        ),
      ],
    );
  }

  Widget _buildHumidityGauge(double value) {
    return AnimatedRadialGauge(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      radius: 100,
      value: value,
      axis: GaugeAxis(
        min: 0,
        max: 100,
        degrees: 180,
        style: const GaugeAxisStyle(
          thickness: 20,
          background: Color(0xFFDFE2EC),
          segmentSpacing: 4,
        ),
        pointer: GaugePointer.needle(
          width: 20,
          height: 30,
          borderRadius: 16,
          color: _darkBrown,
        ),
        progressBar: const GaugeProgressBar.rounded(color: Colors.transparent),
        segments: [
          GaugeSegment(
            from: 0,
            to: 33.3,
            color: _lightBlue.withOpacity(0.5),
            cornerRadius: Radius.circular(10),
          ),
          GaugeSegment(
            from: 33.3,
            to: 66.6,
            color: _lightBlue,
            cornerRadius: Radius.circular(10),
          ),
          GaugeSegment(
            from: 66.6,
            to: 100,
            color: _lightBlue.withOpacity(0.5),
            cornerRadius: Radius.circular(10),
          ),
        ],
      ),
      // Displaying the value inside the gauge
      child: Center(
        child: Text(
          "${value.toStringAsFixed(0)}%",
          style: TextStyle(
            color: _darkBrown,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'BebasNeue',
          ),
        ),
      ),
    );
  }

  Widget _buildTemperatureDisplay(double value) {
    return Center(
      child: Text(
        "${value.toStringAsFixed(1)}°C",
        style: TextStyle(
          color: _darkBrown,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          fontFamily: 'BebasNeue',
        ),
      ),
    );
  }

  Widget _buildHealthDisplay(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // CHANGED: use a fixed-height box for the animation so it doesn't try
        // to expand inside an unbounded parent.
        SizedBox(
          height: 80,
          child: Lottie.asset(
            _getHealthAnimation(message),
            // Use a key to force the animation to restart on change
            key: ValueKey<String>(message),
          ),
        ),
        SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _darkBrown,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'BebasNeue',
          ),
        ),
      ],
    );
  }
}
