import 'package:flutter/material.dart';

class InterestsTravelStylesPage extends StatefulWidget {
  final void Function(List<String> interests, List<String> travelStyles) onNext;
  const InterestsTravelStylesPage({super.key, required this.onNext});

  @override
  State<InterestsTravelStylesPage> createState() =>
      _InterestsTravelStylesPageState();
}

class _InterestsTravelStylesPageState extends State<InterestsTravelStylesPage> {
  final TextEditingController _interestsController = TextEditingController();
  final TextEditingController _travelStylesController = TextEditingController();

  @override
  void dispose() {
    _interestsController.dispose();
    _travelStylesController.dispose();
    super.dispose();
  }

  List<String> _splitInput(String input) {
    // Split by comma or space, remove empty entries, trim whitespace
    return input
        .split(RegExp(r'[ ,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _onNext() {
    final interests = _splitInput(_interestsController.text);
    final travelStyles = _splitInput(_travelStylesController.text);
    widget.onNext(interests, travelStyles);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                const SizedBox(height: 8),
                const Text(
                  'ROAMIE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.deepOrange,
                  ),
                ),
                const Text(
                  'Find your roaming buddy',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Enter your Interests',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _interestsController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. hiking, food, art',
                    filled: true,
                    fillColor: Color(0xFFBFC2D9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Travel Styles',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _travelStylesController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. backpacking, luxury',
                    filled: true,
                    fillColor: Color(0xFFBFC2D9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _onNext,
                    child: const Text(
                      'Next',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
