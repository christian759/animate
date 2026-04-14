import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_provider.dart';
import '../../services/export_service.dart';
import '../../services/ad_service.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.mp4;
  String? _exportedPath;

  // Local settings for the dialog
  late double _exportFps;
  late Size _exportResolution;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    _exportFps = provider.project.fps;
    _exportResolution = Size(provider.project.exportWidth, provider.project.exportHeight);
    
    // Ensure we have an ad ready
    AdService().loadInterstitialAd();
  }

  void _triggerAdAndExport() {
    AdService().showInterstitialAd(
      onAdDismissed: _startActualExport,
    );
  }

  void _startActualExport() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    // Update project settings before export
    provider.setFps(_exportFps);
    provider.setExportResolution(_exportResolution.width, _exportResolution.height);
    
    final path = await provider.export(_selectedFormat);
    setState(() => _exportedPath = path);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        return Dialog(
          backgroundColor: const Color(0xFF161618),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!provider.isExporting && _exportedPath == null) ...[
                  const Text('Export & Settings', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  // Format Selection
                  _sectionTitle('Format'),
                  Row(
                    children: [
                      Expanded(
                        child: _FormatOptionMini(
                          label: 'MP4',
                          isSelected: _selectedFormat == ExportFormat.mp4,
                          onTap: () => setState(() => _selectedFormat = ExportFormat.mp4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FormatOptionMini(
                          label: 'GIF',
                          isSelected: _selectedFormat == ExportFormat.gif,
                          onTap: () => setState(() => _selectedFormat = ExportFormat.gif),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  _sectionTitle('Resolution'),
                  _buildResolutionPicker(),
                  
                  const SizedBox(height: 24),
                  _sectionTitle('Frame Rate (FPS): ${_exportFps.toInt()}'),
                  Slider(
                    value: _exportFps,
                    min: 1,
                    max: 60,
                    divisions: 59,
                    activeColor: Colors.deepPurpleAccent,
                    onChanged: (val) => setState(() => _exportFps = val),
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _triggerAdAndExport,
                      child: const Text('Render & Export (+ Ad)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else if (provider.isExporting) ...[
                  const Hero(
                    tag: 'export_icon',
                    child: Icon(Icons.auto_awesome, color: Colors.deepPurpleAccent, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text('Capturing Frames...', style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: provider.exportProgress,
                      minHeight: 8,
                      backgroundColor: Colors.white10,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('${(provider.exportProgress * 100).toInt()}%', style: const TextStyle(color: Colors.white38)),
                ] else if (_exportedPath != null) ...[
                  const Icon(Icons.movie_filter_rounded, color: Colors.greenAccent, size: 64),
                  const SizedBox(height: 24),
                  const Text('Perfectly Rendered!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: Text(_exportedPath!, style: const TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Studio')),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: const TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
      ),
    );
  }

  Widget _buildResolutionPicker() {
    final resolutions = {
      const Size(1280, 720): 'HD (720p)',
      const Size(1920, 1080): 'FHD (1080p)',
      const Size(2560, 1440): '2K (1440p)',
    };

    return Column(
      children: resolutions.entries.map((entry) {
        final isSelected = _exportResolution == entry.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => _exportResolution = entry.key),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.deepPurpleAccent : Colors.transparent),
              ),
              child: Row(
                children: [
                  Text(entry.value, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
                  const Spacer(),
                  if (isSelected) const Icon(Icons.check, color: Colors.deepPurpleAccent, size: 16),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FormatOptionMini extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOptionMini({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
