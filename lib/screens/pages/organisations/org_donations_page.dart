import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import 'package:intl/intl.dart';

class OrgDonationsPage extends StatefulWidget {
  const OrgDonationsPage({super.key});

  @override
  State<OrgDonationsPage> createState() => _OrgDonationsPageState();
}

class _OrgDonationsPageState extends State<OrgDonationsPage> {
  final List<Map<String, dynamic>> _dummyDonations = [
    {
      'id': '1',
      'donorId': '1', // John Doe
      'donorName': 'John Doe',
      'bloodType': 'A+',
      'donationDate': DateTime.now().subtract(const Duration(days: 30)),
      'units': 1,
      'status': 'Completed',
      'location': 'Main Branch',
      'notes': 'Regular donor, no complications',
    },
    {
      'id': '2',
      'donorId': '2', // Jane Smith
      'donorName': 'Jane Smith',
      'bloodType': 'O-',
      'donationDate': DateTime.now().subtract(const Duration(days: 45)),
      'units': 1,
      'status': 'Completed',
      'location': 'Mobile Camp',
      'notes': 'First-time donor, smooth donation',
    },
    {
      'id': '3',
      'donorId': '3', // Michael Brown
      'bloodType': 'B+',
      'donorName': 'Michael Brown',
      'donationDate': DateTime.now().subtract(const Duration(days: 60)),
      'units': 2,
      'status': 'Completed',
      'location': 'Main Branch',
      'notes': 'Double unit donation',
    },
    {
      'id': '4',
      'donorId': '1', // John Doe's second donation
      'donorName': 'John Doe',
      'bloodType': 'A+',
      'donationDate': DateTime.now().subtract(const Duration(days: 90)),
      'units': 1,
      'status': 'Completed',
      'location': 'Mobile Camp',
      'notes': 'Regular donation',
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredDonations = [];

  @override
  void initState() {
    super.initState();
    _filteredDonations = List.from(_dummyDonations);
  }

  void _filterDonations(String query) {
    setState(() {
      _filteredDonations = _dummyDonations.where((donation) {
        final name = donation['donorName'].toString().toLowerCase();
        final bloodType = donation['bloodType'].toString().toLowerCase();
        final searchLower = query.toLowerCase();
        return name.contains(searchLower) || bloodType.contains(searchLower);
      }).toList();
    });
  }

  void _showDonationDetails(Map<String, dynamic> donation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DonationDetailsSheet(donation: donation),
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
            onChanged: _filterDonations,
            decoration: InputDecoration(
              hintText: 'Search donations...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _filteredDonations.length,
            itemBuilder: (context, index) {
              final donation = _filteredDonations[index];
              return DonationCard(
                donation: donation,
                onTap: () => _showDonationDetails(donation),
              );
            },
          ),
        ),
      ],
    );
  }
}

class DonationCard extends StatelessWidget {
  final Map<String, dynamic> donation;
  final VoidCallback onTap;

  const DonationCard({
    super.key,
    required this.donation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
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
                    donation['bloodType'],
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
                      donation['donorName'],
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
                          DateFormat('MMM d, yyyy').format(donation['donationDate']),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.bloodtype, 
                          size: 16, 
                          color: Colors.white70
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${donation['units']} units',
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

class DonationDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> donation;

  const DonationDetailsSheet({
    super.key,
    required this.donation,
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
                  donation['bloodType'],
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
            donation['donorName'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildDetailRow(Icons.calendar_today, 'Donation Date',
              DateFormat('MMMM d, yyyy').format(donation['donationDate'])),
          _buildDetailRow(Icons.bloodtype, 'Blood Type', donation['bloodType']),
          _buildDetailRow(Icons.local_hospital, 'Units', '${donation['units']} unit(s)'),
          _buildDetailRow(Icons.location_on, 'Location', donation['location']),
          _buildDetailRow(Icons.check_circle, 'Status', donation['status']),
          if (donation['notes'] != null && donation['notes'].isNotEmpty)
            _buildDetailRow(Icons.notes, 'Notes', donation['notes']),
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
          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }
}
