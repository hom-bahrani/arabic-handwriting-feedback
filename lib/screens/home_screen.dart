import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/handwriting_canvas.dart';
import '../providers/handwriting_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'Arabic Learning Assistant',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2235),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Write an Arabic sentence below with your finger or mouse. We\'ll check it and provide feedback on any mistakes.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Main content area (canvas + buttons)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    // Handwriting canvas
                    const Expanded(
                      child: HandwritingCanvas(),
                    ),
                    
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionButton(
                            label: 'Clear',
                            backgroundColor: const Color(0xFF64748B),
                            onPressed: () {
                              // Clear canvas functionality
                              final provider = Provider.of<HandwritingProvider>(context, listen: false);
                              provider.clearCanvas();
                            },
                          ),
                          _buildActionButton(
                            label: 'Reflow',
                            backgroundColor: const Color(0xFF4D7CF6),
                            onPressed: () {
                              // Reflow content functionality
                              // This would reorganize the strokes in a real app
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reflow functionality would reorganize writing in a real app'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          _buildActionButton(
                            label: 'Check',
                            backgroundColor: const Color(0xFF6366F1),
                            onPressed: () {
                              // Check functionality
                              final provider = Provider.of<HandwritingProvider>(context, listen: false);
                              provider.processHandwriting();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              color: Colors.white,
              child: const Text(
                '© 2025 Arabic Learning App',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 2,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}