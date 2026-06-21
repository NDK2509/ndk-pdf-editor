import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StudyTimerWidget extends StatefulWidget {
  const StudyTimerWidget({super.key});

  @override
  State<StudyTimerWidget> createState() => _StudyTimerWidgetState();
}

class _StudyTimerWidgetState extends State<StudyTimerWidget> {
  Timer? _timer;
  int _durationSeconds = 25 * 60; // 25 mins default
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isMinimized = false;

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _stopTimer();
        _showTimeUpDialog();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _durationSeconds;
    });
  }

  void _adjustTime(int minutes) {
    setState(() {
      final newDuration = (_durationSeconds + minutes * 60).clamp(60, 180 * 60);
      _durationSeconds = newDuration;
      if (!_isRunning) {
        _remainingSeconds = newDuration;
      } else {
        _remainingSeconds = (_remainingSeconds + minutes * 60).clamp(0, newDuration);
      }
    });
  }

  void _setPreset(int minutes) {
    setState(() {
      _durationSeconds = minutes * 60;
      _remainingSeconds = _durationSeconds;
      if (_isRunning) {
        _pauseTimer();
      }
    });
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: const Row(
          children: [
            Icon(Icons.timer_outlined, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Study Session Finished', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Well done! You have completed your study interval. Take a short break!',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isMinimized) {
      return _buildMinimizedWidget();
    }
    return _buildExpandedWidget();
  }

  Widget _buildMinimizedWidget() {
    return GestureDetector(
      onTap: () => setState(() => _isMinimized = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 1.5),
          boxShadow: AppTheme.glowPrimary,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isRunning ? Icons.timer_rounded : Icons.timer_outlined,
              color: AppTheme.primary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _formatTime(_remainingSeconds),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedWidget() {
    final progress = _durationSeconds > 0 ? _remainingSeconds / _durationSeconds : 0.0;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.2)),
        boxShadow: AppTheme.elevation2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRunning ? Colors.green : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'STUDY TIMER',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.minimize_rounded, size: 14, color: AppTheme.textSecondary),
                onPressed: () => setState(() => _isMinimized = true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Timer display
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: AppTheme.surfaceMid,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Quick adjustments (+/- 5 min)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _adjustButton(text: '-5m', onTap: () => _adjustTime(-5)),
              _adjustButton(text: '+5m', onTap: () => _adjustTime(5)),
            ],
          ),
          const SizedBox(height: 8),
          // Play/Pause / Stop Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  _isRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                  size: 32,
                  color: _isRunning ? Colors.orange : AppTheme.primary,
                ),
                onPressed: _isRunning ? _pauseTimer : _startTimer,
              ),
              IconButton(
                icon: const Icon(Icons.stop_circle_rounded, size: 32, color: AppTheme.textSecondary),
                onPressed: _stopTimer,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 8),
          // Preset selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _presetChip(label: '25m', minutes: 25),
              _presetChip(label: '50m', minutes: 50),
              _presetChip(label: '15m', minutes: 15),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adjustButton({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMid,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          text,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _presetChip({required String label, required int minutes}) {
    final isCurrentPreset = _durationSeconds == minutes * 60;
    return GestureDetector(
      onTap: () => _setPreset(minutes),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrentPreset ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCurrentPreset ? AppTheme.primary : Colors.white12,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isCurrentPreset ? AppTheme.primary : AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
