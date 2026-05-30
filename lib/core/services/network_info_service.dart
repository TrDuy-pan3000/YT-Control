import 'package:network_info_plus/network_info_plus.dart';

class NetworkInfoService {
  Future<String?> getLocalIp() async {
    final info = NetworkInfo();
    return await info.getWifiIP();
  }

  /// Trích xuất subnet prefix từ IP (ví dụ: "192.168.1")
  String? getSubnetPrefix(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }
}
