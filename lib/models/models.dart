import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ProjectMetadata {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime lastModified;
  final String? thumbnailPath;

  ProjectMetadata({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastModified,
    this.thumbnailPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
        'thumbnailPath': thumbnailPath,
      };

  factory ProjectMetadata.fromJson(Map<String, dynamic> json) => ProjectMetadata(
        id: json['id'],
        name: json['name'],
        createdAt: DateTime.parse(json['createdAt']),
        lastModified: DateTime.parse(json['lastModified']),
        thumbnailPath: json['thumbnailPath'],
      );
}

class DrawnPath {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;
  final String tool;

  DrawnPath({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
    this.tool = 'pen',
  });

      'color': color.value,
      'strokeWidth': strokeWidth,
      'isEraser': isEraser,
      'tool': tool,
    };
  }

  factory DrawnPath.fromJson(Map<String, dynamic> json) {
    return DrawnPath(
      points: (json['points'] as List).map((p) => p != null ? Offset(p['x'], p['y']) : null).toList(),
      color: Color(json['color']),
      strokeWidth: json['strokeWidth']?.toDouble() ?? 5.0,
      isEraser: json['isEraser'] ?? false,
      tool: json['tool'] ?? 'pen',
    );
  }
}

class AnimationLayer {
  final String id;
  String name;
  final List<DrawnPath> paths;
  bool isVisible;
  double opacity;
  Uint8List? sketchData; // Line-art bitmap data
  ui.Image? decodedImage; // Transient decoded image for rendering

  AnimationLayer({
    String? id,
    required this.name,
    List<DrawnPath>? paths,
    this.isVisible = true,
    this.opacity = 1.0,
    this.sketchData,
    this.decodedImage,
  })  : id = id ?? const Uuid().v4(),
        paths = paths ?? [];

  AnimationLayer copyWith({
    String? name,
    bool? isVisible,
    double? opacity,
    List<DrawnPath>? paths,
    Uint8List? sketchData,
    ui.Image? decodedImage,
  }) {
    return AnimationLayer(
      id: id,
      name: name ?? this.name,
      isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
      paths: paths ?? List.from(this.paths),
      sketchData: sketchData ?? this.sketchData,
      decodedImage: decodedImage ?? this.decodedImage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isVisible': isVisible,
      'opacity': opacity,
      'paths': paths.map((p) => p.toJson()).toList(),
    };
  }

  factory AnimationLayer.fromJson(Map<String, dynamic> json) {
    return AnimationLayer(
      id: json['id'],
      name: json['name'],
      isVisible: json['isVisible'] ?? true,
      opacity: (json['opacity'] ?? 1.0).toDouble(),
      paths: (json['paths'] as List).map((p) => DrawnPath.fromJson(p)).toList(),
    );
  }
}

class AnimationFrame {
  final String id;
  final List<AnimationLayer> layers;

  AnimationFrame({
    String? id,
    List<AnimationLayer>? layers,
  })  : id = id ?? const Uuid().v4(),
        layers = layers ?? [AnimationLayer(name: 'Layer 1')];

  AnimationFrame copyWith({List<AnimationLayer>? layers}) {
    return AnimationFrame(
      id: id,
      layers: layers ?? List.from(this.layers),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'layers': layers.map((l) => l.toJson()).toList(),
      };

  factory AnimationFrame.fromJson(Map<String, dynamic> json) {
    return AnimationFrame(
      id: json['id'],
      layers: (json['layers'] as List).map((l) => AnimationLayer.fromJson(l)).toList(),
    );
  }
}

class AnimationProject {
  final String id;
  String name;
  List<AnimationFrame> frames;
  int currentFrameIndex;
  double fps;
  double exportWidth;
  double exportHeight;

  AnimationProject({
    String? id,
    required this.name,
    List<AnimationFrame>? frames,
    this.currentFrameIndex = 0,
    this.fps = 12.0,
    this.exportWidth = 1080,
    this.exportHeight = 1080,
  })  : id = id ?? const Uuid().v4(),
        frames = frames ?? [AnimationFrame()];

  AnimationFrame get currentFrame => frames[currentFrameIndex];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'frames': frames.map((f) => f.toJson()).toList(),
        'currentFrameIndex': currentFrameIndex,
        'fps': fps,
        'exportWidth': exportWidth,
        'exportHeight': exportHeight,
      };

  factory AnimationProject.fromJson(Map<String, dynamic> json) {
    return AnimationProject(
      id: json['id'],
      name: json['name'],
      frames: (json['frames'] as List).map((f) => AnimationFrame.fromJson(f)).toList(),
      currentFrameIndex: json['currentFrameIndex'] ?? 0,
      fps: (json['fps'] ?? 12.0).toDouble(),
      exportWidth: (json['exportWidth'] ?? 1080).toDouble(),
      exportHeight: (json['exportHeight'] ?? 1080).toDouble(),
    );
  }
}
