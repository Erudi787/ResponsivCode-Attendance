import 'package:flutter/material.dart';

class TestHomeView extends StatelessWidget {
  const TestHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    print('🧪 TestHomeView: build() called');
    
    return Scaffold(
      backgroundColor: Colors.green, // GREEN to make it obvious
      appBar: AppBar(
        title: const Text('TEST HOME'),
        backgroundColor: Colors.green.shade700,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'If you see this GREEN screen,\nnavigation is working!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}