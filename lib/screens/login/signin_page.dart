import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redhope/utils/responsive_utils.dart';
import 'package:redhope/theme/theme.dart';
import 'signup_page.dart';
import '../pages/users/user_home_page.dart';
import '../pages/organisations/org_home_page.dart';
import '../pages/admin/admin_home_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with TickerProviderStateMixin {
  // Add controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Add state variables
  bool _rememberMe = false;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _passwordVisible = false;
  
  // Firebase Auth instance
  final _auth = FirebaseAuth.instance;
  
  // Animation controllers for slide-up effect
  AnimationController? _animationController;
  Animation<double>? _containerAnimation;
  Animation<double>? _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Create animation for the bottom container
    _containerAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOut,
      ),
    );
    
    // Create fade-in animation for form elements
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
    
    // Start animation after a short delay
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController!.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndPassword() async {
    // Clear previous error messages
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    // Input validation
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email';
        _isLoading = false;
      });
      return;
    }
    
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Sign in with Firebase Auth
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );      // 2. Get user role from user_roles collection
      final roleDoc = await FirebaseFirestore.instance
          .collection('user_roles')
          .doc(email)
          .get();
      
      if (!roleDoc.exists) {
        throw FirebaseAuthException(
          code: 'role-not-found',
          message: 'User role not found. Please contact support.',
        );
      }

      final role = roleDoc.data()?['role'] as String?;
      // For admin users, use auth UID directly as it matches the admin document ID
      final userId = role == 'admin' ? _auth.currentUser?.uid : roleDoc.data()?['uid'] as String?;

      if (role == null || userId == null) {
        throw FirebaseAuthException(
          code: 'invalid-role-data',
          message: 'Invalid user data. Please contact support.',
        );
      }// 3. Verify user document exists in appropriate collection
      String? collectionName;
      if (role == 'user') {
        collectionName = 'users';
      } else if (role == 'org') {
        collectionName = 'organisations';
      } else if (role == 'admin') {
        collectionName = 'admins';
      }
      
      if (collectionName == null) {
        throw FirebaseAuthException(
          code: 'invalid-role',
          message: 'Invalid user role. Please contact support.',
        );
      }

      final userDoc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw FirebaseAuthException(
          code: 'user-data-missing',
          message: 'User profile not found. Please contact support.',
        );
      }

      // 4. Navigate based on role
      if (!mounted) return;

      switch (role) {
        case 'user':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserHomePage()),
          );
          break;
        case 'org':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OrgHomePage()),
          );
          break;
        case 'admin':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminHomePage()),
          );
          break;
        default:
          throw FirebaseAuthException(
            code: 'invalid-role',
            message: 'Invalid user role. Please contact support.',
          );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        // Handle specific Firebase Auth errors with user-friendly messages
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'No user found with this email.';
            break;
          case 'wrong-password':
            _errorMessage = 'Incorrect password.';
            break;
          case 'invalid-email':
            _errorMessage = 'Please enter a valid email address.';
            break;
          case 'invalid-credential':
            _errorMessage = 'Invalid email address/password.';
            break;
          case 'user-disabled':
            _errorMessage = 'This account has been disabled.';
            break;
          case 'too-many-requests':
            _errorMessage = 'Too many attempts. Please try again later.';
            break;
          case 'role-not-found':
          case 'invalid-role-data':
          case 'invalid-role':
          case 'user-data-missing':
            _errorMessage = e.message ?? 'Authentication error. Please contact support.';
            break;
          default:
            _errorMessage = 'Authentication failed. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to sign in. Please try again.';
      });
      debugPrint('Sign in error: $e');
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
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
          
          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bottomContainerHeight = constraints.maxHeight * 
                    (ResponsiveUtils.getBottomContainerRatio(context) - 0.175);
                
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
                      child: Container(
                        padding: EdgeInsets.all(ResponsiveUtils.getMediumSpace(context)),
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: ResponsiveUtils.isDesktop(context) ? 450 : double.infinity,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBackgroundColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.lightShadowColor,
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: AnimatedBuilder(
                            animation: _fadeAnimation ?? const AlwaysStoppedAnimation(0),
                            builder: (context, child) {
                              return Opacity(
                                opacity: _fadeAnimation?.value ?? 1.0,
                                child: child,
                              );
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: ResponsiveUtils.getSmallSpace(context)),
                                Text(
                                  "Sign In",
                                  style: AppTheme.headingTextStyle,
                                ),
                                SizedBox(height: ResponsiveUtils.getMediumSpace(context)),
                                _buildTextField(
                                  label: 'Email',
                                  controller: _emailController,
                                  icon: Icons.email,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                SizedBox(height: ResponsiveUtils.getSmallSpace(context)),
                                _buildTextField(
                                  label: 'Password',
                                  controller: _passwordController,
                                  icon: Icons.lock,
                                  isPassword: true,
                                ),
                                SizedBox(height: ResponsiveUtils.getSmallSpace(context)),
                                
                                // Remember me & Forgot password
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Transform.scale(
                                          scale: ResponsiveUtils.isSmallPhone(context) ? 0.9 : 1.0,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                            activeColor: AppTheme.primaryColor,
                                            checkColor: Colors.white, // Explicit white check mark
                                            // Add these properties for the outline
                                            side: BorderSide(
                                              color: AppTheme.lightDividerColor.withOpacity(0.8), 
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Remember me',
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.getSmallTextSize(context),
                                            color: AppTheme.lightTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: ResponsiveUtils.getSmallSpace(context) * 0.8),
                                        minimumSize: Size(0, 0),
                                      ),
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: ResponsiveUtils.getSmallTextSize(context),
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
                                
                                // Sign In button
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _signInWithEmailAndPassword,
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
                                          color: Colors.white,
                                          strokeWidth: ResponsiveUtils.isSmallPhone(context) ? 1.5 : 2,
                                        ),
                                      )
                                    : Text(
                                        'Sign In', 
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.getBodySize(context),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                ),
                                  SizedBox(height: ResponsiveUtils.getMediumSpace(context)),
                                
                                // Sign Up link
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
                                        "Don't have an account? ",
                                        style: TextStyle(
                                          color: AppTheme.lightTextColor,
                                          fontSize: ResponsiveUtils.getSmallTextSize(context),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => SignupPage()),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: ResponsiveUtils.getSmallSpace(context) * 0.8),
                                          minimumSize: Size(0, 0),
                                        ),
                                        child: Text(
                                          "Sign Up",
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
                                SizedBox(height: ResponsiveUtils.getSmallSpace(context)),
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
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
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
            style: AppTheme.labelTextStyle,
          ),
        ),
        // Text field with rounded styling
        Container(
          height: ResponsiveUtils.getInputHeight(context),
          decoration: BoxDecoration(
            color: AppTheme.lightBackgroundColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightShadowColor,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !_passwordVisible,
            keyboardType: keyboardType,
            style: AppTheme.inputTextStyle,
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
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.primaryColor,
                      size: ResponsiveUtils.getIconSize(context) * 0.9,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  )
                : null,
              // Use fixed light theme styles
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