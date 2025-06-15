import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _selectedBloodType = 'All';
  String _selectedUrgency = 'All';
  late final AnimationController _spinController;
  
  final List<String> _bloodTypes = ['All', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _urgencyLevels = ['All', 'High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadDummyData();
  }

  @override
  void dispose() {
    if (_spinController.isAnimating) {
      _spinController.stop();
    }
    _spinController.dispose();
    super.dispose();
  }

  void _loadDummyData() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _requests = [
            {
              'id': '1',
              'patientName': 'John Doe',
              'bloodType': 'A+',
              'units': 2,
              'hospital': 'City Hospital',
              'urgency': 'High',
              'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
              'status': 'Pending',
              'contact': '+91 9876543210',
            },
            {
              'id': '2',
              'patientName': 'Jane Smith',
              'bloodType': 'O-',
              'units': 3,
              'hospital': 'General Hospital',
              'urgency': 'Medium',
              'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
              'status': 'Accepted',
              'contact': '+91 9876543211',
            },
            {
              'id': '3',
              'patientName': 'Mike Johnson',
              'bloodType': 'B+',
              'units': 1,
              'hospital': 'Apollo Hospital',
              'urgency': 'Low',
              'timestamp': DateTime.now().subtract(const Duration(days: 1)),
              'status': 'Completed',
              'contact': '+91 9876543212',
            },
            {
              'id': '4',
              'patientName': 'Sarah Williams',
              'bloodType': 'AB+',
              'units': 4,
              'hospital': 'Medicare Center',
              'urgency': 'High',
              'timestamp': DateTime.now().subtract(const Duration(minutes: 45)),
              'status': 'Pending',
              'contact': '+91 9876543213',
            },
            {
              'id': '5',
              'patientName': 'David Chen',
              'bloodType': 'B-',
              'units': 2,
              'hospital': 'Life Care Hospital',
              'urgency': 'High',
              'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
              'status': 'Pending',
              'contact': '+91 9876543214',
            },
            {
              'id': '6',
              'patientName': 'Emily Brown',
              'bloodType': 'A-',
              'units': 1,
              'hospital': 'City Medical Center',
              'urgency': 'Medium',
              'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
              'status': 'Accepted',
              'contact': '+91 9876543215',
            },
            {
              'id': '7',
              'patientName': 'Robert Wilson',
              'bloodType': 'O+',
              'units': 3,
              'hospital': 'Global Hospital',
              'urgency': 'High',
              'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
              'status': 'Pending',
              'contact': '+91 9876543216',
            },
            {
              'id': '8',
              'patientName': 'Maria Garcia',
              'bloodType': 'AB-',
              'units': 2,
              'hospital': 'Community Hospital',
              'urgency': 'Low',
              'timestamp': DateTime.now().subtract(const Duration(hours: 12)),
              'status': 'Completed',
              'contact': '+91 9876543217',
            },
          ];
          _isLoading = false;
        });
      }
    });
  }

  List<Map<String, dynamic>> _getFilteredRequests() {
    return _requests.where((request) {
      bool matchesBloodType = _selectedBloodType == 'All' || request['bloodType'] == _selectedBloodType;
      bool matchesUrgency = _selectedUrgency == 'All' || request['urgency'] == _selectedUrgency;
      return matchesBloodType && matchesUrgency;
    }).toList()
      ..sort((a, b) {
        switch (_selectedFilter) {
          case 'Time':
            return (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime);
          case 'Urgency':
            final urgencyOrder = {'High': 0, 'Medium': 1, 'Low': 2};
            return (urgencyOrder[a['urgency']] ?? 3).compareTo(urgencyOrder[b['urgency']] ?? 3);
          default:
            return (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime);
        }
      });
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
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
  Color _getUrgencyColor(String urgency) {
    final color = AppTheme.primaryColor;
    switch (urgency) {
      case 'High':
        return color;
      case 'Medium':
        return color.withOpacity(0.8);
      case 'Low':
        return color.withOpacity(0.6);
      default:
        return color.withOpacity(0.4);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Requests',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedFilter = 'All';
                            _selectedBloodType = 'All';
                            _selectedUrgency = 'All';
                          });
                          if (mounted) {
                            this.setState(() {});
                          }
                        },
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Sort section
                  const Text(
                    'Sort by',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['Time', 'Urgency'].map((filter) => _buildFilterChip(
                      label: filter,
                      selected: _selectedFilter == filter,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = selected ? filter : 'Time');
                        if (mounted) {
                          this.setState(() {});
                        }
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Blood Type section
                  const Text(
                    'Blood Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _bloodTypes.map((type) => _buildFilterChip(
                      label: type,
                      selected: _selectedBloodType == type,
                      onSelected: (selected) {
                        setState(() => _selectedBloodType = selected ? type : 'All');
                        if (mounted) {
                          this.setState(() {});
                        }
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Urgency section
                  const Text(
                    'Urgency Level',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _urgencyLevels.map((urgency) => _buildFilterChip(
                      label: urgency,
                      selected: _selectedUrgency == urgency,
                      onSelected: (selected) {
                        setState(() => _selectedUrgency = selected ? urgency : 'All');
                        if (mounted) {
                          this.setState(() {});
                        }
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 32),
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: selected,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? Colors.transparent : AppTheme.primaryColor,
      ),
      onSelected: onSelected,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {      return Center(
        child: SpinKitPumpingHeart(
          color: AppTheme.primaryColor,
          size: 50.0,
          controller: AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1200),
          )..repeat(),
        ),
      );
    }

    final filteredRequests = _getFilteredRequests();

    return Scaffold(
      body: Column(
        children: [
          // Header with filter button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Blood Requests (${filteredRequests.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.filter_list),
                  label: Text(_selectedFilter != 'All' || _selectedBloodType != 'All' || _selectedUrgency != 'All' 
                    ? 'Filters Applied'
                    : 'Filter'),
                  onPressed: _showFilterSheet,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          // Requests list
          Expanded(
            child: filteredRequests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No requests found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredRequests.length,
                    itemBuilder: (context, index) {
                      final request = filteredRequests[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            // TODO: Show request details
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row with name and urgency
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        request['patientName'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getUrgencyColor(request['urgency']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        request['urgency'],
                                        style: TextStyle(
                                          color: _getUrgencyColor(request['urgency']),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Blood info row
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        request['bloodType'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${request['units']} units needed',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Hospital and time
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.local_hospital_outlined,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  request['hospital'],
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _getTimeAgo(request['timestamp']),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
