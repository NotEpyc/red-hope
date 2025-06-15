import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive_utils.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;  final List<Map<String, dynamic>> _allRequests = [
    {
      'patientName': 'John Doe',
      'age': 45,
      'bloodGroup': 'A+',
      'hospital': 'City General Hospital',
      'urgency': 'High',
      'postedTime': '10 min ago',
      'unitsNeeded': 2,
      'contactNumber': '+91 9876543210',
      'additionalInfo': 'Heart surgery scheduled for tomorrow morning',
    },
    {
      'patientName': 'Rachel Green',
      'age': 29,
      'bloodGroup': 'B-',
      'hospital': 'City Medical Center',
      'urgency': 'Medium',
      'postedTime': '15 min ago',
      'unitsNeeded': 1,
      'contactNumber': '+91 9876543215',
      'additionalInfo': 'Scheduled transfusion for anemia treatment',
    },
    {
      'patientName': 'Ross Geller',
      'age': 35,
      'bloodGroup': 'AB+',
      'hospital': 'Central Hospital',
      'urgency': 'Medium',
      'postedTime': '25 min ago',
      'unitsNeeded': 2,
      'contactNumber': '+91 9876543216',
      'additionalInfo': 'Scheduled for minor surgery next week',
    },
    {
      'patientName': 'Sarah Smith',
      'age': 32,
      'bloodGroup': 'O-',
      'hospital': 'Memorial Hospital',      'urgency': 'High',
      'postedTime': '30 min ago',
      'unitsNeeded': 1,
      'contactNumber': '+91 9876543211',
      'additionalInfo': 'Regular transfusion needed',
    },
    {
      'patientName': 'Michael Brown',
      'age': 28,
      'bloodGroup': 'B+',
      'hospital': "St. Mary's Medical Center",
      'urgency': 'High',
      'postedTime': '1 hour ago',
      'unitsNeeded': 3,
      'contactNumber': '+91 9876543212',
      'additionalInfo': 'Accident case, immediate requirement',
    },
    {
      'patientName': 'Emily Johnson',
      'age': 55,
      'bloodGroup': 'AB-',
      'hospital': 'Apollo Hospital',      'urgency': 'High',
      'postedTime': '2 hours ago',
      'unitsNeeded': 2,
      'contactNumber': '+91 9876543213',
      'additionalInfo': 'Surgery scheduled for evening',
    },
    {
      'patientName': 'David Wilson',
      'age': 40,
      'bloodGroup': 'O+',
      'hospital': 'Fortis Hospital',
      'urgency': 'High',
      'postedTime': '3 hours ago',
      'unitsNeeded': 4,
      'contactNumber': '+91 9876543214',
      'additionalInfo': 'Multiple injuries from road accident',
    },
  ];
  List<Map<String, dynamic>> _filteredRequests = [];
  String _selectedBloodGroup = '';
  String _selectedUrgency = '';

  @override
  void initState() {
    super.initState();
    _filteredRequests = List.from(_allRequests);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _filterRequests();
  }

  void _filterRequests() {
    setState(() {
      _filteredRequests = _allRequests.where((request) {
        final search = _searchController.text.toLowerCase();
        final matchesSearch = request['patientName'].toString().toLowerCase().contains(search) ||
            request['hospital'].toString().toLowerCase().contains(search) ||
            request['bloodGroup'].toString().toLowerCase().contains(search);
        
        final matchesBloodGroup = _selectedBloodGroup.isEmpty || 
            request['bloodGroup'] == _selectedBloodGroup;
            
        final matchesUrgency = _selectedUrgency.isEmpty || 
            request['urgency'] == _selectedUrgency;

        return matchesSearch && matchesBloodGroup && matchesUrgency;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedBloodGroup = '';
      _selectedUrgency = '';
      _searchController.clear();
      _filteredRequests = List.from(_allRequests);
    });
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  Widget _buildSearchSection() {
    final smallTextSize = ResponsiveUtils.getSmallTextSize(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Colors.grey[800]),
                decoration: InputDecoration(                  hintText: 'Search for blood requests...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear, color: AppTheme.primaryColor),
                          onPressed: () {
                            _searchController.clear();
                            _filterRequests();
                          },
                        ),
                      IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            _showFilters ? Icons.filter_list_off : Icons.filter_list,
                            key: ValueKey<bool>(_showFilters),
                            color: _showFilters ? AppTheme.primaryColor : Colors.grey[600],
                          ),
                        ),
                        onPressed: _toggleFilters,
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),
          
          // Active Filters Display
          if (_selectedBloodGroup.isNotEmpty || _selectedUrgency.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedBloodGroup.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(_selectedBloodGroup),
                          deleteIcon: Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              _selectedBloodGroup = '';
                              _filterRequests();
                            });
                          },
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: smallTextSize,
                          ),
                        ),
                      ),
                    if (_selectedUrgency.isNotEmpty)
                      Chip(
                        label: Text(_selectedUrgency),
                        deleteIcon: Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _selectedUrgency = '';
                            _filterRequests();
                          });
                        },
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: smallTextSize,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          
          // Expandable Filter Section
          ClipRect(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              alignment: Alignment.topCenter,
              heightFactor: _showFilters ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    // Blood Group and Urgency Filters in a Row
                    Row(
                      children: [
                        // Blood Group Filter
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedBloodGroup.isEmpty ? null : _selectedBloodGroup,
                              hint: Text('Blood Group', style: TextStyle(fontSize: smallTextSize)),
                              isExpanded: true,
                              underline: SizedBox(),
                              items: [
                                DropdownMenuItem(
                                  value: '',
                                  child: Text('All Blood Groups', style: TextStyle(fontSize: smallTextSize)),
                                ),
                                ...['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                                    .map((group) => DropdownMenuItem(
                                          value: group,
                                          child: Text(group, style: TextStyle(fontSize: smallTextSize)),
                                        ))
                                    .toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedBloodGroup = value ?? '';
                                  _filterRequests();
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        // Urgency Filter
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedUrgency.isEmpty ? null : _selectedUrgency,
                              hint: Text('Urgency', style: TextStyle(fontSize: smallTextSize)),
                              isExpanded: true,
                              underline: SizedBox(),                              items: [
                                DropdownMenuItem(
                                  value: '',
                                  child: Text('All Urgency', style: TextStyle(fontSize: smallTextSize)),
                                ),
                                DropdownMenuItem(
                                  value: 'High',
                                  child: Text('High', style: TextStyle(fontSize: smallTextSize)),
                                ),
                                DropdownMenuItem(
                                  value: 'Medium',
                                  child: Text('Medium', style: TextStyle(fontSize: smallTextSize)),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedUrgency = value ?? '';
                                  _filterRequests();
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodySize = ResponsiveUtils.getBodySize(context);
    final smallTextSize = ResponsiveUtils.getSmallTextSize(context);
    
    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Section
          _buildSearchSection(),
          
          // Results Count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${_filteredRequests.length} requests found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: smallTextSize,
                  ),
                ),
              ],
            ),
          ),
          
          // Request List
          Expanded(
            child: _filteredRequests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No matching requests found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: bodySize,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredRequests.length,
                    itemBuilder: (context, index) {
                      final request = _filteredRequests[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.lightDividerColor),
                        ),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.all(16),
                          childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                  request['bloodGroup'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: smallTextSize,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request['patientName'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: bodySize,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      request['hospital'],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: smallTextSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: request['urgency'] == 'High'
                                      ? Colors.red[50]
                                      : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  request['urgency'],
                                  style: TextStyle(
                                    color: request['urgency'] == 'High'
                                        ? Colors.red
                                        : Colors.orange[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  request['postedTime'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Icon(
                                  Icons.bloodtype_outlined,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${request['unitsNeeded']} units needed',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          children: [
                            Divider(),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.person_outline, color: AppTheme.primaryColor),
                              title: Text(
                                'Patient Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Age: ${request['age']} years',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.phone_outlined, color: AppTheme.primaryColor),
                              title: Text(
                                'Contact',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                request['contactNumber'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (request['additionalInfo'] != null)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.info_outline, color: AppTheme.primaryColor),
                                title: Text(
                                  'Additional Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  request['additionalInfo'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // TODO: Implement donate action
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: Text(
                                  'Donate',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
