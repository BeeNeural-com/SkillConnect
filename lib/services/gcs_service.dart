import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gcloud/storage.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class GCSUploadFailure implements Exception {
  final String message;

  GCSUploadFailure(this.message);

  @override
  String toString() => message;
}

class GCSService {
  late final String projectId;
  late final String bucketName;
  late final ServiceAccountCredentials credentials;
  Storage? _storage;

  GCSService() {
    projectId = (dotenv.env['GCS_PROJECT_ID'] ?? '').trim();
    bucketName = (dotenv.env['GCS_BUCKET_NAME'] ?? '').trim();
    final serviceAccountJson = (dotenv.env['GCS_SERVICE_ACCOUNT_JSON'] ?? '')
        .trim();

    if (projectId.isEmpty || bucketName.isEmpty || serviceAccountJson.isEmpty) {
      debugPrint(
        'GCS config missing: projectId=${projectId.isNotEmpty}, '
        'bucket=${bucketName.isNotEmpty}, '
        'credentials=${serviceAccountJson.isNotEmpty}',
      );
      throw Exception('GCS configuration missing in .env file');
    }

    try {
      final jsonMap = json.decode(serviceAccountJson) as Map<String, dynamic>;
      credentials = ServiceAccountCredentials.fromJson(jsonMap);
      debugPrint('GCS config loaded: projectId=$projectId, bucket=$bucketName');
    } catch (e) {
      debugPrint('Failed to parse GCS service account JSON: $e');
      throw Exception('Invalid GCS service account JSON');
    }
  }

  /// Initialize the Storage client
  Future<Storage> _getStorage() async {
    if (_storage != null) return _storage!;

    try {
      final client = await clientViaServiceAccount(credentials, [
        'https://www.googleapis.com/auth/devstorage.full_control',
      ]);
      _storage = Storage(client, projectId);
      return _storage!;
    } catch (e) {
      debugPrint('Failed to initialize GCS client: $e');
      throw GCSUploadFailure('Failed to connect to Google Cloud Storage');
    }
  }

  /// Upload a video file to GCS
  /// Returns the public URL of the uploaded video
  Future<String> uploadVideo(
    File file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      debugPrint('GCS upload start: path=${file.path}');

      final storage = await _getStorage();
      final bucket = storage.bucket(bucketName);

      // Generate unique filename
      final uuid = const Uuid().v4();
      final extension = path.extension(file.path);
      final fileName = 'vendor_reels/$uuid$extension';

      // Read file bytes
      final bytes = await file.readAsBytes();
      final totalBytes = bytes.length;
      debugPrint('File size: $totalBytes bytes');

      // Upload to GCS
      final objectInfo = await bucket.writeBytes(
        fileName,
        bytes,
        metadata: ObjectMetadata(
          contentType: 'video/mp4',
          custom: {'uploadedAt': DateTime.now().toIso8601String()},
        ),
      );

      // Simulate progress callback (GCS doesn't provide real-time progress)
      if (onProgress != null) {
        onProgress(totalBytes, totalBytes);
      }

      // Generate public URL
      // Format: https://storage.googleapis.com/BUCKET_NAME/OBJECT_NAME
      final publicUrl =
          'https://storage.googleapis.com/$bucketName/${objectInfo.name}';

      debugPrint('GCS upload success: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('GCS upload error: $e');
      throw GCSUploadFailure('Upload failed: ${e.toString()}');
    }
  }

  /// Delete a video from GCS
  Future<void> deleteVideo(String videoUrl) async {
    try {
      // Extract object name from URL
      final uri = Uri.parse(videoUrl);
      final objectName = uri.pathSegments.skip(1).join('/');

      if (objectName.isEmpty) {
        throw GCSUploadFailure('Invalid video URL');
      }

      final storage = await _getStorage();
      final bucket = storage.bucket(bucketName);

      await bucket.delete(objectName);
      debugPrint('GCS delete success: $objectName');
    } catch (e) {
      debugPrint('GCS delete error: $e');
      throw GCSUploadFailure('Delete failed: ${e.toString()}');
    }
  }

  /// Generate a signed URL for private access (optional)
  /// Use this if your bucket is private
  Future<String> getSignedUrl(
    String objectName, {
    Duration expiration = const Duration(hours: 1),
  }) async {
    try {
      await _getStorage();

      // Note: Signed URLs require additional setup
      // For now, return the public URL
      final publicUrl =
          'https://storage.googleapis.com/$bucketName/$objectName';
      return publicUrl;
    } catch (e) {
      debugPrint('Failed to generate signed URL: $e');
      throw GCSUploadFailure('Failed to generate signed URL');
    }
  }

  /// Close the storage client
  void dispose() {
    _storage = null;
  }
}
