import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/upload_file.dart';
import '../services/api_service.dart';

class PreviewScreen extends StatefulWidget {
  final UploadFile file;
  final List<UploadFile> files;
  final int index;
  final void Function(int id)? onDelete;
  final void Function(int id, String name)? onRename;

  const PreviewScreen({
    super.key,
    required this.file,
    required this.files,
    required this.index,
    this.onDelete,
    this.onRename,
  });
  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late PageController _page;
  int _current = 0;
  VideoPlayerController? _vpCtrl;
  ChewieController? _chewieCtrl;
  bool _showInfo = true;
  bool _videoLoading = false;

  @override
  void initState() {
    super.initState();
    _current = widget.index;
    _page = PageController(initialPage: widget.index);
    _initMedia(widget.files[widget.index]);
  }

  @override
  void dispose() {
    _disposeVideo();
    _page.dispose();
    super.dispose();
  }

  void _disposeVideo() {
    _chewieCtrl?.dispose();
    _vpCtrl?.dispose();
    _chewieCtrl = null;
    _vpCtrl = null;
  }

  Future<void> _initMedia(UploadFile f) async {
    _disposeVideo();
    if (f.isVideo) {
      setState(() => _videoLoading = true);
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(f.url));
      await ctrl.initialize();
      if (mounted) {
        setState(() {
          _vpCtrl = ctrl;
          _chewieCtrl = ChewieController(
            videoPlayerController: ctrl,
            autoPlay: true,
            looping: false,
            allowFullScreen: true,
            materialProgressColors: ChewieProgressColors(
              playedColor: AppTheme.gold,
              handleColor: AppTheme.goldLight,
              backgroundColor: AppTheme.greenMid,
              bufferedColor: AppTheme.greenRim,
            ),
          );
          _videoLoading = false;
        });
      }
    }
  }

  UploadFile get _currentFile => widget.files[_current];

  // ── Hapus dari preview ────────────────────────────────────────────
  Future<void> _delete() async {
    final f = _currentFile;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.greenCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.red)),
        title: const Text('Hapus File?', style: TextStyle(color: Colors.white)),
        content: Text(f.filenameOri, style: const TextStyle(color: AppTheme.goldLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final success = await ApiService.deleteFile(f.id);
    if (!mounted) return;
    if (success) {
      widget.onDelete?.call(f.id);
      if (widget.files.length <= 1) {
        Navigator.pop(context);
      } else {
        widget.files.removeAt(_current);
        if (_current >= widget.files.length) {
          setState(() => _current = widget.files.length - 1);
          _page.jumpToPage(_current);
        } else {
          setState(() {});
          _initMedia(widget.files[_current]);
        }
      }
      _showSnack('File dihapus');
    } else {
      _showSnack('Gagal menghapus', error: true);
    }
  }

  // ── Rename dari preview ───────────────────────────────────────────
  Future<void> _rename() async {
    final f = _currentFile;
    final ctrl = TextEditingController(text: f.filenameOri);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.greenCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.gold)),
        title: const Text('Rename File', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nama baru',
            filled: true, fillColor: AppTheme.greenMid,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.greenRim)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gold)),
            labelStyle: const TextStyle(color: Color(0xFF5A8A6A)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Simpan')),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || result.isEmpty || result == f.filenameOri || !mounted) return;

    final newName = await ApiService.renameFile(f.id, result);
    if (!mounted) return;
    if (newName != null) {
      setState(() => widget.files[_current].filenameOri = newName);
      widget.onRename?.call(f.id, newName);
      _showSnack('Nama diubah');
    } else {
      _showSnack('Gagal rename', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade800 : AppTheme.greenMid,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showOptions() => showModalBottomSheet(
    context: context, backgroundColor: AppTheme.greenCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: AppTheme.greenRim, borderRadius: BorderRadius.circular(2))),
      ListTile(
        leading: const Icon(Icons.drive_file_rename_outline, color: AppTheme.gold),
        title: const Text('Rename', style: TextStyle(color: Colors.white)),
        onTap: () { Navigator.pop(context); _rename(); },
      ),
      ListTile(
        leading: const Icon(Icons.refresh, color: Colors.blue),
        title: const Text('Hapus Cache Thumbnail', style: TextStyle(color: Colors.white)),
        onTap: () async {
          Navigator.pop(context);
          await ApiService.clearCacheOne(_currentFile.id);
          _showSnack('Cache dihapus');
        },
      ),
      ListTile(
        leading: const Icon(Icons.delete_outline, color: Colors.red),
        title: const Text('Hapus File', style: TextStyle(color: Colors.red)),
        onTap: () { Navigator.pop(context); _delete(); },
      ),
      const SizedBox(height: 8),
    ])),
  );

  @override
  Widget build(BuildContext context) {
    final f = _currentFile;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black38,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.gold),
            onPressed: _showOptions,
          ),
          IconButton(
            icon: Icon(_showInfo ? Icons.info : Icons.info_outline, color: AppTheme.gold),
            onPressed: () => setState(() => _showInfo = !_showInfo),
          ),
        ],
      ),
      body: Stack(children: [
        // ── Media PageView ──
        PageView.builder(
          controller: _page,
          itemCount: widget.files.length,
          onPageChanged: (i) {
            setState(() => _current = i);
            _initMedia(widget.files[i]);
          },
          itemBuilder: (_, i) {
            final file = widget.files[i];
            if (file.isVideo && i == _current) {
              if (_videoLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
              if (_chewieCtrl != null) return Center(child: Chewie(controller: _chewieCtrl!));
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('🎬', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                const Text('Memuat video...', style: TextStyle(color: Colors.white70)),
              ]));
            } else if (file.isPhoto) {
              return InteractiveViewer(
                minScale: 0.5, maxScale: 4.0,
                child: Center(child: CachedNetworkImage(
                  imageUrl: file.url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
                  errorWidget: (_, __, ___) => const Center(child: Text('📷', style: TextStyle(fontSize: 48))),
                )),
              );
            } else {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(file.isVideo ? '🎬' : '📄', style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text('Geser untuk navigasi', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ]));
            }
          },
        ),

        // ── Info panel ──
        if (_showInfo)
          Positioned(left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.filenameOri,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 2),
                const SizedBox(height: 6),
                Row(children: [
                  _tag(f.divisi, AppTheme.gold),
                  const SizedBox(width: 8),
                  _tag(f.filetype, AppTheme.greenRim),
                  const Spacer(),
                  Text(f.filesizeFmt, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.person_outline, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text(f.nama, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  Text(DateFormat('dd MMM yyyy, HH:mm').format(f.createdAt),
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ]),
                if (f.keterangan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(f.keterangan, style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)),
                ],
              ]),
            ),
          ),

        // ── Counter ──
        Positioned(top: 100, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
            child: Text('${_current + 1} / ${widget.files.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          )),
      ]),
    );
  }

  Widget _tag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
  );
}
