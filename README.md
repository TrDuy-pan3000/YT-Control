 # 🎤 YT Karaoke — Ứng dụng Karaoke 2-in-1 (Tivi & Điện thoại)

> Ứng dụng Flutter duy nhất (1 APK) tích hợp cả hai chế độ: **Đầu thu Tivi (TV Receiver)** hiển thị video chất lượng cao và **Bộ điều khiển từ xa (Phone Remote)** trên điện thoại để tìm kiếm, chọn bài hát thời gian thực trên cùng mạng Wi-Fi.

---

## 🌟 Tính Năng Nổi Bật

*   **Chế độ TV Receiver**: Tối ưu hoàn toàn cho Android TV / TV Box với giao diện rộng rãi, hỗ trợ điều khiển D-pad, hiệu ứng bóng mờ (focus glow) và cơ chế tự động giữ màn hình luôn sáng (**Wake Lock**).
*   **Chế độ Phone Remote**: Giao diện tối ưu cho phòng tối (Premium Dark Mode), cảm ứng nhạy bén, các nút nhạc siêu lớn dễ thao tác.
*   **Kết nối không cấu hình (Zero-Config Connection)**:
    *   *Phương án 1 (mDNS)*: Điện thoại tự phát hiện TV trong mạng Wi-Fi và hiển thị danh sách kết nối tức thì.
    *   *Phương án 2 (Smart Scan Subnet - Fallback)*: Ping quét song song toàn bộ dải subnet `/24` trên cổng `8080` khi router chặn multicast. Tốc độ quét cực nhanh (2 giây), tìm thấy TV 100%.
*   **Tìm kiếm YouTube không cần API Key**: Tích hợp service tìm kiếm thông minh thông qua `youtube_explode_dart`, tự động lọc bỏ livestream, hỗ trợ chế độ tự động điền từ khóa *" karaoke"*.
*   **Đồng bộ hóa 1 Giây (Realtime Sync)**: TV gửi trạng thái phát thực tế (position, duration, play/pause) về điện thoại mỗi 1 giây để cập nhật thanh tiến trình.
*   **Hàng đợi bài hát thông minh**: Vuốt sang trái để xóa bài, kéo thả để đổi thứ tự ưu tiên hát (Reorderable). Tự động chuyển bài tiếp theo khi bài hát cũ kết thúc hoặc bỏ qua khi video lỗi.

---

## 📦 Tải Xuống & Cài Đặt Ngay (Direct Download APK)

Sau khi biên dịch thành công, tệp tin APK tối ưu hóa cực kỳ nhẹ (< 20 MB) sẽ được tạo ra tại thư mục build. Bạn có thể cài đặt trực tiếp lên thiết bị Android của mình thông qua đường dẫn:

👉 **[Tải xuống APK Karaoke 2-in-1 (Bản Release)](file:///e:/YT-control/build/app/outputs/flutter-apk/app-release.apk)** *(Đường dẫn cục bộ sau khi build)*

---

## 📐 Cấu Trúc Mã Nguồn Chuẩn Hóa

Mã nguồn được tổ chức khoa học theo mô hình phân lớp rõ ràng để dễ dàng bảo trì và mở rộng:

```
lib/
├── main.dart                                    # Đăng ký MultiProvider & Khởi chạy ứng dụng
├── app.dart                                     # Cấu hình MaterialApp, Premium Dark Theme
│
├── core/                                        # Lớp nhân dùng chung (Shared Core)
│   ├── constants/
│   │   ├── app_colors.dart                      # Design tokens hệ màu tối
│   │   ├── app_strings.dart                     # Các nhãn văn bản tiếng Việt
│   │   └── ws_protocol.dart                     # Hằng số giao thức lệnh WebSocket
│   ├── models/
│   │   ├── song.dart                            # Model bài hát (Song)
│   │   └── ws_message.dart                      # Model tin nhắn WebSocket (WsMessage)
│   └── services/
│       ├── youtube_search_service.dart          # Service tìm kiếm YouTube
│       └── network_info_service.dart            # Utility lấy IP Wi-Fi nội bộ
│
├── tv/                                          # Thành phần Tivi (TV Side)
│   ├── screens/
│   │   ├── tv_waiting_screen.dart               # Chờ kết nối (Khởi tạo server + mDNS)
│   │   └── tv_player_screen.dart                # Trình phát video YouTube và nối dây logic
│   ├── services/
│   │   ├── ws_server_service.dart               # WebSocket Server chạy trên TV (port 8080)
│   │   ├── tv_player_controller.dart            # Cầu nối Dart-JS điều khiển IFrame Player
│   │   └── tv_wakelock_service.dart             # Giữ TV luôn sáng (Wakelock)
│   └── widgets/
│       ├── tv_player_widget.dart                # InAppWebView nhúng YouTube IFrame Player API
│       └── tv_now_playing_overlay.dart          # Lớp phủ báo tên bài hát (tự ẩn sau 5 giây)
│
└── remote/                                      # Thành phần Điện thoại (Phone Side)
    ├── screens/
    │   ├── remote_connect_screen.dart           # Kết nối tivi (Auto-discovery / Nhập IP)
    │   └── remote_control_screen.dart           # Giao diện điều khiển chính (Search, Queue, Player Controls)
    ├── services/
    │   ├── ws_client_service.dart               # WebSocket Client trên Phone (Auto-reconnect)
    │   ├── discovery_service.dart               # Service tìm kiếm TV trong Wi-Fi
    │   └── queue_manager.dart                   # Trình quản lý hàng đợi bài hát (ChangeNotifier)
    └── widgets/
        ├── search_bar_widget.dart               # Thanh tìm kiếm + Toggle chế độ Karaoke
        ├── search_results_widget.dart           # Kết quả tìm kiếm + Shimmer skeleton loading
        ├── queue_list_widget.dart               # Hàng đợi nhạc kéo thả reorder & vuốt xóa
        └── playback_controls.dart               # Panel điều khiển lớn + Realtime progress bar
```

---

## ⚡ Hướng Dẫn Vận Hành & Biên Dịch (Dành Cho Nhà Phát Triển)

Để chạy thử nghiệm ứng dụng trực tiếp từ mã nguồn, bạn hãy làm theo các bước sau:

### 1. Tải các gói thư viện
Mở Terminal trong thư mục dự án và chạy:
```bash
flutter pub get
```

### 2. Khởi chạy ứng dụng
*   **Khởi chạy trên Android TV / Giả lập TV**:
    ```bash
    flutter run -d <tivi_device_id>
    ```
    *Chọn **CHẾ ĐỘ TIVI** trên màn hình chính.*
*   **Khởi chạy trên Điện thoại / Giả lập Phone**:
    ```bash
    flutter run -d <phone_device_id>
    ```
    *Chọn **ĐIỀU KHIỂN TỪ XA** trên màn hình chính và kết nối tới TV.*

### 3. Biên dịch bản Release APK cực nhẹ
```bash
flutter build apk --release
```
*Tệp APK đầu ra sẽ nằm tại: `build/app/outputs/flutter-apk/app-release.apk`*

---

## 🤝 Giao Thức Điều Khiển WebSocket (WebSocket Protocol)

| # | Hướng Gửi | Loại | Lệnh (Action) | Payload ví dụ | Mô tả |
|---|-----------|------|---------------|---------------|-------|
| 1 | Remote → TV | `COMMAND` | `play_now` | `{videoId, title, channelName}` | Phát bài hát ngay |
| 2 | Remote → TV | `COMMAND` | `pause` | – | Tạm dừng video |
| 3 | Remote → TV | `COMMAND` | `resume` | – | Tiếp tục phát video |
| 4 | Remote → TV | `COMMAND` | `seek_forward` | `{seconds: 10}` | Tua tới 10 giây |
| 5 | Remote → TV | `COMMAND` | `seek_backward` | `{seconds: 10}` | Tua lùi 10 giây |
| 6 | Remote → TV | `COMMAND` | `next` | `{videoId, title}` | Chuyển sang bài tiếp theo |
| 7 | TV → Remote | `EVENT` | `video_ended` | – | Thông báo video đã kết thúc |
| 8 | TV → Remote | `EVENT` | `video_error` | `{code: "101", message: "..."}` | Thông báo lỗi phát video |
| 9 | TV → Remote | `EVENT` | `connected` | – | Xác nhận kết nối thành công |
| 10 | TV → Remote | `SYNC` | `player_state` | `{state: "playing", position: 120, duration: 270}` | Đồng bộ thời lượng mỗi 1s |

---

## 🛠️ Công Nghệ Sử Dụng

*   **Framework**: Flutter & Dart (Null-safety)
*   **State Management**: Provider & ChangeNotifier
*   **Network & Discovery**: `dart:io` (WebSocket Server), `web_socket_channel` (Client), `nsd` (mDNS)
*   **Media**: `flutter_inappwebview` & YouTube IFrame Player API
*   **UI/UX**: `google_fonts` (Outfit/Inter), `shimmer`, `cached_network_image`, `reorderables`
*   **System Tools**: `wakelock_plus` (Wake Lock), `network_info_plus` (Wi-Fi IP Utility)
#   Y T - C o n t r o l  
 