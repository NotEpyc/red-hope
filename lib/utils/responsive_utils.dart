import 'package:flutter/material.dart';
import 'dart:math' as math;

class ResponsiveUtils {
  // Device size breakpoints
  static const double phoneSmallBreakpoint = 360;
  static const double phoneLargeBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;
  
  // Device type getters
  static bool isSmallPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < phoneSmallBreakpoint;
  }
  
  static bool isLargePhone(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= phoneSmallBreakpoint && width < phoneLargeBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= phoneLargeBreakpoint && width < desktopBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
  
  // Get font sizes based on device
  static double getHeadingSize(BuildContext context) {
    if (isSmallPhone(context)) return 20;
    if (isLargePhone(context)) return 24;
    if (isTablet(context)) return 28;
    return 32; // Desktop
  }
  
  static double getTitleSize(BuildContext context) {
    if (isSmallPhone(context)) return 18;
    if (isLargePhone(context)) return 20;
    if (isTablet(context)) return 22;
    return 24; // Desktop
  }
  
  static double getBodySize(BuildContext context) {
    if (isSmallPhone(context)) return 14;
    if (isLargePhone(context)) return 16;
    return 18; // Tablet and Desktop
  }
  
  static double getSmallTextSize(BuildContext context) {
    if (isSmallPhone(context)) return 12;
    return 14; // All other devices
  }
  
  // Get space sizes based on device
  static double getSmallSpace(BuildContext context) {
    if (isSmallPhone(context)) return 8;
    if (isLargePhone(context)) return 10;
    return 12; // Tablet and Desktop
  }
  
  static double getMediumSpace(BuildContext context) {
    if (isSmallPhone(context)) return 16;
    if (isLargePhone(context)) return 20;
    if (isTablet(context)) return 24;
    return 28; // Desktop
  }
  
  static double getLargeSpace(BuildContext context) {
    if (isSmallPhone(context)) return 24;
    if (isLargePhone(context)) return 32;
    if (isTablet(context)) return 40;
    return 48; // Desktop
  }
  
  // Get widget sizes
  static double getIconSize(BuildContext context) {
    if (isSmallPhone(context)) return 20;
    if (isLargePhone(context)) return 24;
    return 28; // Tablet and Desktop
  }
  
  static double getButtonHeight(BuildContext context) {
    if (isSmallPhone(context)) return 48;
    if (isLargePhone(context)) return 55;
    return 60; // Tablet and Desktop
  }
  
  static double getInputHeight(BuildContext context) {
    if (isSmallPhone(context)) return 50;
    return 55; // All other devices
  }
  
  static double getAvatarRadius(BuildContext context) {
    if (isSmallPhone(context)) return 16;
    if (isLargePhone(context)) return 18;
    if (isTablet(context)) return 22;
    return 26; // Desktop
  }
  
  // Get padding
  static EdgeInsets getScreenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (isSmallPhone(context)) {
      return EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 16);
    } else if (isLargePhone(context)) {
      return EdgeInsets.symmetric(horizontal: width * 0.07, vertical: 20);
    } else if (isTablet(context)) {
      // More padding on tablets for better readability
      return EdgeInsets.symmetric(horizontal: width * 0.1, vertical: 24);
    }
    
    // On desktop, constrain width and center
    return EdgeInsets.symmetric(horizontal: (width - 1000) / 2, vertical: 32)
        .copyWith(left: math.max((width - 1000) / 2, 24), right: math.max((width - 1000) / 2, 24));
  }
  
  // Get the bottom container height ratio for signup/signin pages
  static double getBottomContainerRatio(BuildContext context) {
    if (isSmallPhone(context)) return 0.9; // Small phones need more space
    if (isTablet(context)) return 0.8;    // Tablets can show more background
    return 0.85;                         // Default for regular phones
  }
}