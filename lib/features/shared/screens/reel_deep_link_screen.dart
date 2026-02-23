import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../vendor/presentation/models/reel_model.dart';
import '../../vendor/presentation/widgets/reel_item.dart';

class ReelDeepLinkScreen extends StatefulWidget {
  final String shortId;

  const ReelDeepLinkScreen({super.key, required this.shortId});

  @override
  State<ReelDeepLinkScreen> createState() => _ReelDeepLinkScreenState();
}

class _ReelDeepLinkScreenState extends State<ReelDeepLinkScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  ReelModel? _reel;

  @override
  void initState() {
    super.initState();
    _fetchReel();
  }

  Future<void> _fetchReel() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      debugPrint('Fetching reel with shortId: ${widget.shortId}');

      // Query Firestore for reel with matching shortId
      final snapshot = await FirebaseFirestore.instance
          .collection('reels')
          .where('shortId', isEqualTo: widget.shortId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Reel not found or no longer available';
        });
        return;
      }

      final reelDoc = snapshot.docs.first;
      final reel = ReelModel.fromFirestore(reelDoc);

      setState(() {
        _reel = reel;
        _isLoading = false;
      });

      debugPrint('Reel fetched successfully: ${reel.id}');
    } catch (e) {
      debugPrint('Error fetching reel: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load reel. Please check your connection.';
      });
    }
  }

  void _navigateToReelsFeed() {
    // Navigate back or to reels feed
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CustomLoadingIndicator(size: 80, message: 'Loading reel...'),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white70,
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _fetchReel,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _navigateToReelsFeed,
                  child: const Text(
                    'Go to Reels Feed',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_reel == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: TextButton(
            onPressed: _navigateToReelsFeed,
            child: const Text(
              'Go to Reels Feed',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    // Display the reel in full screen
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Reel viewer
          ReelItem(reel: _reel!, isActive: true),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: _navigateToReelsFeed,
            ),
          ),
        ],
      ),
    );
  }
}
