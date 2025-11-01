import 'dart:async';
import 'dart:ui'; // Import for ImageFilter
import 'package:flutter/material.dart';
import 'package:innovatika/database/informer_hardware.dart';
import 'package:innovatika/database/informer_plant.dart';
import 'package:innovatika/pages/view_device.dart';
import 'package:innovatika/widget/associate_plant.dart';
import 'package:innovatika/widget/hardware_widget.dart';
import 'package:innovatika/widget/loading.dart';
import 'package:innovatika/widget/nav.dart';
import 'package:realm/realm.dart';
import 'package:toastification/toastification.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late Realm realm;
  late StreamSubscription<RealmResultsChanges<HardwareInformerr>>
      _devicesSubscription;

  // Added a default initialization for realm to avoid late initialization errors
  // before _initializeRealm completes. This is a common pattern.
  // We'll check if realm is initialized before using it.
  bool isRealmInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeRealm();
  }

  Future<void> _initializeRealm() async {
    try {
      final openedRealm =
          await Realm.open(Configuration.local([HardwareInformerr.schema]));
      if (mounted) {
        setState(() {
          realm = openedRealm;
          isRealmInitialized = true;
          final devices = realm.all<HardwareInformerr>().changes;
          _devicesSubscription = devices.listen((event) => _onDevicesChanged());
        });
      } else {
        // If the widget is disposed before realm opens, close it.
        openedRealm.close();
      }
    } catch (e) {
      // Handle potential errors during realm initialization
      print("Error initializing Realm: $e");
      if (mounted) {
        // Show an error to the user if appropriate
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 5),
          title: Text(
            "Error loading database",
            textAlign: TextAlign.center,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Check if subscription was initialized before trying to cancel
    if (isRealmInitialized) {
      _devicesSubscription.cancel();
      realm.close();
    }
    super.dispose();
  }

  void _onDevicesChanged() {
    // Ensure the widget is still mounted before calling setState
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set a background color or image for the glass effect to be visible
    return Scaffold(
      backgroundColor: Colors.purple.shade50, // Example background
      body: !isRealmInitialized
          ? LoadingDeviceAnimation() // Show loading while realm initializes
          : StreamBuilder<RealmResultsChanges<HardwareInformerr>>(
              stream: realm.all<HardwareInformerr>().changes,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var devices = snapshot.data!.results;
                  if (devices.isEmpty) {
                    return emptyLoading("No devices found");
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(20), // Add padding to grid
                    itemCount: devices.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20, // Increased spacing
                      mainAxisSpacing: 20, // Increased spacing
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return GestureDetector(
                        onTap: () async {
                          if (device.plantAssociated == -1) {
                            // Open a Realm instance
                            var config = await Realm.open(
                                Configuration.local(([PlantInformer.schema])));

                            // Fetch all plant from MongoDB Realm
                            var plantt = config.all<PlantInformer>().toList();
                            // Close the config realm instance after use
                            config.close();

                            if (plantt.isEmpty) {
                              if (!context.mounted) return;
                              toastification.show(
                                context: context,
                                type: ToastificationType.error,
                                style: ToastificationStyle.flat,
                                alignment: Alignment.bottomCenter,
                                autoCloseDuration: const Duration(seconds: 5),
                                title: Text(
                                  "Add a Plant first",
                                  textAlign: TextAlign.center,
                                ),
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NavBar(
                                    index: 1,
                                  ),
                                ),
                              );
                            } else {
                              //fetch hardware
                              Hardware hardware = await HardwareManager()
                                  .accessHardware(device.id);
                              if (!context.mounted) return;
                              associatePlant(
                                context,
                                plantt,
                                [
                                  hardware.name,
                                  hardware.passwd,
                                ],
                              );
                            }
                          } else {
                            Hardware hardware = await HardwareManager()
                                .accessHardware(device.id);
                            if (!context.mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewDevice(
                                  hardware: hardware,
                                ),
                              ),
                            );
                          }
                        },
                        child:
                            // --- Glassmorphism UI Starts Here ---
                            ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                // Semi-transparent white for the glass effect
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                // Border to catch the light
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                // Softer shadow for a "glowing" edge
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Image with a slight border/shadow
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          child: Image.asset(
                                            'assets/images/device.jpg',
                                            fit: BoxFit.contain,
                                            height: 70,
                                            width: 70,
                                          ),
                                        ),
                                      ),
                                      // Delete Icon
                                      GestureDetector(
                                        onTap: () async {
                                          // Added a confirmation dialog
                                          bool? confirmDelete =
                                              await showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text("Delete Device?"),
                                              content: Text(
                                                  "Are you sure you want to delete '${device.name}'?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: Text(
                                                    "Delete",
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirmDelete == true) {
                                            await HardwareManager()
                                                .removeHardware(device.id);
                                            if (context.mounted) {
                                              toastification.show(
                                                context: context,
                                                type:
                                                    ToastificationType.success,
                                                style: ToastificationStyle.flat,
                                                alignment:
                                                    Alignment.bottomCenter,
                                                autoCloseDuration:
                                                    const Duration(seconds: 3),
                                                title: Text(
                                                  "'${device.name}' deleted",
                                                  textAlign: TextAlign.center,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.delete_outline,
                                            size: 28,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  // Device Name
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(
                                      device.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff0f52ba),
                                        fontSize: 20,
                                        fontFamily: "Poppins",
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black12,
                                            blurRadius: 2,
                                            offset: Offset(1, 1),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // --- Glassmorphism UI Ends Here ---
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return emptyLoading("Error loading devices");
                } else {
                  return LoadingDeviceAnimation();
                }
              },
            ),
    );
  }
}
