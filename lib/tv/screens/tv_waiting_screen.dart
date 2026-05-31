import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/network_info_service.dart';
import '../services/ws_server_service.dart';
import '../services/mdns_advertiser.dart';
import 'tv_player_screen.dart';

class TvWaitingScreen extends StatefulWidget {
  const TvWaitingScreen({Key? key}) : super(key: key);

  @override
  State<TvWaitingScreen> createState() => _TvWaitingScreenState();
}

class _TvWaitingScreenState extends State<TvWaitingScreen>
    with SingleTickerProviderStateMixin {
  final MdnsAdvertiser _mdnsAdvertiser = MdnsAdvertiser();
  String _localIp = 'Đang lấy IP Wi-Fi...';
  bool _isLoading = true;
  late AnimationController _animationController;

  /// StreamSubscription thay thế cho addListener() — tránh race condition.
  StreamSubscription<bool>? _connectionSub;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupServerAndDiscovery();
    });
  }

  Future<void> _setupServerAndDiscovery() async {
    final wsServer = Provider.of<WsServerService>(context, listen: false);
    final netInfo = Provider.of<NetworkInfoService>(context, listen: false);

    // 1. Lấy IP nội bộ
    final ip = await netInfo.getLocalIp();
    if (mounted) {
      setState(() {
        _localIp = ip ?? 'Không kết nối Wi-Fi';
        _isLoading = false;
      });
    }

    // 2. Khởi động WebSocket Server
    try {
      await wsServer.startServer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khởi động Server: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    // 3. Đăng ký mDNS
    if (wsServer.isRunning) {
      await _mdnsAdvertiser.registerService();
    }

    // 4. Lắng nghe sự kiện kết nối qua Stream — KHÔNG dùng addListener().
    // Stream event đến sau Future.microtask() nên TvPlayerScreen đã sẵn sàng
    // set onCommandReceived trước khi bất kỳ lệnh nào có thể tới.
    _connectionSub = wsServer.onClientConnectionChanged.listen((connected) {
      if (connected && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TvPlayerScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _connectionSub?.cancel();
    _mdnsAdvertiser.unregisterService();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, Color(0xFF0F0E24)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              const Icon(Icons.tv_outlined, size: 96, color: AppColors.primary),
              const SizedBox(height: 24.0),

              // App Name
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8.0),

              // Status Description
              const Text(
                AppStrings.waitingTitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 48.0),

              // Network IP Info box
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32.0, vertical: 20.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                      color: AppColors.surfaceLight.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 20.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Kết nối điện thoại vào cùng Wi-Fi và nhập IP:',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13.0),
                    ),
                    const SizedBox(height: 12.0),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accent),
                      )
                    else
                      Text(
                        _localIp,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    const SizedBox(height: 6.0),
                    const Text(
                      'Cổng: 8080',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48.0),

              // Premium Pulsing Dots Loader
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final delay = index * 0.3;
                      final double value =
                          (sin((_animationController.value * 2 * pi) -
                                      (delay * pi)) +
                                  1) /
                              2;
                      return Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 4.0),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.primary
                              .withValues(alpha: 0.3 + 0.7 * value),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
