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
                    IconButton(
                      icon: const Icon(Icons.add, size: 20, color: Colors.white70),
                      onPressed: provider.addLayer,
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.currentFrame.layers.length,
                  itemBuilder: (context, index) {
                    // Reverse index to show top layer first
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
