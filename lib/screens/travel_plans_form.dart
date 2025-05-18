import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/travel_model.dart';
import '../provider/travel_provider.dart';

class TravelPlanFormScreen extends StatefulWidget {
  final TravelPlan? existing;
  const TravelPlanFormScreen({super.key, this.existing});

  @override
  State<TravelPlanFormScreen> createState() => _TravelPlanFormScreenState();
}

class _TravelPlanFormScreenState extends State<TravelPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _placeCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _startDateCtrl;
  late TextEditingController _endDateCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _placeCtrl = TextEditingController(text: widget.existing?.place ?? '');
    _locationCtrl =
        TextEditingController(text: widget.existing?.location ?? '');
    _startDateCtrl =
        TextEditingController(text: widget.existing?.startDate ?? '');
    _endDateCtrl = TextEditingController(text: widget.existing?.endDate ?? '');
    _notesCtrl = TextEditingController(text: widget.existing?.notes ?? '');
  }

  @override
  void dispose() {
    _placeCtrl.dispose();
    _locationCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _pickDate(TextEditingController controller) async {
    final selected = await showDatePicker(
      //https://api.flutter.dev/flutter/material/showDatePicker.html
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      controller.text = selected.toIso8601String().split('T').first;
      //https://api.flutter.dev/flutter/dart-core/DateTime/toIso8601String.html
    }
  }

  void _savePlan() async {
    if (_formKey.currentState!.validate()) {
      final userId = widget.existing?.ownerId ??
          ''; //fetch current user UID here if needed

      final plan = TravelPlan(
        id: widget.existing?.id,
        place: _placeCtrl.text,
        location: _locationCtrl.text,
        startDate: _startDateCtrl.text,
        endDate: _endDateCtrl.text,
        notes: _notesCtrl.text,
        ownerId: userId,
        sharedWith: widget.existing?.sharedWith ?? [],
      );

      final travelProvider = context.read<TravelProvider>();

      if (widget.existing == null) {
        await travelProvider.addTravelPlan(plan);
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        await travelProvider.updateTravelPlan(plan.id!, plan);
        if (!mounted) return;
        Navigator.pop(context);
        if (!mounted) return;
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: Text(
          widget.existing == null ? "Add Travel Plan" : "Edit Travel Plan",
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label("Name of Place"),
              _inputField(controller: _placeCtrl, hint: "e.g. Palawan"),
              const SizedBox(height: 20),
              _label("Start Date"),
              _inputField(
                controller: _startDateCtrl,
                hint: "YYYY-MM-DD",
                suffixIcon: Icons.calendar_today,
                onSuffixTap: () => _pickDate(_startDateCtrl),
              ),
              const SizedBox(height: 20),
              _label("End Date"),
              _inputField(
                controller: _endDateCtrl,
                hint: "YYYY-MM-DD",
                suffixIcon: Icons.calendar_today,
                onSuffixTap: () => _pickDate(_endDateCtrl),
              ),
              const SizedBox(height: 20),
              _label("Notes"),
              _inputField(controller: _notesCtrl, hint: "e.g. Bring sunscreen"),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _savePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: Icon(widget.existing == null ? Icons.add : Icons.edit,
                      color: Colors.white),
                  label: Text(
                    widget.existing == null ? "CREATE" : "UPDATE",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.orange,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: suffixIcon != null,
      onTap: onSuffixTap,
      validator: (val) => val == null || val.isEmpty ? "Required field" : null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade200,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon),
                onPressed: onSuffixTap,
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
