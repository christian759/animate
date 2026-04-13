import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_provider.dart';
import '../../services/export_service.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.mp4;
  String? _exportedPath;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Export Animation', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!provider.isExporting && _exportedPath == null) ...[
                const Text('Choose format:', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                _FormatOption(
                  label: 'Video (MP4)',
                  icon: Icons.movie_outlined,
                  isSelected: _selectedFormat == ExportFormat.mp4,
                  onTap: () => setState(() => _selectedFormat = ExportFormat.mp4),
                ),
                const SizedBox(height: 12),
                _FormatOption(
                  label: 'Animated GIF',
                  icon: Icons.gif_box_outlined,
                  isSelected: _selectedFormat == ExportFormat.gif,
                  onTap: () => setState(() => _selectedFormat = ExportFormat.gif),
                ),
              ] else if (provider.isExporting) ...[
                const Text('Encoding...', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: provider.exportProgress,
                  backgroundColor: Colors.white10,
                  color: Colors.deepPurpleAccent,
                ),
                const SizedBox(height: 12),
                Text(
                  '${(provider.exportProgress * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ] else if (_exportedPath != null) ...[
                const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 48),
                const SizedBox(height: 16),
                const Text('Export Success!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _exportedPath!,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            if (!provider.isExporting)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_exportedPath != null ? 'Close' : 'Cancel', style: const TextStyle(color: Colors.white54)),
              ),
            if (!provider.isExporting && _exportedPath == null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white),
                onPressed: () async {
                  final path = await provider.export(_selectedFormat);
                  setState(() => _exportedPath = path);
                },
                child: const Text('Render & Export'),
              ),
          ],
        );
      },
    );
  }
}

class _FormatOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurpleAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepPurpleAccent : Colors.white10,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.deepPurpleAccent : Colors.white70),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.deepPurpleAccent, size: 18),
          ],
        ),
      ),
    );
  }
}
