import 'package:flutter/material.dart';
import '../models/fuel_log_model.dart';
import '../services/fuel_service.dart';

class AddEditFuelDialog extends StatefulWidget {
  final FuelLog? fuelLog; // Null for Add, Not Null for Edit
  final int? preSelectedVehicleId;
  final int? preSelectedBookingId;

  const AddEditFuelDialog({
    Key? key,
    this.fuelLog,
    this.preSelectedVehicleId,
    this.preSelectedBookingId,
  }) : super(key: key);

  @override
  State<AddEditFuelDialog> createState() => _AddEditFuelDialogState();
}

class _AddEditFuelDialogState extends State<AddEditFuelDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _fuelType;
  late TextEditingController _rateController;
  late TextEditingController _unitsController;
  late TextEditingController _costController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _fuelType = widget.fuelLog?.fuelType ?? 'Diesel';
    _rateController = TextEditingController(text: widget.fuelLog?.ratePerUnit.toString() ?? '');
    _unitsController = TextEditingController(text: widget.fuelLog?.totalUnits.toString() ?? '');
    _costController = TextEditingController(text: widget.fuelLog?.totalCost.toString() ?? '');
    _notesController = TextEditingController(text: widget.fuelLog?.notes ?? '');
    _selectedDate = widget.fuelLog != null ? DateTime.parse(widget.fuelLog!.date) : DateTime.now();

    _rateController.addListener(_calculateTotal);
    _unitsController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    final rate = double.tryParse(_rateController.text) ?? 0;
    final units = double.tryParse(_unitsController.text) ?? 0;
    if (rate > 0 && units > 0) {
      _costController.text = (rate * units).toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.fuelLog != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Fuel Record' : 'Add Fuel Record'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _fuelType,
                decoration: const InputDecoration(labelText: 'Fuel Type'),
                items: ['Diesel', 'Petrol', 'LPG'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => _fuelType = val!),
              ),
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(labelText: 'Rate per Unit (Rs)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Enter rate' : null,
              ),
              TextFormField(
                controller: _unitsController,
                decoration: const InputDecoration(labelText: 'Total Units (Liters / Kg)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Enter units' : null,
              ),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Total Cost (Rs)'),
                keyboardType: TextInputType.number,
                readOnly: true,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes / Petrol Pump Name'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final log = FuelLog(
                id: widget.fuelLog?.id,
                vehicleId: widget.preSelectedVehicleId ?? widget.fuelLog!.vehicleId,
                bookingId: widget.preSelectedBookingId ?? widget.fuelLog?.bookingId,
                fuelType: _fuelType,
                ratePerUnit: double.parse(_rateController.text),
                totalUnits: double.parse(_unitsController.text),
                totalCost: double.parse(_costController.text),
                date: _selectedDate.toIso8601String().split('T')[0],
                notes: _notesController.text,
              );

              final service = FuelService();
              if (isEditing) {
                await service.updateFuelLog(log);
              } else {
                await service.addFuelLog(log);
              }
              Navigator.pop(context, true);
            }
          },
          child: Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}
