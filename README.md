<div align="center">

# 🎤 YT Karaoke

### Ứng dụng Karaoke 2-in-1 · Tivi & Điện thoại · 1 APK duy nhất

[![Flutter](https://img.shields.io/badge/Flutter-3.44.0-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Android%20TV-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://www.android.com)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Release](https://img.shields.io/badge/Release-v1.0.0-brightgreen?style=for-the-badge)](https://github.com/TrDuy-pan3000/YT-Control/releases/latest)

<br/>

> **1 file APK duy nhất** — cài lên **Tivi** để phát nhạc karaoke chất lượng cao, cài lên **Điện thoại** để điều khiển từ xa, chọn bài, quản lý hàng đợi — tất cả trên cùng mạng Wi-Fi nội bộ, không cần internet phụ trợ.

<br/>

## ⬇️ Tải Xuống APK

<a href="https://github.com/TrDuy-pan3000/YT-Control/releases/download/v1.0.0/app-release.apk">
  <img src="https://img.shields.io/badge/📥%20Tải%20APK%20v1.0.0-52.7%20MB-FF5722?style=for-the-badge" alt="Download APK" height="50"/>
</a>

*Không cần tài khoản Google Play · Cài đặt trực tiếp qua APK*

</div>

---

## 📸 Giao Diện

| Màn hình chọn chế độ | Chế độ TV — Chờ kết nối | Chế độ Remote — Điều khiển |
|:---:|:---:|:---:|
| *(Mode Selection)* | *(TV Waiting Screen)* | *(Remote Control Screen)* |

---

## ✨ Tính Năng Nổi Bật

### 📺 Chế độ Tivi (TV Receiver)
- Giao diện full-screen tối ưu cho **Android TV / TV Box**
- Phát video YouTube chất lượng cao qua **YouTube IFrame Player API**
- Hiển thị overlay tên bài hát đang phát (tự ẩn sau 5 giây)
- Hỗ trợ **D-pad remote** và điều hướng bàn phím đầy đủ
- **Wake Lock** — màn hình Tivi luôn sáng khi đang phát nhạc
- Tự động lắng nghe kết nối từ điện thoại trên cổng `8080`

### 📱 Chế độ Điện Thoại (Phone Remote)
- **Premium Dark Mode** — giao diện tối ưu cho không gian phòng karaoke tối
- Tìm kiếm bài hát **không giới hạn**, không cần API Key
- Hàng đợi bài hát — **kéo thả đổi thứ tự**, vuốt trái để xóa
- Điều khiển phát nhạc: Play · Pause · Tua tới · Tua lùi · Chuyển bài
- **Thanh tiến trình thời gian thực** đồng bộ với TV mỗi 1 giây

### 🌐 Kết Nối Không Cấu Hình (Zero-Config)
| Phương thức | Mô tả |
|---|---|
| **mDNS (Bonjour)** | Điện thoại tự phát hiện TV trong mạng Wi-Fi — chỉ cần chọn và kết nối |
| **Smart Subnet Scan** | Dự phòng khi router chặn multicast — quét song song toàn dải `/24` trong ≈2 giây |

---

## 🚀 Cài Đặt Nhanh

### Yêu cầu thiết bị
- **Tivi**: Thiết bị Android TV / TV Box chạy Android 5.0+ với WebView
- **Điện thoại**: Android 5.0+ (điện thoại thông thường)
- **Mạng**: Cả hai thiết bị **phải cùng mạng Wi-Fi** nội bộ

### Bước 1: Tải APK
👉 **[Tải app-release.apk (v1.0.0 · 52.7 MB)](https://github.com/TrDuy-pan3000/YT-Control/releases/download/v1.0.0/app-release.apk)**

### Bước 2: Cài APK lên Tivi
```
1. Bật "Nguồn không xác định" trong Cài đặt → Bảo mật
2. Copy file APK vào USB → cắm vào Tivi → mở bằng File Manager
   HOẶC dùng ADB: adb install app-release.apk
3. Mở ứng dụng → chọn "CHẾ ĐỘ TIVI"
```

### Bước 3: Cài APK lên Điện thoại
```
1. Bật "Cài ứng dụng từ nguồn không xác định" trong Cài đặt
2. Tải APK → nhấn file → Cài đặt
3. Mở ứng dụng → chọn "ĐIỀU KHIỂN TỪ XA"
4. Ứng dụng tự tìm Tivi trong mạng và kết nối
```

---

## 🗂️ Cấu Trúc Mã Nguồn

```
lib/
├── main.dart                           # Đăng ký MultiProvider & Khởi chạy app
├── app.dart                            # MaterialApp, Premium Dark Theme
│
├── core/                               # ─── Lớp Nhân Dùng Chung ───
│   ├── constants/
│   │   ├── app_colors.dart             # Design Tokens hệ màu tối
│   │   ├── app_strings.dart            # Nhãn văn bản tiếng Việt
│   │   └── ws_protocol.dart            # Hằng số lệnh WebSocket Protocol
│   ├── models/
│   │   ├── song.dart                   # Model bài hát
│   │   └── ws_message.dart             # Model tin nhắn WebSocket
│   └── services/
│       ├── youtube_search_service.dart # Tìm kiếm YouTube (không cần API Key)
│       └── network_info_service.dart   # Lấy địa chỉ IP Wi-Fi nội bộ
│
├── tv/                                 # ─── Thành Phần Tivi ───
│   ├── screens/
│   │   ├── tv_waiting_screen.dart      # Màn hình chờ kết nối
│   │   └── tv_player_screen.dart       # Trình phát video YouTube
│   ├── services/
│   │   ├── ws_server_service.dart      # WebSocket Server (port 8080)
│   │   ├── tv_player_controller.dart   # Cầu nối Dart ↔ JS (IFrame API)
│   │   └── tv_wakelock_service.dart    # Giữ màn hình TV luôn sáng
│   └── widgets/
│       ├── tv_player_widget.dart       # InAppWebView + YouTube Player
│       └── tv_now_playing_overlay.dart # Overlay tên bài (tự ẩn 5s)
│
├── remote/                             # ─── Thành Phần Điện Thoại ───
│   ├── screens/
│   │   ├── remote_connect_screen.dart  # Kết nối Tivi (Auto/Manual)
│   │   └── remote_control_screen.dart  # Giao diện điều khiển chính
│   ├── services/
│   │   ├── ws_client_service.dart      # WebSocket Client (auto-reconnect)
│   │   ├── discovery_service.dart      # mDNS + Subnet Scanner
│   │   └── queue_manager.dart          # Quản lý hàng đợi (ChangeNotifier)
│   └── widgets/
│       ├── search_bar_widget.dart      # Thanh tìm kiếm + Toggle Karaoke
│       ├── search_results_widget.dart  # Kết quả + Shimmer skeleton
│       ├── queue_list_widget.dart      # Hàng đợi kéo thả & vuốt xóa
│       └── playback_controls.dart      # Panel điều khiển + Progress bar
│
└── mode_selection/
    └── mode_selection_screen.dart      # Màn hình chọn chế độ khởi động
```

---

## 🔌 Giao Thức WebSocket

Mọi liên lạc giữa Tivi và Điện thoại sử dụng **JSON qua WebSocket** theo giao thức sau:

```json
{
  "type": "COMMAND | EVENT | SYNC",
  "action": "tên_lệnh",
  "payload": { ... }
}
```

| # | Hướng | Loại | Action | Payload | Mô tả |
|---|-------|------|--------|---------|-------|
| 1 | 📱→📺 | `COMMAND` | `play_now` | `{videoId, title, channelName}` | Phát bài ngay |
| 2 | 📱→📺 | `COMMAND` | `pause` | — | Tạm dừng |
| 3 | 📱→📺 | `COMMAND` | `resume` | — | Tiếp tục phát |
| 4 | 📱→📺 | `COMMAND` | `seek_forward` | `{seconds: 10}` | Tua tới 10s |
| 5 | 📱→📺 | `COMMAND` | `seek_backward` | `{seconds: 10}` | Tua lùi 10s |
| 6 | 📱→📺 | `COMMAND` | `next` | `{videoId, title}` | Chuyển bài tiếp |
| 7 | 📺→📱 | `EVENT` | `video_ended` | — | Video đã kết thúc |
| 8 | 📺→📱 | `EVENT` | `video_error` | `{code, message}` | Lỗi phát video |
| 9 | 📺→📱 | `EVENT` | `connected` | — | Kết nối thành công |
| 10 | 📺→📱 | `SYNC` | `player_state` | `{state, position, duration}` | Đồng bộ mỗi 1s |

---

## 🛠️ Công Nghệ Sử Dụng

| Nhóm | Thư viện | Phiên bản | Vai trò |
|------|----------|-----------|---------|
| **Core** | Flutter / Dart | 3.44.0 / 3.x | Framework chính |
| **State** | `provider` | ^6.1.0 | Quản lý trạng thái |
| **Media** | `flutter_inappwebview` | ^6.0.0 | Phát YouTube IFrame |
| **Search** | `youtube_explode_dart` | ^3.1.0 | Tìm kiếm YouTube (no API key) |
| **Network** | `web_socket_channel` | ^3.0.0 | WebSocket Client |
| **Discovery** | `nsd` | ^3.0.0 | mDNS / Bonjour |
| **UI** | `google_fonts` | ^6.2.0 | Typography (Outfit, Inter) |
| **UI** | `shimmer` | ^3.0.0 | Skeleton loading |
| **UI** | `cached_network_image` | ^3.4.0 | Cache hình thumbnail |
| **UI** | `reorderables` | ^0.6.0 | Kéo thả hàng đợi |
| **System** | `wakelock_plus` | ^1.2.0 | Wake Lock màn hình |
| **System** | `network_info_plus` | ^6.0.0 | Lấy IP Wi-Fi nội bộ |

---

## 👨‍💻 Dành Cho Nhà Phát Triển

### Yêu cầu môi trường
- Flutter SDK `>=3.0.0`
- Android SDK (API 21+)
- Dart SDK `>=3.0.0 <4.0.0`

### Clone & Chạy thử
```bash
# Clone dự án
git clone https://github.com/TrDuy-pan3000/YT-Control.git
cd YT-Control

# Tải dependencies
flutter pub get

# Chạy trên thiết bị đã kết nối
flutter run
```

### Build APK Release
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Chạy Unit Tests
```bash
flutter test
# Kết quả: 7/7 tests passed ✅
```

---

## 📋 Lộ Trình Phát Triển

- [x] Chế độ TV Receiver với YouTube IFrame Player
- [x] Chế độ Phone Remote với giao diện Dark Mode
- [x] Kết nối Zero-Config (mDNS + Subnet Scanner)
- [x] Tìm kiếm YouTube không cần API Key
- [x] Hàng đợi bài hát kéo thả
- [x] Đồng bộ trạng thái realtime (1s)
- [ ] Xác thực phòng karaoke bằng mã PIN
- [ ] Tích hợp bộ chấm điểm karaoke
- [ ] Hỗ trợ nhiều điện thoại điều khiển 1 Tivi
- [ ] Xuất bản lên Google Play Store

---

## 📄 Giấy Phép

Dự án này được phân phối theo giấy phép **MIT**. Xem chi tiết tại file [LICENSE](LICENSE).

---

<div align="center">

Made with ❤️ in Vietnam · Powered by Flutter & YouTube

⭐ Nếu dự án hữu ích, hãy để lại một **Star** nhé!

</div>