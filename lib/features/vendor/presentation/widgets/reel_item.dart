import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/reel_model.dart';
import '../services/reel_service.dart';
import 'comments_sheet.dart';
import 'reel_action_button.dart';
import 'reel_video_player.dart';

class ReelItem extends StatefulWidget {
  final ReelModel reel;
  final bool isActive;

  const ReelItem({super.key, required this.reel, required this.isActive});

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  final ReelService _reelService = ReelService();

  late bool _isLiked;
  late int _likeCount;
  late int _commentCount;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _syncFromReel(widget.reel);
  }

  @override
  void didUpdateWidget(covariant ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reel.id != widget.reel.id ||
        oldWidget.reel.likeCount != widget.reel.likeCount ||
        oldWidget.reel.commentCount != widget.reel.commentCount) {
      _syncFromReel(widget.reel);
    }
  }

  void _syncFromReel(ReelModel reel) {
    final userId = _reelService.currentUserId;
    _isLiked = userId != null && reel.likes.contains(userId);
    _likeCount = reel.likeCount;
    _commentCount = reel.commentCount;
  }

  Future<void> _toggleLike() async {
    final userId = _reelService.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like reels')),
      );
      return;
    }
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked
          ? _likeCount + 1
          : (_likeCount - 1).clamp(0, 999999);
    });
    await _reelService.toggleLike(
      reelId: widget.reel.id,
      isLiked: _isLiked,
      newLikeCount: _likeCount,
    );
  }

  void _shareReel(String url) {
    if (_isSharing) return;

    // Generate custom share URL
    final shortId = widget.reel.shortId ?? _extractShortId(url);
    // Use Firebase hosting URL (change to custom domain when ready)
    final customUrl = 'https://skill-connect-9d6b3.web.app/reels/$shortId';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _ShareSheet(url: customUrl, onDismiss: () => Navigator.of(ctx).pop()),
    );
  }

  /// Extract short ID from GCS URL
  String _extractShortId(String gcsUrl) {
    try {
      final uri = Uri.parse(gcsUrl);
      final filename = uri.pathSegments.last;
      final uuid = filename.replaceAll('.mp4', '').replaceAll('.mov', '');
      return uuid.split('-').first;
    } catch (e) {
      return 'reel';
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(reelId: widget.reel.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final size = MediaQuery.of(context).size;
    final sidePadding = size.width * 0.04;
    final bottomPadding = size.height * 0.06;

    return Stack(
      children: [
        // ── Video player ──
        Positioned.fill(
          child: ReelVideoPlayer(url: reel.videoUrl, isActive: widget.isActive),
        ),

        // ── Gradient overlays ──
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.25, 0.6, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
        ),

        // ── Bottom info: username + caption ──
        Positioned(
          left: sidePadding,
          right: size.width * 0.22,
          bottom: bottomPadding,
          child: Semantics(
            container: true,
            label: 'Reel details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar circle
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          reel.userName.isNotEmpty
                              ? reel.userName[0].toUpperCase()
                              : 'V',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '@${reel.userName}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Caption text
                if (reel.caption.isNotEmpty)
                  Text(
                    reel.caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Right side action buttons ──
        Positioned(
          right: sidePadding,
          bottom: bottomPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReelActionButton(
                label: 'Like',
                count: _likeCount,
                isActive: _isLiked,
                icon: _isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                activeColor: const Color(0xFFED4956),
                onTap: _toggleLike,
              ),
              const SizedBox(height: 18),
              ReelActionButton(
                label: 'Comment',
                count: _commentCount,
                icon: Icons.chat_bubble_outline_rounded,
                onTap: _openComments,
              ),
              const SizedBox(height: 18),
              ReelActionButton(
                label: 'Share',
                count: 0,
                icon: Icons.send_rounded,
                onTap: () => _shareReel(reel.videoUrl),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Clean share bottom sheet ──
class _ShareSheet extends StatelessWidget {
  final String url;
  final VoidCallback onDismiss;

  const _ShareSheet({required this.url, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share Reel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareOption(
                  icon: Icons.copy_rounded,
                  label: 'Copy Link',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: url));
                    onDismiss();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _ShareOption(
                  icon: Icons.share_rounded,
                  label: 'More',
                  onTap: () async {
                    onDismiss();
                    await Share.share(url);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
