import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/handwriting_provider.dart';

class HandwritingCanvas extends StatefulWidget {
  const HandwritingCanvas({super.key});

  @override
  State<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends State<HandwritingCanvas> {
  // Store drawing points
  final List<Offset?> points = [];
  
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Drawing area
            Expanded(
              child: Stack(
                children: [
                  // Background
                  Container(
                    color: Colors.white,
                  ),
                  
                  // Drawing canvas - absolutely simplest implementation
                  GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        RenderBox renderBox = context.findRenderObject() as RenderBox;
                        Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                        points.add(localPosition);
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        RenderBox renderBox = context.findRenderObject() as RenderBox;
                        Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                        points.add(localPosition);
                      });
                    },
                    onPanEnd: (details) {
                      setState(() {
                        // Add null to mark the end of a stroke
                        points.add(null);
                      });
                    },
                    child: CustomPaint(
                      painter: SimplePainter(points: points),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  
                  // Placeholder text or feedback display
                  Consumer<HandwritingProvider>(
                    builder: (context, provider, child) {
                      if (points.isEmpty && provider.state == ProcessingState.idle) {
                        return Center(
                          child: Text(
                            'مرحبا بالعالم',
                            style: GoogleFonts.amiri(
                              fontSize: 40,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        );
                      } else if (provider.state == ProcessingState.processing) {
                        return Center(
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
                        );
                      } else if (provider.state == ProcessingState.previewText) {
                        return Center(
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
                        );
                      } else if (provider.state == ProcessingState.showingCorrection) {
                        return Center(
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
                        );
                      }
                      return Container(); // Return empty container if drawing
                    },
                  ),
                ],
              ),
            ),
            
            // Scroll indicator
            Container(
              height: 16,
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD1B9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8F56),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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