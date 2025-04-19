import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../providers/handwriting_provider.dart';

class HandwritingCanvas extends StatefulWidget {
  const HandwritingCanvas({super.key});

  @override
  State<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends State<HandwritingCanvas> {
  // A list of points for the drawing
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  
  // Transform variables for zoom and pan
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  
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
  
  @override
  void dispose() {
    // If needed, clean up any resources
    super.dispose();
  }
  
  // Method to add a point to the current stroke
  void _addPoint(Offset point) {
    setState(() {
      _currentStroke.add(point);
    });
  }
  
  // Method to clear all strokes
  void clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
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
            // Canvas with zoom controls and guidelines
            Expanded(
              child: Stack(
                children: [
                  // Canvas for drawing
                  GestureDetector(
                    onScaleStart: (details) {
                      if (details.pointerCount == 1) {
                        _addPoint(details.localFocalPoint);
                      }
                    },
                    onScaleUpdate: (details) {
                      if (details.pointerCount == 1) {
                        _addPoint(details.localFocalPoint);
                      } else if (details.pointerCount == 2) {
                        setState(() {
                          _scale = details.scale;
                          _offset += details.focalPointDelta;
                        });
                      }
                    },
                    onScaleEnd: (details) {
                      if (_currentStroke.isNotEmpty) {
                        setState(() {
                          _strokes.add(List.from(_currentStroke));
                          _currentStroke = [];
                        });
                      }
                    },
                    child: Container(
                      color: Colors.white,
                      child: CustomPaint(
                        painter: _DrawingPainter(
                          strokes: _strokes,
                          currentStroke: _currentStroke,
                          scale: _scale,
                          offset: _offset,
                        ),
                        child: Container(),
                      ),
                    ),
                  ),
                  
                  // Placeholder text (for demo)
                  Consumer<HandwritingProvider>(
                    builder: (context, provider, child) {
                      if (provider.state == ProcessingState.idle) {
                        return Center(
                          child: Text(
                            'مرحبا بالعالم',
                            style: GoogleFonts.amiri(
                              fontSize: 40,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        );
                      } else if (provider.state == ProcessingState.processing) {
                        return const Center(
                          child: CircularProgressIndicator(),
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
                      } else {
                        return Center(
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
                            ],
                          ),
                        );
                      }
                    },
                  ),
                  
                  // Zoom control buttons
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        _buildControlButton(
                          icon: Icons.remove,
                          onPressed: () {
                            setState(() {
                              _scale = (_scale - 0.1).clamp(0.5, 2.0);
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildControlButton(
                          icon: Icons.refresh,
                          onPressed: () {
                            setState(() {
                              _scale = 1.0;
                              _offset = Offset.zero;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildControlButton(
                          icon: Icons.add,
                          onPressed: () {
                            setState(() {
                              _scale = (_scale + 0.1).clamp(0.5, 2.0);
                            });
                          },
                        ),
                      ],
                    ),
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
  
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE0E7FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF4F46E5)),
        onPressed: onPressed,
        iconSize: 20,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      ),
    );
  }
}

// Custom painter for rendering the strokes
class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final double scale;
  final Offset offset;

  _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw guidelines
    final guidelinePaint = Paint()
      ..color = const Color(0xFF5F67EA).withOpacity(0.1)
      ..strokeWidth = 1;
      
    const lineSpacing = 40.0;
    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        guidelinePaint,
      );
    }

    // Apply transformations for zoom and pan
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Draw existing strokes
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      
      final path = Path();
      path.moveTo(stroke[0].dx, stroke[0].dy);
      
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      
      canvas.drawPath(path, paint);
    }
    
    // Draw current stroke
    if (currentStroke.length >= 2) {
      final path = Path();
      path.moveTo(currentStroke[0].dx, currentStroke[0].dy);
      
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      
      canvas.drawPath(path, paint);
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return true;
  }
}