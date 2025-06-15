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
import './user_profile_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import './requests_page.dart';
import './search_page.dart';
import './chat_page.dart';
import './notifications_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class RecentRequest {
  final String patientName;
  final String bloodGroup;
  final String hospital;
  final String status;
  final String postedTime;

  RecentRequest({
    required this.patientName,
    required this.bloodGroup,
    required this.hospital,
    required this.status,
    required this.postedTime,
  });
}

class _UserHomePageState extends State<UserHomePage> with TickerProviderStateMixin {
  int _currentNewsIndex = 0;
  int _currentNavIndex = 0;
  List<Map<String, dynamic>> _newsItems = [];
  List<RecentRequest> _recentRequests = [];
  String _userName = '';
  String? _userImageUrl;
  bool _isLoading = true;
  Widget? _searchPage;
  Widget? _requestsPage;
  Widget? _chatPage;
  bool _isRefreshing = false;
  int _unreadNotifications = 0;
  StreamSubscription<int>? _notificationsSubscription;

  @override
  void initState() {
    super.initState();
    _searchPage = const SearchPage();
    _requestsPage = const RequestsPage(key: ValueKey('requests_page'));
    _chatPage = const ChatPage();
    _setupNotificationsListener();
    _fetchData();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
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
        // Build home page fresh each time to get updated responsive sizes
        return _buildHomePage();
      case 1:
        return _searchPage!;
      case 2:
        return _requestsPage!;
      case 3:
        return _chatPage!;
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRecentRequests() {
    final bodySize = ResponsiveUtils.getBodySize(context);
    final smallTextSize = ResponsiveUtils.getSmallTextSize(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Recent Requests',
                style: TextStyle(
                  fontSize: bodySize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton.icon(
                onPressed: _isRefreshing
                    ? null
                    : () async {
                        setState(() {
                          _isRefreshing = true;
                        });
                        try {
                          await _loadRecentRequests();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Requests refreshed'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to refresh requests. Index is being created, please try again in a few minutes.'),
                                duration: Duration(seconds: 4),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isRefreshing = false;
                            });
                          }
                        }
                      },
                icon: _isRefreshing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      )
                    : Icon(Icons.refresh, size: 20, color: AppTheme.primaryColor),
                label: Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: smallTextSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_recentRequests.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No requests made yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: smallTextSize,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _recentRequests.length,
              itemBuilder: (context, index) {
                final request = _recentRequests[index];
                return Card(
                  elevation: 0,
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppTheme.lightDividerColor,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            request.bloodGroup,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: smallTextSize,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            request.patientName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: smallTextSize,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              request.hospital,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: smallTextSize,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(request.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request.status,
                              style: TextStyle(
                                color: _getStatusColor(request.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Text(
                      request.postedTime,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'fulfilled':
        return Colors.green;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildNewsCarousel(),
          _buildRecentRequests(),
        ],
      ),
    );
  }

  Future<void> _fetchData() async {
    // First load all the data
    await Future.wait([
      _loadUserData(),
      _loadNewsItems(),
      _loadRecentRequests(),
    ]);
    
    // Then show loading indicator for 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (mounted) {
          setState(() {            _userName = userData['name'] ?? '';
            _userImageUrl = userData['localImagePath']; // Changed to use local image path
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }
  Future<void> _loadNewsItems() async {
    try {
      debugPrint('Loading news items for user home page');
      List<Map<String, dynamic>> newsItems = [];
      
      // Load news items in same order as admin page
      for (int i = 1; i <= 3; i++) {
        final docId = 'news_$i';
        debugPrint('Loading $docId');
        
        final docSnapshot = await FirebaseFirestore.instance
            .collection('news')
            .doc(docId)
            .get();
        
        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          debugPrint('Found $docId: ${data['title']}');
          newsItems.add(data);
        }
      }
      
      if (newsItems.isEmpty) {
        debugPrint('No news items found, using defaults');
        newsItems = [
          {
            'title': 'Welcome to RedHope',
            'description': 'Connect with blood donors in your area',
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
    }  }

  Future<void> _loadRecentRequests() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('postedTime', descending: true)
          .limit(3)
          .get();      if (!mounted) return;

      final requests = querySnapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['postedTime'] as Timestamp;
        final now = DateTime.now();
        final difference = now.difference(timestamp.toDate());
        
        String postedTime;
        if (difference.inDays > 7) {
          postedTime = '${(difference.inDays / 7).floor()} weeks ago';
        } else if (difference.inDays > 0) {
          postedTime = '${difference.inDays} days ago';
        } else if (difference.inHours > 0) {
          postedTime = '${difference.inHours} hours ago';
        } else if (difference.inMinutes > 0) {
          postedTime = '${difference.inMinutes} minutes ago';
        } else {
          postedTime = 'Just now';
        }

        return RecentRequest(
          patientName: 'Request for ${data['patientName']}',
          bloodGroup: data['bloodGroup'],
          hospital: data['hospital'],
          status: data['status'] ?? 'Pending',
          postedTime: postedTime,
        );
      }).toList();

      if (mounted) {        setState(() {
          _recentRequests = requests;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent requests: $e');
      rethrow; // Rethrow to handle in UI
    }
  }
  Widget _buildNewsCarousel() {
    return Column(
      children: [
        CustomCarousel(
          items: _newsItems,
          height: 200,
          viewportFraction: 0.9,
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
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _newsItems.asMap().entries.map((entry) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: EdgeInsets.symmetric(horizontal: 4.0),
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
  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: 'Welcome back,',
      subtitle: _userName,
      imagePath: _userImageUrl,
      onProfileTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserProfilePage()),
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
    );
  }
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
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
                border: _currentNavIndex == 0 ? Border.all(color: AppTheme.primaryColor, width: 1.5) : null,
              ),
              GButton(
                icon: Icons.search_outlined,
                text: 'Search',
                style: GnavStyle.google,
                border: _currentNavIndex == 1 ? Border.all(color: AppTheme.primaryColor, width: 1.5) : null,
              ),
              GButton(
                icon: Icons.bloodtype_outlined,
                text: 'Request',
                style: GnavStyle.google,
                border: _currentNavIndex == 2 ? Border.all(color: AppTheme.primaryColor, width: 1.5) : null,
              ),
              GButton(
                icon: Icons.chat_outlined,
                text: 'Chat',
                style: GnavStyle.google,
                border: _currentNavIndex == 3 ? Border.all(color: AppTheme.primaryColor, width: 1.5) : null,
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
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _getPage(_currentNavIndex),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
