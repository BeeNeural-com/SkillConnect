import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryUploadFailure implements Exception {
  final String message;

  CloudinaryUploadFailure(this.message);

  @override
  String toString() => message;
}

class CloudinaryService {
  late final CloudinaryPublic _cloudinary;
  late final String cloudName;
  late final String uploadPreset;

  CloudinaryService() {
    cloudName = (dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '').trim();
    uploadPreset = (dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '').trim();

    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      debugPrint(
        'Cloudinary config missing: cloudName=${cloudName.isNotEmpty}, preset=${uploadPreset.isNotEmpty}',
      );
      throw Exception('Cloudinary config missing');
    }

    debugPrint(
      'Cloudinary config loaded: cloudName=$cloudName, presetLength=${uploadPreset.length}',
    );
    _cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);
  }

  Future<CloudinaryResponse> uploadVideo(
    File file, {
    void Function(int sent, int total)? onProgress,
  }) {
    debugPrint('Cloudinary upload start: path=${file.path}');
    return _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: CloudinaryResourceType.Video,
        folder: 'vendor_reels',
      ),
      onProgress: onProgress,
    ).then((response) {
      debugPrint('Cloudinary upload success: ${response.secureUrl}');
      return response;
    }).catchError((error) {
      if (error is CloudinaryException) {
        debugPrint('Cloudinary error message: ${error.message}');
        debugPrint('Cloudinary error request: ${error.request}');
        throw CloudinaryUploadFailure(error.message ?? 'Upload failed');
      } else if (error is DioException) {
        debugPrint('Dio error status: ${error.response?.statusCode}');
        debugPrint('Dio error data: ${error.response?.data}');
        final data = error.response?.data;
        if (data is Map<String, dynamic> &&
            data['error'] is Map<String, dynamic> &&
            data['error']['message'] is String) {
          throw CloudinaryUploadFailure(data['error']['message'] as String);
        }
      }
      debugPrint('Cloudinary upload error: $error');
      throw error;
    });
  }
}
