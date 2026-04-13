import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_provider.dart';
import '../canvas_painter.dart';

class DrawingCanvas extends StatelessWidget {
  const DrawingCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onPanStart: (details) {
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final offset = renderBox.globalToLocal(details.globalPosition);
                provider.startDrawing(offset);
              },
              onPanUpdate: (details) {
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final offset = renderBox.globalToLocal(details.globalPosition);
                provider.updateDrawing(offset);
              },
              onPanEnd: (_) => provider.endDrawing(),
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: CanvasPainter(
                    currentFrame: provider.currentFrame,
                    previousFrame: provider.currentFrameIndex > 0 
                        ? provider.project.frames[provider.currentFrameIndex - 1]
                        : null,
                    activePoints: provider.activePoints,
                    currentColor: provider.currentColor,
                    strokeWidth: provider.strokeWidth,
                    showOnionSkin: !provider.isPlaying,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
