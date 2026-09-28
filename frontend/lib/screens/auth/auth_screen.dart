import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_shell.dart';

class AuthScreen extends StatefulWidget {
  final bool initialIsRegister;

  const AuthScreen({super.key, this.initialIsRegister = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isRegister;

  // Login Controllers
  final _loginEmailController = TextEditingController(text: 'customer@cargarage.com');
  final _loginPasswordController = TextEditingController(text: 'customer123');
  bool _loginObscure = false;
  String? _selectedDemoRole = 'Customer';

  // Register Controllers
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  bool _regObscure = true;

  // Profile Picture / Avatar State for Registration
  String? _regAvatarUrl;
  Uint8List? _regAvatarBytes;
  bool _isUploadingAvatar = false;

  // Vehicle Details (Optional during registration)
  bool _showVehicleForm = false;
  final _plateController = TextEditingController();
  final _makeController = TextEditingController(text: 'Toyota');
  final _modelController = TextEditingController(text: 'Camry');
  final _yearController = TextEditingController(text: '2022');
  final _colorController = TextEditingController(text: 'Pearl White');

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialIsRegister;
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color fillColor = AppColors.surfaceElevated,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.charcoal),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.charcoal, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background, // Warm sand #F5F1E8
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Garage Branding Header
                  _buildBrandHeader(),
                  const SizedBox(height: 24),

                  // Main Auth Card (Floating softly on sand)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface, // #FFFFFF
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border), // #E4DED0
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2B2F2C).withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Segmented Tabs: Sign In / Create Account (Static, no animation)
                          Container(
                            height: 44,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isRegister = false;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: !_isRegister ? AppColors.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Sign In',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: !_isRegister ? FontWeight.w700 : FontWeight.w500,
                                          color: !_isRegister ? Colors.white : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isRegister = true;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _isRegister ? AppColors.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Create Account',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: _isRegister ? FontWeight.w700 : FontWeight.w500,
                                          color: _isRegister ? Colors.white : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Error Banner
                          if (auth.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.errorMessage!,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Form Content: Login or Register (Instant switch, no animation)
                          !_isRegister
                              ? _buildLoginForm(auth)
                              : _buildRegisterForm(auth),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick Demo Role Login Buttons
                  if (!_isRegister)
                    _buildQuickDemoSelector(auth),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Brand Header
  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.primary, // Solid Sage #5F7F6B
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2B2F2C).withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.directions_car_filled, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'CAR GARAGE',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Service, Inspection & Repair Management Portal',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // LOGIN FORM
  // -------------------------------------------------------------
  Widget _buildLoginForm(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email or Username',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _loginEmailController,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody),
          decoration: _buildInputDecoration(
            hintText: 'name@example.com',
            prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.primary),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your email or username' : null,
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primary,
                    content: Text(
                      'Demo: Use password "customer123", "mechanic123", or 1-tap demo logins below.',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ),
                );
              },
              child: Text(
                'Forgot password?',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _loginPasswordController,
          obscureText: _loginObscure,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody),
          decoration: _buildInputDecoration(
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _loginObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _loginObscure = !_loginObscure),
            ),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
        ),
        const SizedBox(height: 22),

        // Sign In Button (Solid sage with white text)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, // Solid Sage #5F7F6B
              foregroundColor: Colors.white, // White text
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: auth.isLoading ? null : _handleLogin,
            child: auth.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Sign In to Garage',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // REGISTER FORM
  // -------------------------------------------------------------
  Widget _buildRegisterForm(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatarSelector(),
        const SizedBox(height: 14),

        Text(
          'Full Name',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _regNameController,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody),
          decoration: _buildInputDecoration(
            hintText: 'e.g. John Doe',
            prefixIcon: const Icon(Icons.person_outline, size: 18, color: AppColors.primary),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
        ),
        const SizedBox(height: 14),

        Text(
          'Email Address',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _regEmailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody),
          decoration: _buildInputDecoration(
            hintText: 'john@example.com',
            prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.primary),
          ),
          validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
        ),
        const SizedBox(height: 14),

        Text(
          'Phone Number',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _regPhoneController,
          keyboardType: TextInputType.phone,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody),
          decoration: _buildInputDecoration(
            hintText: '+1 555-0199',
            prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.primary),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your phone number' : null,
        ),
        const SizedBox(height: 14),

        Text(
          'Password',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _regPasswordController,
          obscureText: _regObscure,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody),
          decoration: _buildInputDecoration(
            hintText: 'At least 6 characters',
            prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _regObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _regObscure = !_regObscure),
            ),
          ),
          validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
        ),
        const SizedBox(height: 14),

        Text(
          'Confirm Password',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _regConfirmPasswordController,
          obscureText: _regObscure,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody),
          decoration: _buildInputDecoration(
            hintText: 'Re-enter your password',
            prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.primary),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Confirm your password';
            if (v != _regPasswordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Optional Vehicle Details Accordion
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated, // #FDF6F5
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _showVehicleForm = !_showVehicleForm),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _showVehicleForm ? 'Vehicle Details (Optional)' : 'Add Vehicle Details (Optional)',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        _showVehicleForm ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showVehicleForm)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'License Plate',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _plateController,
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody),
                                  decoration: _buildInputDecoration(
                                    hintText: 'e.g. ABC-1234',
                                    fillColor: AppColors.surface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Year',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _yearController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody),
                                  decoration: _buildInputDecoration(
                                    hintText: '2022',
                                    fillColor: AppColors.surface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Make & Model',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _makeController,
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody),
                                  decoration: _buildInputDecoration(
                                    hintText: 'Toyota Camry',
                                    fillColor: AppColors.surface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Color',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _colorController,
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody),
                                  decoration: _buildInputDecoration(
                                    hintText: 'Silver',
                                    fillColor: AppColors.surface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Create Account CTA Button (Solid sage with white text)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: auth.isLoading ? null : _handleRegister,
            child: auth.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Create Customer Account',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  // Quick Demo Accounts Credential Loader
  Widget _buildQuickDemoSelector(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // #FFFFFF
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'TEST ROLE CREDENTIALS (CLICK TO FILL & VIEW)',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Click any role below to populate its email and password above. Then press "Sign In".',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textBody),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: [
              _buildDemoButton('CUSTOMER', 'Customer', 'customer@cargarage.com', 'customer123', Icons.person_outline),
              _buildDemoButton('RECEPTIONIST', 'Receptionist', 'reception@cargarage.com', 'reception123', Icons.desk_outlined),
              _buildDemoButton('MECHANIC', 'Mechanic', 'mechanic@cargarage.com', 'mechanic123', Icons.build_outlined),
              _buildDemoButton('ADMIN', 'Admin', 'admin@cargarage.com', 'admin123', Icons.admin_panel_settings_outlined),
            ],
          ),
          if (_selectedDemoRole != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_selectedDemoRole credentials loaded into form! Click "Sign In" above.',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDemoButton(String role, String title, String email, String password, IconData icon) {
    final isSelected = _selectedDemoRole == title;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        backgroundColor: isSelected ? AppColors.primary : AppColors.surfaceElevated,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1.0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        setState(() {
          _loginEmailController.text = email;
          _loginPasswordController.text = password;
          _loginObscure = false;
          _selectedDemoRole = title;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'Filled $title credentials ($email / $password). Click "Sign In" to authenticate.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _loginEmailController.text.trim(),
      _loginPasswordController.text,
    );

    if (success && mounted) {
      Provider.of<TicketProvider>(context, listen: false).fetchTickets();
      PreferencesService.setLastRole(auth.currentRole);
      PreferencesService.setHasSeenOnboarding(true);

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AppShell(),
            transitionDuration: AppAnimations.durBase,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: AppAnimations.ease),
                child: child,
              );
            },
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    // If an image was picked from device but not yet uploaded, upload it now
    if (_regAvatarUrl == null && _regAvatarBytes != null) {
      try {
        _regAvatarUrl = await auth.apiService.uploadImageFile(
          fileBytes: _regAvatarBytes!,
          fileName: 'avatar_reg_${DateTime.now().millisecondsSinceEpoch}.jpg',
          folder: 'car_gar/avatars',
        );
      } catch (_) {}
    }

    final success = await auth.register(
      email: _regEmailController.text.trim(),
      password: _regPasswordController.text,
      fullName: _regNameController.text.trim(),
      phoneNumber: _regPhoneController.text.trim(),
      avatarUrl: _regAvatarUrl,
      licensePlate: _plateController.text.trim().isNotEmpty ? _plateController.text.trim() : null,
      make: _makeController.text.trim().isNotEmpty ? _makeController.text.trim() : null,
      model: _modelController.text.trim().isNotEmpty ? _modelController.text.trim() : null,
      year: int.tryParse(_yearController.text),
      color: _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
    );

    if (success && mounted) {
      Provider.of<TicketProvider>(context, listen: false).fetchTickets();
      PreferencesService.setLastRole(auth.currentRole);
      PreferencesService.setHasSeenOnboarding(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            'Account registered successfully! Welcome to Car Garage.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AppShell(),
            transitionDuration: AppAnimations.durBase,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: AppAnimations.ease),
                child: child,
              );
            },
          ),
        );
      }
    }
  }

  // -------------------------------------------------------------
  // AVATAR PICKER FOR REGISTRATION
  // -------------------------------------------------------------
  Widget _buildAvatarSelector() {
    final hasImage = _regAvatarBytes != null || (_regAvatarUrl != null && _regAvatarUrl!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated, // #FBF9F4
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Interactive avatar circle
          InkWell(
            onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
            borderRadius: BorderRadius.circular(34),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.surface,
                  backgroundImage: _regAvatarBytes != null
                      ? MemoryImage(_regAvatarBytes!)
                      : (_regAvatarUrl != null && _regAvatarUrl!.isNotEmpty)
                          ? NetworkImage(_regAvatarUrl!) as ImageProvider
                          : null,
                  child: !hasImage
                      ? const Icon(Icons.person_outline, size: 32, color: AppColors.primary)
                      : null,
                ),
                if (_isUploadingAvatar)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                    child: Icon(
                      hasImage ? Icons.check : Icons.camera_alt_outlined,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Upload Image button & description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      'Profile Photo',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                    ),
                    Text(
                      '(Optional)',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _isUploadingAvatar
                      ? 'Uploading photo to garage...'
                      : hasImage
                          ? 'Photo attached to account'
                          : 'Upload your profile picture from device',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.upload, size: 14, color: Colors.white),
                      label: Text(
                        'Upload Image',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      onPressed: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                    ),
                    if (hasImage && !_isUploadingAvatar) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Remove Photo',
                        icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _regAvatarUrl = null;
                            _regAvatarBytes = null;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final messenger = ScaffoldMessenger.of(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        setState(() {
          _regAvatarBytes = bytes;
          _isUploadingAvatar = true;
        });

        try {
          final uploadedUrl = await auth.apiService.uploadImageFile(
            fileBytes: bytes,
            fileName: file.name,
            folder: 'car_gar/avatars',
          );
          if (mounted) {
            setState(() {
              _regAvatarUrl = uploadedUrl;
              _isUploadingAvatar = false;
            });
            messenger.showSnackBar(
              SnackBar(
                backgroundColor: AppColors.primary,
                content: Text(
                  'Profile image uploaded successfully!',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            );
          }
        } catch (uploadError) {
          if (mounted) {
            setState(() => _isUploadingAvatar = false);
            messenger.showSnackBar(
              SnackBar(
                backgroundColor: AppColors.primary,
                content: Text(
                  'Upload failed: $uploadError',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'Failed to select file: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        );
      }
    }
  }
}
