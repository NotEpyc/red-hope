import 'package:flutter/material.dart';
import 'dart:async';
import 'carousel_controller.dart';
import '../../../theme/theme.dart';

class CustomCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final double height;
  final double viewportFraction;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Duration autoPlayAnimationDuration;
  final Curve autoPlayCurve;
  final bool enlargeCenterPage;
  final Function(int)? onPageChanged;

  const CustomCarousel({
    super.key,
    required this.items,
    this.height = 200.0,
    this.viewportFraction = 0.9,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.autoPlayAnimationDuration = const Duration(milliseconds: 800),
    this.autoPlayCurve = Curves.fastOutSlowIn,
    this.enlargeCenterPage = true,
    this.onPageChanged,
  });

  @override
  State<CustomCarousel> createState() => _CustomCarouselState();
}

class _CustomCarouselState extends State<CustomCarousel> with SingleTickerProviderStateMixin {
  late final CustomCarouselController _controller;
  Timer? _autoPlayTimer;
  int _currentPage = 0;
  @override
  void initState() {
    super.initState();
    _controller = CustomCarouselController(viewportFraction: widget.viewportFraction);
    if (widget.autoPlay) {
      _startAutoPlay();
    }

    _controller.pageController.addListener(() {
      final currentPage = _controller.pageController.page?.round() ?? 0;
      if (currentPage != _currentPage) {
        setState(() {
          _currentPage = currentPage;
        });
        widget.onPageChanged?.call(_currentPage);
      }
    });
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (_controller.pageController.hasClients) {
        final nextPage = (_currentPage + 1) % widget.items.length;
        _controller.animateToPage(nextPage);
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _controller.pageController,
        itemCount: widget.items.length,
        pageSnapping: true,
        padEnds: false,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final isCurrentPage = index == _currentPage;
          
          return AnimatedContainer(
            duration: widget.autoPlayAnimationDuration,
            curve: widget.autoPlayCurve,
            margin: EdgeInsets.symmetric(
              horizontal: 5.0,
              vertical: isCurrentPage && widget.enlargeCenterPage ? 0 : 10.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(item['imageUrl']),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [                      Colors.transparent,
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.secColor.withOpacity(0.8),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['description'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
