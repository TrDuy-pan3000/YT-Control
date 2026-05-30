import 'package:wakelock_plus/wakelock_plus.dart';

class TvWakelockService {
  Future<void> enable() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Bỏ qua lỗi nếu chạy trên nền tảng không hỗ trợ wakelock
    }
  }

  Future<void> disable() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {
      // Bỏ qua lỗi
    }
  }
}
