import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:innovatika/pages/device_setup.dart';
import 'package:innovatika/widget/const.dart';

AppBar commonApp({
  required BuildContext context,
  GlobalKey? key,
  String? title,
  Widget? widget,
}) {
  // Use shared AppColors instead of local hardcoded color
  return AppBar(
    automaticallyImplyLeading: false,
    // leading: const Text("Compu Rf"),
    title: Navigator.canPop(context) && title == null
        ? null
        : Text(
            title != null && title.isNotEmpty ? title : "InnoVatika",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
    leading: Navigator.canPop(context)
        ? IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios_outlined,
            ),
          )
        : null,
    backgroundColor: Colors.transparent, // Make app bar transparent
    elevation: 0, // Remove shadow
      titleTextStyle: TextStyle(
      color: AppColors.darkBrown, // Set title color
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: "Ubuntu",
    ),
    iconTheme: IconThemeData(color: AppColors.darkBrown), // Set icon color

    actions: Navigator.canPop(context)
        ? null
        : [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DeviceSetup(),
                  ),
                );
              },
              label: const Text("Add a Device"),
              icon: const Icon(Iconsax.add),
            )
          ],
  );
}
