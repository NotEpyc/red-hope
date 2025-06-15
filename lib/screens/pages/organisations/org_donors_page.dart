import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import 'package:intl/intl.dart';

class OrgDonorsPage extends StatefulWidget {
  const OrgDonorsPage({super.key});

  @override
  State<OrgDonorsPage> createState() => _OrgDonorsPageState();
}

class _OrgDonorsPageState extends State<OrgDonorsPage> {
  final List<Map<String, dynamic>> _dummyDonors = [
    {
      'id': '1',
      'name': 'John Doe',
      'bloodType': 'A+',
      'lastDonation': DateTime.now().subtract(const Duration(days: 30)),
      'totalDonations': 5,
      'age': 28,
      'phone': '+1234567890',
      'email': 'john.doe@example.com',
      'address': '123 Main St, City',
      'imageUrl': null,
    },
    {
      'id': '2',
      'name': 'Jane Smith',
      'bloodType': 'O-',
      'lastDonation': DateTime.now().subtract(const Duration(days: 45)),
      'totalDonations': 3,
      'age': 32,
      'phone': '+0987654321',
      'email': 'jane.smith@example.com',
      'address': '456 Oak Ave, Town',
      'imageUrl': null,
    },
    {
      'id': '3',
      'name': 'Michael Brown',
      'bloodType': 'B+',
      'lastDonation': DateTime.now().subtract(const Duration(days: 60)),
      'totalDonations': 8,
      'age': 35,
      'phone': '+1122334455',
      'email': 'michael.b@example.com',
      'address': '789 Pine Rd, Village',
      'imageUrl': null,
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredDonors = [];

  @override
  void initState() {
    super.initState();
    _filteredDonors = List.from(_dummyDonors);
  }

  void _filterDonors(String query) {
    setState(() {
      _filteredDonors = _dummyDonors.where((donor) {
        final name = donor['name'].toString().toLowerCase();
        final bloodType = donor['bloodType'].toString().toLowerCase();
        final searchLower = query.toLowerCase();
        return name.contains(searchLower) || bloodType.contains(searchLower);
      }).toList();
    });
  }

  void _showDonorDetails(Map<String, dynamic> donor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DonorDetailsSheet(donor: donor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _filterDonors,
            decoration: InputDecoration(
              hintText: 'Search donors...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _filteredDonors.length,
            itemBuilder: (context, index) {
              final donor = _filteredDonors[index];
              return DonorCard(
                donor: donor,
                onTap: () => _showDonorDetails(donor),
              );
            },
          ),
        ),
      ],
    );
  }
}

class DonorCard extends StatelessWidget {
  final Map<String, dynamic> donor;
  final VoidCallback onTap;

  const DonorCard({
    super.key,
    required this.donor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      elevation: 0,
      color: AppTheme.primaryColor,
      child: InkWell(
        onTap: onTap,
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
                child: Center(
                  child: Text(
                    donor['bloodType'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donor['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, 
                          size: 16, 
                          color: Colors.white70
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(donor['lastDonation']),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.favorite, 
                          size: 16, 
                          color: Colors.white70
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${donor['totalDonations']} donations',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
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

class DonorDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> donor;

  const DonorDetailsSheet({
    super.key,
    required this.donor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  donor['bloodType'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            donor['name'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildDetailRow(Icons.calendar_today, 'Last Donation',
              DateFormat('MMMM d, yyyy').format(donor['lastDonation'])),
          _buildDetailRow(Icons.bloodtype, 'Blood Type', donor['bloodType']),
          _buildDetailRow(Icons.favorite, 'Total Donations', donor['totalDonations'].toString()),
          _buildDetailRow(Icons.person, 'Age', '${donor['age']} years'),
          _buildDetailRow(Icons.phone, 'Phone', donor['phone']),
          _buildDetailRow(Icons.email, 'Email', donor['email']),
          _buildDetailRow(Icons.location_on, 'Address', donor['address']),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
