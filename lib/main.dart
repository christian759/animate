import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'state/project_provider.dart';
import 'ui/widgets/drawing_canvas.dart';
import 'ui/widgets/toolbar.dart';
import 'ui/widgets/timeline.dart';
import 'ui/widgets/layer_panel.dart';
import 'ui/widgets/export_dialog.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ProjectProvider(),
      child: const AnimXApp(),
    ),
  );
}

class AnimXApp extends StatelessWidget {
  const AnimXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anim-X',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          primary: Colors.deepPurpleAccent,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const MainAnimationScreen(),
    );
  }
}

class MainAnimationScreen extends StatelessWidget {
  const MainAnimationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            const _TopHeader(),
            
            // Middle Area (Toolbar + Canvas + Layer Panel)
            Expanded(
              child: Stack(
                children: [
                   // The Drawing Surface
                  const Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: DrawingCanvas(),
                    ),
                  ),

                  // Toolbar (Floating Left)
                  const Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: AnimToolbar(),
                  ),

                  // Layer Panel (Floating Right)
                  const Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: LayerPanel(),
                  ),
                ],
              ),
            ),
            
            // Bottom Area (Timeline)
            const AnimTimeline(),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.movie_filter, color: Colors.deepPurpleAccent, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anim-X Studio',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Text(
                    'V1.0.0 Alpha',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.ios_share, size: 18),
            label: const Text('Export'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ExportDialog(),
              );
            },
          ),
        ],
      ),
    );
  }
}
