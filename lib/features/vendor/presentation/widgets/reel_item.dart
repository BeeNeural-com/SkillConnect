import 'package:flutter/material.dart';
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
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _syncFromReel(widget.reel);
    _checkSavedState();
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

  Future<void> _checkSavedState() async {
    final saved = await _reelService.isReelSaved(widget.reel.id);
    if (mounted) {
      setState(() => _isSaved = saved);
    }
  }

  Future<void> _toggleSave() async {
    final userId = _reelService.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save reels')),
      );
      return;
    }
    setState(() => _isSaved = !_isSaved);
    await _reelService.toggleSaveReel(
      reelId: widget.reel.id,
      isSaved: _isSaved,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSaved ? 'Reel saved' : 'Reel unsaved'),
          duration: const Duration(seconds: 1),
        ),
      );
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
                label: 'Save',
                count: 0,
                isActive: _isSaved,
                icon: _isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                activeColor: Colors.white,
                onTap: _toggleSave,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
