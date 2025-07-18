import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class HomeMinimal extends StatelessWidget {
  const HomeMinimal({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final userName = box.read('fullname') ?? 'User';
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Welcome $userName'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Minimal Home View',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'If you see this, navigation works!\nThe issue is in the complex HomeView.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Get.snackbar(
                  'Test',
                  'Button works!',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              },
              child: const Text('Test Button'),
            ),
          ],
        ),
      ),
    );
  }
}