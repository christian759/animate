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
                icon: Icons.edit,
                isSelected: provider.currentTool == DrawingTool.brush,
                onTap: () => provider.setTool(DrawingTool.brush),
              ),
              _ToolButton(
                icon: Icons.auto_fix_normal,
                isSelected: provider.currentTool == DrawingTool.eraser,
                onTap: () => provider.setTool(DrawingTool.eraser),
              ),
              const Divider(color: Colors.white10),
              _ColorButton(
                color: provider.currentColor,
                onTap: () => _showColorPicker(context, provider),
              ),
              const SizedBox(height: 12),
              _ToolButton(
                icon: Icons.undo,
                isSelected: false,
                onTap: provider.undo,
              ),
              _ToolButton(
                icon: Icons.redo,
                isSelected: false,
                onTap: provider.redo,
              ),
              const Spacer(),
              _ToolButton(
                icon: Icons.layers,
                isSelected: false,
                onTap: () {
                    // Logic for layer selection will be in a separate panel
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
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: provider.currentColor,
            onColorChanged: provider.setColor,
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
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: IconButton(
        icon: Icon(icon),
        color: isSelected ? theme.colorScheme.primary : Colors.white70,
        iconSize: 28,
        onPressed: onTap,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}
