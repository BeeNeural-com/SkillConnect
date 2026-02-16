import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../screens/booking_requests_screen.dart';
import '../../screens/vendor_home_screen.dart';
import '../../screens/vendor_profile_view_screen.dart';
import 'vendor_post_reel_screen.dart';
import 'vendor_reels_screen.dart';

class VendorShellScreen extends StatefulWidget {
  const VendorShellScreen({super.key});

  @override
  State<VendorShellScreen> createState() => _VendorShellScreenState();
}

class _VendorShellScreenState extends State<VendorShellScreen> {
  int _currentIndex = 0;

  List<Widget> get _tabs => [
        const VendorHomeScreen(),
        VendorReelsScreen(isActive: _currentIndex == 1),
        const SizedBox.shrink(),
        const BookingRequestsScreen(),
        const VendorProfileViewScreen(),
      ];

  void _handleTap(int index) {
    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const VendorPostReelScreen()),
      );
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    border: Border(top: BorderSide(color: AppTheme.dividerColor)),
                    boxShadow: AppTheme.shadowSm,
                  ),
                ),
              ),
              Positioned.fill(
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: _handleTap,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: AppTheme.surfaceColor,
                  elevation: 0,
                  selectedItemColor: AppTheme.primaryColor,
                  unselectedItemColor: AppTheme.textSecondaryColor,
                  selectedLabelStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  selectedIconTheme: const IconThemeData(size: 22),
                  unselectedIconTheme: const IconThemeData(size: 20),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.video_library_rounded),
                      label: 'Reels',
                    ),
                    BottomNavigationBarItem(
                      icon: SizedBox(width: 24, height: 24),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.pending_actions_rounded),
                      label: 'Pending',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_rounded),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -28,
                child: GestureDetector(
                  onTap: () => _handleTap(2),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.shadowMd,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
