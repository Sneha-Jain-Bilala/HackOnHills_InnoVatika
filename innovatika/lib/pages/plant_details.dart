import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui'; // Import for ImageFilter
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:innovatika/database/informer_plant.dart';
import 'package:innovatika/widget/appbar.dart';
import 'package:innovatika/widget/const.dart';
import 'package:innovatika/widget/garden_api.dart';
import 'package:innovatika/widget/garden_widget.dart';
import 'package:innovatika/widget/gemini.dart';
import 'package:innovatika/widget/plant_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:toastification/toastification.dart';

class PlantDetails extends StatefulWidget {
  final Plant plant;
  final String location;
  const PlantDetails({
    super.key,
    required this.plant,
    required this.location,
  });

  @override
  State<PlantDetails> createState() => _PlantDetailsState();
}

class _PlantDetailsState extends State<PlantDetails> {
  Uint8List? imageMem;
  // late PlantDesc plantDesc = PlantDesc(
  //   description: "",
  //   technique: "",
  // );

  final TextEditingController gardenNameC = TextEditingController();

  late bool isShowpage = false;
  Future fetchDescription() async {
    final stringJsonData = await GeminiClient(model: "gemini-1.5-flash-latest")
        .generateContentFromText(
      prompt:
          'Hi, I am trying to plant ${widget.plant.name} in my location ${widget.location}, first give me a brief description of the plant, some growing techniques and suggest me some caring techniques, give me the output strictly in json format and no other text, remove any kind of formatting and remove all newline characters. remember output strictly in json format and no other text. here is the format(key value): {"description": "All description goes here", "techniques":"All techniques goes here", "timeToGrow":"actual growing time in 10 letters"} in minimum 200 words,techniques must only contain the growing techniques and description should only contain a description, description and techniques should be strictly unique. both description and techniques keys should be present and strictly only json',
    );

    try {
      final Map<String, dynamic> jsonData = jsonDecode(stringJsonData);

      setState(() {
        widget.plant.longDesc = jsonData["description"] ?? "";
        widget.plant.shortDesc = jsonData["techniques"] ?? "";
        widget.plant.timeToGrow = jsonData["timeToGrow"] ?? "";
      });

      if (widget.plant.longDesc.isEmpty || widget.plant.shortDesc.isEmpty) {
        if (!mounted) return;
        fetchDescription();
      } else {
        setState(() {
          isShowpage = true;
        });
      }
    } catch (e) {
      print("Error decoding JSON from Gemini: $e");
      print("Received data: $stringJsonData");
      if (mounted) {
        // Retry if parsing failed
        fetchDescription();
      }
    }
  }

  void addGardenFn(
    BuildContext context,
    int gardenID,
  ) async {
    final url = await fetchGardenImage();
    GardenManager().addGarden(gardenID, url);
    var plantList = await PlantManager().listPlant();
    int plantLastID = 0;
    if (plantList.isNotEmpty) {
      plantLastID = plantList.last?.id + 1 ?? 0;
    }
    PlantManager().addPlant(widget.plant, plantLastID);
    GardenManager().addAssociates(
      gardenID,
      plantLastID,
    );
    if (!context.mounted) return;
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 5),
      title: Text(
        "Garden Added Successfully",
        textAlign: TextAlign.center,
      ),
    );
    Navigator.of(context).pop();
  }

  void addPlant(int gardenID) async {
    var plantList = await PlantManager().listPlant();
    int plantLastID = 0;
    if (plantList.isNotEmpty) {
      plantLastID = plantList.last?.id + 1 ?? 0;
    }
    PlantManager().addPlant(widget.plant, plantLastID);
    GardenManager().addAssociates(
      gardenID,
      plantLastID,
    );
    if (!mounted) return;
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 5),
      title: Text(
        "Plant Added Successfully",
        textAlign: TextAlign.center,
      ),
    );
    Navigator.of(context).pop();
  }

  Future loadNetworkImg() async {
    try {
      http.Response response = await http.get(
        Uri.parse(
          widget.plant.image,
        ),
      );
      // final Uint8List img = await removeBG(response.bodyBytes);
      if (mounted) {
        setState(() {
          imageMem = response.bodyBytes;
        });
      }
      return imageMem;
    } catch (e) {
      print("Error loading network image: $e");
      // Optionally set a placeholder image
    }
  }

  @override
  void initState() {
    loadNetworkImg().then((onValue) {
      fetchDescription();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    ///

    void listGardens(BuildContext context, List<dynamic> garden, int gardenID) {
      // late bool isLoading = false;
      // final width = MediaQuery.of(context).size.width;
      // final height = MediaQuery.of(context).size.height;
      showModalBottomSheet(
        backgroundColor:
            Colors.transparent, // Make modal background transparent
        context: context,
        isScrollControlled: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: garden.length,
                          itemBuilder: (context, index) {
                            var garData = garden[index];
                            return GestureDetector(
                              onTap: () {
                                addPlant(garData.id);
                              },
                              child: ListTile(
                                tileColor: Colors
                                    .transparent, // Use transparent tile color
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 20.0, horizontal: 20.0),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    garData.imgURL,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(
                                  "Garden ${garData.id + 1}",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkBrown, // Apply color
                                  ),
                                ),
                                subtitle: Text(
                                  garData.dateTime,
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.mediumBrown),
                                ),
                                trailing: Container(
                                  padding: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightPastelGreen
                                        .withOpacity(0.5), // Apply color
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "${garData.plantAssoc.length} Plants",
                                    style: TextStyle(
                                      color: AppColors.darkGreen, // Apply color
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Divider(color: AppColors.mediumBrown.withOpacity(0.3)),
                      TextButton.icon(
                        onPressed: () {
                          addGardenFn(context, gardenID + 1);
                        },
                        icon: Icon(Iconsax.add,
                            color: AppColors.darkGreen), // Apply color
                        label: Text(
                          "Add Garden",
                          style: TextStyle(
                              color: AppColors.darkGreen), // Apply color
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          });
        },
      );
    }

    ////
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent, // Make scaffold transparent
        extendBodyBehindAppBar: true, // Extend body behind app bar
        appBar: commonApp(
          context: context,
          title: widget.plant.name,
        ),
        body: SafeArea(
          child: isShowpage
              ? ListView(
                  children: [
                    Container(
                      height: height / 2.5,
                      // Removed white background color to show gradient
                      child: SizedBox(
                        height: height / 2.5,
                        width: width,
                        child: imageMem != null ? Image.asset("assets/images/on.png")
                            // ? Image.memory(
                            //     imageMem!,
                            //     fit: BoxFit.contain,
                            //   )
                            : Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.darkGreen),
                              ), // Show loader if image is null
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          // margin: const EdgeInsets.all(2), // Removed margin
                          padding: const EdgeInsets.all(20),
                          width: width,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.3), // Glass effect color
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.plant.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 23,
                                  fontFamily: "Ubuntu",
                                  color: AppColors.darkBrown, // Apply color
                                ),
                                textAlign: TextAlign.start,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      widget.plant.timeToGrow,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                        fontFamily: "Ubuntu",
                                        color: AppColors
                                            .mediumBrown, // Apply color
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        final garden =
                                            await GardenManager().listGarden();

                                        if (!context.mounted) return;
                                        if (garden.isEmpty) {
                                          addGardenFn(context, 0);
                                        } else {
                                          var gardenList = await GardenManager()
                                              .listGarden();
                                          int gardenID =
                                              gardenList.last?.id ?? 0;
                                          if (!context.mounted) return;
                                          listGardens(
                                              context, garden, gardenID);
                                        }
                                      },
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll(
                                          AppColors.lightPastelGreen
                                              .withOpacity(0.5), // Apply color
                                        ),
                                      ),
                                      label: Text(
                                        "Save",
                                        style: TextStyle(
                                          color: AppColors
                                              .darkGreen, // Apply color
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.favorite,
                                        color:
                                            AppColors.darkGreen, // Apply color
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "Description",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: AppColors.darkBrown, // Apply color
                                  fontFamily: "Montserrat",
                                ),
                                textAlign: TextAlign.start,
                              ),
                              Text(
                                widget.plant.longDesc,
                                textAlign: TextAlign.justify,
                                style: TextStyle(
                                  color: AppColors.mediumBrown, // Apply color
                                  fontFamily: "Ubuntu",
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Text(
                                "Growing Techniques",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: AppColors.darkBrown, // Apply color
                                  fontFamily: "Montserrat",
                                ),
                                textAlign: TextAlign.start,
                              ),
                              Text(
                                widget.plant.shortDesc,
                                textAlign: TextAlign.justify,
                                style: TextStyle(
                                  color: AppColors.mediumBrown, // Apply color
                                  fontFamily: "Ubuntu",
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                )
              : animatedLoader(),
        ),
      ),
    );
  }

  Widget animatedLoader() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
              child: Column(
                mainAxisSize: MainAxisSize.min, // Fit content
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Lottie.asset("assets/animation/wait.json", height: 250),
                  const SizedBox(
                    height: 50,
                  ),
                  Text(
                    "Communing with the Plant Spirits...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      color: AppColors.darkBrown, // Apply color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Connecting with plant spirits to weave tales inspired by your location, creating a truly immersive experience.",
                    style: TextStyle(
                      color: AppColors.mediumBrown, // Apply color
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
