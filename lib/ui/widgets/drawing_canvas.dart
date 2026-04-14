import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_provider.dart';
import '../canvas_painter.dart';

class DrawingCanvas extends StatelessWidget {
  const DrawingCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    
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
          child: Stack(
            children: [
              // 1. Static Layers (Repaints ONLY when frame/layer changes)
              RepaintBoundary(
                child: Consumer<ProjectProvider>(
                  builder: (context, proj, _) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: CanvasPainter(
                        currentFrame: proj.currentFrame,
                        previousFrame: proj.currentFrameIndex > 0 
                            ? proj.project.frames[proj.currentFrameIndex - 1]
                            : null,
                        showOnionSkin: !proj.isPlaying,
                      ),
                    );
                  },
                ),
              ),

              // 2. Active Stroke (Repaints on EVERY move, but restricted to this layer)
              RepaintBoundary(
                child: ValueListenableBuilder<List<Offset?>>(
                  valueListenable: provider.activePointsNotifier,
                  builder: (context, points, _) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: CanvasPainter(
                        activePoints: points,
                        currentColor: provider.currentColor,
                        strokeWidth: provider.strokeWidth,
                        showOnionSkin: false,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
