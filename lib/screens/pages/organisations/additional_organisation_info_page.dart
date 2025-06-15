import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive_utils.dart';

class AdditionalOrgInfoPage extends StatefulWidget {
  const AdditionalOrgInfoPage({super.key});

  @override
  State<AdditionalOrgInfoPage> createState() => _AdditionalOrgInfoPageState();
}

class _AdditionalOrgInfoPageState extends State<AdditionalOrgInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _registrationIdController = TextEditingController();
  String _errorMessage = '';
  String? _selectedType;
  bool _isLoading = false;

  final List<String> _orgTypes = ['NGO', 'Blood Bank', 'Hospital'];

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _registrationIdController.dispose();
    super.dispose();
  }

  Future<void> _saveAdditionalInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not found';
          _isLoading = false;
        });
        return;
      }
      
      await FirebaseFirestore.instance.collection('organisations').doc(user.uid).update({
        'type': _selectedType,
        'registrationId': _registrationIdController.text,
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
                    'Organization Information',
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
                          // Organization Type Dropdown
                          Text(
                            'Organization Type',
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
                              value: _selectedType,
                              menuMaxHeight: 200,
                              decoration: InputDecoration(
                                isDense: true,
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
                                'Select Type',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: AppTheme.primaryColor,
                              ),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              items: _orgTypes.map((String type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedType = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select organization type';
                                }
                                return null;
                              },
                              isExpanded: true,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getMediumSpace(context)),

                          // Registration ID Field
                          Text(
                            'Registration ID',
                            style: AppTheme.labelTextStyle.copyWith(
                              fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getSmallSpace(context) * 0.6),
                          TextFormField(
                            controller: _registrationIdController,
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
                                return 'Please enter registration ID';
                              }
                              return null;
                            },
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
                          SizedBox(height: ResponsiveUtils.getSmallSpace(context) * 0.6),                            
                          TextFormField(
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
                                return 'Please enter phone number';
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
                          SizedBox(height: ResponsiveUtils.getSmallSpace(context) * 0.6),
                          TextFormField(
                            controller: _addressController,
                            maxLines: null,
                            minLines: 3,
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
                                return 'Please enter address';
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