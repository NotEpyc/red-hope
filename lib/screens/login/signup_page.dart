import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redhope/screens/pages/users/additional_user_info_page.dart';
import 'package:redhope/screens/pages/organisations/additional_organisation_info_page.dart';
import 'signin_page.dart';
import 'package:redhope/utils/responsive_utils.dart';
import 'package:redhope/theme/theme.dart';
import 'package:redhope/services/user_service.dart';
import 'package:redhope/models/user_model.dart';
import 'package:redhope/models/organisation_model.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

enum UserType { person, organisation }

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  // Form key for validation
  final _formSignupKey = GlobalKey<FormState>();
  
  // State variables for user type
  UserType _selectedUserType = UserType.person;
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Focus nodes
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  
  // State variables
  bool _agreeToTerms = false;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // Animation controllers
  AnimationController? _animationController;
  Animation<double>? _containerAnimation;
  // Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Add listeners to focus nodes
    _nameFocusNode.addListener(() => setState(() {}));
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
    _confirmPasswordFocusNode.addListener(() => setState(() {}));
    
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _containerAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOut,
      ),
    );
    
    // _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
    //   CurvedAnimation(
    //     parent: _animationController!,
    //     curve: Interval(0.4, 1.0, curve: Curves.easeIn),
    //   ),
    // );
    
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) _animationController!.forward();
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }
  // Validate form
  bool _validateForm() {
    final form = _formSignupKey.currentState;
    if (form?.validate() != true) {
      return false;
    }
    if (!_agreeToTerms) {
      setState(() => _errorMessage = 'Please agree to the Terms of Service');
      return false;
    }
    return true;
  }
  Future<void> _signUpWithEmailAndPassword() async {
    if (!_validateForm()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // First create Firebase Auth account
      print('Creating Firebase Auth account...');
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Get the UID from auth
      String uid = userCredential.user!.uid;
      print('User created with UID: $uid');
      
      // Update display name
      await userCredential.user?.updateDisplayName(_nameController.text.trim());
      print('Display name updated');      // Create appropriate model based on user type
      dynamic user;
      if (_selectedUserType == UserType.organisation) {
        user = OrganisationModel(
          id: uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          address: '',  // Empty initially
          phone: 0,    // Zero initially
          type: ''     // Empty initially
        );
      } else {
        user = UserModel(
          id: uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          address: '',
          phone: 0,
          gender: '',
          bloodGroup: '',
          age: 0
        );
      }
      
      debugPrint('Creating Firestore document...');
      debugPrint('Document ID (auth UID): $uid');
      debugPrint('User data: $user');        try {
          // Use UserService to create the document
          final userService = UserService();
          final isOrg = _selectedUserType == UserType.organisation;
                // Create user/org in Firestore
          await userService.createUser(
            user, 
            uid,
            isOrganisation: isOrg
          );
          debugPrint('✅ User data saved to Firestore');
          
          // Create entry in user_roles collection with email as document ID
          final email = _emailController.text.trim();
          await FirebaseFirestore.instance
              .collection('user_roles')
              .doc(email)
              .set({
                'role': isOrg ? 'org' : 'user',
                'uid': uid,
                'email': email,
                'createdAt': FieldValue.serverTimestamp(),
              });
          debugPrint('✅ User role saved to Firestore');
          
          // Verify document exists in the correct collection
          final collection = isOrg ? 'organisations' : 'users';
          debugPrint('Verifying document in collection: $collection');
          
          final userDoc = await FirebaseFirestore.instance
              .collection(collection)
              .doc(uid)
              .get();
              
          if (!userDoc.exists) {
            throw Exception('Document does not exist after creation');
          }
        
        debugPrint('✅ Verified document exists in Firestore');
      } catch (e) {
        debugPrint('❌ Error creating/verifying Firestore document: $e');
        rethrow; // This will be caught by the outer try-catch
      }      if (mounted) {
        Navigator.pushReplacement(
          context,          MaterialPageRoute(
            builder: (context) => _selectedUserType == UserType.organisation
                ? const AdditionalOrgInfoPage()
                : const AdditionalUserInfoPage(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.message}');
      setState(() {
        switch (e.code) {
          case 'weak-password':
            _errorMessage = 'The password is too weak.';
            break;
          case 'email-already-in-use':
            _errorMessage = 'An account already exists for this email.';
            break;
          case 'invalid-email':
            _errorMessage = 'Please enter a valid email address.';
            break;
          default:
            _errorMessage = e.message ?? 'Registration failed. Please try again.';
        }
      });
    } on FirebaseException catch (e) {
      print('FirebaseException: ${e.plugin} - ${e.message}');
      setState(() {
        if (e.plugin == 'cloud_firestore') {
          _errorMessage = 'Failed to save user data. Please try again.';
        } else {
          _errorMessage = e.message ?? 'An error occurred. Please try again.';
        }
      });
    } catch (e) {
      print('Unexpected error in sign up: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Full screen background image
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
          
          // Main content with animation
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bottomContainerHeight = constraints.maxHeight * 
                    (ResponsiveUtils.getBottomContainerRatio(context) + 0.035);
                
                return Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _animationController ?? const AlwaysStoppedAnimation(0),
                      builder: (context, child) {
                        return Positioned(
                          bottom: -bottomContainerHeight * (_containerAnimation?.value ?? 0.0),
                          left: 0,
                          right: 0,
                          height: bottomContainerHeight,
                          child: child!,
                        );
                      },
                      child: Container(                        padding: EdgeInsets.all(
                          ResponsiveUtils.isSmallPhone(context) 
                              ? ResponsiveUtils.getSmallSpace(context)
                              : ResponsiveUtils.getMediumSpace(context)
                        ),
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: ResponsiveUtils.isDesktop(context) 
                              ? 450 
                              : ResponsiveUtils.isTablet(context)
                                  ? 600
                                  : double.infinity,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBackgroundColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(ResponsiveUtils.isSmallPhone(context) ? 15 : 20),
                            topRight: Radius.circular(ResponsiveUtils.isSmallPhone(context) ? 15 : 20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.lightShadowColor,
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Form(
                            key: _formSignupKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: ResponsiveUtils.getSmallSpace(context)),
                                Text(
                                  "Sign Up",
                                  style: AppTheme.headingTextStyle.copyWith(
                                    fontSize: ResponsiveUtils.getHeadingSize(context),
                                  ),
                                ),
                                SizedBox(height: ResponsiveUtils.getMediumSpace(context)),                                Container(
                                  width: ResponsiveUtils.isTablet(context) 
                                      ? MediaQuery.of(context).size.width * 0.7
                                      : double.infinity,
                                  child: _buildTextField(
                                    label: _selectedUserType == UserType.person ? 'Full Name' : 'Organisation Name',
                                    icon: _selectedUserType == UserType.person ? Icons.person : Icons.business,
                                    controller: _nameController,
                                  ),
                                ),
                                SizedBox(height: ResponsiveUtils.getSmallSpace(context) * 0.8),
                                Container(
                                  width: ResponsiveUtils.isTablet(context) 
                                      ? MediaQuery.of(context).size.width * 0.7
                                      : double.infinity,
                                  child: _buildTextField(
                                    label: 'Email',
                                    icon: Icons.email,
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                                SizedBox(height: ResponsiveUtils.getSmallSpace(context) * 0.8),
                                Container(
                                  width: ResponsiveUtils.isTablet(context) 
                                      ? MediaQuery.of(context).size.width * 0.7
                                      : double.infinity,
                                  child: _buildTextField(
                                    label: 'Password',
                                    icon: Icons.lock,
                                    isPassword: true,
                                    controller: _passwordController,
                                  ),
                                ),
                                SizedBox(height: ResponsiveUtils.getMediumSpace(context)),
                                  // User type selection
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedUserType = UserType.person;
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: ResponsiveUtils.getMediumSpace(context) * 0.6,
                                          ),
                                          margin: EdgeInsets.only(
                                            right: ResponsiveUtils.getSmallSpace(context) * 0.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _selectedUserType == UserType.person 
                                                ? AppTheme.primaryColor
                                                : AppTheme.lightBackgroundColor,
                                            borderRadius: BorderRadius.circular(30),
                                            border: Border.all(
                                              color: AppTheme.primaryColor,
                                              width: 1.5,
                                            ),
                                          ),                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: ResponsiveUtils.getIconSize(context) * 1.2,
                                                child: Icon(
                                                  Icons.person,
                                                  color: _selectedUserType == UserType.person 
                                                      ? AppTheme.secondaryColor
                                                      : AppTheme.primaryColor,
                                                  size: ResponsiveUtils.getIconSize(context) * 0.9,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  "I'm a\nPerson",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: _selectedUserType == UserType.person 
                                                        ? AppTheme.secondaryColor
                                                        : AppTheme.primaryColor,
                                                    fontSize: ResponsiveUtils.getSmallTextSize(context),
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedUserType = UserType.organisation;
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: ResponsiveUtils.getMediumSpace(context) * 0.6,
                                          ),
                                          margin: EdgeInsets.only(
                                            left: ResponsiveUtils.getSmallSpace(context) * 0.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _selectedUserType == UserType.organisation 
                                                ? AppTheme.primaryColor
                                                : AppTheme.lightBackgroundColor,
                                            borderRadius: BorderRadius.circular(30),
                                            border: Border.all(
                                              color: AppTheme.primaryColor,
                                              width: 1.5,
                                            ),
                                          ),                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: ResponsiveUtils.getIconSize(context) * 1.2,
                                                child: Icon(
                                                  Icons.business,
                                                  color: _selectedUserType == UserType.organisation 
                                                      ? AppTheme.secondaryColor
                                                      : AppTheme.primaryColor,
                                                  size: ResponsiveUtils.getIconSize(context) * 0.9,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  "I'm an\nOrganisation",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: _selectedUserType == UserType.organisation 
                                                        ? AppTheme.secondaryColor
                                                        : AppTheme.primaryColor,
                                                    fontSize: ResponsiveUtils.getSmallTextSize(context),
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: ResponsiveUtils.getSmallSpace(context) * 0.8),
                                
                                // Terms and conditions checkbox with proper alignment
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Transform.scale(
                                      scale: ResponsiveUtils.isSmallPhone(context) ? 0.9 : 1.0,
                                      child: Checkbox(
                                        value: _agreeToTerms,
                                        onChanged: (value) {
                                          setState(() {
                                            _agreeToTerms = value ?? false;
                                          });
                                        },
                                        activeColor: AppTheme.primaryColor,
                                        checkColor: AppTheme.secondaryColor,
                                        side: BorderSide(
                                          color: AppTheme.lightDividerColor.withOpacity(0.8), 
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        materialTapTargetSize: ResponsiveUtils.isSmallPhone(context) 
                                            ? MaterialTapTargetSize.shrinkWrap 
                                            : MaterialTapTargetSize.padded,
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 1),
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: ResponsiveUtils.getSmallTextSize(context) - 2,
                                              color: AppTheme.lightTextColor.withOpacity(0.8),
                                              height: 1.3,
                                            ),
                                            children: [
                                              TextSpan(text: 'I agree to the '),
                                              TextSpan(
                                                text: 'Terms of Service',
                                                style: TextStyle(
                                                  color: AppTheme.primaryColor,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: ResponsiveUtils.getSmallTextSize(context) - 2,
                                                ),
                                              ),
                                              TextSpan(text: ' and '),
                                              TextSpan(
                                                text: 'Privacy Policy',
                                                style: TextStyle(
                                                  color: AppTheme.primaryColor,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: ResponsiveUtils.getSmallTextSize(context) - 2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: ResponsiveUtils.getMediumSpace(context)),
                                
                                // Error message (if any)
                                if (_errorMessage.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: ResponsiveUtils.getSmallSpace(context)),
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(
                                          color: AppTheme.lightErrorColor,
                                          fontSize: ResponsiveUtils.getSmallTextSize(context)),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                
                                // Sign Up button
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _signUpWithEmailAndPassword,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(double.infinity,
                                        ResponsiveUtils.getButtonHeight(context)),
                                    backgroundColor: AppTheme.primaryColor,
                                    disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: _isLoading 
                                    ? SizedBox(
                                        height: ResponsiveUtils.isSmallPhone(context) ? 18 : 22,
                                        width: ResponsiveUtils.isSmallPhone(context) ? 18 : 22, 
                                        child: CircularProgressIndicator(
                                          color: AppTheme.secondaryColor,
                                          strokeWidth: ResponsiveUtils.isSmallPhone(context) ? 1.5 : 2,
                                        ),
                                      )
                                    : Text(
                                        'Create Account', 
                                        style: AppTheme.buttonTextStyle.copyWith(
                                          fontSize: ResponsiveUtils.getBodySize(context),
                                        ),
                                      ),
                                ),
                                
                                SizedBox(height: ResponsiveUtils.getMediumSpace(context)),
                                
                                // Sign In link
                                Container(
                                  margin: EdgeInsets.only(top: ResponsiveUtils.getSmallSpace(context) * 0.5),
                                  padding: EdgeInsets.symmetric(
                                      vertical: ResponsiveUtils.getSmallSpace(context) * 0.5),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: AppTheme.lightDividerColor,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Already have an account? ",
                                        style: TextStyle(
                                          color: AppTheme.lightTextColor,
                                          fontSize: ResponsiveUtils.getSmallTextSize(context),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => SignInPage()),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: ResponsiveUtils.getSmallSpace(context) * 0.8),
                                          minimumSize: Size(0, 0),
                                        ),
                                        child: Text(
                                          "Sign In",
                                          style: TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: ResponsiveUtils.getSmallTextSize(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: ResponsiveUtils.getSmallSpace(context) * 1.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    // Check if this is a name field
    final isNameField = label == 'Full Name' || label == 'Organisation Name';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label above the field
        Padding(
          padding: EdgeInsets.only(
            left: 4, 
            bottom: ResponsiveUtils.getSmallSpace(context) * 0.6
          ),
          child: Text(
            label,
            style: AppTheme.labelTextStyle.copyWith(
              fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
            ),
          ),
        ),
        // Text field with rounded styling
        Container(
          height: ResponsiveUtils.getInputHeight(context) * 0.95,
          decoration: BoxDecoration(
            color: AppTheme.lightBackgroundColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightShadowColor,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && (isConfirmPassword ? !_confirmPasswordVisible : !_passwordVisible),
            keyboardType: isNameField ? TextInputType.name : keyboardType,
            // Add input formatters for name fields
            inputFormatters: isNameField ? [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
            ] : null,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your ${label.toLowerCase()}';
              }
              if (label == 'Email') {
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Please enter a valid email address';
                }
              }
              if (label == 'Password' && value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              if (label == 'Confirm Password' && value != _passwordController.text) {
                return 'Passwords do not match';
              }
              // Add minimum length validation for names
              if (isNameField && value.trim().length < 2) {
                return '${label} must be at least 2 characters';
              }
              return null;
            },
            style: AppTheme.inputTextStyle.copyWith(
              fontSize: ResponsiveUtils.getBodySize(context) * 0.9,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.isSmallPhone(context) ? 14 : 17,
                horizontal: ResponsiveUtils.isSmallPhone(context) ? 16 : 20,
              ),
              filled: true,
              fillColor: AppTheme.lightBackgroundColor,
              hintText: 'Enter your $label',
              hintStyle: TextStyle(
                color: AppTheme.lightHintColor,
                fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
              ),
              prefixIcon: Icon(
                icon, 
                color: AppTheme.primaryColor,
                size: ResponsiveUtils.getIconSize(context) * 0.9,
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: ResponsiveUtils.isSmallPhone(context) ? 35 : 45
              ),
              suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (isConfirmPassword ? _confirmPasswordVisible : _passwordVisible) 
                          ? Icons.visibility 
                          : Icons.visibility_off,
                      color: AppTheme.primaryColor,
                      size: ResponsiveUtils.getIconSize(context) * 0.9,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isConfirmPassword) {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        } else {
                          _passwordVisible = !_passwordVisible;
                        }
                      });
                    },
                  )
                : null,
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
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppTheme.lightDividerColor.withOpacity(0.5), width: 1),
              ),
            ),
            cursorColor: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}