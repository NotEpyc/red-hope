import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';

class OrganizationsPage extends StatefulWidget {
  const OrganizationsPage({super.key});

  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _organizations = [];
  List<Map<String, dynamic>> _filteredOrganizations = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedOrgType = 'All';
  late final AnimationController _spinController;
  final List<String> _orgTypes = ['All', 'NGO', 'Hospital', 'Blood Bank'];
  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadOrganizations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_spinController.isAnimating) {
      _spinController.stop();
    }
    _spinController.dispose();
    super.dispose();
  }

  void _filterOrganizations(String query) {
    setState(() {
      _filteredOrganizations = _organizations.where((org) {
        final name = (org['name'] ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(query.toLowerCase());
        final matchesType = _selectedOrgType == 'All' || org['type'] == _selectedOrgType;
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  Future<void> _loadOrganizations() async {
    try {
      final QuerySnapshot organizationsSnapshot = await FirebaseFirestore.instance
          .collection('organisations')
          .orderBy('name')
          .get();

      setState(() {
        _organizations = organizationsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
        _filteredOrganizations = _organizations;
        _isLoading = false;
      });
    } catch (e) {      debugPrint('Error loading organisations: $e');
      setState(() => _isLoading = false);
    }
  }
  void _showOrganizationDetails(Map<String, dynamic> org) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.9 > 400 ? 400.0 : screenWidth * 0.9;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Container(
            width: dialogWidth,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Organisation Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildDetailRow('Name', org['name'] ?? 'N/A'),
                    _buildDetailRow('Type', org['type'] ?? 'N/A'),
                    _buildDetailRow('Email', org['email'] ?? 'N/A'),
                    _buildDetailRow('Phone', org['phone'] != null ? '+91 ${org['phone']}' : 'N/A'),
                    _buildDetailRow('Registration ID', org['registrationId'] ?? 'N/A'),
                    _buildDetailRow('Address', org['address'] ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 24),
                if (org['phone'] != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.phone, color: Colors.white),
                      label: const Text(
                        'Call',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () async {
                        final phoneNumber = '+91${org['phone']}';
                        final uri = Uri.parse('tel:$phoneNumber');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFilterChip(String label, bool selected, Function(bool) onSelected) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
          fontSize: 13, // Reduced font size
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppTheme.primaryColor,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.white,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Makes the chip more compact
      visualDensity: VisualDensity.compact, // Reduces the internal padding
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0), // Reduced padding
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Slightly reduced border radius
        side: BorderSide(
          color: selected ? AppTheme.primaryColor : Colors.grey[300]!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {      return Center(
        child: SpinKitPumpingHeart(
          color: AppTheme.primaryColor,
          size: 50.0,
          controller: _spinController,
        ),
      );
    }

    return Column(
      children: [
        // Search and filter section
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: _filterOrganizations,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(                  hintText: 'Search organisations by name...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),              const Text(
                'Organisation Type',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),              Wrap(
                spacing: 6, // Reduced spacing between chips
                runSpacing: 6, // Reduced spacing between rows
                children: _orgTypes.map((type) => _buildFilterChip(
                  type,
                  _selectedOrgType == type,
                  (selected) {
                    setState(() {
                      _selectedOrgType = selected ? type : 'All';
                      _filterOrganizations(_searchController.text);
                    });
                  },
                )).toList(),
              ),
            ],
          ),
        ),
        // List section
        Expanded(
          child: _filteredOrganizations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),                      Text(
                        _searchController.text.isEmpty
                            ? 'No organisations registered yet'
                            : 'No organisations match your search',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredOrganizations.length,
                  itemBuilder: (context, index) {
                    final org = _filteredOrganizations[index];
                    return _buildOrganizationCard(org);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOrganizationCard(Map<String, dynamic> org) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      elevation: 0,
      color: AppTheme.primaryColor,
      child: InkWell(
        onTap: () => _showOrganizationDetails(org),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.business_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      org['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      org['type'] ?? 'Unknown Type',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
