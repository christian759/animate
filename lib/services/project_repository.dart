import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';

class ProjectRepository {
  static const String _projectsDirName = 'projects';
  static const String _metadataFileName = 'metadata.json';
  static const String _projectDataFileName = 'project.json';

  Future<Directory> _getProjectsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final projectsDir = Directory(p.join(appDir.path, _projectsDirName));
    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }
    return projectsDir;
  }

  Future<List<ProjectMetadata>> listProjects() async {
    final projectsDir = await _getProjectsDir();
    final List<ProjectMetadata> projects = [];

    await for (final entity in projectsDir.list()) {
      if (entity is Directory) {
        final metadataFile = File(p.join(entity.path, _metadataFileName));
        if (await metadataFile.exists()) {
          try {
            // Processing metadata is small, usually fine on main thread, 
            // but let's be consistent for huge libraries
            final jsonStr = await metadataFile.readAsString();
            final json = await compute(jsonDecode, jsonStr);
            projects.add(ProjectMetadata.fromJson(json));
          } catch (e) {
            debugPrint('Error loading metadata for ${entity.path}: $e');
          }
        }
      }
    }

    // Sort by last modified descending
    projects.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return projects;
  }

  Future<void> saveProject(AnimationProject project, {String? thumbnailPath}) async {
    final projectsDir = await _getProjectsDir();
    final projectDir = Directory(p.join(projectsDir.path, project.id));
    
    if (!await projectDir.exists()) {
      await projectDir.create();
    }

    // 1. Save Project Data in Background Isolate
    final projectFile = File(p.join(projectDir.path, _projectDataFileName));
    
    // Performance: Encode JSON in background
    final jsonStr = await compute((AnimationProject p) => jsonEncode(p.toJson()), project);
    await projectFile.writeAsString(jsonStr);

    // 2. Save/Update Metadata
    final metadataFile = File(p.join(projectDir.path, _metadataFileName));
    final metadata = ProjectMetadata(
      id: project.id,
      name: project.name,
      createdAt: DateTime.now(), 
      lastModified: DateTime.now(),
      thumbnailPath: thumbnailPath,
    );
    
    final metaJsonStr = jsonEncode(metadata.toJson());
    await metadataFile.writeAsString(metaJsonStr);
  }

  Future<AnimationProject?> loadProject(String id) async {
    final projectsDir = await _getProjectsDir();
    final projectFile = File(p.join(projectsDir.path, id, _projectDataFileName));

    if (await projectFile.exists()) {
      try {
        final jsonStr = await projectFile.readAsString();
        
        // Performance: Decode JSON in background isolate
        final json = await compute(jsonDecode, jsonStr);
        return AnimationProject.fromJson(json);
      } catch (e) {
        debugPrint('Error loading project $id: $e');
      }
    }
    return null;
  }

  Future<void> deleteProject(String id) async {
    final projectsDir = await _getProjectsDir();
    final projectDir = Directory(p.join(projectsDir.path, id));
    if (await projectDir.exists()) {
      await projectDir.delete(recursive: true);
    }
  }
}
