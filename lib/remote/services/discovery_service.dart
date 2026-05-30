import 'dart:async';
import 'dart:io';
import 'package:nsd/nsd.dart';
import '../../core/constants/ws_protocol.dart';
import '../../core/services/network_info_service.dart';

class DiscoveredTV {
  final String name;
  final String ip;
  final int port;
  const DiscoveredTV({required this.name, required this.ip, required this.port});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredTV &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          port == other.port;

  @override
  int get hashCode => ip.hashCode ^ port.hashCode;
}

class DiscoveryService {
  /// ★ PHƯƠNG ÁN 1: mDNS Discovery (Nhanh, sạch)
  Future<List<DiscoveredTV>> discoverViaMdns({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final results = <DiscoveredTV>[];

    try {
      final discovery = await startDiscovery(WsProtocol.serviceType);
      final servicesList = <Service>[];
      
      final listener = () {
        for (var service in discovery.services) {
          if (!servicesList.contains(service)) {
            servicesList.add(service);
          }
        }
      };
      discovery.addListener(listener);

      await Future.delayed(timeout);
      discovery.removeListener(listener);
      await stopDiscovery(discovery);

      for (final service in servicesList) {
        // Lấy địa chỉ IP
        final ip = service.addresses?.first.address;
        if (ip != null) {
          results.add(DiscoveredTV(
            name: service.name ?? WsProtocol.serviceName,
            ip: ip,
            port: service.port ?? WsProtocol.port,
          ));
        }
      }
    } catch (_) {
      // Bỏ qua lỗi, fallback sẽ xử lý
    }

    return results;
  }

  /// ★ PHƯƠNG ÁN 2: Smart Scan Fallback (Quét toàn subnet)
  /// Lấy IP điện thoại (ví dụ: 192.168.1.5),
  /// sau đó ping song song từng IP .1 → .255 trên port 8080.
  Future<List<DiscoveredTV>> smartScan() async {
    final results = <DiscoveredTV>[];
    final networkInfo = NetworkInfoService();
    final localIp = await networkInfo.getLocalIp();

    if (localIp == null) return results;

    final subnet = networkInfo.getSubnetPrefix(localIp);
    if (subnet == null) return results;

    final futures = <Future>[];
    for (int i = 1; i <= 255; i++) {
      final targetIp = '$subnet.$i';
      
      // Bỏ qua IP của chính mình để tránh mất thời gian
      if (targetIp == localIp) continue;

      futures.add(_probeHost(targetIp, WsProtocol.port).then((found) {
        if (found) {
          results.add(DiscoveredTV(
            name: 'TV tại $targetIp',
            ip: targetIp,
            port: WsProtocol.port,
          ));
        }
      }));
    }

    // Chờ tất cả hoàn thành (timeout mỗi cái 2 giây)
    await Future.wait(futures);
    return results;
  }

  /// Thử kết nối TCP đến host:port, nếu thành công → có server ở đó
  Future<bool> _probeHost(String ip, int port) async {
    try {
      final socket = await Socket.connect(
        ip, port,
        timeout: const Duration(seconds: 1, milliseconds: 500),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// ★ Chiến lược tổng hợp: thử mDNS trước, nếu rỗng thì fallback sang Smart Scan
  Future<List<DiscoveredTV>> discoverAll() async {
    // 1. Thử mDNS
    var results = await discoverViaMdns();
    if (results.isNotEmpty) return results;

    // 2. Fallback: Smart Scan (chậm hơn nhưng 100% tìm ra)
    return await smartScan();
  }
}
