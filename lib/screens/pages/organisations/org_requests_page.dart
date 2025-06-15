import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class OrgRequestsPage extends StatefulWidget {
  const OrgRequestsPage({super.key});

  @override
  State<OrgRequestsPage> createState() => _OrgRequestsPageState();
}

class _OrgRequestsPageState extends State<OrgRequestsPage> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    // Simulating network delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _requests.addAll([
          {
            'id': '1',
            'patientName': 'John Smith',
            'bloodGroup': 'A+',
            'urgency': 'High',
            'hospital': 'City Hospital',
            'description': 'Emergency surgery scheduled',
            'units': 2,
            'status': 'pending',
            'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
          },
          {
            'id': '2',
            'patientName': 'Sarah Johnson',
            'bloodGroup': 'O-',
            'urgency': 'Medium',
            'hospital': 'General Hospital',
            'description': 'Regular transfusion needed',
            'units': 1,
            'status': 'fulfilled',
            'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          },
          {
            'id': '3',
            'patientName': 'Robert Wilson',
            'bloodGroup': 'B+',
            'urgency': 'High',
            'hospital': 'Medicare Center',
            'description': 'Accident case',
            'units': 3,
            'status': 'expired',
            'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
          },
          {
            'id': '4',
            'patientName': 'Emily Brown',
            'bloodGroup': 'AB+',
            'urgency': 'Medium',
            'hospital': 'Life Care Hospital',
            'description': 'Planned surgery next week',
            'units': 2,
            'status': 'pending',
            'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
          },
          {
            'id': '5',
            'patientName': 'Michael Davis',
            'bloodGroup': 'O+',
            'urgency': 'High',
            'hospital': 'City Hospital',
            'description': 'Emergency case',
            'units': 4,
            'status': 'fulfilled',
            'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
          },
          {
            'id': '6',
            'patientName': 'Lisa Anderson',
            'bloodGroup': 'A-',
            'urgency': 'Low',
            'hospital': 'General Hospital',
            'description': 'Regular checkup',
            'units': 1,
            'status': 'expired',
            'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
          }
        ]);
        _isLoading = false;
      });
    }
  }

  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  List<Map<String, dynamic>> _getFilteredRequests(String status) {
    return _requests.where((request) => 
      (request['status'] ?? '').toLowerCase() == status.toLowerCase()
    ).toList();
  }

  Widget _buildRequestsList(String status) {
    final filteredRequests = _getFilteredRequests(status);
    
    return filteredRequests.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${status.toLowerCase()} requests',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: filteredRequests.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final request = filteredRequests[index];
              final timestamp = request['timestamp'] as Timestamp;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
                color: AppTheme.primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  request['bloodGroup'] ?? 'Unknown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: request['urgency']?.toLowerCase() == 'high'
                                      ? Colors.red[50]
                                      : request['urgency']?.toLowerCase() == 'medium'
                                          ? Colors.orange[50]
                                          : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  request['urgency'] ?? 'Normal',
                                  style: TextStyle(
                                    color: request['urgency']?.toLowerCase() == 'high'
                                        ? Colors.red
                                        : request['urgency']?.toLowerCase() == 'medium'
                                            ? Colors.orange[700]
                                            : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _getTimeAgo(timestamp),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        request['patientName'] ?? 'Unknown Patient',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request['hospital'] ?? 'Unknown Hospital',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request['description'] ?? 'No description provided',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${request['units']} units needed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (status == 'pending')                            TextButton(
                              onPressed: () {
                                // TODO: Implement mark as fulfilled functionality
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                side: const BorderSide(color: Colors.white, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text('Mark as Fulfilled'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey[600],
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Fulfilled'),
              Tab(text: 'Expired'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(              child: SpinKitPumpingHeart(
                color: AppTheme.primaryColor,
                size: 50.0,
                controller: AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
              )
            )
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestsList('pending'),
                    _buildRequestsList('fulfilled'),
                    _buildRequestsList('expired'),
                  ],
                ),
    );
  }
}
