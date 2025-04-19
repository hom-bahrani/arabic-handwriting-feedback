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
  // Points and strokes for drawing
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  
  // Transform variables for zoom and pan
  double _scale = 0.8; // Default smaller scale for more detailed writing
  Offset _offset = Offset.zero;
  
  // Direction flag (true for RTL, which is appropriate for Arabic)
  bool _isRightToLeft = true;
  
  // Controller to detect when to reset
  bool _isDrawing = false;
  
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
  
  // Method to clear all strokes
  void clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }
  
  // Method to reset the canvas settings
  void _resetCanvas() {
    setState(() {
      _scale = 0.8; // Better default for Arabic writing
      _offset = Offset.zero;
    });
  }
  
  // Method to get adjusted position based on scale and offset
  Offset _getAdjustedPosition(Offset position) {
    final Offset center = Offset(
      context.size?.width ?? 300 / 2, 
      context.size?.height ?? 400 / 2
    );
    
    // Apply inverse transformations to get the correct position
    final dx = (position.dx - center.dx) / _scale + center.dx - _offset.dx;
    final dy = (position.dy - center.dy) / _scale + center.dy - _offset.dy;
    
    return Offset(dx, dy);
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
                  // Background with guide lines
                  Container(
                    color: Colors.white,
                    child: CustomPaint(
                      painter: _GuidelinesPainter(isRightToLeft: _isRightToLeft),
                      child: Container(),
                    ),
                  ),
                  
                  // Drawing layer with gestures
                  GestureDetector(
                    onPanStart: (details) {
                      // Start a new stroke
                      _isDrawing = true;
                      setState(() {
                        // Apply inverse scale to make strokes appear correctly
                        final Offset adjustedPosition = _getAdjustedPosition(details.localPosition);
                        _currentStroke = [adjustedPosition];
                      });
                    },
                    onPanUpdate: (details) {
                      // Add point to current stroke
                      if (_isDrawing) {
                        setState(() {
                          final Offset adjustedPosition = _getAdjustedPosition(details.localPosition);
                          _currentStroke.add(adjustedPosition);
                        });
                      }
                    },
                    onPanEnd: (details) {
                      // End the stroke
                      _isDrawing = false;
                      if (_currentStroke.isNotEmpty) {
                        setState(() {
                          _strokes.add(List.from(_currentStroke));
                          _currentStroke = [];
                        });
                      }
                    },
                    child: CustomPaint(
                      painter: _DrawingPainter(
                        strokes: _strokes,
                        currentStroke: _currentStroke,
                        scale: _scale,
                        offset: _offset,
                      ),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  
                  // Placeholder text or feedback display
                  Consumer<HandwritingProvider>(
                    builder: (context, provider, child) {
                      if (_strokes.isEmpty && provider.state == ProcessingState.idle) {
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
                  
                  // Zoom control buttons
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      children: [
                        Row(
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
                              onPressed: _resetCanvas,
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
                        const SizedBox(height: 8),
                        _buildControlButton(
                          icon: _isRightToLeft ? Icons.format_textdirection_r_to_l : Icons.format_textdirection_l_to_r,
                          onPressed: () {
                            setState(() {
                              _isRightToLeft = !_isRightToLeft;
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

// Painter for the horizontal guidelines
class _GuidelinesPainter extends CustomPainter {
  final bool isRightToLeft;
  
  _GuidelinesPainter({this.isRightToLeft = true});
  
  @override
  void paint(Canvas canvas, Size size) {
    final horizontalPaint = Paint()
      ..color = const Color(0xFF5F67EA).withOpacity(0.1)
      ..strokeWidth = 1;
      
    final verticalPaint = Paint()
      ..color = const Color(0xFF5F67EA).withOpacity(0.07)
      ..strokeWidth = 1;
    
    // Draw horizontal lines at regular intervals
    const lineSpacing = 40.0;
    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        horizontalPaint,
      );
    }
    
    // Draw a light vertical guide on the right side for RTL writing
    if (isRightToLeft) {
      canvas.drawLine(
        Offset(size.width - 40, 0),
        Offset(size.width - 40, size.height),
        verticalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter for drawing the actual strokes
class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final double scale;
  final Offset offset;

  _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    this.scale = 1.0,
    this.offset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Save the canvas state
    canvas.save();
    
    // Apply transformations - scale from center and apply offset
    final Offset center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx + offset.dx, -center.dy + offset.dy);

    // Thinner stroke width better suited for Arabic script
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.8 / scale // Adjust stroke width based on scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      
      final path = Path();
      path.moveTo(stroke[0].dx, stroke[0].dy);
      
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      
      canvas.drawPath(path, paint);
    }
    
    // Draw current (in-progress) stroke
    if (currentStroke.length >= 2) {
      final path = Path();
      path.moveTo(currentStroke[0].dx, currentStroke[0].dy);
      
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      
      canvas.drawPath(path, paint);
    } else if (currentStroke.length == 1) {
      // Draw a dot if it's just a tap
      canvas.drawCircle(currentStroke[0], 1.5 / scale, paint);
    }
    
    // Restore the canvas state
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return true;
  }
}