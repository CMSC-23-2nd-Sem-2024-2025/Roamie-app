import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/travel_model.dart';
import '../provider/travel_provider.dart'; // <-- your provider
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
    final plans = context.watch<TravelProvider>().plans;

    return Scaffold(
      backgroundColor: Color(0xffffffff),
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Text("Your Travel Plans :)",
            style: TextStyle(color: Colors.white)),
      ),
      body: plans.isEmpty
          ? const Center(
              child: Text("No Travel Plans Yet :(",
                  style: TextStyle(fontSize: 18)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: plans.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DetailsScreen(plan: plans[index])),
                ),
                child: _buildTravelCard(plans[index], index),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue[900],
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const TravelPlanFormScreen()));
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("CREATE",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTravelCard(TravelPlan plan, int index) {
    final backgroundColor = index.isEven
        ? Colors.orange.withOpacity(0.85)
        : Colors.blue.withOpacity(0.85);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.place,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text("Start Date: ${plan.startDate}"),
          Text("End Date: ${plan.endDate}"),
          const SizedBox(height: 8),
          Text("Notes: ${plan.notes}"),
        ],
      ),
    );
  }
}
