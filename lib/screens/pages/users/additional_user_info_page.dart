import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive_utils.dart';

class AdditionalUserInfoPage extends StatefulWidget {
  const AdditionalUserInfoPage({super.key});

  @override
  State<AdditionalUserInfoPage> createState() => _AdditionalUserInfoPageState();
}

class _AdditionalUserInfoPageState extends State<AdditionalUserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _errorMessage = '';
  String? _selectedGender;
  String? _selectedBloodGroup;
  DateTime? _selectedDate;
  bool _isLoading = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Non-Binary', 'Prefer not to say'];
  final List<String> _bloodGroupOptions = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
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
  }

  Future<void> _saveAdditionalInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final age = _getAge();
      if (age == null || age < 16) {
        setState(() {
          _errorMessage = 'You must be at least 16 years old to register';
          _isLoading = false;
        });
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not found';
          _isLoading = false;
        });
        return;
      }
      
      final calculatedAge = _getAge();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'dateOfBirth': _selectedDate,
        'age': calculatedAge,
        'bloodGroup': _selectedBloodGroup,
        'gender': _selectedGender,
        'phone': _phoneController.text,
        'address': _addressController.text,
      });

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home_page', (route) => false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Opacity overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Additional Information',
                    style: AppTheme.headingTextStyle.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // White container with scrollable content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date of Birth Field
                          Text(
                            'Date of Birth',
                            style: AppTheme.labelTextStyle.copyWith(
                              fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getSmallSpace(context) * 0.6),
                          InkWell(
                            onTap: () async {
                              final now = DateTime.now();
                              final firstDate = DateTime(now.year - 100);
                              final lastDate = DateTime(now.year - 16, now.month, now.day);
                              
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? lastDate,
                                firstDate: firstDate,
                                lastDate: lastDate,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: AppTheme.primaryColor,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (picked != null) {
                                setState(() {
                                  _selectedDate = picked;
                                });
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: AppTheme.lightDividerColor,
                                  width: 1,
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: ResponsiveUtils.isSmallPhone(context) ? 14 : 17,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedDate == null
                                          ? 'Select Date of Birth'
                                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                      style: AppTheme.inputTextStyle.copyWith(
                                        fontSize: ResponsiveUtils.getBodySize(context) * 0.9,
                                        color: _selectedDate == null
                                            ? Colors.grey[600]
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getMediumSpace(context)),

                          // Age and Blood Group row
                          Row(
                            children: [
                              // Age Display
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Age',
                                      style: AppTheme.labelTextStyle.copyWith(
                                        fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveUtils.getSmallSpace(context) * 0.6),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: AppTheme.lightDividerColor,
                                          width: 1,
                                        ),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: ResponsiveUtils.isSmallPhone(context) ? 14 : 17,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${_getAge()?.toString() ?? '-'} years',
                                              style: AppTheme.inputTextStyle.copyWith(
                                                fontSize: ResponsiveUtils.getBodySize(context) * 0.9,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              // Blood Group Dropdown
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Blood Group',
                                      style: AppTheme.labelTextStyle.copyWith(
                                        fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveUtils.getSmallSpace(context) * 0.6),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: AppTheme.lightDividerColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedBloodGroup,
                                        menuMaxHeight: 200, // Makes it scrollable with max height
                                        decoration: InputDecoration(
                                          isDense: true, // Makes the field more compact
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: ResponsiveUtils.isSmallPhone(context) ? 12 : 15,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: BorderSide.none,
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: BorderSide(color: AppTheme.lightErrorColor.withOpacity(0.5)),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: BorderSide(color: AppTheme.lightErrorColor),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        style: AppTheme.inputTextStyle.copyWith(
                                          fontSize: ResponsiveUtils.getBodySize(context) * 0.9,
                                          color: Colors.black87,
                                        ),
                                        hint: Text(
                                          'Select',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                        icon: Icon(
                                          Icons.arrow_drop_down,
                                        ),
                                        dropdownColor: Colors.white,
                                        borderRadius: BorderRadius.circular(15), // Rounded corners for dropdown items
                                        items: _bloodGroupOptions.map((String bloodGroup) {
                                          return DropdownMenuItem<String>(
                                            value: bloodGroup,
                                            child: Text(bloodGroup),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _selectedBloodGroup = newValue;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Required';
                                          }
                                          return null;
                                        },
                                        isExpanded: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ResponsiveUtils.getMediumSpace(context)),

                          // Gender Dropdown
                          Text(
                            'Gender',
                            style: AppTheme.labelTextStyle.copyWith(
                              fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getSmallSpace(context) * 0.6),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: AppTheme.lightDividerColor,
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: ResponsiveUtils.isSmallPhone(context) ? 14 : 17,
                                ),
                                border: InputBorder.none,
                              ),
                              style: AppTheme.inputTextStyle.copyWith(
                                fontSize: ResponsiveUtils.getBodySize(context) * 0.9,
                                color: Colors.black87,
                              ),
                              hint: Text(
                                'Select Gender',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              dropdownColor: Colors.white,
                              items: _genderOptions.map((String gender) {
                                return DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(gender),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedGender = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select your gender';
                                }
                                return null;
                              },
                              isExpanded: true,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getMediumSpace(context)),
                          
                          // Phone Field
                          Text(
                            'Phone Number',
                            style: AppTheme.labelTextStyle.copyWith(
                              fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getSmallSpace(context) * 0.6),                            TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            style: AppTheme.inputTextStyle.copyWith(
                              fontSize: ResponsiveUtils.getBodySize(context) * 0.9,
                              color: Colors.black87,
                            ),
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
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: AppTheme.lightErrorColor.withOpacity(0.5), width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: AppTheme.lightErrorColor, width: 1.5),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              if (value.length != 10) {
                                return 'Phone number must be 10 digits';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: ResponsiveUtils.getMediumSpace(context)),

                          // Address Field
                          Text(
                            'Address',
                            style: AppTheme.labelTextStyle.copyWith(
                              fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getSmallSpace(context) * 0.6),                          TextFormField(
                            controller: _addressController,
                            maxLines: null, // Allow unlimited lines
                            minLines: 3, // Start with 3 lines minimum
                            style: AppTheme.inputTextStyle.copyWith(
                              fontSize: ResponsiveUtils.getBodySize(context) * 0.9,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: ResponsiveUtils.isSmallPhone(context) ? 14 : 17,
                              ),
                              filled: true,
                              fillColor: Colors.white,
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
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: AppTheme.lightErrorColor.withOpacity(0.5), width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: AppTheme.lightErrorColor, width: 1.5),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your address';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: ResponsiveUtils.getMediumSpace(context)),

                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: ResponsiveUtils.getSmallSpace(context),
                              ),
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: AppTheme.lightErrorColor,
                                  fontSize: ResponsiveUtils.getSmallTextSize(context),
                                ),
                              ),
                            ),

                          // Continue button at the bottom with some padding
                          Padding(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveAdditionalInfo,
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text('Continue'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}