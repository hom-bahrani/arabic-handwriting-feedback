import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../providers/handwriting_provider.dart';

class HandwritingCanvas extends StatefulWidget {
  const HandwritingCanvas({super.key});

  @override
  State<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends State<HandwritingCanvas> {
  // Store drawing points
  final List<Offset?> points = [];
  // Flag to track if user has started writing
  bool _hasStartedWriting = false;
  
  @override
  void initState() {
    super.initState();
    // Listen for provider changes to clear canvas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<HandwritingProvider>(context, listen: false);
      provider.addListener(() {
        if (provider.state == ProcessingState.idle) {
          clearCanvas();
        }
      });
    });
  }
  
  void clearCanvas() {
    setState(() {
      points.clear();
      _hasStartedWriting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  // Drawing area
                  SizedBox(
                    height: 400, // Increased height for drawing area (was 400)
                    child: Stack(
                      children: [
                        // Background
                        Container(
                          color: Colors.white,
                        ),
                        
                        // Guide text at the top - always visible
                        Positioned(
                          top: 30,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Text(
                              'مرحبا بالعالم',
                              style: GoogleFonts.amiri(
                                fontSize: 40,
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                        
                        // Guide lines - always visible, but text disappears when writing
                        Positioned(
                          top: 150, // Position with more space from top (was 200)
                          left: 20, // Wider margins
                          right: 20, // Wider margins
                          child: Column(
                            children: [
                              Container(
                                height: 1,
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              if (!_hasStartedWriting)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 30), // Doubled vertical space (was 15)
                                  child: Text(
                                    'write here',
                                    style: TextStyle(
                                      color: Colors.grey.withOpacity(0.5),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              if (_hasStartedWriting)
                                const SizedBox(height: 120), // Doubled space between lines when text is hidden (was 30)
                              Container(
                                height: 1,
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                        
                        // Drawing canvas - absolutely simplest implementation
                        GestureDetector(
                          onPanStart: (details) {
                            setState(() {
                              _hasStartedWriting = true;
                              // Use details.localPosition directly - more reliable
                              points.add(details.localPosition);
                            });
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              // Use details.localPosition directly - more reliable
                              points.add(details.localPosition);
                            });
                          },
                          onPanEnd: (details) {
                            setState(() {
                              // Add null to mark the end of a stroke
                              points.add(null);
                              
                              // Log to terminal that a stroke was completed
                              developer.log('Handwriting stroke completed. Total points: ${points.length}');
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.transparent,
                            child: CustomPaint(
                              painter: SimplePainter(points: points),
                              size: const Size(double.infinity, double.infinity),
                            ),
                          ),
                        ),
                        
                        // Processing overlay
                        Consumer<HandwritingProvider>(
                          builder: (context, provider, child) {
                            if (provider.state == ProcessingState.processing) {
                              return Container(
                                color: Colors.white.withOpacity(0.8),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Analyzing your handwriting...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else if (provider.state == ProcessingState.previewText) {
                              return Container(
                                color: Colors.white,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'You wrote:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        provider.recognizedText,
                                        style: GoogleFonts.amiri(
                                          fontSize: 40,
                                          color: Colors.black87,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else if (provider.state == ProcessingState.showingCorrection) {
                              return Container(
                                color: Colors.white,
                                child: Center(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Corrected:',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          provider.correctedText,
                                          style: GoogleFonts.amiri(
                                            fontSize: 40,
                                            color: Colors.black87,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'Feedback:',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ...provider.corrections.map((correction) => 
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.info_outline, 
                                                  size: 18, 
                                                  color: Color(0xFF6366F1)
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(correction),
                                                ),
                                              ],
                                            ),
                                          )
                                        ).toList(),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Container(); // Return empty container if drawing
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Control buttons - Clear and Check side by side
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clear button
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: clearCanvas,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF94A3B8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Check button
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () {
                      // Log the drawing to the terminal
                      developer.log('Checking handwriting with ${points.length} points');
                      
                      // Start processing
                      if (points.isNotEmpty) {
                        final provider = Provider.of<HandwritingProvider>(context, listen: false);
                        provider.processHandwriting();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Check',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Super simple painter that draws lines between points
class SimplePainter extends CustomPainter {
  final List<Offset?> points;
  
  SimplePainter({required this.points});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(SimplePainter oldDelegate) => true;
}