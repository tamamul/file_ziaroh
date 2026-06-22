import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../constants.dart';
import '../models/upload_file.dart';
import 'package:intl/intl.dart';

class PreviewScreen extends StatefulWidget {
  final UploadFile file;
  final List<UploadFile> files;
  final int index;
  const PreviewScreen({super.key, required this.file, required this.files, required this.index});
  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late PageController _page;
  int _current = 0;
  VideoPlayerController? _vpCtrl;
  ChewieController? _chewieCtrl;
  bool _showInfo = true;

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
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.files[_current];
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.gold),
            onPressed: () => setState(() => _showInfo = !_showInfo),
          ),
        ],
      ),
      body: Stack(children: [
        // Media viewer
        PageView.builder(
          controller: _page,
          itemCount: widget.files.length,
          onPageChanged: (i) {
            setState(() => _current = i);
            _initMedia(widget.files[i]);
          },
          itemBuilder: (_, i) {
            final file = widget.files[i];
            if (file.isVideo && i == _current && _chewieCtrl != null) {
              return Center(child: Chewie(controller: _chewieCtrl!));
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
                const Text('🎬', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                const Text('Memuat video...', style: TextStyle(color: Colors.white70)),
              ]));
            }
          },
        ),

        // Info panel bawah
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

        // Counter
        Positioned(top: 100, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(12)),
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
