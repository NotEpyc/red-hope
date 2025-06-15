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

class OrgProfilePage extends StatefulWidget {
  const OrgProfilePage({super.key});

  @override
  State<OrgProfilePage> createState() => _OrgProfilePageState();
}

class _OrgProfilePageState extends State<OrgProfilePage> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _registrationIdController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  String? _localImagePath;
  bool _isEditing = false;
  bool _isLoading = true;
  Map<String, dynamic> _orgData = {};

  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _loadOrgData();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _registrationIdController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _loadOrgData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('organisations')
            .doc(user.uid)
            .get();

        final data = userData.data();
        if (data != null && mounted) {
          setState(() {
            _orgData = data;
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone']?.toString() ?? '';
            _addressController.text = data['address'] ?? '';
            _registrationIdController.text = data['registrationId'] ?? '';
            _typeController.text = data['type'] ?? '';
            _localImagePath = data['localImagePath']; // Will be null if field doesn't exist
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading organization data: $e');
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
          final String fileName = 'org_profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
          final String localPath = path.join(appDir.path, fileName);

          // Make sure the directory exists
          if (!await appDir.exists()) {
            await appDir.create(recursive: true);
          }

          // Copy the image file to local storage
          final File newImage = await File(image.path).copy(localPath);
          
          if (await newImage.exists()) {
            // Clean up old image if it exists
            if (_localImagePath != null) {
              try {
                final oldFile = File(_localImagePath!);
                if (await oldFile.exists()) {
                  await oldFile.delete();
                }
              } catch (e) {
                debugPrint('Error deleting old image: $e');
              }
            }

            setState(() => _localImagePath = localPath);
            await _updateOrgData({'localImagePath': localPath});
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

  Future<void> _updateOrgData(Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('organisations')
            .doc(user.uid)
            .update(data);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error updating organization data: $e');
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
      'address': _addressController.text,
      'registrationId': _registrationIdController.text,
      'type': _typeController.text,
    };

    await _updateOrgData(updates);
    setState(() => _isEditing = false);
  }

  // Build method with modernized UI elements and functionality
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          color: Colors.white,          child: Center(
            child: SpinKitPumpingHeart(
              color: AppTheme.primaryColor,
              size: 80.0,
              controller: _spinController
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
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppTheme.lightDividerColor,
                          backgroundImage: _localImagePath != null && File(_localImagePath!).existsSync()
                              ? FileImage(File(_localImagePath!))
                              : null,
                          child: _localImagePath == null || !File(_localImagePath!).existsSync()
                              ? const Icon(
                                  Icons.business,
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nameController,
              label: 'Organization Name',
              enabled: _isEditing,
              readOnly: !_isEditing,
              icon: Icons.business_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _registrationIdController,
              label: 'Registration ID',
              enabled: _isEditing,
              readOnly: !_isEditing,
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _typeController,
              label: 'Organization Type',
              enabled: _isEditing,
              readOnly: !_isEditing,
              icon: Icons.category_outlined,
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
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Address',
              enabled: _isEditing,
              readOnly: !_isEditing,
              icon: Icons.location_on_outlined,
              maxLines: 3,
              minLines: 1,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 32),
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
    required IconData icon,
    bool enabled = true,
    bool readOnly = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? minLines,
    String? prefixText,
  }) {
    return ThemedTextField(
      label: label,
      icon: icon,
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
}
