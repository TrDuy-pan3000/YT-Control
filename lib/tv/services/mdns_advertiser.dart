import 'package:nsd/nsd.dart';
import '../../core/constants/ws_protocol.dart';

class MdnsAdvertiser {
  Registration? _registration;

  /// Đăng ký service trên mạng nội bộ để Phone tự tìm thấy
  Future<void> registerService({int port = WsProtocol.port}) async {
    try {
      _registration = await register(Service(
        name: WsProtocol.serviceName,
        type: WsProtocol.serviceType,
        port: port,
      ));
    } catch (e) {
      // Bỏ qua lỗi nếu đăng ký mDNS thất bại (Phone vẫn có thể quét bằng IP Smart Scan)
    }
  }

  Future<void> unregisterService() async {
    if (_registration != null) {
      try {
        await unregister(_registration!);
      } catch (_) {}
      _registration = null;
    }
  }
}
