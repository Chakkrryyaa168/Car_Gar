import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';

class CheckInModal extends StatefulWidget {
  const CheckInModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CheckInModal(),
    );
  }

  @override
  State<CheckInModal> createState() => _CheckInModalState();
}

class _CheckInModalState extends State<CheckInModal> {
  final _formKey = GlobalKey<FormState>();
  List<VehicleModel> _vehicles = [];
  String? _selectedVehicleId;
  String? _selectedOwnerId;

  final _mileageController = TextEditingController(text: '45000');
  final _notesController = TextEditingController(text: 'Routine maintenance and brake inspection.');
  final _photoUrlController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1617814076367-b759c7d7e738?auto=format&fit=crop&w=800&q=80',
  );
  double _fuelLevel = 60.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final api = Provider.of<TicketProvider>(context, listen: false).apiService;
    try {
      final list = await api.fetchVehicles();
      setState(() {
        _vehicles = list;
        if (list.isNotEmpty) {
          _selectedVehicleId = list.first.id;
          _selectedOwnerId = list.first.owner;
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.directions_car, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Customer Vehicle Check-In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Selector
                    const Text('Select Customer Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_vehicles.isEmpty)
                      const Text('Loading vehicles...', style: TextStyle(color: AppColors.textSecondary))
                    else
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedVehicleId,
                        decoration: const InputDecoration(),
                        items: _vehicles.map((v) {
                          return DropdownMenuItem(
                            value: v.id,
                            child: Text(
                              '${v.displayName} - ${v.ownerName ?? 'Owner'}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedVehicleId = val;
                            final selected = _vehicles.firstWhere((v) => v.id == val);
                            _selectedOwnerId = selected.owner;
                          });
                        },
                      ),
                    const SizedBox(height: 16),

                    // Mileage
                    const Text('Current Odometer (Miles)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _mileageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.speed, color: AppColors.textSecondary),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter mileage' : null,
                    ),
                    const SizedBox(height: 16),

                    // Fuel Level Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fuel Level:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_fuelLevel.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    Slider(
                      value: _fuelLevel,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _fuelLevel = val),
                    ),
                    const SizedBox(height: 12),

                    // Customer Complaints
                    const Text('Customer Complaints / Request Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Squeaking brakes, oil service, warning light...',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Walkaround Photo URL
                    const Text('Check-in Walkaround Photo (Cloudinary URL)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _photoUrlController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Submit CTA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent, // #F97316
                ),
                onPressed: _isLoading ? null : _submitCheckIn,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Complete Check-In & Generate Ticket',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCheckIn() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null || _selectedOwnerId == null) return;

    setState(() => _isLoading = true);
    final provider = Provider.of<TicketProvider>(context, listen: false);

    try {
      final ticket = await provider.apiService.createTicket(
        vehicleId: _selectedVehicleId!,
        customerId: _selectedOwnerId!,
        mileageIn: int.tryParse(_mileageController.text) ?? 0,
        fuelLevelPercent: _fuelLevel.toInt(),
        notes: _notesController.text,
      );

      // Upload check-in photo if provided
      if (_photoUrlController.text.isNotEmpty) {
        await provider.uploadPhoto(
          ticketId: ticket.id,
          stage: 'CHECKIN_INSPECTION',
          url: _photoUrlController.text,
          caption: 'Vehicle walkaround check-in condition',
        );
      }

      await provider.fetchTickets();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket #${ticket.ticketNumber} created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
