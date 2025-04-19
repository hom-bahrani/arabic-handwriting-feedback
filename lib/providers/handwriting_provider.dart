import 'package:flutter/material.dart';

enum ProcessingState {
  idle,
  processing,
  previewText,
  showingCorrection,
}

class HandwritingProvider extends ChangeNotifier {
  ProcessingState _state = ProcessingState.idle;
  String _recognizedText = '';
  String _correctedText = '';
  List<String> _corrections = [];
  
  ProcessingState get state => _state;
  String get recognizedText => _recognizedText;
  String get correctedText => _correctedText;
  List<String> get corrections => _corrections;
  
  // Method to simulate OCR processing
  Future<void> processHandwriting() async {
    _state = ProcessingState.processing;
    notifyListeners();
    
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // For the prototype, we'll use a hardcoded value
    _recognizedText = "مرحبا بالعالم";
    _state = ProcessingState.previewText;
    notifyListeners();
    
    // Simulate grammar checking delay
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // For the prototype, we'll use hardcoded corrections
    _correctedText = "مرحباً بالعالم";
    _corrections = [
      "Missing tanween (double vowel mark) on 'مرحبا'. It should be 'مرحباً' to indicate the adverbial form.",
      "Word spacing is correct but consider practicing letter connecting in 'بالعالم'."
    ];
    _state = ProcessingState.showingCorrection;
    notifyListeners();
  }
  
  // Method to clear the canvas and reset the state
  void clearCanvas() {
    _state = ProcessingState.idle;
    _recognizedText = '';
    _correctedText = '';
    _corrections = [];
    notifyListeners();
  }
}