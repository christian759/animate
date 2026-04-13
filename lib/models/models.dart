import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class DrawnPath {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  DrawnPath({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => p != null ? {'x': p.dx, 'y': p.dy} : null).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'isEraser': isEraser,
    };
  }
}

class AnimationLayer {
  final String id;
  String name;
  final List<DrawnPath> paths;
  bool isVisible;
  double opacity;

  AnimationLayer({
    String? id,
    required this.name,
    List<DrawnPath>? paths,
    this.isVisible = true,
    this.opacity = 1.0,
  })  : id = id ?? const Uuid().v4(),
        paths = paths ?? [];

  AnimationLayer copyWith({
    String? name,
    bool? isVisible,
    double? opacity,
    List<DrawnPath>? paths,
  }) {
    return AnimationLayer(
      id: id,
      name: name ?? this.name,
      isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
      paths: paths ?? List.from(this.paths),
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
}

class AnimationProject {
  String name;
  List<AnimationFrame> frames;
  int currentFrameIndex;
  double fps;

  AnimationProject({
    required this.name,
    List<AnimationFrame>? frames,
    this.currentFrameIndex = 0,
    this.fps = 12.0,
  }) : frames = frames ?? [AnimationFrame()];

  AnimationFrame get currentFrame => frames[currentFrameIndex];
}
