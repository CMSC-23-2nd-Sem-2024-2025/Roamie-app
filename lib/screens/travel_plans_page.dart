import 'package:flutter/material.dart';

class TravelPlansPage extends StatelessWidget {
  const TravelPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Travel Plans')),
      body: const Center(child: Text('Travel Plans Page')),
    );
  }
}
