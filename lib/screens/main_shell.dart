import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'song_selection_screen.dart';

/// Hosts the three primary product destinations.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex.clamp(0, 2);
  late final PageController _pageController = PageController(
    initialPage: _index,
  );

  void _goTab(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: AppMotion.page,
        curve: AppMotion.standard,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onGoTab: _goTab),
      const SongSelectionScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          if (_index != index) setState(() => _index = index);
        },
        children: pages,
      ),
      bottomNavigationBar: _BottomNav(index: _index, onTap: _goTab),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.library_music_rounded, 'Library'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.panel.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.strokeStrong),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _NavItem(
                  icon: _items[i].$1,
                  label: _items[i].$2,
                  selected: index == i,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label tab',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: AnimatedContainer(
              duration: AppMotion.state,
              curve: AppMotion.standard,
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.interactive.withValues(alpha: 0.92)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: selected
                      ? AppColors.neonPurple.withValues(alpha: 0.45)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: selected
                        ? AppGradients.aurora.createShader
                        : (rect) => const LinearGradient(
                            colors: [AppColors.textLow, AppColors.textLow],
                          ).createShader(rect),
                    child: Icon(icon, color: Colors.white, size: 23),
                  ),
                  AnimatedSize(
                    duration: AppMotion.state,
                    curve: AppMotion.standard,
                    child: selected
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              label,
                              maxLines: 1,
                              style: const TextStyle(
                                color: AppColors.textHi,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
