import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/travel_model.dart';
import '../provider/travel_provider.dart';
import 'travel_plans_form.dart';
import '../api/firebase_api_travel.dart';

class DetailsScreen extends StatelessWidget {
  final TravelPlan plan;

  const DetailsScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TravelProvider>(context);
    final currentUser = provider.currentUserId;

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
        if (plan.id == null) return;
        await provider.deleteTravelPlan(plan.id!);
        if (context.mounted) Navigator.pop(context);
      }
    }

    Future<void> shareByUsername() async {
      final controller = TextEditingController();
      final username = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share via Username'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Enter username'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Share')),
          ],
        ),
      );

      if (username != null && username.isNotEmpty) {
        await provider.sharePlanWithUser(plan.id!, username);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Shared successfully')));
        }
      }
    }

    Future<void> generateAndSaveQR() async {
      final qrData = jsonEncode({'planId': plan.id});
      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: false,
      );
      final ui.Image qrImage = await qrPainter.toImage(300);
      final byteData = await qrImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final status = await Permission.storage.request();
      if (status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR code saved to gallery')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied')),
          );
        }
      }
    }

    Future<void> scanQR() async {
      await showDialog(
        context: context,
        builder: (context) {
          final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
          return AlertDialog(
            title: const Text('Scan QR Code'),
            content: SizedBox(
              width: 300,
              height: 300,
              child: QRView(
                key: qrKey,
                onQRViewCreated: (controller) {
                  controller.scannedDataStream.listen((scanData) async {
                    // Don't dispose controller here
                    final data = jsonDecode(scanData.code ?? '{}');
                    final sharedPlanId = data['planId'];

                    if (sharedPlanId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid QR code data')),
                      );
                      return;
                    }

                    // Fetch the plan data from Firestore by ID
                    final planDoc = await FirebaseTravelAPI.db
                        .collection('travel_plans')
                        .doc(sharedPlanId)
                        .get();

                    if (!planDoc.exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shared plan not found')),
                      );
                      return;
                    }

                    final planData = planDoc.data() as Map<String, dynamic>;
                    planData['id'] = planDoc.id;

                    // Get current username (you might need a method in your provider or from Firestore)
                    final currentUserId = provider.currentUserId;
                    if (currentUserId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not logged in')),
                      );
                      return;
                    }

                    // Get username from uid
                    final username =
                        await provider.getUsernameFromUid(currentUserId);
                    if (username == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Username not found')),
                      );
                      return;
                    }

                    // Now import the plan properly
                    await provider.importSharedPlan(planData, username);

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Plan added to your account')),
                    );
                  });
                },
              ),
            ),
          );
        },
      );
    }

    Future<void> showShareOptions() async {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Share via username'),
                onTap: () {
                  Navigator.pop(context);
                  shareByUsername();
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('Generate & save QR code'),
                onTap: () {
                  Navigator.pop(context);
                  generateAndSaveQR();
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Scan QR code'),
                onTap: () {
                  Navigator.pop(context);
                  scanQR();
                },
              ),
            ],
          ),
        ),
      );
    }

    Future<String> getUsername(String uid) async {
      // Implement or call provider method to fetch username by uid.
      return await provider.getUsernameFromUid(uid) ?? 'Unknown user';
    }

    Widget buildCoverImage() {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.black,
              insetPadding: const EdgeInsets.all(10),
              child: Stack(
                children: [
                  InteractiveViewer(
                    child: (plan.imageBase64 != null)
                        ? Image.memory(base64Decode(plan.imageBase64!),
                            fit: BoxFit.contain)
                        : Image.asset('lib/assets/placeholder.jpg',
                            fit: BoxFit.contain),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: (plan.imageBase64 != null)
            ? Image.memory(base64Decode(plan.imageBase64!),
                fit: BoxFit.cover, width: double.infinity, height: 300)
            : Image.asset('lib/assets/placeholder.jpg',
                fit: BoxFit.cover, width: double.infinity, height: 300),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: double.infinity, height: 300, child: buildCoverImage()),
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
                            Text(plan.place,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            Text(plan.location,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black54)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.orange),
                        onPressed: () => Navigator.pop(context),
                      ),
                      if (plan.ownerId == currentUser) ...[
                        IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: editPlan),
                        IconButton(
                            icon:
                                const Icon(Icons.delete, color: Colors.orange),
                            onPressed: deletePlan),
                      ],
                      IconButton(
                          icon: const Icon(Icons.share, color: Colors.orange),
                          onPressed: showShareOptions),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      plan.notes.isNotEmpty ? plan.notes : 'No notes added.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('${plan.startDate} to ${plan.endDate}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  if (plan.itinerary.isNotEmpty) ...[
                    const Text(
                      'Itinerary',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange),
                    ),
                    const SizedBox(height: 8),
                    ...plan.itinerary.map((entry) {
                      final day = entry['day'] ?? '';
                      final start = entry['start'] ?? '';
                      final end = entry['end'] ?? '';
                      final details = entry['details'] ?? '';
                      final timeRange = (start.isNotEmpty && end.isNotEmpty)
                          ? '$start to $end'
                          : start.isNotEmpty
                              ? 'Starts at $start'
                              : end.isNotEmpty
                                  ? 'Ends at $end'
                                  : '';
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text('Day: $day'),
                          subtitle: Text(timeRange.isNotEmpty
                              ? '$timeRange\n$details'
                              : details),
                        ),
                      );
                    }),
                  ],

                  // --- Your added "Shared With" section below ---
                  if (plan.ownerId == currentUser &&
                      (plan.sharedWith?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Shared With:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...plan.sharedWith!.map((uid) {
                      // Use FutureBuilder to asynchronously get username from uid
                      return FutureBuilder<String>(
                        future: getUsername(uid),
                        builder: (context, snapshot) {
                          final username = snapshot.data ?? 'Loading...';
                          return Card(
                            child: ListTile(
                              title: Text(username),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Remove User'),
                                      content: Text(
                                          'Remove $username from this plan?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel')),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Remove')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await provider.removeSharedUser(
                                        plan.id!, uid);
                                    await provider.reloadPlan(plan.id!);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content:
                                                  Text('$username removed')));
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
