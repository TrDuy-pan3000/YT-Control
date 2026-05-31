import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../tv/screens/tv_waiting_screen.dart';
import '../remote/screens/remote_connect_screen.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              Color(0xFF130F26),
              AppColors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Title with premium font style
                  const Icon(
                    Icons.mic_external_on,
                    size: 80,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Ứng Dụng Karaoke 2-in-1 (TV & Remote)',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 48.0),
                  
                  // Mode Cards (TV and Remote)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 600) {
                        // Desktop/Tablet/TV Landscape mode
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildModeCard(
                              context,
                              icon: Icons.tv,
                              title: AppStrings.modeTV,
                              desc: AppStrings.modeTVDesc,
                              color: AppColors.primary,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const TvWaitingScreen()),
                                );
                              },
                            ),
                            const SizedBox(width: 32.0),
                            _buildModeCard(
                              context,
                              icon: Icons.settings_remote,
                              title: AppStrings.modeRemote,
                              desc: AppStrings.modeRemoteDesc,
                              color: AppColors.accent,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RemoteConnectScreen()),
                                );
                              },
                            ),
                          ],
                        );
                      } else {
                        // Phone Portrait mode
                        return Column(
                          children: [
                            _buildModeCard(
                              context,
                              icon: Icons.tv,
                              title: AppStrings.modeTV,
                              desc: AppStrings.modeTVDesc,
                              color: AppColors.primary,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const TvWaitingScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 24.0),
                            _buildModeCard(
                              context,
                              icon: Icons.settings_remote,
                              title: AppStrings.modeRemote,
                              desc: AppStrings.modeRemoteDesc,
                              color: AppColors.accent,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RemoteConnectScreen()),
                                );
                              },
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _TVFocusableWrapper(
      onTap: onTap,
      glowColor: color,
      child: Container(
        width: 260,
        height: 200,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              desc,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.0,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A wrapper class that handles TV D-pad focus and Phone touch effects elegantly.
class _TVFocusableWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color glowColor;

  const _TVFocusableWrapper({
    Key? key,
    required this.child,
    required this.onTap,
    required this.glowColor,
  }) : super(key: key);

  @override
  State<_TVFocusableWrapper> createState() => _TVFocusableWrapperState();
}

class _TVFocusableWrapperState extends State<_TVFocusableWrapper> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      borderRadius: BorderRadius.circular(16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _isFocused ? AppColors.surfaceLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: _isFocused ? AppColors.tvFocusBorder : AppColors.surfaceLight.withValues(alpha: 0.3),
            width: _isFocused ? 2.5 : 1.0,
          ),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: widget.glowColor.withValues(alpha: 0.4),
                    blurRadius: 16.0,
                    spreadRadius: 2.0,
                  )
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}
