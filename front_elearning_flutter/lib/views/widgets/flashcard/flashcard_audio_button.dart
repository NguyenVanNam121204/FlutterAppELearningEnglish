import 'package:flutter/material.dart';

class FlashcardAudioButton extends StatelessWidget {
  const FlashcardAudioButton({
    super.key,
    required this.onPressed,
    required this.isPlaying,
  });

  final VoidCallback onPressed;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFFACC15),
        foregroundColor: const Color(0xFF1F2937),
      ),
      tooltip: isPlaying ? 'Dừng phát âm' : 'Phát âm',
      onPressed: onPressed,
      icon: Icon(isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded),
    );
  }
}
