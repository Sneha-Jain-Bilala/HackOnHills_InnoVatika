import 'dart:async';
import 'dart:ui'; // Import for ImageFilter
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:innovatika/database/informer_plant.dart';
import 'package:innovatika/pages/plant_details.dart';
import 'package:innovatika/widget/const.dart';
import 'package:innovatika/widget/gemini.dart';
import 'package:innovatika/widget/mapping.dart';
import 'package:innovatika/widget/unsplash_api.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toastification/toastification.dart';

class PlantCategorization extends StatefulWidget {
  const PlantCategorization({super.key});

  @override
  State<PlantCategorization> createState() => _PlantCategorizationState();
}

class _PlantCategorizationState extends State<PlantCategorization> {
  //
  //
  //
  late bool displayLocationPermission = true;
  late bool isGeminiRequestInProgress = true;
  late String locationCity;

  late List<Plant> fruit;
  late List<Plant> veggies;
  late List<Plant> flower;
  late List<Plant> herbs;
  late List<Plant> shrubs;
  //
  //
  final futureGroup = FutureGroup();
  //
  // late List<dynamic> fruitJsonData;
  // late List<dynamic> veggiesJsonData;
  // late List<dynamic> flowersJsonData;
  // late List<dynamic> herbsJsonData;
  // late List<dynamic> shrubsJsonData;
  //

  //
  void locationError(BuildContext context, String description) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 5),
      title: const Text('Location Permission Denied!'),
      description: Text(description),
      // description: const Text(
      //   "Location Permission is Denied, kindly turn it on from the settings",
      // ),
    );
  }

  void locationSuccess(BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 5),
      title: const Text(
        'Location Permission Granted!',
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return Future.error("buildcontext error");
      locationError(
        context,
        "Location services are disabled, Please turn it on from the device settings",
      );
      setState(() {
        displayLocationPermission = true;
      });
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return Future.error("buildcontext error");
        locationError(
          context,
          "Location Permission is Denied, kindly turn it on from the settings",
        );
        setState(() {
          displayLocationPermission = true;
        });
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return Future.error("buildcontext error");
      locationError(
        context,
        "Location Permission is Denied, kindly turn it on from the settings",
      );
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    if ((permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) &&
        serviceEnabled == true) {
      setState(() {
        displayLocationPermission = false;
      });
      if (!mounted) return Future.error("buildcontext error");
      locationSuccess(context);
    }

    return await Geolocator.getCurrentPosition();
  }

  Future processGemReq(String category, String locationCity) async {
    var geminiData = await GeminiClient(model: "gemini-1.5-flash-latest")
        .generateContentFromText(
          prompt:
              "Give me 5 fruits that can be grown in $locationCity. For each $category, provide its name, a placeholder image, and the approximate time it takes to grow. Format the output as JSON with the following keys: name, image, time_to_grow.",
        );

    if (category == "fruit") {
      setState(() {
        fruit = handleFruitMapping(geminiData);
      });
      for (int i = 0; i < fruit.length; i++) {
        var img = await fetchImgUnsplash(fruit[i].name, false);
        setState(() {
          fruit[i].image = img.toString();
        });
      }
    }
    if (category == "veggies") {
      veggies = handleVeggiesMapping(geminiData);
      for (int i = 0; i < veggies.length; i++) {
        var img = await fetchImgUnsplash(veggies[i].name, false);
        setState(() {
          veggies[i].image = img.toString();
        });
      }
    }
    if (category == "Flowers") {
      flower = handleVeggiesMapping(geminiData);
      for (int i = 0; i < flower.length; i++) {
        var img = await fetchImgUnsplash(flower[i].name, false);
        setState(() {
          flower[i].image = img.toString();
        });
      }
    }
    if (category == "herbs") {
      herbs = handleVeggiesMapping(geminiData);
      for (int i = 0; i < herbs.length; i++) {
        var img = await fetchImgUnsplash(herbs[i].name, false);
        setState(() {
          herbs[i].image = img.toString();
        });
      }
    }
    if (category == "shrubs") {
      shrubs = handleVeggiesMapping(geminiData);
      for (int i = 0; i < shrubs.length; i++) {
        var img = await fetchImgUnsplash(shrubs[i].name, false);
        setState(() {
          shrubs[i].image = img.toString();
        });
      }
    }
  }

  void callAPI() {
    // parallel processing of API
    futureGroup.add(processGemReq("fruit", locationCity));
    futureGroup.add(processGemReq("veggies", locationCity));
    futureGroup.add(processGemReq("Flowers", locationCity));
    futureGroup.add(processGemReq("herbs", locationCity));
    futureGroup.add(processGemReq("shrubs", locationCity));
    futureGroup.close();
    futureGroup.future.then((onValue) {
      if (mounted) {
        setState(() {
          isGeminiRequestInProgress = false;
        });
      }
    });
  }

  Future geminiReq() async {
    try {
      final Position position = await _determinePosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        setState(() {
          locationCity = placemarks[0].locality ?? "India";
        });
      } else {
        return; // Stop execution if widget is disposed
      }

      callAPI();
    } catch (e) {
      print("Error in geminiReq (location or placemark): $e");
      if (mounted) {
        setState(() {
          // Handle error, maybe show location permission screen again
          displayLocationPermission = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    geminiReq();
  }

  @override
  Widget build(BuildContext context) {
    // Parse the JSON data
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      // Apply a gradient background for the glass effect to be visible
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // New pastel colors related to gardening
            colors: [
              Color(0xFFE8F5E9), // Pastel Green
              Color(0xFFFFFDE7), // Pastel Yellow/Cream
              Color(0xFFE3F2FD), // Pastel Blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          // Use SafeArea to avoid UI overlapping with notches
          child: displayLocationPermission
              ? locationAnimation()
              : isGeminiRequestInProgress
              ? geminiReqAnimation(width)
              : plantCatalogue(),
        ),
      ),
    );
  }

  Widget locationAnimation() => Center(
    child: Container(
      margin: const EdgeInsets.all(20), // Margin for the glass card
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3), // Slightly more opaque
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: ListView(
              shrinkWrap: true, // Make ListView fit its content
              children: [
                Lottie.asset("assets/animation/location.json", height: 250),
                const SizedBox(height: 30),
                const Text(
                  "Allow Location Access",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    color: AppColors.darkBrown, // Changed text color
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "We need location permission to show personalised plant recommendation based on your location.",
                  style: TextStyle(
                    color: AppColors.mediumBrown, // Changed text color
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () async {
                    await openAppSettings();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.lightPastelGreen.withOpacity(
                      0.5,
                    ), // Pastel green
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Open Location Settings",
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget geminiReqAnimation(double width) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3), // Slightly more opaque
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Lottie.asset(
                    "assets/animation/geminiReqAnimation.json",
                    height: 300,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Embrace Nature's Lore",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      color: AppColors.darkBrown, // Changed text color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(18.0),
                    child: Text(
                      "Tapping into nature's whispers to cultivate stories that bloom uniquely for you",
                      style: TextStyle(
                        color: AppColors.mediumBrown, // Changed text color
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget plantCatalogue() {
    return ListView(
      primary: true,
      padding: const EdgeInsets.only(top: 20, bottom: 20), // Add padding
      children: [
        if (flower.isNotEmpty) category1(flower),
        if (fruit.isNotEmpty) category2(fruit),
        if (veggies.isNotEmpty) category3(veggies),
        if (herbs.isNotEmpty) category4(herbs),
        if (shrubs.isNotEmpty) category5(shrubs),
      ],
    );
  }

  // Helper widget to create a glass icon
  Widget _buildGlassIcon(String imagePath) {
    return Container(
      margin: const EdgeInsets.only(left: 20),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.3),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: ClipOval(
              child: FractionallySizedBox(
                widthFactor: 0.7, // Adjusted size
                heightFactor: 0.7, // Adjusted size
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain, // Use contain to avoid clipping
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to create a glass plant card
  Widget _buildGlassPlantCard(Plant plant) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PlantDetails(plant: plant, location: locationCity),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(left: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 110, // Increased size slightly
              height: 110, // Increased size slightly
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.0),

                child: Image.network(
                  plant.image,
                  fit: BoxFit.cover,
                  // Add loading and error builders for a better UX
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.darkGreen,
                            ),
                          );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 50,
                        color: AppColors.mediumBrown,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Common text style for category titles
  final TextStyle categoryTitleStyle = const TextStyle(
    fontSize: 20,
    fontFamily: "BebasNeue",
    fontWeight: FontWeight.bold,
    color: AppColors.darkBrown, // Changed text color
  );

  Widget category1(List<Plant> plants) {
    return SizedBox(
      height: 220, // Adjusted height
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        primary: false,
        children: [
          Row(
            children: [
              _buildGlassIcon("assets/images/flower.png"),
              const SizedBox(width: 20),
              Text("Flowering Plants", style: categoryTitleStyle),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 100,
            height: 110, // Adjusted height
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: plants.length,
              padding: const EdgeInsets.only(left: 10), // Adjust padding
              itemBuilder: (context, index) {
                return _buildGlassPlantCard(plants[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget category2(List<Plant> plants) {
    return SizedBox(
      height: 220,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        primary: false,
        children: [
          Row(
            children: [
              _buildGlassIcon("assets/images/fruit.png"),
              const SizedBox(width: 20),
              Text("Fruit-Bearing Plants", style: categoryTitleStyle),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 100,
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: plants.length,
              padding: const EdgeInsets.only(left: 10),
              itemBuilder: (context, index) {
                return _buildGlassPlantCard(plants[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget category3(List<Plant> plants) {
    return SizedBox(
      height: 220,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        primary: false,
        children: [
          Row(
            children: [
              _buildGlassIcon("assets/images/vegetables.png"),
              const SizedBox(width: 20),
              Text("Vegetables", style: categoryTitleStyle),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 100,
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: plants.length,
              padding: const EdgeInsets.only(left: 10),
              itemBuilder: (context, index) {
                return _buildGlassPlantCard(plants[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget category4(List<Plant> plants) {
    return SizedBox(
      height: 220,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        primary: false,
        children: [
          Row(
            children: [
              _buildGlassIcon("assets/images/herbs.png"),
              const SizedBox(width: 20),
              Text("Herbs", style: categoryTitleStyle),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 100,
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: plants.length,
              padding: const EdgeInsets.only(left: 10),
              itemBuilder: (context, index) {
                return _buildGlassPlantCard(plants[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget category5(List<Plant> plants) {
    return SizedBox(
      height: 220,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        primary: false,
        children: [
          Row(
            children: [
              _buildGlassIcon("assets/images/shrubs.png"),
              const SizedBox(width: 20),
              Text("Shrubs", style: categoryTitleStyle),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 100,
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: plants.length,
              padding: const EdgeInsets.only(left: 10),
              itemBuilder: (context, index) {
                return _buildGlassPlantCard(plants[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
