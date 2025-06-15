import 'package:flutter/material.dart';

class CustomCarouselController {
  final _pageController;

  CustomCarouselController({double viewportFraction = 0.9})
      : _pageController = PageController(viewportFraction: viewportFraction);

  void nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  PageController get pageController => _pageController;

  void dispose() {
    _pageController.dispose();
  }
}
