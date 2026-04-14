import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_provider.dart';

class LayerPanel extends StatelessWidget {
  const LayerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        return Container(
          width: 200,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Layers',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                         IconButton(
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 20, color: Colors.white70),
                          tooltip: 'Import Image Sketch',
                          onPressed: provider.isProcessing ? null : provider.importImageAsSketch,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20, color: Colors.white70),
                          onPressed: provider.addLayer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Video Import Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: ElevatedButton.icon(
                  onPressed: provider.isProcessing ? null : provider.importVideoAsAnimation,
                  icon: const Icon(Icons.movie_creation_outlined, size: 16),
                  label: const Text('Import Video', style: TextStyle(fontSize: 10)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white70,
                    minimumSize: const Size(double.infinity, 32),
                  ),
                ),
              ),

              if (provider.isProcessing) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: provider.processingProgress > 0 ? provider.processingProgress : null,
                        backgroundColor: Colors.white10,
                        color: Colors.deepPurpleAccent,
                        minHeight: 2,
                      ),
                      const SizedBox(height: 4),
                      const Text('Sketching...', style: TextStyle(color: Colors.white38, fontSize: 9)),
                    ],
                  ),
                ),
              ],

              const Divider(color: Colors.white10),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.currentFrame.layers.length,
                  itemBuilder: (context, index) {
                    final layerIndex = provider.currentFrame.layers.length - 1 - index;
                    final layer = provider.currentFrame.layers[layerIndex];
                    final isSelected = provider.currentLayerIndex == layerIndex;

                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: Colors.white10,
                      leading: Icon(
                        layer.isVisible ? Icons.visibility : Icons.visibility_off,
                        size: 18,
                        color: Colors.white70,
                      ),
                      title: Text(
                        layer.name,
                        style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white38,
                            fontSize: 12),
                      ),
                      subtitle: layer.sketchData != null 
                        ? const Text('Sketch Content', style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 8))
                        : null,
                      onTap: () => provider.setLayer(layerIndex),
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
