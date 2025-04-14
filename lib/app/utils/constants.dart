import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colors
const Color kPrimaryColor = Color(0xFF7B61FF); // Light Purple
const Color kSecondaryColor = Color(0xFFFFFFFF); // White
const Color kTextColor = Color(0xFF333333); // Dark Grey for text
const Color kLightTextColor = Color(0xFF666666); // Lighter Grey
const Color kBackgroundColor = Color(0xFFF8F8F8); // Light background
const Color kErrorColor = Color(0xFFFF4D4F);
const Color kSuccessColor = Color(0xFF52C41A);
const Color kDisabledColor = Color(0xFFD9D9D9);

// Padding & Margins
const double kDefaultPadding = 16.0;
const double kDefaultMargin = 16.0;
const double kDefaultRadius = 12.0;

// Text Styles
final TextStyle kHeadlineStyle = GoogleFonts.poppins(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: kTextColor,
);

final TextStyle kSubheadlineStyle = GoogleFonts.poppins(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: kTextColor,
);

final TextStyle kBodyTextStyle = GoogleFonts.poppins(
  fontSize: 14,
  fontWeight: FontWeight.normal,
  color: kTextColor,
);

final TextStyle kHintTextStyle = GoogleFonts.poppins(
  fontSize: 14,
  fontWeight: FontWeight.normal,
  color: kLightTextColor,
);

final TextStyle kButtonTextStyle = GoogleFonts.poppins(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: kSecondaryColor,
);

final TextStyle kLinkTextStyle = GoogleFonts.poppins(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: kPrimaryColor,
);

// Theme Data
final ThemeData appTheme = ThemeData(
  primaryColor: kPrimaryColor,
  scaffoldBackgroundColor: kBackgroundColor,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimaryColor,
    primary: kPrimaryColor,
    secondary: kSecondaryColor,
    error: kErrorColor,
    background: kBackgroundColor,
  ),
  textTheme: TextTheme(
    displayLarge: kHeadlineStyle, // Use for large headlines
    displayMedium: kHeadlineStyle.copyWith(fontSize: 22),
    displaySmall: kHeadlineStyle.copyWith(fontSize: 20),
    headlineMedium: kSubheadlineStyle, // Use for sub-headlines/titles
    headlineSmall: kSubheadlineStyle.copyWith(fontSize: 18),
    titleLarge: kSubheadlineStyle.copyWith(fontWeight: FontWeight.w600), // Use for AppBar titles
    bodyLarge: kBodyTextStyle, // Use for main body text
    bodyMedium: kBodyTextStyle.copyWith(fontSize: 12), // Use for smaller body text
    labelLarge: kButtonTextStyle, // Use for button text
    bodySmall: kHintTextStyle, // Use for hint text or captions
  ).apply(
    bodyColor: kTextColor,
    displayColor: kTextColor,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kSecondaryColor,
    hintStyle: kHintTextStyle,
    contentPadding: const EdgeInsets.symmetric(vertical: kDefaultPadding, horizontal: kDefaultPadding),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultRadius),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultRadius),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultRadius),
      borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultRadius),
      borderSide: const BorderSide(color: kErrorColor, width: 1.0),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultRadius),
      borderSide: const BorderSide(color: kErrorColor, width: 1.5),
    ),
    prefixIconColor: kLightTextColor,
    suffixIconColor: kLightTextColor,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: kSecondaryColor,
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding * 0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultRadius),
      ),
      textStyle: kButtonTextStyle,
      elevation: 2,
      shadowColor: kPrimaryColor.withOpacity(0.3),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kPrimaryColor,
      textStyle: kLinkTextStyle,
    ),
  ),
  cardTheme: CardTheme(
    color: kSecondaryColor,
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kDefaultRadius),
    ),
    margin: const EdgeInsets.symmetric(vertical: kDefaultMargin / 2, horizontal: kDefaultMargin),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: kBackgroundColor,
    elevation: 0,
    iconTheme: const IconThemeData(color: kTextColor),
    titleTextStyle: GoogleFonts.poppins(
      color: kTextColor,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
  useMaterial3: true,
);