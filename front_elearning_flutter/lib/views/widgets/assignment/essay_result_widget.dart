import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/assignment/assignment_models.dart';
import '../common/catalunya_card.dart';

class EssayResultWidget extends StatelessWidget {
  const EssayResultWidget({
    required this.submission,
    required this.instruction,
    required this.onBack,
    this.audioUrl,
    this.imageUrl,
    super.key,
  });

  final EssaySubmissionModel submission;
  final String instruction;
  final String? audioUrl;
  final String? imageUrl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final themeColor = submission.isGraded
        ? const Color(0xFF10B981)
        : const Color(0xFF3B82F6);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Status Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: themeColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(
                submission.isGraded
                    ? Icons.verified_rounded
                    : Icons.pending_actions_rounded,
                color: themeColor,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission.isGraded
                          ? 'Đã hoàn thành & Chấm điểm'
                          : 'Đã nộp bài',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: themeColor,
                      ),
                    ),
                    Text(
                      submission.isGraded
                          ? 'Giáo viên đã đánh giá bài làm của bạn'
                          : 'Vui lòng chờ giáo viên chấm điểm',
                      style: TextStyle(
                        fontSize: 13,
                        color: themeColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Score Section (if graded)
        if (submission.isGraded) ...[
          Center(
            child: Column(
              children: [
                const Text(
                  'ĐIỂM CỦA BẠN',
                  style: TextStyle(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  submission.score!,
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Instruction (Collapsed)
        _SectionTitle(title: 'Đề bài & Hướng dẫn'),
        CatalunyaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instruction,
                style: const TextStyle(color: Colors.black87),
              ),
              if (audioUrl != null) ...[
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
              if (imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // User Submission
        _SectionTitle(title: 'Bài làm của bạn'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                submission.textContent.isNotEmpty
                    ? submission.textContent
                    : '(Không có nội dung văn bản)',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF334155),
                ),
              ),
              if (submission.attachmentUrl != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'FILE ĐÍNH KÈM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final fullUrl = submission.fullAttachmentUrl;
                    if (fullUrl == null) return;
                    
                    final url = Uri.parse(fullUrl);
                    try {
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        // Fallback to internal browser if external fails
                        await launchUrl(url, mode: LaunchMode.platformDefault);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi khi mở file: $e')),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined,
                            color: Color(0xFF475569)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Xem bài làm file đính kèm',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        Icon(Icons.open_in_new_rounded,
                            size: 18, color: Colors.blue.shade600),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Teacher Comment (if graded)
        if (submission.isGraded && submission.feedback != null) ...[
          _SectionTitle(title: 'Nhận xét của giáo viên'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              submission.feedback!,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFF40C4D8)),
              foregroundColor: const Color(0xFF40C4D8),
            ),
            child: const Text(
              'Quay lại',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
