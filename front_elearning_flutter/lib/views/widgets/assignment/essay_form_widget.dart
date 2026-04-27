import 'package:flutter/material.dart';
import '../common/catalunya_card.dart';

class EssayFormWidget extends StatefulWidget {
  const EssayFormWidget({
    required this.instruction,
    required this.onOpenMenu,
    required this.onSubmit,
    this.audioUrl,
    this.imageUrl,
    this.isSubmitting = false,
    super.key,
  });

  final String instruction;
  final String? audioUrl;
  final String? imageUrl;
  final VoidCallback onOpenMenu;
  final Function(String) onSubmit;
  final bool isSubmitting;

  @override
  State<EssayFormWidget> createState() => _EssayFormWidgetState();
}

class _EssayFormWidgetState extends State<EssayFormWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        CatalunyaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hướng dẫn',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(widget.instruction),
              if (widget.audioUrl != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.audiotrack, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Có file âm thanh kèm theo'),
                    ],
                  ),
                ),
              ],
              if (widget.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          maxLines: 12,
          decoration: InputDecoration(
            labelText: 'Nội dung bài làm',
            alignLabelWithHint: true,
            hintText: 'Nhập nội dung bài tự luận của bạn tại đây...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF40C4D8), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: widget.onOpenMenu,
                icon: const Icon(Icons.menu),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: widget.isSubmitting
                      ? null
                      : () => widget.onSubmit(_controller.text),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF40C4D8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: widget.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Nộp bài',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
