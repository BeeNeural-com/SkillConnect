import 'package:flutter/material.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/reel_model.dart';
import '../services/reel_service.dart';
import '../widgets/reel_item.dart';

class VendorReelsScreen extends StatefulWidget {
  final bool isActive;

  const VendorReelsScreen({super.key, required this.isActive});

  @override
  State<VendorReelsScreen> createState() => _VendorReelsScreenState();
}

class _VendorReelsScreenState extends State<VendorReelsScreen>
    with WidgetsBindingObserver {
  final PageController _controller = PageController();
  final ReelService _reelService = ReelService();
  late final Stream<List<ReelModel>> _reelsStream;
  int _activeIndex = 0;
  bool _appActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cache the stream so it isn't recreated on every setState / build call.
    _reelsStream = _reelService.reelsStream();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
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
      body: StreamBuilder<List<ReelModel>>(
        stream: _reelsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading reels...');
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reels = snapshot.data ?? [];

          if (reels.isEmpty) {
            return const EmptyStateWidget(
              message: 'No reels yet. Upload your first reel.',
            );
          }

          final isVisible = widget.isActive && _appActive;
          return PageView.builder(
            controller: _controller,
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _activeIndex = index);
            },
            itemCount: reels.length,
            itemBuilder: (context, index) {
              final reel = reels[index];
              return ReelItem(
                key: ValueKey(reel.id),
                reel: reel,
                isActive: isVisible && index == _activeIndex,
              );
            },
          );
        },
      ),
    );
  }
}
