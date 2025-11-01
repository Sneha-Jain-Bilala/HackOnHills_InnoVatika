import 'package:flutter/material.dart';
import 'package:innovatika/database/informer_hardware.dart';
import 'package:innovatika/widget/hardware_widget.dart';
import 'package:innovatika/widget/nav.dart';
import 'package:toastification/toastification.dart';

void associatePlant(BuildContext context, List<dynamic> plants, List input) {
  // late bool isLoading = false;
  // final width = MediaQuery.of(context).size.width;
  // final height = MediaQuery.of(context).size.height;
  showModalBottomSheet(
    backgroundColor: Color.fromARGB(255, 237, 228, 251),
    context: context,
    isScrollControlled: false,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: plants.length,
                itemBuilder: (context, index) {
                  var plantData = plants[index];
                  return ListTile(
                    onTap: () async {
                      int selectedPlant = plantData.id;
                      var deviceList = await HardwareManager().listDevices();
                      int deviceLastID = 0;
                      if (deviceList.isNotEmpty) {
                        deviceLastID = deviceList.last?.id + 1 ?? 0;
                      }
                      Hardware hardware = Hardware(
                        name: input[0],
                        passwd: input[1],
                        devName: input[0],
                        devImage: plantData.image,
                        id: deviceLastID,
                        plantAssociated: selectedPlant,
                      );
                      await HardwareManager().removeHardware(selectedPlant);
                      await HardwareManager().addHardware(hardware);
                      Navigator.popUntil(context, (route) => route.isFirst);
                      setState(() {});
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
                    },
                    tileColor: Theme.of(context).colorScheme.surface,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
                    leading: Image.network(
                      plantData.image,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                    title: Text(
                      plantData.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      plantData.timeToGrow,
                      style: TextStyle(fontSize: 16),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${plantData.id} Plants",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NavBar(
                        index: 1,
                      ),
                    ),
                  );
                },
                child: Text('Add More Plants'),
              ),
            ),
          ],
        );
      });
    },
  );
}
