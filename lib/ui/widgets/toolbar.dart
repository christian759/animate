import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../state/project_provider.dart';
import '../../models/models.dart';

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
          child: SingleChildScrollView(
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
                  icon: Icons.title_rounded,
                  tooltip: 'Text',
                  isSelected: provider.currentTool == DrawingTool.text,
                  onTap: () {
                    provider.setTool(DrawingTool.text);
                    _showTextInput(context, provider);
                  },
                ),
                _ToolButton(
                  icon: Icons.auto_fix_normal_rounded,
                  tooltip: 'Eraser',
                  isSelected: provider.currentTool == DrawingTool.eraser,
                  onTap: () => provider.setTool(DrawingTool.eraser),
                ),
                const Divider(color: Colors.white10, indent: 15, endIndent: 15),
                _ToolButton(
                  icon: Icons.filter_vintage_rounded,
                  tooltip: 'Visual Effects',
                  isSelected: false,
                  onTap: () => _showEffectsPanel(context, provider),
                ),
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
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTextInput(BuildContext context, ProjectProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2A),
        title: const Text('Add Text', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Type something...',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                // Add text to center of screen roughly
                provider.addText(controller.text, const Offset(540, 540));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEffectsPanel(BuildContext context, ProjectProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Layer Effects', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: EffectType.values.map((effect) {
                final isSelected = provider.currentLayer.effect == effect;
                return ChoiceChip(
                  label: Text(effect.name.toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      provider.setLayerEffect(effect);
                      Navigator.pop(context);
                    }
                  },
                  backgroundColor: Colors.white10,
                  selectedColor: Colors.deepPurpleAccent,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 12),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
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
          onSizeConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
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
