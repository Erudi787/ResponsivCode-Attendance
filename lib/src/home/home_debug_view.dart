// lib/src/home/home_debug_view.dart (NEW FILE)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rts_locator/src/home/home_controller.dart';
import 'package:rts_locator/src/home/home_service.dart';
import 'package:rts_locator/src/home/home_view.dart';

class HomeDebugView extends StatefulWidget {
  const HomeDebugView({super.key});

  @override
  State<HomeDebugView> createState() => _HomeDebugViewState();
}

class _HomeDebugViewState extends State<HomeDebugView> {
  String debugInfo = "Starting debug...";
  List<String> debugSteps = [];
  bool hasError = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _runDebugSequence();
  }

  void _addDebugStep(String step) {
    setState(() {
      debugSteps.add("${DateTime.now().toString().substring(11, 19)}: $step");
      debugInfo = debugSteps.join('\n');
    });
  }

  Future<void> _runDebugSequence() async {
    try {
      _addDebugStep("✓ View created");
      
      // Check if controller exists
      if (Get.isRegistered<HomeController>()) {
        _addDebugStep("✓ HomeController is registered");
      } else {
        _addDebugStep("✗ HomeController NOT registered");
        _addDebugStep("→ Creating HomeController...");
        Get.put(HomeController(HomeService()));
        _addDebugStep("✓ HomeController created");
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get controller
      final controller = Get.find<HomeController>();
      _addDebugStep("✓ Got HomeController reference");
      
      // Check camera status
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (controller.cameraController == null) {
        _addDebugStep("✗ Camera controller is null");
        _addDebugStep("→ Initializing camera...");
        
        try {
          await controller.initializeCamera();
          _addDebugStep("✓ Camera initialized");
        } catch (e) {
          _addDebugStep("✗ Camera init failed: ${e.toString().substring(0, 50)}...");
        }
      } else {
        _addDebugStep("✓ Camera controller exists");
        _addDebugStep("→ Is initialized: ${controller.cameraController!.value.isInitialized}");
      }
      
      _addDebugStep("✓ Debug sequence complete");
      
      // Try to navigate to actual home after 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      _addDebugStep("→ Attempting to load real HomeView...");
      
    } catch (e, stack) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        _addDebugStep("✗ ERROR: $errorMessage");
        _addDebugStep("Stack: ${stack.toString().substring(0, 100)}...");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hasError ? Colors.red.shade50 : Colors.white,
      appBar: AppBar(
        title: const Text('Home Debug View'),
        backgroundColor: hasError ? Colors.red : Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasError)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ERROR DETECTED',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage ?? 'Unknown error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Debug Steps:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                debugInfo,
                style: GoogleFonts.robotoMono(fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      debugSteps.clear();
                      hasError = false;
                      errorMessage = null;
                    });
                    _runDebugSequence();
                  },
                  child: const Text('Retry Debug'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    Get.snackbar(
                      'Navigation Test',
                      'Trying to go to actual HomeView...',
                      backgroundColor: Colors.blue,
                      colorText: Colors.white,
                    );
                    
                    await Future.delayed(const Duration(seconds: 1));
                    
                    try {
                      Get.off(() => const HomeView());
                    } catch (e) {
                      Get.snackbar(
                        'Navigation Failed',
                        e.toString(),
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 5),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Try Real Home'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}