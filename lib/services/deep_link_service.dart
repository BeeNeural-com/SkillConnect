import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();

  /// Initialize deep link listener
  /// [onReelDeepLink] callback is called when a reel deep link is received
  Future<void> initialize(Function(String shortId) onReelDeepLink) async {
    try {
      // Listen for deep links while app is running
      _appLinks.uriLinkStream.listen(
        (Uri? uri) {
          if (uri != null) {
            debugPrint('Deep link received: $uri');
            final shortId = parseReelId(uri);
            if (shortId != null) {
              onReelDeepLink(shortId);
            }
          }
        },
        onError: (err) {
          debugPrint('Deep link error: $err');
        },
      );

      debugPrint('Deep link service initialized');
    } catch (e) {
      debugPrint('Failed to initialize deep link service: $e');
    }
  }

  /// Get the initial deep link that launched the app (cold start)
  /// Returns the shortId if a valid reel deep link was used to launch the app
  Future<String?> getInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        debugPrint('Initial deep link: $uri');
        return parseReelId(uri);
      }
    } catch (e) {
      debugPrint('Failed to get initial link: $e');
    }
    return null;
  }

  /// Parse reel shortId from deep link URI
  /// Expected format: https://skill-connect-9d6b3.web.app/reels/{shortId}
  /// Returns null if URI is invalid or not a reel deep link
  String? parseReelId(Uri uri) {
    try {
      // Check if host matches
      if (uri.host != 'skill-connect-9d6b3.web.app') {
        debugPrint('Invalid host: ${uri.host}');
        return null;
      }

      // Check if path starts with /reels/
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2 && pathSegments[0] == 'reels') {
        final shortId = pathSegments[1];

        // Validate shortId format (alphanumeric, 6-36 chars)
        if (RegExp(r'^[a-zA-Z0-9]{6,36}$').hasMatch(shortId)) {
          debugPrint('Parsed shortId: $shortId');
          return shortId;
        } else {
          debugPrint('Invalid shortId format: $shortId');
        }
      }
    } catch (e) {
      debugPrint('Error parsing reel ID: $e');
    }
    return null;
  }
}
