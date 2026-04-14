import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/models.dart';
import '../services/export_service.dart';
import '../services/media_import_service.dart';
import '../services/project_repository.dart';
import '../services/ad_service.dart';

enum DrawingTool { pen, pencil, brush, eraser, text }

class ProjectProvider extends ChangeNotifier {
  AnimationProject _project = AnimationProject(name: 'New Animation');
  final MediaImportService _importService = MediaImportService();
  final ProjectRepository _repository = ProjectRepository();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Tool state
  DrawingTool _currentTool = DrawingTool.pen;
  Color _currentColor = Colors.white;
  double _strokeWidth = 5.0;
  int _currentLayerIndex = 0;
  
  // Drawing state
  List<Offset?> _activePoints = [];
  final ValueNotifier<List<Offset?>> activePointsNotifier = ValueNotifier([]);
  
  // Playback state (High Performance Ticker-like)
  bool _isPlaying = false;
  Timer? _playbackTimer;
  int _lastPlaybackTick = 0;

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

  // --- Project Settings ---

  void setFps(double fps) {
    _project.fps = fps;
    saveCurrentProject();
    notifyListeners();
  }

  void setExportResolution(double width, double height) {
    _project.exportWidth = width;
    _project.exportHeight = height;
    saveCurrentProject();
    notifyListeners();
  }

  // --- Audio ---

  Future<void> pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null) {
      _project.audioPath = result.files.single.path;
      saveCurrentProject();
      notifyListeners();
    }
  }

  void removeAudio() {
    _project.audioPath = null;
    saveCurrentProject();
    notifyListeners();
  }

  // --- Effects ---

  void setLayerEffect(EffectType effect) {
    _saveToUndo();
    currentLayer.effect = effect;
    currentLayer.clearCache(); // Invalidate Cache
    saveCurrentProject();
    notifyListeners();
  }

  // --- Text ---

  void addText(String content, Offset pos) {
    _saveToUndo();
    final newText = TextElement(text: content, position: pos, color: _currentColor);
    currentLayer.texts.add(newText);
    currentLayer.clearCache(); // Invalidate Cache
    saveCurrentProject();
    notifyListeners();
  }

  void updateText(String id, {String? text, Offset? pos, double? fontSize, Color? color, double? rotation}) {
    _saveToUndo();
    final index = currentLayer.texts.indexWhere((t) => t.id == id);
    if (index != -1) {
      currentLayer.texts[index] = currentLayer.texts[index].copyWith(
        text: text,
        position: pos,
        fontSize: fontSize,
        color: color,
        rotation: rotation,
      );
      currentLayer.clearCache(); // Invalidate Cache
      saveCurrentProject();
      notifyListeners();
    }
  }

  void removeText(String id) {
    _saveToUndo();
    currentLayer.texts.removeWhere((t) => t.id == id);
    currentLayer.clearCache(); // Invalidate Cache
    saveCurrentProject();
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
    if (_currentTool == DrawingTool.text) {
      return;
    }
    _saveToUndo();
    _activePoints = [point];
    activePointsNotifier.value = List.from(_activePoints);
  }

  void updateDrawing(Offset point) {
    if (_currentTool == DrawingTool.text) return;
    _activePoints.add(point);
    activePointsNotifier.value = List.from(_activePoints);
  }

  void endDrawing() {
    if (_currentTool == DrawingTool.text) return;
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
      
      currentLayers[_currentLayerIndex].clearCache(); // Invalidate Cache

      final currentFrames = List<AnimationFrame>.from(_project.frames);
      currentFrames[currentFrameIndex] = currentFrame.copyWith(layers: currentLayers);
      
      _project.frames = currentFrames;
      saveCurrentProject();
    }
    _activePoints = [];
    activePointsNotifier.value = [];
    notifyListeners();
  }

  // --- Timeline Control ---

  void setCurrentFrame(int index) {
    if (index >= 0 && index < _project.frames.length) {
      _project.currentFrameIndex = index;
      notifyListeners();
    }
  }

  void addFrame() {
    _saveToUndo();
    final newFrame = AnimationFrame(
      layers: currentFrame.layers.map((l) => l.copyWith(paths: [], texts: [])).toList()
    );
    _project.frames.insert(currentFrameIndex + 1, newFrame);
    _project.currentFrameIndex++;
    saveCurrentProject();
    notifyListeners();
  }

  void duplicateFrame() {
    _saveToUndo();
    final duplicatedFrame = currentFrame.copyWith();
    _project.frames.insert(currentFrameIndex + 1, duplicatedFrame);
    _project.currentFrameIndex++;
    saveCurrentProject();
    notifyListeners();
  }

  void removeFrame() {
    if (_project.frames.length <= 1) return;
    _saveToUndo();
    _project.frames.removeAt(currentFrameIndex);
    if (currentFrameIndex >= _project.frames.length) {
      _project.currentFrameIndex = _project.frames.length - 1;
    }
    saveCurrentProject();
    notifyListeners();
  }

  // --- Playback ---

  void togglePlayback() {
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      _startPlayback();
    } else {
      _stopPlayback();
    }
    notifyListeners();
  }

  void _startPlayback() async {
    if (_project.audioPath != null) {
      await _audioPlayer.play(DeviceFileSource(_project.audioPath!));
      final frameTimeMs = (currentFrameIndex * (1000 / _project.fps)).round();
      await _audioPlayer.seek(Duration(milliseconds: frameTimeMs));
    }

    _playbackTimer?.cancel();
    _lastPlaybackTick = DateTime.now().millisecondsSinceEpoch;
    
    // Performance: Using SchedulerBinding for frame-perfect updates if possible, 
    // or a high-frequency timer to catch frame boundaries
    _playbackTimer = Timer.periodic(
      const Duration(milliseconds: 16), // 60fps check
      (timer) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsed = now - _lastPlaybackTick;
        final frameDuration = 1000 / _project.fps;
        
        if (elapsed >= frameDuration) {
          _lastPlaybackTick = now;
          int nextFrame = (_project.currentFrameIndex + 1) % _project.frames.length;
          _project.currentFrameIndex = nextFrame;
          
          if (nextFrame == 0 && _project.audioPath != null) {
            _audioPlayer.seek(Duration.zero);
          }
          notifyListeners();
        }
      },
    );
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _audioPlayer.pause();
  }

  // --- Export ---

  Future<String?> export(ExportFormat format, {Size? customResolution}) async {
    _isExporting = true;
    _exportProgress = 0.0;
    notifyListeners();

    try {
      final result = await ExportService.exportProject(
        project: _project,
        format: format,
        resolution: customResolution ?? Size(_project.exportWidth, _project.exportHeight),
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
      
      // Invalidate all layer caches on undo
      for (var frame in _project.frames) {
        for (var layer in frame.layers) {
           layer.clearCache();
        }
      }

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
      
      // Invalidate all layer caches on redo
      for (var frame in _project.frames) {
        for (var layer in frame.layers) {
           layer.clearCache();
        }
      }

      saveCurrentProject();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _audioPlayer.dispose();
    activePointsNotifier.dispose();
    super.dispose();
  }
}
