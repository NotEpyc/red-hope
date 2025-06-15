import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/theme.dart';
import '../../../widgets/carousel/custom_carousel.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import './admin_profile_page.dart';
import './edit_news_page.dart';
import './donors_page.dart';
import './requests_page.dart';
import './organizations_page.dart';
import './notifications_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../../widgets/common/custom_app_bar.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int _currentNewsIndex = 0;
  List<Map<String, dynamic>> _newsItems = [];
  String _adminName = '';
  String? _adminImageUrl;
  bool _isLoading = true;
  bool _isEditingNews = false;
  int _userCount = 0;
  int _orgCount = 0;
  int _unreadNotifications = 2; // Start with some dummy unread notifications

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _loadCounts() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').count().get();
      final orgsSnapshot = await FirebaseFirestore.instance.collection('organisations').count().get();
      
      if (mounted) {
        setState(() {
          _userCount = usersSnapshot.count ?? 0;
          _orgCount = orgsSnapshot.count ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading counts: $e');
    }
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _loadAdminData(),
      _loadNewsItems(),
      _loadCounts(),
    ]);
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAdminData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .get();
        
        if (mounted) {
          setState(() {
            _adminName = userData['name'] ?? '';
            _adminImageUrl = userData['localImagePath'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    }
  }

  Future<void> _loadNewsItems() async {
    try {
      debugPrint('=== Starting to load news items ===');
      List<Map<String, dynamic>> orderedNews = [];
      
      for (int i = 1; i <= 3; i++) {
        final docId = 'news_$i';
        debugPrint('Attempting to load $docId');
        
        final docSnapshot = await FirebaseFirestore.instance
            .collection('news')
            .doc(docId)
            .get();
        
        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          debugPrint('$docId found: ${data.toString()}');
          orderedNews.add(data);
        } else {
          debugPrint('$docId does not exist, using placeholder');
          orderedNews.add({
            'title': 'Add News Item',
            'description': 'Click to add news content',
            'imageUrl': '',
          });
        }
      }

      debugPrint('=== Finished loading news items ===');
      if (mounted) {
        setState(() {
          _newsItems = orderedNews;
        });
      }
    } catch (e) {
      debugPrint('Error loading news items: $e');
      setState(() {
        _newsItems = List.generate(3, (index) => {
          'title': 'Add News Item',
          'description': 'Click to add news content',
          'imageUrl': '',
        });
      });
    }
  }

  Widget _buildNewsCarousel() {
    return Column(
      children: [
        Stack(
          children: [
            CustomCarousel(
              items: _newsItems,
              height: 200,
              viewportFraction: 0.9,
              autoPlay: !_isEditingNews,
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
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () async {
                  if (!_isEditingNews) {
                    setState(() => _isEditingNews = true);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditNewsPage(
                          newsItem: _newsItems[_currentNewsIndex],
                          newsIndex: _currentNewsIndex,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadNewsItems();
                    }
                    setState(() => _isEditingNews = false);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.1),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    _isEditingNews ? Icons.close : Icons.edit,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
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
  }  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: 'Welcome back,',
      subtitle: _adminName,  
      imagePath: _adminImageUrl,
      onProfileTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminProfilePage()),
        );
      },
      onNotificationTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsPage()),
        );
      },
      showNotificationBadge: true, // Will show the red dot indicator for unread notifications
    );
  }

  Widget _buildStatisticsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [                Container(                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _userCount.toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      'Active Users',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [                Container(                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.business_outlined,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _orgCount.toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      'Organizations',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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

    Widget _buildBody() {
      switch (_selectedIndex) {
        case 0:
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildNewsCarousel(),
                        _buildStatisticsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );        case 1:
          return const DonorsPage();        case 2:
          return const RequestsPage();
        case 3:
          return const OrganizationsPage();
        default:
          return const SizedBox.shrink();
      }
    }

    return WillPopScope(
      onWillPop: () async {
        bool? exitConfirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return exitConfirmed ?? false;
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: SafeArea(
            child: Padding(                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: GNav(
                rippleColor: Colors.grey[300]!,
                hoverColor: Colors.grey[100]!,
                gap: 4,
                activeColor: AppTheme.primaryColor,
                iconSize: 22,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: Colors.transparent,
                color: Colors.black,
                tabs: [
                  GButton(
                    icon: Icons.home_outlined,
                    text: 'Home',
                    style: GnavStyle.google,
                    border: _selectedIndex == 0 ? Border.all(color: AppTheme.primaryColor, width: 1.5) : null,
                  ),                  GButton(
                    icon: Icons.water_drop_outlined,
                    text: 'Donors',
                    style: GnavStyle.google,
                    border: _selectedIndex == 1 ? Border.all(color: AppTheme.primaryColor, width: 1.5) : null,
                  ),                  GButton(
                    icon: Icons.list_alt_outlined,
                    text: 'Requests',
                    style: GnavStyle.google,
                    border: _selectedIndex == 2 ? Border.all(color: AppTheme.primaryColor, width: 1.5) : null,
                  ),
                  GButton(
                    icon: Icons.business_outlined,
                    text: 'Orgs',
                    style: GnavStyle.google,
                    border: _selectedIndex == 3 ? Border.all(color: AppTheme.primaryColor, width: 1.5) : null,
                  ),
                ],
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}