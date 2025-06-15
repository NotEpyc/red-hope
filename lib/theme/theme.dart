import 'package:flutter/material.dart';

class AppTheme {  // Define primary colors
  static const Color primaryColor = Color(0xFFE53940); // Red
  static const Color secColor = Color(0xFFEF5350); // Lighter Red
  static const Color secondaryColor = Colors.white;
  
  // Light theme colors
  static const Color lightBackgroundColor = Colors.white;  static const Color lightTextColor = Color(0xFF333333);
  static const Color lightHintColor = Color(0xFFBDBDBD);
  static const Color lightDividerColor = Color(0xFFEEEEEE);
  static const Color lightErrorColor = Color(0xFFD32F24);
  
  // Shadow colors
  static final Color lightShadowColor = Colors.black.withOpacity(0.04);
  
  // Text styles for reuse
  static final TextStyle headingTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: primaryColor,
    fontSize: 24,
  );
  
  static final TextStyle labelTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: lightTextColor,
    fontSize: 14,
  );
  
  static final TextStyle buttonTextStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: secondaryColor,
  );
  
  static final TextStyle socialButtonTextStyle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: primaryColor,
  );

  static final TextStyle regularTextStyle = TextStyle(
    color: lightTextColor,
    fontSize: 14,
  );

  static final TextStyle inputTextStyle = TextStyle(
    color: lightTextColor,
    fontSize: 16,
  );
  
  static final TextStyle hintTextStyle = TextStyle(
    color: lightHintColor,
    fontSize: 14,
  );

  // Light theme definition
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBackgroundColor,
    cardColor: Colors.white,
    shadowColor: lightShadowColor,
    hintColor: lightHintColor,
    dividerColor: lightDividerColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: lightErrorColor,
      onPrimary: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: lightTextColor),
      titleTextStyle: TextStyle(
        color: lightTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    iconTheme: IconThemeData(
      color: primaryColor, 
      size: 22,
    ),
    textTheme: TextTheme(
      headlineLarge: headingTextStyle,
      titleLarge: TextStyle(color: lightTextColor, fontWeight: FontWeight.bold, fontSize: 18),
      titleMedium: TextStyle(color: lightTextColor, fontWeight: FontWeight.bold, fontSize: 16),
      bodyLarge: TextStyle(color: lightTextColor, fontSize: 16),
      bodyMedium: TextStyle(color: lightTextColor, fontSize: 14),
      labelLarge: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
      labelMedium: TextStyle(color: primaryColor, fontWeight: FontWeight.w500, fontSize: 14),
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      hintStyle: hintTextStyle,
      filled: true,
      fillColor: Colors.white,
      // Login screen uses custom border radius, so keeping these generic
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: lightDividerColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: lightDividerColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: lightErrorColor.withOpacity(0.5), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: lightErrorColor, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: lightDividerColor.withOpacity(0.5), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: primaryColor.withOpacity(0.5),
        disabledForegroundColor: Colors.white.withOpacity(0.8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(vertical: 16),
        textStyle: buttonTextStyle,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor.withOpacity(0.5), width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(vertical: 16),
        textStyle: socialButtonTextStyle,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size(0, 0),
        textStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        },
      ),
      checkColor: MaterialStateProperty.all(Colors.white),
      side: BorderSide(color: lightDividerColor.withOpacity(0.8), width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
    ),
  );
}