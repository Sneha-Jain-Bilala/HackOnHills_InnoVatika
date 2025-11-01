import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:innovatika/database/informer_hardware.dart';
import 'package:innovatika/widget/appbar.dart';
import 'package:innovatika/widget/associate_plant.dart';
import 'package:innovatika/widget/hardware_widget.dart';
import 'package:innovatika/widget/loading.dart';
import 'package:innovatika/widget/plant_widget.dart';
import 'package:innovatika/widget/wifi.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:toastification/toastification.dart';

class DeviceSetup extends StatefulWidget {
  const DeviceSetup({super.key});

  @override
  State<DeviceSetup> createState() => _DeviceSetupState();
}

class _DeviceSetupState extends State<DeviceSetup> {
  static final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final MobileScannerController controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  late bool isLoading = false;
  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    TextEditingController password = TextEditingController();
    TextEditingController devID = TextEditingController();
    TextEditingController devName = TextEditingController();
    devName.text = "device_1";
    devID.text = "device_1";
    password.text = "1_device";

    Future<void> handleSubmit() async {
      if (formKey.currentState!.validate()) {
        setState(() {
          isLoading = true;
        });
        devName.text = devID.text;
        bool isAuthenticate = await CredentialService().validateCredentials(
          deviceId: devName.text,
          password: password.text,
        );
        // if (!context.mounted) return;
        if (!isAuthenticate) {
          String errorN = "Failed! Please provide valid details.";
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 5),
            title: Text(
              errorN,
              textAlign: TextAlign.center,
            ),
          );
          setState(() {
            isLoading = false;
          });
          return;
        }
        var listPlants = await PlantManager().listPlant();
        if (listPlants.isEmpty) {
          var deviceList = await HardwareManager().listDevices();
          int deviceLastID = 0;
          if (deviceList.isNotEmpty) {
            deviceLastID = deviceList.last?.id + 1 ?? 0;
          }
          Hardware hardware = Hardware(
            name: devName.text,
            passwd: password.text,
            devImage: "assets/images/device.jpg",
            id: deviceLastID,
            devName: devID.text,
          );
          HardwareManager().addHardware(hardware);
          if (!context.mounted) return;
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 5),
            title: const Text(
              'Device Added Successfully!',
              textAlign: TextAlign.center,
            ),
          );
        } else {
          if (!context.mounted) return;
          associatePlant(
            context,
            listPlants,
            [
              devName.text,
              devID.text,
              password.text,
            ],
          );
        }
        setState(() {
          isLoading = false;
        });
      }
      if (!context.mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    }
    // }

    Map<String, String> extractbarDet(String qrData) {
      String password = '';
      String devID = '';
      String devName = '';

      // Split the input string by commas to get individual parts
      List<String> parts = qrData.split(',');

      // Loop through each part and extract the corresponding value
      for (String part in parts) {
        if (part.contains('password:')) {
          password = part.split(',')[1];
        } else if (part.contains('devID:')) {
          devID = part.split(',')[1];
        } else if (part.contains('devName:')) {
          devName = part.split(',')[1];
        }
      }
      return {
        'password': password,
        'devID': devID,
        'devName': devName,
      };
    }

    return Scaffold(
      appBar: commonApp(context: context),
      body: !isLoading
          ? ListView(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      width: width / 2,
                      height: width / 2,
                      child: MobileScanner(
                        controller: controller,
                        onDetect: (barcodes) {
                          if (barcodes.raw != null) {
                            Map<String, String> barDet =
                                extractbarDet(barcodes.raw.toString());
                            password.text = barDet['password'] ?? '';
                            devID.text = barDet['devID'] ?? '';
                            devName.text = barDet['devName'] ?? '';
                            formKey.currentState!.save();
                            handleSubmit();
                          }
                        },
                      ),
                    ),
                    // Bottom half: Divider and manual input section
                    const SizedBox(
                      height: 50,
                    ),
                    Form(
                      key: formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: Divider(
                              thickness: 2.0,
                            ),
                          ),
                          const Text(
                            "OR",
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.w500),
                          ),
                          const Text(
                            'Enter Manually',
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 20.0),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: TextFormField(
                              controller: devID,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter Device ID';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Device ID',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: TextFormField(
                              controller: password,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter Password';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: TextFormField(
                              controller: devName,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter Device Name';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Device Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          TextButton.icon(
                            onPressed: () {
                              handleSubmit();
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                const Color.fromARGB(255, 253, 234, 255),
                              ),
                            ),
                            icon: const Text("Save"),
                            label: const Icon(Iconsax.document_upload),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 100,
                    ),
                  ],
                ),
              ],
            )
          : const Column(
              children: [
                SizedBox(
                  height: 50,
                ),
                LoadingDeviceAnimation(),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
    );
  }
}
