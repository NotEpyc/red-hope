import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../../theme/theme.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/carousel/custom_carousel.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/common/custom_app_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import './org_profile_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import './org_donations_page.dart';
import './org_donors_page.dart';
import './org_requests_page.dart';
import './notifications_page.dart';

class OrgHomePage extends StatefulWidget {
  const OrgHomePage({super.key});

  @override
  State<OrgHomePage> createState() => _OrgHomePageState();
}

class _OrgHomePageState extends State<OrgHomePage> with TickerProviderStateMixin {
  int _currentNewsIndex = 0;
  int _currentNavIndex = 0;
  List<Map<String, dynamic>> _newsItems = [];
  String _orgName = '';
  String? _orgImageUrl;
  bool _isLoading = true;
  Widget? _donorsPage;
  Widget? _donationsPage;
  Widget? _requestsPage;
  int _unreadNotifications = 0;
  StreamSubscription<int>? _notificationsSubscription;

  @override
  void initState() {
    super.initState();
    _donorsPage = const OrgDonorsPage(key: ValueKey('donors_page'));
    _donationsPage = const OrgDonationsPage(key: ValueKey('donations_page'));
    _requestsPage = const OrgRequestsPage(key: ValueKey('requests_page'));
    _setupNotificationsListener();
    _init();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ No user found');
        setState(() => _isLoading = false);
        return;
      }

      // Fetch organization data and news items in parallel
      await Future.wait([
        _loadOrgData(),
        _loadNewsItems(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupNotificationsListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _notificationsSubscription = NotificationService.getUnreadCount(user.uid).listen(
      (count) {
        if (mounted) {
          setState(() {
            _unreadNotifications = count;
          });
        }
      },
      onError: (error) {
        debugPrint('Error getting unread notifications count: $error');
      },
    );
  }

  Future<void> _loadOrgData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('organisations')
            .doc(user.uid)
            .get();

        final data = userData.data();
        if (data != null && mounted) {
          setState(() {
            _orgName = data['name'] ?? '';
            _orgImageUrl = data['localImagePath']; // Will be null if field doesn't exist
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading organization data: $e');
    }
  }

  Future<void> _loadNewsItems() async {
    try {
      debugPrint('Loading news items...');
      List<Map<String, dynamic>> newsItems = [];
      
      for (int i = 1; i <= 3; i++) {
        final docId = 'news_$i';
        
        final docSnapshot = await FirebaseFirestore.instance
            .collection('news')
            .doc(docId)
            .get();
        
        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          newsItems.add(data);
        }
      }
      
      if (newsItems.isEmpty) {
        newsItems = [
          {
            'title': 'Welcome to RedHope',
            'description': 'Connect with donors and manage blood requests efficiently',
            'imageUrl': '',
          },
          {
            'title': 'Manage Blood Inventory',
            'description': 'Track blood donations and manage your blood bank inventory',
            'imageUrl': '',
          },
          {
            'title': 'Stay Connected',
            'description': 'Get real-time updates on blood requests and donor availability',
            'imageUrl': '',
          }
        ];
      }
      
      if (mounted) {
        setState(() {
          _newsItems = newsItems;
        });
      }
    } catch (e) {
      debugPrint('Error loading news items: $e');
    }
  }

  Widget _getPage(int index) {
    if (_isLoading) {
      return Container(
        color: Colors.white,
        child: Center(
          child: SpinKitPumpingHeart(
            color: AppTheme.primaryColor,
            size: 80.0,
            controller: AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
          ),
        ),
      );
    }

    switch (index) {
      case 0:
        return _buildHomePage();
      case 1:
        return _donorsPage!;
      case 2:
        return _donationsPage!;
      case 3:
        return _requestsPage!;
      default:
        return const SizedBox.shrink();
    }
  }
  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          _buildNewsCarousel(),
          const SizedBox(height: 24),
          _buildBloodInventory(),
        ],
      ),
    );
  }

  Widget _buildBloodInventory() {
    final List<Map<String, dynamic>> bloodUnits = [
      {'type': 'A+', 'units': 25},
      {'type': 'A-', 'units': 12},
      {'type': 'B+', 'units': 18},
      {'type': 'B-', 'units': 8},
      {'type': 'O+', 'units': 30},
      {'type': 'O-', 'units': 15},
      {'type': 'AB+', 'units': 10},
      {'type': 'AB-', 'units': 5},
    ];    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Blood Inventory',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),          const SizedBox(height: 16),
          Column(
            children: bloodUnits.map((blood) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            blood['type'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Blood Type',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '${blood['units']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'units',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCarousel() {
    if (_newsItems.isEmpty) {
      return const Center(
        child: Text('Loading news...'),
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomCarousel(
            items: _newsItems,
            height: 200,
            viewportFraction: 0.85,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            onPageChanged: (index) {
              setState(() {
                _currentNewsIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _newsItems.asMap().entries.map((entry) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentNewsIndex == entry.key
                    ? AppTheme.primaryColor
                    : Colors.grey[300],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          color: Colors.white,
          child: Center(
            child: SpinKitPumpingHeart(
              color: AppTheme.primaryColor,
              size: 80.0,
              controller: AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Welcome back,',
        subtitle: _orgName,
        imagePath: _orgImageUrl,
        onProfileTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OrgProfilePage()),
          );
        },
        onNotificationTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationsPage()),
          );
        },
        showNotificationBadge: true,
        notificationCount: _unreadNotifications,
      ),
      body: SafeArea(
        child: _getPage(_currentNavIndex),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Padding(            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),            child: GNav(
              gap: 4, // Reduced gap
              activeColor: AppTheme.primaryColor,
              iconSize: 20, // Reduced icon size
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Reduced horizontal padding
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.transparent,
              color: Colors.grey[600],
              tabActiveBorder: Border.all(color: AppTheme.primaryColor, width: 1.5),
              tabBorderRadius: 100,
              tabs: const [
                GButton(
                  icon: Icons.home_outlined,
                  text: 'Home',
                ),
                GButton(
                  icon: Icons.people_outline,
                  text: 'Donors',
                ),
                GButton(
                  icon: Icons.bloodtype_outlined,
                  text: 'Donations',
                ),
                GButton(
                  icon: Icons.report_outlined,
                  text: 'Requests',
                ),
              ],
              selectedIndex: _currentNavIndex,
              onTabChange: (index) {
                setState(() {
                  _currentNavIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
