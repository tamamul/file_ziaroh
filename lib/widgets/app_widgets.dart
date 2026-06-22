import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants.dart';
import '../models/upload_file.dart';

class GoldDivider extends StatelessWidget {
  const GoldDivider({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [
        Colors.transparent, AppTheme.gold, Colors.transparent,
      ]),
    ),
  );
}

class StatCard extends StatelessWidget {
  final String emoji, label, value;
  const StatCard({super.key, required this.emoji, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.greenCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.greenRim.withOpacity(0.5)),
    ),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label, style: const TextStyle(color: Color(0xFF5A8A6A), fontSize: 11)),
    ]),
  );
}

class DivisiChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const DivisiChip({super.key, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? AppTheme.gold.withOpacity(0.2) : AppTheme.greenMid,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppTheme.gold : AppTheme.greenRim),
      ),
      child: Text(label, style: TextStyle(
        color: selected ? AppTheme.goldLight : Colors.white70,
        fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      )),
    ),
  );
}

class FileCard extends StatelessWidget {
  final UploadFile file;
  final VoidCallback onTap;
  const FileCard({super.key, required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: AppTheme.greenCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.greenRim.withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Thumbnail
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Stack(fit: StackFit.expand, children: [
              if (file.isPhoto)
                CachedNetworkImage(
                  imageUrl: file.url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.greenMid,
                    child: const Center(child: CircularProgressIndicator(color: AppTheme.gold, strokeWidth: 2))),
                  errorWidget: (_, __, ___) => Container(color: AppTheme.greenMid,
                    child: const Center(child: Text('📷', style: TextStyle(fontSize: 28)))),
                )
              else
                Container(color: AppTheme.greenMid,
                  child: const Center(child: Text('🎬', style: TextStyle(fontSize: 28)))),
              if (file.isVideo)
                Center(child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.gold, width: 1.5),
                  ),
                  child: const Icon(Icons.play_arrow, color: AppTheme.gold, size: 20),
                )),
            ]),
          ),
        ),
        // Info
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(file.filenameOri,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(file.divisi, style: const TextStyle(color: AppTheme.gold, fontSize: 9)),
              ),
              const Spacer(),
              Text(file.filesizeFmt, style: const TextStyle(color: Color(0xFF5A8A6A), fontSize: 9)),
            ]),
            const SizedBox(height: 2),
            Text(file.nama, style: const TextStyle(color: Color(0xFF5A8A6A), fontSize: 10),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String emoji, title, subtitle;
  const EmptyState({super.key, required this.emoji, required this.title, this.subtitle = ''});
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(emoji, style: const TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
      if (subtitle.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Color(0xFF5A8A6A), fontSize: 13), textAlign: TextAlign.center),
      ],
    ],
  ));
}
