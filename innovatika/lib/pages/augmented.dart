import 'dart:typed_data'; // Import Uint8List
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ArImageDisplayScreen extends StatefulWidget {
  @override
  _ArImageDisplayScreenState createState() => _ArImageDisplayScreenState();
}

class _ArImageDisplayScreenState extends State<ArImageDisplayScreen> {
  late ArCoreController arCoreController;
  Uint8List? imageBytes; // Store the loaded image bytes

  @override
  void initState() {
    super.initState();
    _loadAsset();
  }

  Future<void> _loadAsset() async {
    try {
      final ByteData data = await rootBundle.load(
        'assets/images/vegetables.png',
      );
      setState(() {
        imageBytes = data.buffer.asUint8List();
      });
    } catch (e) {
      print("Error loading asset: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tap a plane to place image')),
      body: ArCoreView(
        onArCoreViewCreated: _onArCoreViewCreated,
        enableTapRecognizer: true, // <-- 1. Enable tap recognition
        // We no longer use 'onTap' here
      ),
    );
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;

    // 2. Assign the plane tap handler to the controller
    arCoreController.onPlaneTap = _handleOnPlaneTap;
  }

  // 3. This function is now called ONLY when a plane is tapped
  void _handleOnPlaneTap(List<ArCoreHitTestResult> hits) {
    // Check if the tap hit a plane and if our image is loaded
    if (hits.isNotEmpty && imageBytes != null) {
      final hit = hits.first;
      _addImage(arCoreController, hit);
    }
  }

  // 4. This function is the same as before
  void _addImage(ArCoreController controller, ArCoreHitTestResult hit) {
    final node = ArCoreNode(
      image: ArCoreImage(
        bytes: imageBytes!,
        width: 5, // 30cm
        height: 5,
      ),
      position: hit.pose.translation,
      rotation: hit.pose.rotation,
    );

    controller.addArCoreNode(node);
  }

  @override
  void dispose() {
    arCoreController.dispose();
    super.dispose();
  }
}
