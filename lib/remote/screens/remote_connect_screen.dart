import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../services/ws_client_service.dart';
import '../services/discovery_service.dart';
import 'remote_control_screen.dart';

class RemoteConnectScreen extends StatefulWidget {
  const RemoteConnectScreen({Key? key}) : super(key: key);

  @override
  State<RemoteConnectScreen> createState() => _RemoteConnectScreenState();
}

class _RemoteConnectScreenState extends State<RemoteConnectScreen> {
  final TextEditingController _ipController = TextEditingController();
  List<DiscoveredTV> _discoveredTvs = [];
  bool _isSearching = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
    _startDiscovery();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedIp() async {
    final wsClient = Provider.of<WsClientService>(context, listen: false);
    final savedIp = await wsClient.getLastIp();
    if (savedIp != null) {
      setState(() {
        _ipController.text = savedIp;
      });
    }
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isSearching = true;
      _discoveredTvs = [];
    });

    final discovery = Provider.of<DiscoveryService>(context, listen: false);
    try {
      final results = await discovery.discoverAll();
      if (mounted) {
        setState(() {
          _discoveredTvs = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _connectToTv(String ip) async {
    if (ip.trim().isEmpty) return;

    setState(() {
      _isConnecting = true;
    });

    final wsClient = Provider.of<WsClientService>(context, listen: false);
    final success = await wsClient.connect(ip.trim());

    if (mounted) {
      setState(() {
        _isConnecting = false;
      });

      if (success) {
        // Kết nối thành công → Chuyển sang Remote Điều khiển chính
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RemoteControlScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kết nối thất bại. Vui lòng kiểm tra lại IP hoặc Wi-Fi!'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.modeRemote,
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accent),
            onPressed: _isSearching ? null : _startDiscovery,
          ),
        ],
      ),
      body: Container(
        color: AppColors.background,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon
                const Icon(Icons.settings_remote_outlined, size: 72, color: AppColors.accent),
                const SizedBox(height: 24.0),
                
                // Discovered TVs section
                const Text(
                  'TIVI ĐÃ TÌM THẤY TRONG MẠNG WI-FI:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12.0),
                _buildDiscoveryList(),
                
                const SizedBox(height: 32.0),
                
                // Divider or text
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.surfaceLight, height: 1.0)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'HOẶC NHẬP IP THỦ CÔNG',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.surfaceLight, height: 1.0)),
                  ],
                ),
                const SizedBox(height: 24.0),
                
                // Manual IP input
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.surfaceLight),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi, color: AppColors.textSecondary),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: TextField(
                          controller: _ipController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16.0, letterSpacing: 1.0),
                          decoration: const InputDecoration(
                            hintText: 'Ví dụ: 192.168.1.15',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14.0),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                
                // Connect button
                ElevatedButton(
                  onPressed: _isConnecting ? null : () => _connectToTv(_ipController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
                    elevation: 4,
                  ),
                  child: _isConnecting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'KẾT NỐI TIVI',
                          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryList() {
    if (_isSearching) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
              SizedBox(height: 12.0),
              Text(
                'Đang tìm kiếm Tivi trong Wi-Fi...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.0),
              ),
            ],
          ),
        ),
      );
    }

    if (_discoveredTvs.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5)),
        ),
        child: const Center(
          child: Text(
            'Chưa tìm thấy Tivi nào tự động.\nBạn có thể nhấn nút Refresh hoặc nhập IP thủ công.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.0),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _discoveredTvs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8.0),
      itemBuilder: (context, index) {
        final tv = _discoveredTvs[index];
        return InkWell(
          onTap: () => _connectToTv(tv.ip),
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tv, color: AppColors.primary),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tv.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.0),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'IP: ${tv.ip}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.0),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }
}
