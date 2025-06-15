import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive_utils.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _hospitalNameController = TextEditingController();
  final TextEditingController _contactPersonNameController = TextEditingController();
  final TextEditingController _contactPersonNumberController = TextEditingController();
  final TextEditingController _additionalInfoController = TextEditingController();
  
  String? _selectedBloodGroup;
  String _errorMessage = '';
  bool _isLoading = false;

  final List<String> _bloodGroupOptions = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void dispose() {
    _patientNameController.dispose();
    _unitsController.dispose();
    _ageController.dispose();
    _hospitalNameController.dispose();
    _contactPersonNameController.dispose();
    _contactPersonNumberController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _saveRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not found. Please sign in again.';
          _isLoading = false;
        });
        return;
      }

      final requestData = {
        'patientName': _patientNameController.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'unitsNeeded': int.parse(_unitsController.text.trim()),
        'age': int.parse(_ageController.text.trim()),
        'hospital': _hospitalNameController.text.trim(),
        'contactPersonName': _contactPersonNameController.text.trim(),
        'contactNumber': _contactPersonNumberController.text.trim(),
        'additionalInfo': _additionalInfoController.text.trim(),
        'userId': user.uid,
        'status': 'Active',
        'postedTime': FieldValue.serverTimestamp(),
        'urgency': 'High',
      };

      await FirebaseFirestore.instance
          .collection('requests')
          .add(requestData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Blood request posted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear all fields after successful submission
        _patientNameController.clear();
        _unitsController.clear();
        _ageController.clear();
        _hospitalNameController.clear();
        _contactPersonNameController.clear();
        _contactPersonNumberController.clear();
        _additionalInfoController.clear();
        setState(() {
          _selectedBloodGroup = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to post request: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Blood Request',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Patient Name Field
                    Text(
                      'Patient Name',
                      style: AppTheme.labelTextStyle.copyWith(
                        fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _patientNameController,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: ResponsiveUtils.isSmallPhone(context) ? 14 : 17,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.lightDividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.lightDividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter patient name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Blood Group Dropdown
                    Text(
                      'Required Blood Group',
                      style: AppTheme.labelTextStyle.copyWith(
                        fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppTheme.lightDividerColor,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedBloodGroup,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: ResponsiveUtils.isSmallPhone(context) ? 14 : 17,
                          ),
                          border: InputBorder.none,
                        ),
                        hint: Text('Select Blood Group'),
                        items: _bloodGroupOptions.map((String group) {
                          return DropdownMenuItem<String>(
                            value: group,
                            child: Text(group),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedBloodGroup = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select blood group';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Units Required Field
                    Text(
                      'Units Required',
                      style: AppTheme.labelTextStyle.copyWith(
                        fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _unitsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: ResponsiveUtils.isSmallPhone(context) ? 14 : 17,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.lightDividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.lightDividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter required units';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Age Field
                    Text(
                      'Patient Age',
                      style: AppTheme.labelTextStyle.copyWith(
                        fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: ResponsiveUtils.isSmallPhone(context) ? 14 : 17,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.lightDividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.lightDividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter age';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age <= 0 || age > 150) {
                          return 'Please enter a valid age between 1 and 150';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Hospital Name Field
                    Text(
                      'Hospital Name',
                      style: AppTheme.labelTextStyle.copyWith(
                        fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _hospitalNameController,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: ResponsiveUtils.isSmallPhone(context) ? 14 : 17,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.lightDividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.lightDividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter hospital name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Contact Person Name Field
                    Text(
                      'Contact Person Name',
                      style: AppTheme.labelTextStyle.copyWith(
                        fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contactPersonNameController,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: ResponsiveUtils.isSmallPhone(context) ? 14 : 17,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.lightDividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.lightDividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter contact person name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Contact Person Number Field
                    Text(
                      'Contact Person Number',
                      style: AppTheme.labelTextStyle.copyWith(
                        fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contactPersonNumberController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        prefixText: '+91 ',
                        prefixStyle: AppTheme.inputTextStyle.copyWith(
                          fontSize: ResponsiveUtils.getBodySize(context) * 0.9,
                          color: Colors.black87,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: ResponsiveUtils.isSmallPhone(context) ? 14 : 17,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.lightDividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.lightDividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter contact number';
                        }
                        if (value.length != 10) {
                          return 'Phone number must be 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Additional Information Field
                    Text(
                      'Additional Information',
                      style: AppTheme.labelTextStyle.copyWith(
                        fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _additionalInfoController,
                      maxLines: null,
                      minLines: 3,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: ResponsiveUtils.isSmallPhone(context) ? 14 : 17,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.lightDividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.lightDividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _isLoading ? 'Posting Request...' : 'Post Request',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getBodySize(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
