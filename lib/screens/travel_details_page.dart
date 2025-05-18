import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/travel_model.dart';
import '../provider/travel_provider.dart';
import 'travel_plans_form.dart';

class DetailsScreen extends StatelessWidget {
  final TravelPlan plan;

  const DetailsScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TravelProvider>(context);

    void editPlan() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TravelPlanFormScreen(existing: plan),
        ),
      );
    }

    void deletePlan() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Travel Plan'),
          content: const Text('Are you sure you want to delete this plan?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete')),
          ],
        ),
      );

      if (confirm == true) {
        if (plan.id == null) return; // safety check
        await provider.deleteTravelPlan(plan.id!);
        if (context.mounted) Navigator.pop(context);
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: plan.imageUrl != null
                      ? NetworkImage(plan.imageUrl!)
                      : const AssetImage('lib/assets/placeholder.jpg')
                          as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.place,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              plan.location,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: editPlan,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.orange),
                        onPressed: deletePlan,
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.orange),
                        onPressed: null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 100,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        plan.notes.isNotEmpty ? plan.notes : 'Add note...',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${plan.startDate} – ${plan.endDate}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
