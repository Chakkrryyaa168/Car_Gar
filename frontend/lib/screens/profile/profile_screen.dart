import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Account Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  // General Profile Controllers
  late TextEditingController _avatarUrlController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyContactController;

  // Customer Specific Controllers
  late TextEditingController _secondaryPhoneController;
  late TextEditingController _billingAddressController;
  String _preferredContactChannel = 'App push';
  String _savedPaymentMethod = 'CREDIT_CARD';
  String _communicationPreferences = 'ALL';
  String? _selectedDefaultVehicleId;

  // Staff Specific Controllers
  late TextEditingController _employeeIdController;
  late TextEditingController _specializationController;
  late TextEditingController _bioController;

  // Admin Specific Controllers
  late TextEditingController _hourlyRateController;
  DateTime? _dateJoinedCompany;

  List<VehicleModel> _vehicles = [];
  bool _isLoadingVehicles = false;
  bool _isSaving = false;

  final List<String> _contactChannels = ['App push', 'SMS', 'WhatsApp', 'Email'];
  final List<Map<String, String>> _paymentMethods = [
    {'value': 'CREDIT_CARD', 'label': 'Credit / Debit Card'},
    {'value': 'CASH', 'label': 'Cash at Desk'},
    {'value': 'BANK_TRANSFER', 'label': 'Bank Wire Transfer'},
    {'value': 'ONLINE', 'label': 'Online Wallet / Pay'},
  ];
  final List<String> _specializationPresets = [
    'Engine & Transmission',
    'Electrical & Diagnostics',
    'Brakes & Suspension',
    'Air Conditioning & Heating',
    'Tire & Wheel Alignment',
    'Bodywork & Detailing',
    'General Maintenance',
  ];

  final List<String> _avatarPresets = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=250',
    'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?auto=format&fit=crop&q=80&w=250',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=250',
    'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=250',
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=250',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&q=80&w=250',
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final profile = user?.profile;

    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');

    _avatarUrlController = TextEditingController(text: profile?.avatarUrl ?? '');
    _addressController = TextEditingController(text: profile?.address ?? '');
    _emergencyContactController = TextEditingController(text: profile?.emergencyContact ?? '');

    _secondaryPhoneController = TextEditingController(text: profile?.secondaryPhone ?? '');
    _billingAddressController = TextEditingController(text: profile?.billingAddress ?? '');
    _preferredContactChannel = profile?.preferredContactChannel.isNotEmpty == true
        ? profile!.preferredContactChannel
        : 'App push';
    _savedPaymentMethod = profile?.savedPaymentMethod.isNotEmpty == true
        ? profile!.savedPaymentMethod
        : 'CREDIT_CARD';
    _communicationPreferences = profile?.communicationPreferences.isNotEmpty == true
        ? profile!.communicationPreferences
        : 'ALL';
    _selectedDefaultVehicleId = profile?.defaultVehicleId;

    _employeeIdController = TextEditingController(text: profile?.employeeId ?? '');
    _specializationController = TextEditingController(text: profile?.specialization ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');

    _hourlyRateController = TextEditingController(
      text: profile != null && profile.hourlyRate > 0 ? profile.hourlyRate.toStringAsFixed(2) : '',
    );
    if (profile?.dateJoinedCompany != null && profile!.dateJoinedCompany!.isNotEmpty) {
      _dateJoinedCompany = DateTime.tryParse(profile.dateJoinedCompany!);
    }

    if (auth.isCustomer) {
      _loadVehicles();
    }
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoadingVehicles = true);
    try {
      final api = Provider.of<TicketProvider>(context, listen: false).apiService;
      final vehicles = await api.fetchVehicles();
      if (mounted) setState(() => _vehicles = vehicles);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingVehicles = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _avatarUrlController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _secondaryPhoneController.dispose();
    _billingAddressController.dispose();
    _employeeIdController.dispose();
    _specializationController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final data = <String, dynamic>{
      'full_name': _fullNameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'avatar_url': _avatarUrlController.text.trim(),
      'address': _addressController.text.trim(),
      'emergency_contact': _emergencyContactController.text.trim(),
    };

    if (auth.isCustomer) {
      data['secondary_phone'] = _secondaryPhoneController.text.trim();
      data['preferred_contact_channel'] = _preferredContactChannel;
      data['billing_address'] = _billingAddressController.text.trim();
      data['saved_payment_method'] = _savedPaymentMethod;
      data['default_vehicle'] = _selectedDefaultVehicleId ?? '';
      data['communication_preferences'] = _communicationPreferences;
    }

    if (auth.isMechanic || auth.isReceptionist) {
      data['employee_id'] = _employeeIdController.text.trim();
      data['specialization'] = _specializationController.text.trim();
      data['bio'] = _bioController.text.trim();
    }

    if (auth.isAdmin) {
      data['employee_id'] = _employeeIdController.text.trim();
      final rate = double.tryParse(_hourlyRateController.text.trim());
      if (rate != null) data['hourly_rate'] = rate;
      if (_dateJoinedCompany != null) {
        data['date_joined_company'] = _dateJoinedCompany!.toIso8601String().split('T').first;
      }
    }

    try {
      final success = await auth.updateProfile(data);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(auth.errorMessage ?? 'Failed to update profile.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAvatarPickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose Profile Avatar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Upload your own picture or select from presets below.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),

              // Upload from Device Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                  label: const Text(
                    'Upload Image',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(ctx);
                    final api = Provider.of<TicketProvider>(context, listen: false).apiService;

                    final files = await FilePicker.pickFiles(type: FileType.image);
                    if (files.isNotEmpty) {
                      final file = files.first;
                      final bytes = await file.readAsBytes();
                      try {
                        final uploadedUrl = await api.uploadImageFile(
                          fileBytes: bytes,
                          fileName: file.name,
                          folder: 'car_gar/avatars',
                        );
                        if (mounted) {
                          setState(() => _avatarUrlController.text = uploadedUrl);
                          nav.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Avatar uploaded successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.danger),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('OR PICK PRESET / URL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _avatarPresets.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final url = _avatarPresets[index];
                    return InkWell(
                      onTap: () {
                        setState(() => _avatarUrlController.text = url);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(35),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(url),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _avatarUrlController,
                decoration: InputDecoration(
                  labelText: 'Custom Image Web URL',
                  hintText: 'https://example.com/photo.jpg',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final role = auth.currentRole;

    Color roleColor;
    String roleBadgeLabel;
    IconData roleIcon;

    switch (role) {
      case 'ADMIN':
        roleColor = const Color(0xFF6366F1);
        roleBadgeLabel = 'Administrator';
        roleIcon = Icons.admin_panel_settings_outlined;
        break;
      case 'RECEPTIONIST':
        roleColor = const Color(0xFF3B82F6);
        roleBadgeLabel = 'Front Desk & Cashier';
        roleIcon = Icons.desk_outlined;
        break;
      case 'MECHANIC':
        roleColor = const Color(0xFFF97316);
        roleBadgeLabel = 'Workshop Mechanic';
        roleIcon = Icons.build_outlined;
        break;
      case 'CUSTOMER':
      default:
        roleColor = const Color(0xFF14B8A6);
        roleBadgeLabel = 'Vehicle Owner';
        roleIcon = Icons.person_outline;
        break;
    }

    final avatarUrl = _avatarUrlController.text.trim();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F172A), // Deep Slate
                Color(0xFF1E3A5F), // Deep Steel Blue
                Color(0xFF1E293B), // Dark Slate
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(color: Color(0xFF334155), width: 1),
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: roleColor.withValues(alpha: 0.5), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: roleColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(roleIcon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ACCOUNT PROFILE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF22C55E),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$roleBadgeLabel Settings',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: roleColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 12, color: roleColor),
                const SizedBox(width: 5),
                Text(
                  role,
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: _isSaving
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.accent,
                  backgroundColor: Colors.transparent,
                ),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Card with Avatar
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: roleColor.withValues(alpha: 0.15),
                            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl.isEmpty
                                ? Icon(roleIcon, size: 36, color: roleColor)
                                : null,
                          ),
                          PositionedDirectional(
                            bottom: 0,
                            end: 0,
                            child: InkWell(
                              onTap: _showAvatarPickerModal,
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? user?.username ?? 'User Profile',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: roleColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(roleIcon, size: 13, color: roleColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        roleBadgeLabel,
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleColor),
                                      ),
                                    ],
                                  ),
                                ),
                                if (user?.customerCode != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.badge, size: 13, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Customer ID: ${user!.customerCode}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
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
              ),

              const SizedBox(height: 20),

              // 2. Personal Information Section
              _buildSectionCard(
                title: 'Basic Information',
                icon: Icons.badge_outlined,
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Full name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Primary Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Physical / Residential Address', prefixIcon: Icon(Icons.home_outlined)),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emergencyContactController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact (Name & Phone)',
                      hintText: 'e.g. Jane Doe (+1 555-0199)',
                      prefixIcon: Icon(Icons.contact_phone_outlined),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 3. Customer Specific Sections (Emergency & Billing, Garage Trust)
              if (auth.isCustomer) ...[
                _buildSectionCard(
                  title: 'Emergency & Tax Invoicing',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    TextFormField(
                      controller: _secondaryPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Secondary Contact Number',
                        hintText: '+1 555-0188',
                        prefixIcon: Icon(Icons.phone_android_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    const Text('Preferred Contact Channel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _contactChannels.map((channel) {
                        final isSelected = _preferredContactChannel == channel;
                        return ChoiceChip(
                          label: Text(channel),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _preferredContactChannel = channel);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Billing Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        TextButton(
                          onPressed: () {
                            setState(() => _billingAddressController.text = _addressController.text);
                          },
                          child: const Text('Same as Residential', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _billingAddressController,
                      decoration: const InputDecoration(
                        hintText: 'Enter official billing address for tax invoices...',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildSectionCard(
                  title: 'Garage Trust & Preferences',
                  icon: Icons.shield_outlined,
                  children: [
                    const Text('Saved Preferred Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _paymentMethods.map((pm) {
                        final isSelected = _savedPaymentMethod == pm['value'];
                        return ChoiceChip(
                          label: Text(pm['label']!),
                          selected: isSelected,
                          selectedColor: const Color(0xFF14B8A6),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _savedPaymentMethod = pm['value']!);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Default Vehicle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    _isLoadingVehicles
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            initialValue: _selectedDefaultVehicleId,
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.directions_car)),
                            hint: const Text('Select a default vehicle'),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('No Default Vehicle')),
                              ..._vehicles.map((v) => DropdownMenuItem<String>(
                                    value: v.id,
                                    child: Text('${v.year} ${v.make} ${v.model} (${v.licensePlate})'),
                                  )),
                            ],
                            onChanged: (val) => setState(() => _selectedDefaultVehicleId = val),
                          ),
                    const SizedBox(height: 16),
                    const Text('Notification Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _communicationPreferences,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.notifications_active_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('All Updates (Inspection, Approval, Work, Bill)')),
                        DropdownMenuItem(value: 'IMPORTANT', child: Text('Important Only (Action Required & Pickup)')),
                        DropdownMenuItem(value: 'MINIMAL', child: Text('Minimal (Pickup Ready Only)')),
                      ],
                      onChanged: (val) => setState(() => _communicationPreferences = val ?? 'ALL'),
                    ),
                  ],
                ),
              ],

              // 4. Staff Specific Sections (Mechanic & Receptionist)
              if (auth.isMechanic || auth.isReceptionist) ...[
                _buildSectionCard(
                  title: 'Accountability & Technical Skills',
                  icon: Icons.workspace_premium_outlined,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your profile photo and specialization are visible to customers on their live tracker and help receptionists route repair orders.',
                              style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _employeeIdController,
                      decoration: const InputDecoration(
                        labelText: 'Employee / Staff ID',
                        hintText: 'EMP-MEC-101',
                        prefixIcon: Icon(Icons.credit_card_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _specializationController,
                      decoration: const InputDecoration(
                        labelText: 'Technical Specialization / Department',
                        hintText: 'e.g. Engine & Transmission Specialist',
                        prefixIcon: Icon(Icons.handyman_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _specializationPresets.map((spec) {
                        return ActionChip(
                          label: Text(spec, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setState(() => _specializationController.text = spec);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Professional Bio & Experience',
                        hintText: 'Share your certifications, years of experience, or specialty...',
                        prefixIcon: Icon(Icons.article_outlined),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ],

              // 5. Admin Employment Records
              if (auth.isAdmin) ...[
                const SizedBox(height: 20),
                _buildSectionCard(
                  title: 'Staff Employment & Payroll Records',
                  icon: Icons.payments_outlined,
                  children: [
                    TextFormField(
                      controller: _employeeIdController,
                      decoration: const InputDecoration(
                        labelText: 'Employee / Staff ID',
                        hintText: 'EMP-ADM-001',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _hourlyRateController,
                      decoration: const InputDecoration(
                        labelText: 'Hourly Wage / Labor Rate (\$/hr)',
                        hintText: '65.00',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dateJoinedCompany != null
                                ? 'Date Joined: ${_dateJoinedCompany!.toLocal().toString().split(' ')[0]}'
                                : 'Date Joined: Not Set',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text('Select Date'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dateJoinedCompany ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _dateJoinedCompany = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              // Cool Modern 3D Save Changes Button
              _buildCoolSaveButton(roleColor),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoolSaveButton(Color roleColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A), // Deep Midnight Slate
            Color(0xFF1E3A5F), // Deep Steel Blue (AppColors.primary)
            Color(0xFF1D4ED8), // Electric Royal Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSaving ? null : _saveProfile,
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFF60A5FA).withValues(alpha: 0.35),
          highlightColor: Colors.white.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Left Icon with Glowing Glass Ring
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Center Action Title & Live Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isSaving ? 'UPDATING PROFILE...' : 'SAVE ALL CHANGES',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _isSaving
                            ? 'Synchronizing secure garage records'
                            : 'Save contact info, invoicing & trust settings',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Right Action Glow Capsule
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFB923C), // Amber-orange
                        Color(0xFFEA580C), // Deep safety orange
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isSaving ? 'SAVING' : 'APPLY',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isSaving ? Icons.hourglass_top_rounded : Icons.bolt_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}
