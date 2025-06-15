import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../theme/theme.dart';
import '../../../widgets/themed_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _localImagePath;
  bool _isEditing = false;
  bool _isLoading = true;
  String? _selectedBloodGroup;
  String? _selectedGender;
  DateTime? _selectedDate;
  Map<String, dynamic> _userData = {};
  int _donationCount = 0;

  final List<String> _bloodGroupOptions = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _genderOptions = ['Male', 'Female', 'Non-Binary', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDonationCount();
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
          setState(() {
            _userData = userData.data() ?? {};            _nameController.text = _userData['name'] ?? '';
            _phoneController.text = _userData['phone']?.toString() ?? '';
            _selectedBloodGroup = _userData['bloodGroup'];
            _selectedGender = _userData['gender'];
            _selectedDate = _userData['dateOfBirth']?.toDate(); // Convert Timestamp to DateTime
            _addressController.text = _userData['address'] ?? '';
            _localImagePath = _userData['localImagePath'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }
  Future<void> _pickImage() async {
    try {
      // Show dialog to choose between camera and gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        try {
          // Get the app's local storage directory
          final Directory appDir = await getApplicationDocumentsDirectory();
          final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
          final String localPath = path.join(appDir.path, fileName);

          // Make sure the directory exists
          if (!await appDir.exists()) {
            await appDir.create(recursive: true);
          }

          // Copy the image file to local storage
          final File newImage = await File(image.path).copy(localPath);
          
          if (await newImage.exists()) {
            // Update the local image path in state and Firestore
            setState(() => _localImagePath = localPath);
            await _updateUserData({'localImagePath': localPath});
          } else {
            throw Exception('Failed to save image');
          }
        } catch (e) {
          debugPrint('Error saving image: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save image')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateUserData(Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(data);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error updating user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_isEditing) return;    final age = _getAge();
    if (age != null && age < 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be at least 16 years old')),
      );
      return;
    }

    final updates = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'bloodGroup': _selectedBloodGroup,
      'gender': _selectedGender,
      'dateOfBirth': _selectedDate,
      'age': age,
      'address': _addressController.text,
    };

    await _updateUserData(updates);
    setState(() => _isEditing = false);
  }

  int? _getAge() {
    if (_selectedDate == null) return null;
    final today = DateTime.now();
    var age = today.year - _selectedDate!.year;
    if (today.month < _selectedDate!.month || 
        (today.month == _selectedDate!.month && today.day < _selectedDate!.day)) {
      age--;
    }
    return age;
  }  Future<void> _signOut() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Logout',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/sign_in', 
            (route) => false
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: ${e.toString()}')),
      );
    }
  }
  Future<void> _loadDonationCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // First try to get the count from the user document
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userData.exists && userData.data()?['donationCount'] != null) {
          setState(() {
            _donationCount = userData.data()!['donationCount'] as int;
          });
          return;
        }

        // If not in user document, count from donations collection
        final donationsSnapshot = await FirebaseFirestore.instance
            .collection('donations')
            .where('userId', isEqualTo: user.uid)
            .get();

        final count = donationsSnapshot.docs.length;

        // Update the count in user document for future quick access
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'donationCount': count});

        if (mounted) {
          setState(() {
            _donationCount = count;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading donation count: $e');
    }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppTheme.primaryColor,
            size: 28, // Increased size
            weight: 700, // Added weight to make it thicker
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save, color: AppTheme.primaryColor),
              onPressed: _saveChanges,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],      ),body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 16), // Added top padding to move content below app bar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppTheme.lightDividerColor,
                          backgroundImage: _localImagePath != null
                              ? FileImage(File(_localImagePath!))
                              : null,
                          child: _localImagePath == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppTheme.primaryColor,
                                )
                              : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.water_drop_sharp,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Donations: ${_donationCount.toString()}',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nameController,
              label: 'Name',
              enabled: _isEditing,
              readOnly: !_isEditing,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),              _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              enabled: _isEditing,
              readOnly: !_isEditing,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              prefixText: '+91 ',
            ),
            const SizedBox(height: 16),
            // Date of Birth
            Padding(
              padding: EdgeInsets.only(left: 4, bottom: 5),
              child: Text(
                'Date of Birth',
                style: AppTheme.labelTextStyle.copyWith(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            GestureDetector(
              onTap: _isEditing ? () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null && mounted) {
                  setState(() => _selectedDate = picked);
                }
              } : null,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppTheme.lightDividerColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),                  title: Text(
                    _selectedDate != null 
                      ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                      : "Select Date",
                    style: TextStyle(
                      color: _isEditing ? Colors.black87 : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  trailing: _isEditing ? Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.primaryColor,
                  ) : null,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),            const SizedBox(height: 16),
            // Blood Group and Age Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 5),
                        child: Text(
                          'Blood Group',
                          style: AppTheme.labelTextStyle.copyWith(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppTheme.lightDividerColor,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedBloodGroup,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.bloodtype_outlined,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: AppTheme.lightDividerColor, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: AppTheme.lightDividerColor, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            enabled: _isEditing,
                          ),                          items: _bloodGroupOptions.map((String bloodGroup) {
                            return DropdownMenuItem<String>(
                              value: bloodGroup,
                              child: Text(
                                bloodGroup,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _isEditing ? Colors.black87 : Colors.grey[600],
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: _isEditing ? (String? newValue) {
                            setState(() => _selectedBloodGroup = newValue);
                          } : null,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: _isEditing ? AppTheme.primaryColor : Colors.grey,
                          ),
                          dropdownColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 5),
                        child: Text(
                          'Age',
                          style: AppTheme.labelTextStyle.copyWith(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(                        height: 56, // Fixed height to match dropdown
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppTheme.lightDividerColor,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cake_outlined,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                _getAge()?.toString() ?? '-',
                                style: TextStyle(
                                  color: _isEditing ? Colors.black87 : Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Gender
            Padding(
              padding: EdgeInsets.only(left: 4, bottom: 5),
              child: Text(
                'Gender',
                style: AppTheme.labelTextStyle.copyWith(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppTheme.lightDividerColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: AppTheme.lightDividerColor, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: AppTheme.lightDividerColor, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabled: _isEditing,
                ),                items: _genderOptions.map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(
                      gender,
                      style: TextStyle(
                        fontSize: 16,
                        color: _isEditing ? Colors.black87 : Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _isEditing ? (String? newValue) {
                  setState(() => _selectedGender = newValue);
                } : null,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: _isEditing ? AppTheme.primaryColor : Colors.grey,
                ),
                dropdownColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),            _buildTextField(
              controller: _addressController,
              label: 'Address',
              enabled: _isEditing,
              readOnly: !_isEditing,
              icon: Icons.location_on_outlined,
              maxLines: 5,  // Maximum 5 lines
              minLines: 1,  // Start with 1 line and expand based on content
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 32),            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: _signOut,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool readOnly = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? minLines,
    String? prefixText,
  }) {
    return ThemedTextField(
      label: label,      icon: icon,
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType ?? TextInputType.text,
      maxLines: maxLines,
      minLines: minLines,
      prefixText: prefixText,
      onChanged: _isEditing ? (value) {
        // Only allow changes when editing
      } : null,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}