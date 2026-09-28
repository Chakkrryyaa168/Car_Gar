import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/vehicle_model.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';

class CheckInModal extends StatefulWidget {
  final String? initialVehicleId;
  final String? initialOwnerId;

  const CheckInModal({
    super.key,
    this.initialVehicleId,
    this.initialOwnerId,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialVehicleId,
    String? initialOwnerId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckInModal(
        initialVehicleId: initialVehicleId,
        initialOwnerId: initialOwnerId,
      ),
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
  String _vehicleSearchQuery = '';

  final _mileageController = TextEditingController(text: '45000');
  final _notesController = TextEditingController(text: 'Routine maintenance and brake inspection.');
  final _photoUrlController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1617814076367-b759c7d7e738?auto=format&fit=crop&w=800&q=80',
  );
  double _fuelLevel = 60.0;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.initialVehicleId;
    _selectedOwnerId = widget.initialOwnerId;
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final api = Provider.of<TicketProvider>(context, listen: false).apiService;
    try {
      final list = await api.fetchVehicles();
      if (mounted) {
        setState(() {
          _vehicles = list;
          if (_selectedVehicleId != null && list.any((v) => v.id == _selectedVehicleId)) {
            final match = list.firstWhere((v) => v.id == _selectedVehicleId);
            _selectedOwnerId = match.owner;
          } else if (list.isNotEmpty && _selectedVehicleId == null) {
            _selectedVehicleId = list.first.id;
            _selectedOwnerId = list.first.owner;
          }
        });
      }
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Select Customer Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
                        if (_selectedVehicleId != null && _vehicles.any((v) => v.id == _selectedVehicleId)) ...[
                          Builder(builder: (context) {
                            final current = _vehicles.firstWhere((v) => v.id == _selectedVehicleId);
                            if (current.ownerCustomerCode != null) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'Customer ID: ${current.ownerCustomerCode}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Filter by Customer ID (e.g. CG-1042), Plate, or Name...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _vehicleSearchQuery = val.trim().toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    if (_vehicles.isEmpty)
                      const Text('Loading vehicles...', style: TextStyle(color: AppColors.textSecondary))
                    else
                      Builder(builder: (context) {
                        final displayed = _vehicleSearchQuery.isEmpty
                            ? _vehicles
                            : _vehicles.where((v) {
                                final q = _vehicleSearchQuery;
                                final code = (v.ownerCustomerCode ?? '').toLowerCase();
                                final plate = v.licensePlate.toLowerCase();
                                final name = (v.ownerName ?? '').toLowerCase();
                                final model = '${v.make} ${v.model}'.toLowerCase();
                                return code.contains(q) ||
                                    code.replaceAll('cg-', '').contains(q) ||
                                    plate.contains(q) ||
                                    name.contains(q) ||
                                    model.contains(q);
                              }).toList();

                        if (displayed.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No matching vehicle found for this Customer ID or Plate.',
                              style: TextStyle(fontSize: 12, color: AppColors.danger),
                            ),
                          );
                        }

                        final selectedInList = displayed.any((v) => v.id == _selectedVehicleId);
                        final effectiveValue = selectedInList ? _selectedVehicleId : displayed.first.id;

                        return DropdownButtonFormField<String>(
                          key: ValueKey(effectiveValue),
                          isExpanded: true,
                          initialValue: effectiveValue,
                          decoration: const InputDecoration(),
                          items: displayed.map((v) {
                            final codeBadge = v.ownerCustomerCode != null ? '[${v.ownerCustomerCode}] ' : '';
                            return DropdownMenuItem(
                              value: v.id,
                              child: Text(
                                '$codeBadge${v.displayName} • ${v.ownerName ?? 'Owner'}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedVehicleId = val;
                              final selected = displayed.firstWhere((v) => v.id == val);
                              _selectedOwnerId = selected.owner;
                            });
                          },
                        );
                      }),
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

                    // Walkaround Photo
                    const Text('Check-in Walkaround Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // Upload Image Card
                    InkWell(
                      onTap: _isUploadingPhoto
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final provider = Provider.of<TicketProvider>(context, listen: false);

                              final files = await FilePicker.pickFiles(type: FileType.image);
                              if (files.isNotEmpty) {
                                final file = files.first;
                                final bytes = await file.readAsBytes();
                                setState(() => _isUploadingPhoto = true);
                                try {
                                  final url = await provider.apiService.uploadImageFile(
                                    fileBytes: bytes,
                                    fileName: file.name,
                                    folder: 'car_gar/walkaround',
                                  );
                                  if (mounted) {
                                    setState(() => _photoUrlController.text = url);
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Walkaround photo uploaded successfully!'),
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
                                } finally {
                                  if (mounted) setState(() => _isUploadingPhoto = false);
                                }
                              }
                            },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _photoUrlController.text.isNotEmpty
                              ? AppColors.primary.withValues(alpha: 0.05)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _photoUrlController.text.isNotEmpty ? AppColors.primary : AppColors.border,
                            width: 1.2,
                          ),
                        ),
                        child: _isUploadingPhoto
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                      SizedBox(width: 12),
                                      Text('Uploading image...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              )
                            : _photoUrlController.text.isNotEmpty
                                ? Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          _photoUrlController.text,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 56,
                                            height: 56,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.broken_image, size: 24),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Photo Attached',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Tap to change image',
                                              style: TextStyle(fontSize: 11, color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () => setState(() => _photoUrlController.clear()),
                                      ),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 22),
                                      SizedBox(width: 10),
                                      Text(
                                        'Upload Image',
                                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
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
