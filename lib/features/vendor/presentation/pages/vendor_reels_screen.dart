import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../shared/widgets/loading_widget.dart';

class VendorReelsScreen extends StatefulWidget {
  final bool isActive;

  const VendorReelsScreen({super.key, required this.isActive});

  @override
  State<VendorReelsScreen> createState() => _VendorReelsScreenState();
}

class _VendorReelsScreenState extends State<VendorReelsScreen>
    with WidgetsBindingObserver {
  final PageController _controller = PageController();
  int _activeIndex = 0;
  final Set<String> _cleanedReelIds = {};
  bool _appActive = true;

  String _sanitizeUrl(String raw) {
    final trimmed = raw.trim();
    final match = RegExp(r'https?://\S+').firstMatch(trimmed);
    if (match != null) {
      return match.group(0)!.trim();
    }
    var url = trimmed;
    while (url.isNotEmpty && '`"\''.contains(url[0])) {
      url = url.substring(1);
    }
    while (url.isNotEmpty && '`"\''.contains(url[url.length - 1])) {
      url = url.substring(0, url.length - 1);
    }
    return url.trim();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isActive = state == AppLifecycleState.resumed;
    if (_appActive != isActive) {
      setState(() => _appActive = isActive);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reels').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading reels...');
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          final reels = docs
              .map((doc) => {'id': doc.id, 'data': doc.data()})
              .where((item) {
                final data = item['data'] as Map<String, dynamic>;
                return data['videoUrl'] is String;
              })
              .map((item) {
                final data = Map<String, dynamic>.from(
                  item['data'] as Map<String, dynamic>,
                );
                final rawUrl = (data['videoUrl'] ?? '') as String;
                data['videoUrl'] = _sanitizeUrl(rawUrl);
                final id = item['id'] as String;
                if (!_cleanedReelIds.contains(id) &&
                    rawUrl.trim() != data['videoUrl']) {
                  _cleanedReelIds.add(id);
                  Future.microtask(() {
                    FirebaseFirestore.instance
                        .collection('reels')
                        .doc(id)
                        .update({'videoUrl': data['videoUrl']});
                  });
                }
                return {'id': item['id'], 'data': data};
              })
              .toList();

          reels.sort((a, b) {
            final aData = a['data'] as Map<String, dynamic>;
            final bData = b['data'] as Map<String, dynamic>;
            final aTime = (aData['createdAt'] as Timestamp?)?.toDate();
            final bTime = (bData['createdAt'] as Timestamp?)?.toDate();
            return (bTime ?? DateTime(0)).compareTo(aTime ?? DateTime(0));
          });

          if (reels.isEmpty) {
            return const EmptyStateWidget(
              message: 'No reels yet. Upload your first reel.',
            );
          }

          final isVisible = widget.isActive && _appActive;
          return PageView.builder(
            key: ValueKey(
              reels.map((item) => item['id']).join('_'),
            ),
            controller: _controller,
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _activeIndex = index);
            },
            itemCount: reels.length,
            itemBuilder: (context, index) {
              final item = reels[index];
              final data = item['data'] as Map<String, dynamic>;
              return _ReelItem(
                key: ValueKey(item['id']),
                reelId: item['id'] as String,
                data: Map<String, dynamic>.from(data),
                isActive: isVisible && index == _activeIndex,
              );
            },
          );
        },
      ),
    );
  }
}

class _ReelItem extends StatefulWidget {
  final String reelId;
  final Map<String, dynamic> data;
  final bool isActive;

  const _ReelItem({
    super.key,
    required this.reelId,
    required this.data,
    required this.isActive,
  });

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem> {
  late bool _isLiked;
  late int _likeCount;
  late int _commentCount;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _syncFromData(widget.data);
  }

  @override
  void didUpdateWidget(covariant _ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data || oldWidget.reelId != widget.reelId) {
      _syncFromData(widget.data);
    }
  }

  void _syncFromData(Map<String, dynamic> data) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final likes = data['likes'] is List ? List<String>.from(data['likes']) : [];
    _isLiked = userId != null && likes.contains(userId);
    _likeCount = (data['likeCount'] ?? likes.length) as int;
    _commentCount = (data['commentCount'] ?? 0) as int;
  }

  Future<void> _toggleLike() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like reels')),
      );
      return;
    }
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : (_likeCount - 1).clamp(0, 999999);
    });
    await FirebaseFirestore.instance
        .collection('reels')
        .doc(widget.reelId)
        .update({
      'likes': _isLiked
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
      'likeCount': _likeCount,
    });
  }

  Future<void> _shareReel(String url) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    await Share.share(url);
    if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(reelId: widget.reelId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final url = data['videoUrl'] as String;
    final caption = (data['caption'] ?? '') as String;
    final userName = (data['userName'] ?? 'Vendor') as String;
    final size = MediaQuery.of(context).size;
    final sidePadding = size.width * 0.05;
    final bottomPadding = size.height * 0.08;

    return Stack(
      children: [
        Positioned.fill(
          child: _ReelVideoPlayer(url: url, isActive: widget.isActive),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.45),
                  Colors.transparent,
                  Colors.black.withOpacity(0.65),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: sidePadding,
          right: size.width * 0.25,
          bottom: bottomPadding,
          child: Semantics(
            container: true,
            label: 'Reel details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@$userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: sidePadding,
          bottom: bottomPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                label: 'Like',
                count: _likeCount,
                isActive: _isLiked,
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                activeColor: const Color(0xFFED4956),
                onTap: _toggleLike,
              ),
              const SizedBox(height: 20),
              _ActionButton(
                label: 'Comment',
                count: _commentCount,
                icon: Icons.mode_comment_outlined,
                onTap: _openComments,
                badgeCount: _commentCount,
              ),
              const SizedBox(height: 20),
              _ActionButton(
                label: 'Share',
                count: 0,
                icon: Icons.send_rounded,
                onTap: () => _shareReel(url),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final bool isActive;
  final int? badgeCount;
  final Color? activeColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.badgeCount,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor ?? Colors.white : Colors.white;
    return Semantics(
      button: true,
      toggled: isActive,
      label: label,
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: InkResponse(
              onTap: onTap,
              radius: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedScale(
                    scale: isActive ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: Icon(icon, size: 30, color: color),
                  ),
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFED4956),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeCount!.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count > 0 ? count.toString() : '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final String reelId;

  const _CommentsSheet({required this.reelId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment')),
      );
      return;
    }
    setState(() => _isSending = true);
    final userDoc = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();
    final userName = userDoc.data()?['name'] as String? ?? 'Vendor';
    final commentsRef = FirebaseFirestore.instance
        .collection('reels')
        .doc(widget.reelId)
        .collection('comments');
    await commentsRef.add({
      'userId': user.uid,
      'userName': userName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance.collection('reels').doc(widget.reelId).update({
      'commentCount': FieldValue.increment(1),
    });
    if (mounted) {
      _controller.clear();
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Comments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reels')
                  .doc(widget.reelId)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget(message: 'Loading comments...');
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const EmptyStateWidget(message: 'No comments yet');
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final name = (data['userName'] ?? 'Vendor') as String;
                    final text = (data['text'] ?? '') as String;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'V',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                text,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  width: 44,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: AppTheme.primaryColor,
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelVideoPlayer extends StatefulWidget {
  final String url;
  final bool isActive;

  const _ReelVideoPlayer({required this.url, required this.isActive});

  @override
  State<_ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<_ReelVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant _ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller.dispose();
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _initializeController();
      return;
    }
    if (!_controller.value.isInitialized) return;
    if (widget.isActive && !_controller.value.isPlaying) {
      _controller.play();
    } else if (!widget.isActive && _controller.value.isPlaying) {
      _controller.pause();
    }
  }

  void _initializeController() {
    _controller
      ..setLooping(true)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          if (widget.isActive) {
            _controller.play();
          }
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (!_controller.value.isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
          if (!_controller.value.isPlaying)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
