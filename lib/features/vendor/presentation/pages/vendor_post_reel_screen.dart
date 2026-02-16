import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/cloudinary_service.dart';

class VendorPostReelScreen extends StatefulWidget {
  const VendorPostReelScreen({super.key});

  @override
  State<VendorPostReelScreen> createState() => _VendorPostReelScreenState();
}

class _VendorPostReelScreenState extends State<VendorPostReelScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedVideo;
  String? _uploadedUrl;
  double _uploadProgress = 0;
  bool _isUploading = false;
  bool _isPosting = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      final picked = await _picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) {
        debugPrint('Video pick cancelled');
        return;
      }

      setState(() {
        _selectedVideo = File(picked.path);
        _uploadedUrl = null;
        _uploadProgress = 0;
        _isUploading = true;
      });

      final fileSize = await _selectedVideo!.length();
      debugPrint(
        'Selected video: path=${_selectedVideo!.path}, bytes=$fileSize',
      );

      final cloudinary = CloudinaryService();
      if (kDebugMode) {
        debugPrint(
          'Using cloud=${cloudinary.cloudName}, preset=${cloudinary.uploadPreset}',
        );
        _showSnack(
          'Cloudinary preset: ${cloudinary.uploadPreset} on ${cloudinary.cloudName}',
        );
      }
      final response = await cloudinary.uploadVideo(
        _selectedVideo!,
        onProgress: (sent, total) {
          if (total > 0) {
            setState(() {
              _uploadProgress = sent / total;
            });
            debugPrint('Upload progress: $sent/$total');
          }
        },
      );

      final cleanUrl = response.secureUrl.trim();
      setState(() {
        _uploadedUrl = cleanUrl;
        _isUploading = false;
      });
      debugPrint('Upload complete: $cleanUrl');
      _showSnack('Video uploaded successfully');
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      debugPrint('Upload failed: $e');
      if (e is CloudinaryUploadFailure) {
        _showSnack(e.message);
      } else {
        _showSnack('Upload failed. Check console for details');
      }
    }
  }

  Future<void> _postReel() async {
    if (_uploadedUrl == null) {
      _showSnack('Upload a video first');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Please sign in to post');
      return;
    }
    try {
      setState(() => _isPosting = true);
      final userDoc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] as String? ?? 'Vendor';
      await FirebaseFirestore.instance.collection('reels').add({
        'videoUrl': _uploadedUrl,
        'caption': _captionController.text.trim(),
        'userId': user.uid,
        'userName': userName,
        'likeCount': 0,
        'commentCount': 0,
        'likes': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _showSnack('Reel posted successfully');
      setState(() {
        _selectedVideo = null;
        _uploadedUrl = null;
        _captionController.clear();
        _uploadProgress = 0;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to save reel: $e');
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Post Reel')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.dividerColor),
              boxShadow: AppTheme.shadowSm,
            ),
            child: _selectedVideo == null
                ? const Center(
                    child: Icon(
                      Icons.video_library_rounded,
                      size: 64,
                      color: AppTheme.textSecondaryColor,
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.video_file_rounded,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedVideo!.path.split(Platform.pathSeparator).last,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _captionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write a caption...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isUploading ? null : _pickAndUploadVideo,
            icon: const Icon(Icons.upload_rounded),
            label: Text(_isUploading ? 'Uploading...' : 'Upload Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
            ),
          ),
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(
                value: _uploadProgress == 0 ? null : _uploadProgress,
                backgroundColor: AppTheme.dividerColor,
                color: AppTheme.primaryColor,
              ),
            ),
          if (_uploadedUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Uploaded',
                style: const TextStyle(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isPosting ? null : _postReel,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
            ),
            child: Text(_isPosting ? 'Posting...' : 'Post'),
          ),
        ],
      ),
    );
  }
}
