import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_provider.dart';
import 'package:path/path.dart' as p;

class AnimTimeline extends StatelessWidget {
  const AnimTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final project = provider.project;
        
        return Container(
          height: 140, // Expanded height for audio track
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            border: const Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            children: [
              // Top Control Bar
              _buildControlBar(context, provider),
              
              const Divider(height: 1, color: Colors.white10),
              
              // Timeline Area
              Expanded(
                child: Row(
                  children: [
                    // Audio Track Label & Action
                    _buildAudioAction(context, provider),
                    
                    const VerticalDivider(width: 1, color: Colors.white10),
                    
                    // Frames & Audio Track
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: project.frames.length,
                        itemBuilder: (context, index) {
                          final isCurrent = index == project.currentFrameIndex;
                          return Column(
                            children: [
                              // Frame Card
                              GestureDetector(
                                onTap: () => provider.setCurrentFrame(index),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: isCurrent ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCurrent ? Colors.white : Colors.white12,
                                      width: isCurrent ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isCurrent ? Colors.white : Colors.white38,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Audio Waveform Placeholder segment
                              if (project.audioPath != null)
                                Container(
                                  width: 60,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlBar(BuildContext context, ProjectProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            color: Colors.white,
            onPressed: provider.togglePlayback,
          ),
          const SizedBox(width: 16),
          _ActionButton(
            icon: Icons.add_box_outlined,
            onTap: provider.addFrame,
            tooltip: 'Add Frame',
          ),
          _ActionButton(
            icon: Icons.copy_all_outlined,
            onTap: provider.duplicateFrame,
            tooltip: 'Duplicate Frame',
          ),
          _ActionButton(
            icon: Icons.delete_outline_rounded,
            onTap: provider.removeFrame,
            tooltip: 'Delete Frame',
          ),
        ],
      ),
    );
  }

  Widget _buildAudioAction(BuildContext context, ProjectProvider provider) {
    final hasAudio = provider.project.audioPath != null;
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasAudio ? Icons.audiotrack_rounded : Icons.music_off_rounded,
            color: hasAudio ? Colors.cyanAccent : Colors.white24,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            hasAudio ? p.basename(provider.project.audioPath!) : 'No Audio',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: provider.pickAudio,
            child: Text(
              hasAudio ? 'Change' : 'Add Audio',
              style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onTap,
        color: Colors.white70,
        iconSize: 20,
      ),
    );
  }
}
