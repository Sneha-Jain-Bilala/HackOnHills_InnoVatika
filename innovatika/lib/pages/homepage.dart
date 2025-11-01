import 'dart:async';
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

  @override
  void initState() {
    super.initState();
    _initializeRealm();
  }

  Future<void> _initializeRealm() async {
    final openedRealm = await Realm.open(
      Configuration.local([HardwareInformerr.schema]),
    );
    setState(() {
      realm = openedRealm;
      final devices = realm.all<HardwareInformerr>().changes;
      _devicesSubscription = devices.listen((event) => _onDevicesChanged());
    });
  }

  @override
  void dispose() {
    _devicesSubscription.cancel();
    realm.close();
    super.dispose();
  }

  void _onDevicesChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<RealmResultsChanges<HardwareInformerr>>(
        stream: realm.all<HardwareInformerr>().changes,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var devices = snapshot.data!.results;
            if (devices.isEmpty) {
              return emptyLoading("No devices found");
            }
            return GridView.builder(
              itemCount: devices.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final device = devices[index];
                return GestureDetector(
                  onTap: () async {
                    if (device.plantAssociated == -1) {
                      // Open a Realm instance
                      var config = await Realm.open(
                        Configuration.local(([PlantInformer.schema])),
                      );

                      // Fetch all plant from MongoDB Realm
                      var plantt = config.all<PlantInformer>().toList();
                      if (plantt.isEmpty) {
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
                            builder: (context) => NavBar(index: 1),
                          ),
                        );
                      } else {
                        //fetch hardware
                        Hardware hardware = await HardwareManager()
                            .accessHardware(device.id);
                        if (!context.mounted) return;
                        associatePlant(context, plantt, [
                          hardware.name,
                          hardware.passwd,
                        ]);
                      }
                    } else {
                      Hardware hardware = await HardwareManager()
                          .accessHardware(device.id);
                      if (!context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewDevice(hardware: hardware),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.purple.shade50,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(2, 2),
                          blurRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          offset: const Offset(-2, -2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.asset(
                                'assets/images/device.jpg',
                                fit: BoxFit.contain,
                                height: 70,
                                width: 70,
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                await HardwareManager().removeHardware(
                                  device.id,
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Icon(Icons.delete_outline, size: 30),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(height: 10),
                        Text(
                          device.name,
                          style: const TextStyle(
                            color: Color(0xff0f52ba),
                            fontSize: 20,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return LoadingDeviceAnimation();
          }
        },
      ),
    );
  }
}
