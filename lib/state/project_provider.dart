import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/export_service.dart';

enum DrawingTool { brush, eraser }

class ProjectProvider extends ChangeNotifier {
  AnimationProject _project = AnimationProject(name: 'New Animation');
  
  // Tool state
  DrawingTool _currentTool = DrawingTool.brush;
  Color _currentColor = Colors.white;
  double _strokeWidth = 5.0;
  int _currentLayerIndex = 0;
  
  // Drawing state
  List<Offset?> _activePoints = [];
  
  // Playback state
  bool _isPlaying = false;
  Timer? _playbackTimer;

  // Export state
  bool _isExporting = false;
  double _exportProgress = 0.0;

  // Undo/Redo - For MVP, we'll store frame snapshots
  final List<List<AnimationFrame>> _undoStack = [];
  final List<List<AnimationFrame>> _redoStack = [];

  // Getters
  AnimationProject get project => _project;
  DrawingTool get currentTool => _currentTool;
  Color get currentColor => _currentColor;
  double get strokeWidth => _strokeWidth;
  int get currentLayerIndex => _currentLayerIndex;
  List<Offset?> get activePoints => _activePoints;
  bool get isPlaying => _isPlaying;
  bool get isExporting => _isExporting;
  double get exportProgress => _exportProgress;
  
  int get currentFrameIndex => _project.currentFrameIndex;
  AnimationFrame get currentFrame => _project.currentFrame;
  AnimationLayer get currentLayer => currentFrame.layers[_currentLayerIndex];

  // Tool Setters
  void setTool(DrawingTool tool) {
    _currentTool = tool;
    notifyListeners();
  }

  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  // Draw operations
  void startDrawing(Offset point) {
    _saveToUndo();
    _activePoints = [point];
    notifyListeners();
  }

  void updateDrawing(Offset point) {
    _activePoints.add(point);
    notifyListeners();
  }

  void endDrawing() {
    if (_activePoints.isNotEmpty) {
      final newPath = DrawnPath(
        points: List.from(_activePoints),
        color: _currentTool == DrawingTool.eraser ? Colors.transparent : _currentColor,
        strokeWidth: _strokeWidth,
        isEraser: _currentTool == DrawingTool.eraser,
      );
      
      final currentLayers = List<AnimationLayer>.from(currentFrame.layers);
      final targetLayer = currentLayers[_currentLayerIndex];
      
      currentLayers[_currentLayerIndex] = targetLayer.copyWith(
        paths: [...targetLayer.paths, newPath],
      );
      
      final currentFrames = List<AnimationFrame>.from(_project.frames);
      currentFrames[currentFrameIndex] = currentFrame.copyWith(layers: currentLayers);
      
      _project.frames = currentFrames;
    }
    _activePoints = [];
    notifyListeners();
  }

  // Frame operations
  void setCurrentFrame(int index) {
    if (index >= 0 && index < _project.frames.length) {
      _project.currentFrameIndex = index;
      notifyListeners();
    }
  }

  void addFrame() {
    _saveToUndo();
    final newFrame = AnimationFrame(
      layers: [AnimationLayer(name: 'Layer 1')]
    );
    _project.frames.insert(currentFrameIndex + 1, newFrame);
    _project.currentFrameIndex++;
    notifyListeners();
  }

  void duplicateFrame() {
    _saveToUndo();
    final currentF = currentFrame;
    final duplicatedLayers = currentF.layers.map((l) => l.copyWith()).toList();
    final newFrame = AnimationFrame(layers: duplicatedLayers);
    
    _project.frames.insert(currentFrameIndex + 1, newFrame);
    _project.currentFrameIndex++;
    notifyListeners();
  }

  void removeFrame() {
    if (_project.frames.length > 1) {
      _saveToUndo();
      _project.frames.removeAt(currentFrameIndex);
      if (currentFrameIndex >= _project.frames.length) {
        _project.currentFrameIndex = _project.frames.length - 1;
      }
      notifyListeners();
    }
  }

  // Layer operations
  void setLayer(int index) {
    if (index >= 0 && index < currentFrame.layers.length) {
      _currentLayerIndex = index;
      notifyListeners();
    }
  }

  void addLayer() {
    _saveToUndo();
    final updatedFrames = List<AnimationFrame>.from(_project.frames);
    
    // Add layer to ALL frames for consistency? Or just current? 
    // Usually animation apps add layer to the whole project.
    for (var i = 0; i < updatedFrames.length; i++) {
        updatedFrames[i] = updatedFrames[i].copyWith(
            layers: [...updatedFrames[i].layers, AnimationLayer(name: 'Layer ${updatedFrames[i].layers.length + 1}')]
        );
    }
    _project.frames = updatedFrames;
    _currentLayerIndex = currentFrame.layers.length - 1;
    notifyListeners();
  }

  // Playback
  void togglePlayback() {
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      _playbackTimer = Timer.periodic(
        Duration(milliseconds: (1000 / _project.fps).round()),
        (timer) {
          int nextFrame = (_project.currentFrameIndex + 1) % _project.frames.length;
          _project.currentFrameIndex = nextFrame;
          notifyListeners();
        },
      );
    } else {
      _playbackTimer?.cancel();
    }
    notifyListeners();
  }

  // Undo/Redo
  void _saveToUndo() {
    _undoStack.add(List.from(_project.frames.map((f) => f.copyWith())));
    _redoStack.clear();
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(List.from(_project.frames.map((f) => f.copyWith())));
      _project.frames = _undoStack.removeLast();
      if (_project.currentFrameIndex >= _project.frames.length) {
        _project.currentFrameIndex = _project.frames.length - 1;
      }
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(List.from(_project.frames.map((f) => f.copyWith())));
      _project.frames = _redoStack.removeLast();
      notifyListeners();
    }
  }

  // Export
  Future<String?> export(ExportFormat format) async {
    _isExporting = true;
    _exportProgress = 0.0;
    notifyListeners();

    try {
      final result = await ExportService.exportProject(
        project: _project,
        format: format,
        onProgress: (progress) {
          _exportProgress = progress;
          notifyListeners();
        },
      );
      return result;
    } finally {
      _isExporting = false;
      _exportProgress = 0.0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}
