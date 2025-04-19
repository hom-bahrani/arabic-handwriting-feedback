import 'package:flutter/material.dart';
import 'dart:ui' show PointMode;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/handwriting_provider.dart';

class HandwritingCanvas extends StatefulWidget {
  const HandwritingCanvas({super.key});

  @override
  State<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends State<HandwritingCanvas> {
  // Simple list of points for drawing
  final List<DrawingPoint?> points = [];
  
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
                  // Paper-like background with subtle grid
                  Container(
                    color: Colors.white,
                    child: CustomPaint(
                      painter: GridPainter(),
                      size: Size.infinite,
                    ),
                  ),
                  
                  // Drawing layer - Using RepaintBoundary for performance
                  RepaintBoundary(
                    child: DrawingArea(
                      points: points,
                      onPointsUpdate: (updatedPoints) {
                        // This ensures we update state properly
                        setState(() {
                          points.clear();
                          points.addAll(updatedPoints);
                        });
                      },
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

// Separate widget for drawing area to better handle state changes
class DrawingArea extends StatefulWidget {
  final List<DrawingPoint?> points;
  final Function(List<DrawingPoint?>) onPointsUpdate;

  const DrawingArea({
    super.key,
    required this.points,
    required this.onPointsUpdate,
  });

  @override
  State<DrawingArea> createState() => _DrawingAreaState();
}

class _DrawingAreaState extends State<DrawingArea> {
  // Local copy of points for immediate drawing response
  late List<DrawingPoint?> _localPoints;

  @override
  void initState() {
    super.initState();
    _localPoints = List.from(widget.points);
  }

  @override
  void didUpdateWidget(DrawingArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.points != oldWidget.points) {
      _localPoints = List.from(widget.points);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        // Create a new point and update immediately
        final newPoint = DrawingPoint(
          details.localPosition,
          Paint()
            ..color = Colors.black
            ..isAntiAlias = true
            ..strokeWidth = 1.0 
            ..strokeCap = StrokeCap.round,
        );
        
        setState(() {
          _localPoints.add(newPoint);
        });
        
        // Notify parent
        widget.onPointsUpdate(_localPoints);
      },
      onPanUpdate: (details) {
        // Add new point and update immediately
        final newPoint = DrawingPoint(
          details.localPosition,
          Paint()
            ..color = Colors.black
            ..isAntiAlias = true
            ..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round,
        );
        
        setState(() {
          _localPoints.add(newPoint);
        });
        
        // Notify parent
        widget.onPointsUpdate(_localPoints);
      },
      onPanEnd: (details) {
        // Add null to mark end of stroke
        setState(() {
          _localPoints.add(null);
        });
        
        // Notify parent
        widget.onPointsUpdate(_localPoints);
      },
      child: CustomPaint(
        painter: DrawingPainter(points: _localPoints),
        size: Size.infinite,
      ),
    );
  }
}

// Simple class to represent a drawing point with its style
class DrawingPoint {
  final Offset offset;
  final Paint paint;
  
  DrawingPoint(this.offset, this.paint);
}

// Painter for drawing lines
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  
  DrawingPainter({required this.points});
  
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        // Draw line between points
        canvas.drawLine(
          points[i]!.offset,
          points[i + 1]!.offset,
          points[i]!.paint,
        );
      } else if (points[i] != null && (i == points.length - 1 || points[i + 1] == null)) {
        // Draw a single point if it's at the end of a stroke
        canvas.drawCircle(points[i]!.offset, 0.5, points[i]!.paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

// Simple grid painter for paper-like background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.05)
      ..strokeWidth = 0.5;
    
    // Draw horizontal lines
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    
    // Draw vertical lines
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}