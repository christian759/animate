import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../state/project_provider.dart';

class AnimToolbar extends StatelessWidget {
  const AnimToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        return Container(
          width: 70,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
               _ToolButton(
                icon: Icons.edit_rounded,
                tooltip: 'Pen',
                isSelected: provider.currentTool == DrawingTool.pen,
                onTap: () => provider.setTool(DrawingTool.pen),
              ),
              _ToolButton(
                icon: Icons.create_rounded,
                tooltip: 'Pencil',
                isSelected: provider.currentTool == DrawingTool.pencil,
                onTap: () => provider.setTool(DrawingTool.pencil),
              ),
              _ToolButton(
                icon: Icons.brush_rounded,
                tooltip: 'Paint Brush',
                isSelected: provider.currentTool == DrawingTool.brush,
                onTap: () => provider.setTool(DrawingTool.brush),
              ),
              _ToolButton(
                icon: Icons.auto_fix_normal_rounded,
                tooltip: 'Eraser',
                isSelected: provider.currentTool == DrawingTool.eraser,
                onTap: () => provider.setTool(DrawingTool.eraser),
              ),
              const Divider(color: Colors.white10, indent: 15, endIndent: 15),
              _ColorButton(
                color: provider.currentColor,
                onTap: () => _showColorPicker(context, provider),
              ),
              const SizedBox(height: 12),
              _ToolButton(
                icon: Icons.undo_rounded,
                tooltip: 'Undo',
                isSelected: false,
                onTap: provider.undo,
              ),
              _ToolButton(
                icon: Icons.redo_rounded,
                tooltip: 'Redo',
                isSelected: false,
                onTap: provider.redo,
              ),
              const Spacer(),
              _ToolButton(
                icon: Icons.layers_rounded,
                tooltip: 'Layers',
                isSelected: false,
                onTap: () {
                    // Layer panel toggle logic could go here
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showColorPicker(BuildContext context, ProjectProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2A),
        title: const Text('Pick a Color', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: provider.currentColor,
            onColorChanged: provider.setColor,
            pickerAreaHeightPercent: 0.7,
            enableAlpha: false,
            displayThumbColor: true,
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Done'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon),
          color: isSelected ? theme.colorScheme.primary : Colors.white70,
          iconSize: 26,
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
