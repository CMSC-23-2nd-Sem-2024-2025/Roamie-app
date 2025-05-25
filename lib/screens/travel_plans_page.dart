import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/travel_model.dart';
import '../provider/travel_provider.dart';
import 'travel_plans_form.dart';
import 'travel_details_page.dart';

class TravelPlansPage extends StatefulWidget {
  const TravelPlansPage({super.key});

  @override
  State<TravelPlansPage> createState() => _TravelPlansPageState();
}

class _TravelPlansPageState extends State<TravelPlansPage> {
  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    await context.read<TravelProvider>().fetchTravelPlans();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TravelProvider>();
    final plans = provider.plans;
    final currentUserId = provider.currentUserId;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to see your travel plans')),
      );
    }

    // Separate owned and shared plans
    final ownedPlans = plans.where((p) => p.ownerId == currentUserId).toList();
    final sharedPlans = plans
        .where((p) =>
            p.ownerId != currentUserId &&
            (p.sharedWith?.contains(currentUserId) ?? false))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFA500), // Orange background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.travel_explore, color: Colors.orange),
            SizedBox(width: 8),
            Text("Roamie",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: (ownedPlans.isEmpty && sharedPlans.isEmpty)
          ? const Center(
              child: Text("No Travel Plans Yet :(",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ownedPlans.isNotEmpty) ...[
                    const Text(
                      "Your Travel Plans",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ownedPlans.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final plan = ownedPlans[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DetailsScreen(plan: plan)),
                          ),
                          child: _buildTravelCard(plan, index),
                        );
                      },
                    ),
                  ],
                  if (sharedPlans.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      "Shared With You",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sharedPlans.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final plan = sharedPlans[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DetailsScreen(plan: plan)),
                          ),
                          child: _buildTravelCard(plan, index),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue[900],
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const TravelPlanFormScreen())),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("CREATE",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTravelCard(TravelPlan plan, int index) {
    final imageWidget = _buildImage(plan);
    final startDate = plan.startDate;
    final endDate = plan.endDate;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    startDate == endDate
                        ? _formatDate(startDate)
                        : "${_formatDate(startDate)} to ${_formatDate(endDate)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    plan.place,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    plan.location,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(TravelPlan plan) {
    if (plan.imageBase64 != null && plan.imageBase64!.isNotEmpty) {
      //https://stackoverflow.com/questions/46145472/how-to-convert-base64-string-into-image-with-flutter
      return Image.memory(
        base64Decode(plan.imageBase64!),
        fit: BoxFit.cover,
      );
    } else {
      return Image.asset(
        'lib/assets/placeholder.jpg',
        fit: BoxFit.cover,
      );
    }
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      final month = parts[1];
      final day = parts[2];
      return "$month/$day";
    } catch (_) {
      return date;
    }
  }
}
