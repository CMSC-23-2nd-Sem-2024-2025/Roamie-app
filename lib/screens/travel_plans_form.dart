import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  String? _base64Image;
  Map<String, List<Map<String, String>>> _itinerary = {};

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
    _base64Image = widget.existing?.imageBase64;

    // Group itinerary by date
    _itinerary = {};
    (widget.existing?.itinerary ?? []).forEach((item) {
      final day = item['day']!;
      _itinerary.putIfAbsent(day, () => []).add({
        'start': item['start'] ?? '',
        'end': item['end'] ?? '',
        'details': item['details'] ?? '',
      });
    });
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

  void _pickDate(TextEditingController controller,
      {bool isStart = false}) async {
    final now = DateTime.now();
    DateTime first = DateTime(now.year, now.month, now.day);
    DateTime? last = DateTime(2100);

    if (!isStart && _startDateCtrl.text.isNotEmpty) {
      last =
          DateTime.tryParse(_startDateCtrl.text)?.add(const Duration(days: 90));
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: first,
      lastDate: last ?? DateTime(2100),
    );
    if (selected != null) {
      controller.text = selected.toIso8601String().split('T').first;
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await File(picked.path).readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  void _addOrEditItinerary() {
    DateTime? selectedDate;
    TimeOfDay? selectedStart;
    TimeOfDay? selectedEnd;
    String details = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Itinerary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(selectedDate == null
                    ? "Pick Date"
                    : selectedDate!.toIso8601String().split('T')[0]),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedStart = picked);
                  }
                },
                icon: const Icon(Icons.access_time),
                label: Text(selectedStart == null
                    ? "Pick Start Time"
                    : selectedStart!.format(ctx)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedEnd = picked);
                  }
                },
                icon: const Icon(Icons.access_time),
                label: Text(selectedEnd == null
                    ? "Pick End Time"
                    : selectedEnd!.format(ctx)),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Details"),
                onChanged: (v) => details = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (selectedDate == null ||
                    selectedStart == null ||
                    selectedEnd == null ||
                    details.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please complete all fields."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final day = selectedDate!.toIso8601String().split('T')[0];
                final entry = {
                  'start': selectedStart!.format(ctx),
                  'end': selectedEnd!.format(ctx),
                  'details': details.trim(),
                };
                setState(() {
                  _itinerary.putIfAbsent(day, () => []).add(entry);
                });
                Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _savePlan() async {
    if (_formKey.currentState!.validate()) {
      DateTime now = DateTime.now();
      DateTime? start = DateTime.tryParse(_startDateCtrl.text);
      DateTime? end = DateTime.tryParse(_endDateCtrl.text);
      if (start == null ||
          end == null ||
          start.isBefore(now) ||
          end.isBefore(start)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid travel dates')),
        );
        return;
      }

      for (var day in _itinerary.keys) {
        final date = DateTime.tryParse(day);
        if (date == null || date.isBefore(start) || date.isAfter(end)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Itinerary on $day is outside trip range')),
          );
          return;
        }
      }

      // Flatten itinerary
      final flatItinerary = _itinerary.entries.expand((e) {
        final day = e.key;
        return e.value.map((activity) => {
              'day': day,
              'start': activity['start']!,
              'end': activity['end']!,
              'details': activity['details']!,
            });
      }).toList();

      final userId = widget.existing?.ownerId ?? '';

      final plan = TravelPlan(
        id: widget.existing?.id,
        place: _placeCtrl.text,
        location: _locationCtrl.text,
        startDate: _startDateCtrl.text,
        endDate: _endDateCtrl.text,
        notes: _notesCtrl.text,
        ownerId: userId,
        sharedWith: widget.existing?.sharedWith ?? [],
        imageBase64: _base64Image ?? widget.existing?.imageBase64,
        itinerary: flatItinerary,
      );

      final travelProvider = context.read<TravelProvider>();

      if (widget.existing == null) {
        await travelProvider.addTravelPlan(plan);
      } else {
        await travelProvider.updateTravelPlan(plan.id!, plan);
        if (!mounted) return;
        Navigator.pop(context); // close edit
      }

      if (!mounted) return;
      Navigator.pop(context); // go back
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
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
                onSuffixTap: () => _pickDate(_startDateCtrl, isStart: true),
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
              const SizedBox(height: 20),
              _label("Cover Image"),
              Center(
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text(
                        "Select from Gallery",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[900]),
                    ),
                    if (_base64Image != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(_base64Image!),
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() => _base64Image = null);
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _label("Itinerary"),
              if (_itinerary.isEmpty) const Text("No itineraries added yet."),
              ..._itinerary.entries.map((entry) {
                final day = entry.key;
                final activities = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text("Day $day",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...activities.asMap().entries.map((actEntry) {
                      final idx = actEntry.key;
                      final act = actEntry.value;
                      return ListTile(
                        title: Text("${act['start']}–${act['end']}"),
                        subtitle: Text(act['details'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              activities.removeAt(idx);
                              if (activities.isEmpty) _itinerary.remove(day);
                            });
                          },
                        ),
                      );
                    }),
                  ],
                );
              }),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addOrEditItinerary,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Itinerary"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700]),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _savePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
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
              ),
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
            fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14),
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
            ? IconButton(icon: Icon(suffixIcon), onPressed: onSuffixTap)
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
