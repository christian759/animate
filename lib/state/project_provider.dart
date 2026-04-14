import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/export_service.dart';
import '../services/media_import_service.dart';
import '../services/project_repository.dart';

enum DrawingTool { pen, pencil, brush, eraser }

class ProjectProvider extends ChangeNotifier {
  AnimationProject _project = AnimationProject(name: 'New Animation');
  final MediaImportService _importService = MediaImportService();
  final ProjectRepository _repository = ProjectRepository();
  
  // Tool state
  DrawingTool _currentTool = DrawingTool.brush;
  Color _currentColor = Colors.white;
  double _strokeWidth = 5.0;
  int _currentLayerIndex = 0;
  
  // Drawing state (separated for performance)
  List<Offset?> _activePoints = [];
  final ValueNotifier<List<Offset?>> activePointsNotifier = ValueNotifier([]);
  
  // Playback state
  bool _isPlaying = false;
  Timer? _playbackTimer;

  // Processing state
  bool _isProcessing = false;
  double _processingProgress = 0.0;

  // Export state
  bool _isExporting = false;
  double _exportProgress = 0.0;

  // Undo/Redo
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
  bool get isProcessing => _isProcessing;
  double get processingProgress => _processingProgress;
  bool get isExporting => _isExporting;
  double get exportProgress => _exportProgress;
  
  int get currentFrameIndex => _project.currentFrameIndex;
  AnimationFrame get currentFrame => _project.currentFrame;
  AnimationLayer get currentLayer => currentFrame.layers[_currentLayerIndex];

  // --- Project Management ---

  Future<void> loadProject(String id) async {
    _isProcessing = true;
    notifyListeners();
    try {
      final loaded = await _repository.loadProject(id);
      if (loaded != null) {
        _project = loaded;
        _currentLayerIndex = 0;
        _undoStack.clear();
        _redoStack.clear();
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> newProject(String name) async {
    _project = AnimationProject(name: name);
    _currentLayerIndex = 0;
    _undoStack.clear();
    _redoStack.clear();
    await saveCurrentProject();
    notifyListeners();
  }

  Future<void> saveCurrentProject({String? thumbnailPath}) async {
    await _repository.saveProject(_project, thumbnailPath: thumbnailPath);
  }

  Future<List<ProjectMetadata>> getRecentProjects() async {
    return _repository.listProjects();
  }
  
  Future<void> deleteProject(String id) async {
    await _repository.deleteProject(id);
    notifyListeners();
  }

  // --- Tool Setters ---

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

  // --- Draw operations ---

  void startDrawing(Offset point) {
    _saveToUndo();
    _activePoints = [point];
    activePointsNotifier.value = List.from(_activePoints);
  }

  void updateDrawing(Offset point) {
    _activePoints.add(point);
    activePointsNotifier.value = List.from(_activePoints);
    // Note: We don't call notifyListeners() here to avoid full app rebuild.
    // Instead, DrawingCanvas should listen to activePointsNotifier.
  }

  void endDrawing() {
    if (_activePoints.isNotEmpty) {
      final newPath = DrawnPath(
        points: List.from(_activePoints),
        color: _currentTool == DrawingTool.eraser ? Colors.transparent : _currentColor,
        strokeWidth: _strokeWidth,
        isEraser: _currentTool == DrawingTool.eraser,
        tool: _currentTool.name,
      );
      
      final currentLayers = List<AnimationLayer>.from(currentFrame.layers);
      final targetLayer = currentLayers[_currentLayerIndex];
      
      currentLayers[_currentLayerIndex] = targetLayer.copyWith(
        paths: [...targetLayer.paths, newPath],
      );
      
      final currentFrames = List<AnimationFrame>.from(_project.frames);
      currentFrames[currentFrameIndex] = currentFrame.copyWith(layers: currentLayers);
      
      _project.frames = currentFrames;
      
      // Auto-save on end drawing (debounced in real app, but here simple)
      saveCurrentProject();
    }
    _activePoints = [];
    activePointsNotifier.value = [];
    notifyListeners();
  }

  // --- Media Imports ---

  Future<void> importImageAsSketch() async {
    _isProcessing = true;
    _processingProgress = 0.0;
    notifyListeners();

    try {
      final sketchData = await _importService.pickAndSketchImage();
      if (sketchData != null) {
        final decoded = await _decodeImage(sketchData);
        _saveToUndo();
        
        final updatedLayers = List<AnimationLayer>.from(currentFrame.layers);
        updatedLayers.add(AnimationLayer(
          name: 'Sketch Layer',
          sketchData: sketchData,
          decodedImage: decoded,
        ));
        
        final updatedFrames = List<AnimationFrame>.from(_project.frames);
        updatedFrames[currentFrameIndex] = currentFrame.copyWith(layers: updatedLayers);
        
        _project.frames = updatedFrames;
        _currentLayerIndex = updatedLayers.length - 1;
        saveCurrentProject();
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> importVideoAsAnimation() async {
    _isProcessing = true;
    _processingProgress = 0.0;
    notifyListeners();

    try {
      final sketchesData = await _importService.pickAndSketchVideo(
        targetFps: 12.0,
        onProgress: (p) {
          _processingProgress = p;
          notifyListeners();
        },
      );

      if (sketchesData != null && sketchesData.isNotEmpty) {
        _saveToUndo();
        final List<AnimationFrame> newFrames = [];
        for (var sketchData in sketchesData) {
          final decoded = await _decodeImage(sketchData);
          newFrames.add(AnimationFrame(
            layers: [
              AnimationLayer(name: 'Background Sketch', sketchData: sketchData, decodedImage: decoded),
              AnimationLayer(name: 'Drawing Layer'),
            ],
          ));
        }

        _project.frames = newFrames;
        _project.currentFrameIndex = 0;
        _currentLayerIndex = 1;
        saveCurrentProject();
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<ui.Image> _decodeImage(Uint8List data) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(data, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  // --- Frame operations ---

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
    saveCurrentProject();
    notifyListeners();
  }

  void duplicateFrame() {
    _saveToUndo();
    final currentF = currentFrame;
    final duplicatedLayers = currentF.layers.map((l) => l.copyWith()).toList();
    final newFrame = AnimationFrame(layers: duplicatedLayers);
    
    _project.frames.insert(currentFrameIndex + 1, newFrame);
    _project.currentFrameIndex++;
    saveCurrentProject();
    notifyListeners();
  }

  void removeFrame() {
    if (_project.frames.length > 1) {
      _saveToUndo();
      _project.frames.removeAt(currentFrameIndex);
      if (currentFrameIndex >= _project.frames.length) {
        _project.currentFrameIndex = _project.frames.length - 1;
      }
      saveCurrentProject();
      notifyListeners();
    }
  }

  // --- Layer operations ---

  void setLayer(int index) {
    if (index >= 0 && index < currentFrame.layers.length) {
      _currentLayerIndex = index;
      notifyListeners();
    }
  }

  void addLayer() {
    _saveToUndo();
    final updatedFrames = List<AnimationFrame>.from(_project.frames);
    for (var i = 0; i < updatedFrames.length; i++) {
        updatedFrames[i] = updatedFrames[i].copyWith(
            layers: [...updatedFrames[i].layers, AnimationLayer(name: 'Layer ${updatedFrames[i].layers.length + 1}')]
        );
    }
    _project.frames = updatedFrames;
    _currentLayerIndex = currentFrame.layers.length - 1;
    saveCurrentProject();
    notifyListeners();
  }

  // --- Playback ---

  void togglePlayback() {
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      _playbackTimer?.cancel();
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

  // --- Undo/Redo ---

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
      saveCurrentProject();
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(List.from(_project.frames.map((f) => f.copyWith())));
      _project.frames = _redoStack.removeLast();
      saveCurrentProject();
      notifyListeners();
    }
  }

  // --- Export ---

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
    activePointsNotifier.dispose();
    super.dispose();
  }
}
