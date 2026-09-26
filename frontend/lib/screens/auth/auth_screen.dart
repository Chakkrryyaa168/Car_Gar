import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? const Color(0xFF0F1520) : const Color(0xFFF8FAFC);
    final Color surfaceColor = isDark ? const Color(0xFF171F2C) : const Color(0xFFFFFFFF);
    final Color textColor = isDark ? const Color(0xFFE6EAF0) : const Color(0xFF1E293B);
    final Color mutedColor = isDark ? const Color(0xFF8B96A5) : const Color(0xFF64748B);
    final Color borderColor = isDark ? const Color(0xFF2A3444) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
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

                  // Main Auth Card
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
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
                          // Segmented Tabs: Sign In / Create Account
                          _buildSegmentedTab(borderColor, surfaceColor, isDark),
                          const SizedBox(height: 22),

                          // Error Banner
                          if (auth.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.errorMessage!,
                                      style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Form Content: Login or Register
                          if (!_isRegister)
                            _buildLoginForm(textColor, mutedColor, borderColor, auth)
                          else
                            _buildRegisterForm(textColor, mutedColor, borderColor, auth),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick Demo Role Login Buttons
                  if (!_isRegister)
                    _buildQuickDemoSelector(surfaceColor, borderColor, mutedColor, auth),
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
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A5F), Color(0xFF152A45)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A5F).withValues(alpha: 0.25),
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
        const Text(
          'CAR GARAGE',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E3A5F),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Service, Inspection & Repair Management Portal',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Segmented Tab Switcher
  Widget _buildSegmentedTab(Color borderColor, Color surfaceColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222C3D) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() => _isRegister = false);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isRegister ? surfaceColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: !_isRegister
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                          )
                        ]
                      : null,
                ),
                child: Text(
                  'Sign In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: !_isRegister ? FontWeight.bold : FontWeight.w500,
                    color: !_isRegister ? const Color(0xFF1E3A5F) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() => _isRegister = true);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isRegister ? surfaceColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isRegister
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                          )
                        ]
                      : null,
                ),
                child: Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _isRegister ? FontWeight.bold : FontWeight.w500,
                    color: _isRegister ? const Color(0xFF1E3A5F) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // LOGIN FORM
  // -------------------------------------------------------------
  Widget _buildLoginForm(Color text, Color muted, Color border, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email or Username', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: text)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _loginEmailController,
          decoration: InputDecoration(
            hintText: 'name@example.com',
            prefixIcon: Icon(Icons.email_outlined, size: 18, color: muted),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your email or username' : null,
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: text)),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo: Use password "customer123", "mechanic123", or 1-tap demo logins below.'),
                  ),
                );
              },
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 12, color: Color(0xFFF97316), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _loginPasswordController,
          obscureText: _loginObscure,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: Icon(Icons.lock_outline, size: 18, color: muted),
            suffixIcon: IconButton(
              icon: Icon(_loginObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: muted),
              onPressed: () => setState(() => _loginObscure = !_loginObscure),
            ),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
        ),
        const SizedBox(height: 22),

        // Sign In Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: auth.isLoading ? null : _handleLogin,
            child: auth.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Sign In to Garage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // REGISTER FORM
  // -------------------------------------------------------------
  Widget _buildRegisterForm(Color text, Color muted, Color border, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: text)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _regNameController,
          decoration: InputDecoration(
            hintText: 'e.g. John Doe',
            prefixIcon: Icon(Icons.person_outline, size: 18, color: muted),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
        ),
        const SizedBox(height: 14),

        Text('Email Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: text)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _regEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'john@example.com',
            prefixIcon: Icon(Icons.email_outlined, size: 18, color: muted),
          ),
          validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
        ),
        const SizedBox(height: 14),

        Text('Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: text)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _regPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+1 555-0199',
            prefixIcon: Icon(Icons.phone_outlined, size: 18, color: muted),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your phone number' : null,
        ),
        const SizedBox(height: 14),

        Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: text)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _regPasswordController,
          obscureText: _regObscure,
          decoration: InputDecoration(
            hintText: 'At least 6 characters',
            prefixIcon: Icon(Icons.lock_outline, size: 18, color: muted),
            suffixIcon: IconButton(
              icon: Icon(_regObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: muted),
              onPressed: () => setState(() => _regObscure = !_regObscure),
            ),
          ),
          validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
        ),
        const SizedBox(height: 14),

        Text('Confirm Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: text)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _regConfirmPasswordController,
          obscureText: _regObscure,
          decoration: InputDecoration(
            hintText: 'Re-enter your password',
            prefixIcon: Icon(Icons.lock_outline, size: 18, color: muted),
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
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
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
                      const Icon(Icons.directions_car_outlined, size: 18, color: Color(0xFF1E3A5F)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _showVehicleForm ? 'Vehicle Details (Optional)' : 'Add Vehicle Details (Optional)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                        ),
                      ),
                      Icon(
                        _showVehicleForm ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 20,
                        color: muted,
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
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('License Plate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _plateController,
                                  decoration: const InputDecoration(hintText: 'e.g. ABC-1234'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Year', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _yearController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: '2022'),
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
                                Text('Make & Model', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _makeController,
                                  decoration: const InputDecoration(hintText: 'Toyota Camry'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Color', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _colorController,
                                  decoration: const InputDecoration(hintText: 'Silver'),
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

        // Create Account CTA Button (#F97316 Safety Orange)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: auth.isLoading ? null : _handleRegister,
            child: auth.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Create Customer Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  // Quick Demo Accounts Credential Loader (Fills and shows email/password)
  Widget _buildQuickDemoSelector(Color surface, Color border, Color muted, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key_outlined, size: 16, color: Color(0xFFF97316)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'TEST ROLE CREDENTIALS (CLICK TO FILL & VIEW)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Click any role below to populate and display its email and password above. Then press "Sign In to Garage".',
            style: TextStyle(fontSize: 12, color: muted),
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
                color: const Color(0xFF1E3A5F).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E3A5F).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Color(0xFF1E3A5F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_selectedDemoRole credentials loaded into form! Click "Sign In to Garage" above.',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
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
        backgroundColor: isSelected ? const Color(0xFF1E3A5F).withValues(alpha: 0.08) : Colors.transparent,
        side: BorderSide(
          color: isSelected ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1.0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        setState(() {
          _loginEmailController.text = email;
          _loginPasswordController.text = password;
          _loginObscure = false; // Show the password so user sees it
          _selectedDemoRole = title;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Filled $title credentials ($email / $password). Click "Sign In to Garage" to authenticate.'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF1E3A5F),
          ),
        );
      },
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1E3A5F)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                ),
                Text(
                  email,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
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
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      email: _regEmailController.text.trim(),
      password: _regPasswordController.text,
      fullName: _regNameController.text.trim(),
      phoneNumber: _regPhoneController.text.trim(),
      licensePlate: _plateController.text.trim().isNotEmpty ? _plateController.text.trim() : null,
      make: _makeController.text.trim().isNotEmpty ? _makeController.text.trim() : null,
      model: _modelController.text.trim().isNotEmpty ? _modelController.text.trim() : null,
      year: int.tryParse(_yearController.text),
      color: _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
    );

    if (success && mounted) {
      Provider.of<TicketProvider>(context, listen: false).fetchTickets();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account registered successfully! Welcome to Car Garage.'),
          backgroundColor: AppColors.success,
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }
}
