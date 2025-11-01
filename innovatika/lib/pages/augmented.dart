import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for asset loading
import 'package:vector_math/vector_math_64.dart' as vector;

class HelloWorld extends StatefulWidget {
  @override
  _HelloWorldState createState() => _HelloWorldState();
}

class _HelloWorldState extends State<HelloWorld> {
  late ArCoreController arCoreController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Hello World')),
        body: ArCoreView(onArCoreViewCreated: _onArCoreViewCreated),
      ),
    );
  }

  // Make this async to allow for awaiting asset loading
  void _onArCoreViewCreated(ArCoreController controller) async {
    arCoreController = controller;

    // Call the new function to add the 2D image
    await _addImage(arCoreController);
  }

  /// NEW FUNCTION TO ADD A 2D IMAGE
  Future<void> _addImage(ArCoreController controller) async {
    // 1. Load the image from assets
    final ByteData textureBytes = await rootBundle.load(
      'assets/images/fruit.png',
    );

    // 2. Create a material with the image as a texture
    final material = ArCoreMaterial(
      textureBytes: textureBytes.buffer.asUint8List(),
    );

    // 3. Create a flat "plane" using ArCoreCube
    //    Set the width and height, but make the thickness (z) very small.
    final plane = ArCoreCube(
      materials: [material],
      size: vector.Vector3(0.5, 0.5, 0.001), // width, height, thickness
    );

    // 4. Create a node to position the image in the scene
    final node = ArCoreNode(
      shape: plane,
      position: vector.Vector3(0.5, 0.5, -2.5), // Position it in front
    );

    controller.addArCoreNode(node);
  }

  // void _addSphere(ArCoreController controller) {
  //   final material = ArCoreMaterial(color: Color.fromARGB(120, 66, 134, 244));
  //   final sphere = ArCoreSphere(materials: [material], radius: 0.1);
  //   final node = ArCoreNode(
  //     shape: sphere,
  //     position: vector.Vector3(0, 0, -1.5),
  //   );
  //   controller.addArCoreNode(node);
  // }

  // void _addCylindre(ArCoreController controller) {
  //   final material = ArCoreMaterial(color: Colors.red, reflectance: 1.0);
  //   final cylindre = ArCoreCylinder(
  //     materials: [material],
  //     radius: 0.5,
  //     height: 0.3,
  //   );
  //   final node = ArCoreNode(
  //     shape: cylindre,
  //     position: vector.Vector3(0.0, -0.5, -2.0),
  //   );
  //   controller.addArCoreNode(node);
  // }

  // void _addCube(ArCoreController controller) {
  //   final material = ArCoreMaterial(
  //     color: Color.fromARGB(120, 66, 134, 244),
  //     metallic: 1.0,
  //   );
  //   final cube = ArCoreCube(
  //     materials: [material],
  //     size: vector.Vector3(0.5, 0.5, 0.5),
  //   );
  //   final node = ArCoreNode(
  //     shape: cube,
  //     position: vector.Vector3(-0.5, 0.5, -3.5),
  //   );
  //   controller.addArCoreNode(node);
  // }

  @override
  void dispose() {
    arCoreController.dispose();
    super.dispose();
  }
}
