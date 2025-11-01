import 'package:flutter/material.dart';
import 'package:innovatika/database/informer_hardware.dart';
import 'package:innovatika/widget/hardware_widget.dart';
import 'package:innovatika/widget/nav.dart';
import 'package:toastification/toastification.dart';

Future<void> associatePlant(BuildContext context, List<dynamic> plants, List input) async {
  // late bool isLoading = false;
  // final width = MediaQuery.of(context).size.width;
  // final height = MediaQuery.of(context).size.height;
  print("object");
  // Await the bottom sheet so callers can choose to wait for it before navigating
  await showModalBottomSheet<void>(
    backgroundColor: const Color.fromARGB(255, 237, 228, 251),
    context: context,
    isScrollControlled: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
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
                        // Remove any previous placeholder hardware if needed
                        await HardwareManager().removeHardware(selectedPlant);
                        await HardwareManager().addHardware(hardware);
                        if (!context.mounted) return;
                        // Close the bottom sheet and navigate to root
                        Navigator.pop(context);
                        Navigator.popUntil(context, (route) => route.isFirst);
                        setState(() {});
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
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 20.0,
                        horizontal: 20.0,
                      ),
                      leading: Image.network(
                        plantData.image,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                      title: Text(
                        plantData.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        plantData.timeToGrow,
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${plantData.id} Plants",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
                      MaterialPageRoute(builder: (context) => NavBar(index: 1)),
                    );
                  },
                  child: const Text('Add More Plants'),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
