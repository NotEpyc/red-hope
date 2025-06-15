import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  String? _localImagePath;
  bool _isEditing = false;
  bool _isLoading = true;
  String? _selectedGender;
  DateTime? _selectedDate;
  Map<String, dynamic> _adminData = {};

  final List<String> _genderOptions = ['Male', 'Female', 'Non-Binary', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
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
            _adminData = userData.data() ?? {};
            _nameController.text = _adminData['name'] ?? '';
            _phoneController.text = _adminData['phone']?.toString() ?? '';
            _selectedGender = _adminData['gender'];
            _selectedDate = _adminData['dateOfBirth']?.toDate();
            _roleController.text = _adminData['role'] ?? 'Blood Bank Admin';
            _localImagePath = _adminData['localImagePath'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading admin data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
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
          final Directory appDir = await getApplicationDocumentsDirectory();
          final String fileName = 'admin_profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
          final String localPath = path.join(appDir.path, fileName);

          if (!await appDir.exists()) {
            await appDir.create(recursive: true);
          }

          final File newImage = await File(image.path).copy(localPath);
          
          if (await newImage.exists()) {
            setState(() => _localImagePath = localPath);
            await _updateAdminData({'localImagePath': localPath});
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

  Future<void> _updateAdminData(Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .update(data);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error updating admin data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_isEditing) return;

    final updates = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'gender': _selectedGender,
      'dateOfBirth': _selectedDate,
      'role': _roleController.text,
    };

    await _updateAdminData(updates);
    setState(() => _isEditing = false);
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
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppTheme.primaryColor,
            size: 28,
            weight: 700,
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
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
                    if (_isEditing)                      Positioned(
                        bottom: 0,
                        right: 8,  // Moved more to the left
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.6),  // Made more transparent
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
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nameController,
              label: 'Name',
              enabled: _isEditing,
              readOnly: !_isEditing,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              enabled: _isEditing,
              readOnly: !_isEditing,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              prefixText: '+91 ',
              prefixStyle: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              inputFormatters: [
                LengthLimitingTextInputFormatter(10),
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _roleController,
              label: 'Role',
              enabled: _isEditing,
              readOnly: !_isEditing,
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 16),
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
                  initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
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
                  ),
                  title: Text(
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
            ),
            const SizedBox(height: 16),
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
                ),
                items: _genderOptions.map((String gender) {
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
            ),            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: () async {
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
                },
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    required bool readOnly,
    required IconData icon,
    TextInputType? keyboardType,
    String? prefixText,
    TextStyle? prefixStyle,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 5),
          child: Text(
            label,
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
          ),          child: TextField(
            controller: controller,
            enabled: enabled,
            readOnly: readOnly,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),              prefixText: prefixText,
              prefixStyle: prefixStyle ?? TextStyle(
                color: enabled ? Colors.black87 : Colors.grey[600],
                fontSize: 16,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            ),
            style: TextStyle(
              color: enabled ? Colors.black87 : Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}