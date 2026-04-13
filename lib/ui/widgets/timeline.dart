import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_provider.dart';

class AnimTimeline extends StatelessWidget {
  const AnimTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 140,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            border: const Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            children: [
              // Playback controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow),
                      color: Colors.white,
                      onPressed: provider.togglePlayback,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${provider.currentFrameIndex + 1} / ${provider.project.frames.length}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_box_outlined),
                      color: Colors.white70,
                      onPressed: provider.addFrame,
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      color: Colors.white70,
                      onPressed: provider.duplicateFrame,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      onPressed: provider.removeFrame,
                    ),
                  ],
                ),
              ),
              // Frame list
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.project.frames.length,
                  itemBuilder: (context, index) {
                    final isSelected = provider.currentFrameIndex == index;
                    return GestureDetector(
                      onTap: () => provider.setCurrentFrame(index),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white10 : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white12,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white38,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
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
