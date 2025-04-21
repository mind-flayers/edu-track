import 'package:edu_track/app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // For Get.back() if needed

class Dialogs {
  /// Shows a confirmation dialog with customizable title, message, and button text.
  static void showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultRadius)),
          title: Text(title, style: Theme.of(context).textTheme.headlineSmall),
          content: Text(message, style: Theme.of(context).textTheme.bodyLarge),
          actions: <Widget>[
            TextButton(
              child: Text(cancelText, style: kLinkTextStyle.copyWith(color: kErrorColor)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                onCancel?.call(); // Call optional cancel callback
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor, // Or kSuccessColor depending on context
                padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 1.5, vertical: kDefaultPadding * 0.6),
              ),
              child: Text(confirmText),
              onPressed: onConfirm, // onConfirm should handle dialog closing if needed after action
            ),
          ],
        );
      },
    );
  }

  /// Shows a custom dialog with a title, custom content widget, and confirm/cancel buttons.
  static void showCustomDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultRadius)),
          title: Text(title, style: Theme.of(context).textTheme.headlineSmall),
          content: SingleChildScrollView( // Ensure content is scrollable if it overflows
             child: content,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(cancelText, style: kLinkTextStyle.copyWith(color: kErrorColor)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onCancel?.call();
              },
            ),
            ElevatedButton(
               style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 1.5, vertical: kDefaultPadding * 0.6),
              ),
              child: Text(confirmText),
              onPressed: onConfirm, // Let the confirm callback handle closing if necessary
            ),
          ],
        );
      },
    );
  }

   // Optional: Simple Loading Dialog
   static void showLoadingDialog(BuildContext context, {String message = 'Loading...'}) {
     showDialog(
       context: context,
       barrierDismissible: false,
       builder: (BuildContext context) {
         return AlertDialog(
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultRadius)),
           content: Row(
             children: [
               const CircularProgressIndicator(),
               const SizedBox(width: kDefaultPadding),
               Text(message),
             ],
           ),
         );
       },
     );
   }

   // Optional: Hide Loading Dialog
   static void hideLoadingDialog(BuildContext context) {
     // Check if a dialog is open before trying to pop
     if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
     }
   }

   // Optional: Simple Info/Error Snackbar (using GetX)
   static void showSnackbar(String title, String message, {bool isError = false}) {
     Get.snackbar(
       title,
       message,
       snackPosition: SnackPosition.BOTTOM,
       backgroundColor: isError ? kErrorColor.withOpacity(0.9) : kSuccessColor.withOpacity(0.9),
       colorText: Colors.white,
       borderRadius: kDefaultRadius / 2,
       margin: const EdgeInsets.all(kDefaultPadding),
       duration: const Duration(seconds: 3),
       icon: Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
     );
   }

}