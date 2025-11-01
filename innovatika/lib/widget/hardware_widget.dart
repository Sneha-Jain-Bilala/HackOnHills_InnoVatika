// No of gardens
import 'package:realm/realm.dart';
import 'package:innovatika/database/informer_hardware.dart';

class HardwareManager {
  Future<List> listDevices() async {
    final realm = await Realm.open(
      Configuration.local([HardwareInformerr.schema]),
    );
    var devices = realm.all<HardwareInformerr>().toList();
    if (devices.isEmpty) {
      return [];
    }
    return devices;
  }

  Future<void> addHardware(Hardware hardware) async {
    final realm = await Realm.open(
      Configuration.local([HardwareInformerr.schema]),
    );
    try {
      // Ensure we don't try to add an object with an existing primary key.
      // If the provided id already exists, compute a unique id (auto-increment).
      int chosenId = hardware.id;
      var existing = realm.find<HardwareInformerr>(chosenId);
      if (existing != null) {
        // compute max id present and increment
        final devices = realm.all<HardwareInformerr>().toList();
        int maxId = -1;
        for (var d in devices) {
          if (d.id > maxId) maxId = d.id;
        }
        chosenId = maxId + 1;
      }

      var garData = HardwareInformerr(
        hardware.name,
        hardware.passwd,
        hardware.devName,
        hardware.devImage,
        hardware.plantAssociated,
        chosenId,
      );

      print(garData);

      realm.write(() {
        realm.add(garData);
      });
    } catch (e) {
      // Rethrow after optional logging so callers can handle it.
      // This avoids silently swallowing RealmExceptions when add fails.
      // You can replace this with more specific error handling if desired.
      print('Error adding hardware: $e');
      rethrow;
    } finally {
      // Close the realm we opened here to avoid leaking resources.
      realm.close();
    }
  }

  Future<void> addGarden(int id, int plantID) async {
    final realm = await Realm.open(
      Configuration.local([HardwareInformerr.schema]),
    );
    var garData = realm.find<HardwareInformerr>(id);
    if (garData != null) {
      realm.write(() {
        garData.plantAssociated = plantID;
      });
    }
  }

  Future<List> removeHardware(int id) async {
    final realm = await Realm.open(
      Configuration.local([HardwareInformerr.schema]),
    );
    var garData = realm.find<HardwareInformerr>(id);
    print(garData);
    if (garData != null) {
      realm.write(() {
        realm.delete(garData);
      });
    }

    return listDevices();
  }

  Future<Hardware> accessHardware(int id) async {
    final realm = await Realm.open(
      Configuration.local([HardwareInformerr.schema]),
    );
    var idData = realm.find<HardwareInformerr>(id);
    if (idData != null) {
      return Hardware(
        name: idData.name,
        passwd: idData.passwd,
        devImage: idData.devImage,
        devName: idData.devName,
        plantAssociated: idData.plantAssociated,
        id: idData.id,
      );
    } else {
      throw Exception('Hardware not found');
    }
  }
}
