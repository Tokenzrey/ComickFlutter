import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChapterListItem extends StatelessWidget {
  final int index;
  final Map<String, dynamic> chapter;
  final VoidCallback onTap;

  const ChapterListItem({
    super.key,
    required this.index,
    required this.chapter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String title = chapter['title'] ?? 'Chapter ${chapter['number']}';
    final DateTime? uploadDate = chapter['upload_date'] != null
        ? DateTime.tryParse(chapter['upload_date'])
        : null;
    final String formattedDate = uploadDate != null
        ? DateFormat('MMM dd, yyyy').format(uploadDate)
        : 'Unknown date';
    final bool isRead = chapter['is_read'] ?? false;

    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          color: isRead ? Colors.grey : null,
        ),
      ),
      subtitle: Text(formattedDate),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRead)
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
          if (chapter['is_downloaded'] == true)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.download_done, color: Colors.blue, size: 16),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
