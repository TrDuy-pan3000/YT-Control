import 'package:flutter/foundation.dart';
import '../../core/models/song.dart';

class QueueManager extends ChangeNotifier {
  final List<Song> _queue = [];
  int _currentIndex = -1;

  // === Getters ===
  List<Song> get queue => List.unmodifiable(_queue);
  int get length => _queue.length;
  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;
  int get currentIndex => _currentIndex;
  
  Song? get currentSong => 
      (_currentIndex >= 0 && _currentIndex < _queue.length) 
      ? _queue[_currentIndex] : null;
      
  bool get hasNext => _currentIndex + 1 < _queue.length;
  bool get hasPrevious => _currentIndex > 0;

  /// Thêm bài vào cuối hàng đợi.
  /// Nếu queue trước đó rỗng → trả về true (nên autoplay bài này ngay).
  bool addToQueue(Song song) {
    _queue.add(song);
    final shouldAutoplay = _queue.length == 1 && _currentIndex == -1;
    if (shouldAutoplay) {
      _currentIndex = 0;
    }
    notifyListeners();
    return shouldAutoplay;
  }

  /// Xóa bài tại vị trí index
  void removeAt(int index) {
    if (index < 0 || index >= _queue.length) return;
    
    _queue.removeAt(index);
    
    // Điều chỉnh currentIndex nếu cần
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      if (_currentIndex >= _queue.length) {
        _currentIndex = _queue.length - 1;
      }
    }
    notifyListeners();
  }

  /// Kéo thả đổi thứ tự
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    if (newIndex < 0 || newIndex > _queue.length) return;

    if (oldIndex < newIndex) {
      newIndex--;
    }
    final song = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, song);

    // Cập nhật currentIndex nếu item đang phát bị di chuyển
    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    notifyListeners();
  }

  /// Chuyển bài tiếp theo
  Song? playNext() {
    if (!hasNext) return null;
    _currentIndex++;
    notifyListeners();
    return currentSong;
  }

  /// Quay lại bài trước
  Song? playPrevious() {
    if (!hasPrevious) return null;
    _currentIndex--;
    notifyListeners();
    return currentSong;
  }

  /// Phát một bài hát cụ thể trong queue bằng index
  void playSongAtIndex(int index) {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Xóa toàn bộ queue
  void clear() {
    _queue.clear();
    _currentIndex = -1;
    notifyListeners();
  }
}
