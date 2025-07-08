import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A singleton class responsible for managing registered face data.
///
/// This manager handles loading and saving face embeddings and their
/// associated image paths from a local JSON file, ensuring that the
/// facial recognition data persists across app sessions.
class FaceDataManager {
  // --- Singleton Setup ---
  static final FaceDataManager _instance = FaceDataManager._internal();

  /// Provides a global access point to the singleton instance.
  factory FaceDataManager() => _instance;

  FaceDataManager._internal();

  // --- Private State ---
  /// In-memory storage for registered faces.
  ///
  /// The key is the person's name, and the value is a list of their
  /// registered face data (embedding, imagePath, etc.).
  final Map<String, List<Map<String, dynamic>>> _registeredFaces = {};
  static const String _fileName = 'registered_faces.json';

  // --- Public Getters ---
  /// Returns an unmodifiable view of the registered faces.
  Map<String, List<Map<String, dynamic>>> get registeredFaces => Map.unmodifiable(_registeredFaces);

  /// Checks if there are any registered faces.
  bool get isEmpty => _registeredFaces.isEmpty;

  /// Returns the number of registered individuals.
  int get length => _registeredFaces.length;

  /// Returns an iterable of all registered names.
  Iterable<String> get keys => _registeredFaces.keys;

  /// Retrieves the album (list of face data) for a specific person.
  List<Map<String, dynamic>>? operator [](String key) => _registeredFaces[key];

  /// Checks if a person with the given name is registered.
  bool containsKey(String key) => _registeredFaces.containsKey(key);

  /// Returns the primary image path for a given person, which is typically the first one registered.
  ///
  /// Returns `null` if the person is not found or has no images.
  String? getPrimaryImagePath(String name) {
    if (_registeredFaces.containsKey(name) && _registeredFaces[name]!.isNotEmpty) {
      return _registeredFaces[name]!.first['imagePath'] as String?;
    }
    return null;
  }

  /// Adds a new face record to a person's album.
  ///
  /// If the person is not yet registered, a new album is created for them.
  void addFace(String name, Map<String, dynamic> faceData) {
    if (_registeredFaces.containsKey(name)) {
      _registeredFaces[name]!.add(faceData);
    } else {
      _registeredFaces[name] = [faceData];
    }
    saveRegisteredFaces();
  }

  /// Removes a person and all their associated face data.
  void removePerson(String personName) {
    if (_registeredFaces.containsKey(personName)) {
      _registeredFaces.remove(personName);
      saveRegisteredFaces();
    }
  }

  /// Loads the registered faces from the local JSON file into memory.
  ///
  /// This method should be called once when the app initializes.
  Future<void> loadRegisteredFaces() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(appDir.path, _fileName));

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        if (jsonString.isEmpty) {
          debugPrint('⚠️ registered_faces.json is empty. Starting fresh.');
          return;
        }
        final Map<String, dynamic> jsonDecoded = json.decode(jsonString);

        _registeredFaces.clear();
        jsonDecoded.forEach((key, value) {
          final List<Map<String, dynamic>> faceList = (value as List<dynamic>)
              .map((faceData) => Map<String, dynamic>.from(faceData))
              .toList();
          _registeredFaces[key] = faceList;
        });

        debugPrint('✅ Registered faces loaded from storage. Found ${_registeredFaces.length} users.');
      } else {
        debugPrint('ℹ️ No local face data file found. A new one will be created upon registration.');
      }
    } catch (e) {
      debugPrint('❌ Error loading registered faces: $e');
      // In case of corruption, start with a clean slate
      _registeredFaces.clear();
    }
  }

  /// Saves the current in-memory registered faces map to the local JSON file.
  Future<void> saveRegisteredFaces() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(appDir.path, _fileName));
      final jsonString = json.encode(_registeredFaces);
      await file.writeAsString(jsonString);
      debugPrint("✅ Registered faces saved to storage.");
    } catch (e) {
      debugPrint("❌ Error saving registered faces: $e");
    }
  }
}