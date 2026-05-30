import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String keyword, bool karaokeMode) onSearch;
  
  const SearchBarWidget({Key? key, required this.onSearch}) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isKaraokeMode = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(_controller.text, _isKaraokeMode);
    });
  }

  void _onKaraokeModeChanged(bool val) {
    setState(() {
      _isKaraokeMode = val;
    });
    widget.onSearch(_controller.text, _isKaraokeMode);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: AppColors.background,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: AppColors.surfaceLight, width: 1.0),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Icon(Icons.search, color: AppColors.textSecondary),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: AppStrings.searchHint,
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: () {
                        _controller.clear();
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          // Toggle Karaoke
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppStrings.karaokeToggle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4.0),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: _isKaraokeMode,
                  onChanged: _onKaraokeModeChanged,
                  activeThumbColor: AppColors.primaryLight,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  inactiveThumbColor: AppColors.textMuted,
                  inactiveTrackColor: AppColors.surfaceLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
