import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload file
  Future<String> uploadFile({
    required File file,
    required String path,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Upload multiple files
  Future<List<String>> uploadMultipleFiles({
    required List<File> files,
    required String basePath,
  }) async {
    try {
      final urls = <String>[];
      
      for (int i = 0; i < files.length; i++) {
        final path = '$basePath/${DateTime.now().millisecondsSinceEpoch}_$i';
        final url = await uploadFile(file: files[i], path: path);
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      rethrow;
    }
  }

  // Delete file
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      rethrow;
    }
  }

  // Delete multiple files
  Future<void> deleteMultipleFiles(List<String> urls) async {
    try {
      for (final url in urls) {
        await deleteFile(url);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get download URL
  Future<String> getDownloadURL(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }
}
