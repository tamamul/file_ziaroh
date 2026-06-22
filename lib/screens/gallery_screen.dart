import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/upload_file.dart';
import '../services/api_service.dart';
import '../widgets/app_widgets.dart';
import 'preview_screen.dart';

class GalleryScreen extends StatefulWidget {
  final bool myFilesOnly;
  final String? myNama;
  const GalleryScreen({super.key, this.myFilesOnly = false, this.myNama});
  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<UploadFile> _files = [];
  bool _loading = true;
  bool _loadingMore = false;
  String _filterDivisi = '';
  String _filterTipe = '';
  String _filterNama = '';
  final int _limit = 30;
  int _offset = 0;
  bool _hasMore = true;
  final _scroll = ScrollController();
  UploadStats? _stats;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(reset: true);
    if (!widget.myFilesOnly) _loadStats();
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300 && !_loadingMore && _hasMore) {
      _load();
    }
  }

  Future<void> _loadStats() async {
    final s = await ApiService.getStats();
    if (mounted) setState(() => _stats = s);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() { _loading = true; _offset = 0; _files = []; _hasMore = true; });
    } else {
      if (!_hasMore || _loadingMore) return;
      setState(() => _loadingMore = true);
    }

    final result = await ApiService.getFiles(
      nama: widget.myFilesOnly ? widget.myNama : (_filterNama.isEmpty ? null : _filterNama),
      divisi: _filterDivisi.isEmpty ? null : _filterDivisi,
      tipe: _filterTipe.isEmpty ? null : _filterTipe,
      limit: _limit, offset: _offset,
    );

    if (mounted) {
      setState(() {
        _files.addAll(result);
        _offset += result.length;
        _hasMore = result.length >= _limit;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  // ── Delete dengan konfirmasi ──────────────────────────────────────
  Future<void> _confirmDelete(UploadFile f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.greenCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.red)),
        title: const Text('Hapus File?', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.filenameOri, style: const TextStyle(color: AppTheme.goldLight, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('File akan dihapus permanen dari server.', style: TextStyle(color: Color(0xFF5A8A6A), fontSize: 13)),
        ]),
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
    if (ok != true) return;

    _showSnack('Menghapus...', loading: true);
    final success = await ApiService.deleteFile(f.id);
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      if (success) {
        setState(() => _files.removeWhere((e) => e.id == f.id));
        _loadStats();
        _showSnack('File berhasil dihapus');
      } else {
        _showSnack('Gagal menghapus file', error: true);
      }
    }
  }

  // ── Rename dialog ─────────────────────────────────────────────────
  Future<void> _showRename(UploadFile f) async {
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
          decoration: InputDecoration(
            labelText: 'Nama baru',
            filled: true,
            fillColor: AppTheme.greenMid,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.greenRim)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gold)),
            labelStyle: const TextStyle(color: Color(0xFF5A8A6A)),
          ),
          autofocus: true,
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
    if (result == null || result.isEmpty || result == f.filenameOri) return;

    final newName = await ApiService.renameFile(f.id, result);
    if (mounted) {
      if (newName != null) {
        setState(() {
          final idx = _files.indexWhere((e) => e.id == f.id);
          if (idx != -1) _files[idx].filenameOri = newName;
        });
        _showSnack('Nama berhasil diubah');
      } else {
        _showSnack('Gagal mengubah nama', error: true);
      }
    }
  }

  // ── File option bottom sheet (long press) ─────────────────────────
  void _showFileOptions(UploadFile f) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.greenCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: AppTheme.greenRim, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Text(f.isPhoto ? '📷' : '🎬', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text(f.filenameOri,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ),
        const Divider(color: Color(0xFF2D5A3D), height: 16),
        ListTile(
          leading: const Icon(Icons.drive_file_rename_outline, color: AppTheme.gold),
          title: const Text('Rename', style: TextStyle(color: Colors.white)),
          onTap: () { Navigator.pop(context); _showRename(f); },
        ),
        ListTile(
          leading: const Icon(Icons.refresh, color: Colors.blue),
          title: const Text('Hapus Cache Thumbnail', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Re-generate thumbnail', style: TextStyle(color: Color(0xFF5A8A6A), fontSize: 11)),
          onTap: () async {
            Navigator.pop(context);
            await ApiService.clearCacheOne(f.id);
            _showSnack('Cache dihapus, thumbnail akan di-generate ulang');
            _load(reset: true);
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Hapus File', style: TextStyle(color: Colors.red)),
          onTap: () { Navigator.pop(context); _confirmDelete(f); },
        ),
        const SizedBox(height: 8),
      ])),
    );
  }

  // ── Clear all cache ───────────────────────────────────────────────
  Future<void> _clearAllCache() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.greenCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.gold)),
        title: const Text('Hapus Semua Cache?', style: TextStyle(color: Colors.white)),
        content: const Text('Semua thumbnail akan dihapus dan di-generate ulang saat dibuka.',
          style: TextStyle(color: Color(0xFF5A8A6A))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.white70))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Cache')),
        ],
      ),
    );
    if (ok != true) return;
    final msg = await ApiService.clearCache();
    if (mounted) {
      _showSnack(msg);
      _load(reset: true);
    }
  }

  void _showSnack(String msg, {bool error = false, bool loading = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        if (loading) const SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        if (loading) const SizedBox(width: 10),
        Text(msg),
      ]),
      backgroundColor: error ? Colors.red.shade800 : AppTheme.greenMid,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: Duration(seconds: loading ? 10 : 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.gold,
        backgroundColor: AppTheme.greenCard,
        onRefresh: () => _load(reset: true),
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            // Stats hanya di Galeri Tim
            if (!widget.myFilesOnly && _stats != null)
              SliverToBoxAdapter(child: _buildStats()),

            // Filter
            SliverToBoxAdapter(child: _buildFilter()),

            // Grid
            if (_loading)
              const SliverFillRemaining(child: Center(
                child: CircularProgressIndicator(color: AppTheme.gold)))
            else if (_files.isEmpty)
              SliverFillRemaining(child: EmptyState(
                emoji: '📂',
                title: widget.myFilesOnly ? 'Belum ada upload' : 'Belum ada file',
                subtitle: widget.myFilesOnly ? 'File yang kamu upload akan muncul di sini' : 'Tarik untuk refresh'))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      if (i == _files.length) {
                        return _loadingMore
                          ? const Center(child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(color: AppTheme.gold, strokeWidth: 2)))
                          : const SizedBox();
                      }
                      return FileCard(
                        file: _files[i],
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PreviewScreen(
                            file: _files[i], files: _files, index: i,
                            onDelete: (id) {
                              setState(() => _files.removeWhere((e) => e.id == id));
                              _loadStats();
                            },
                            onRename: (id, name) {
                              setState(() {
                                final idx = _files.indexWhere((e) => e.id == id);
                                if (idx != -1) _files[idx].filenameOri = name;
                              });
                            },
                          ))),
                        onLongPress: () => _showFileOptions(_files[i]),
                      );
                    },
                    childCount: _files.length + (_loadingMore ? 1 : 0),
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 0.72,
                    crossAxisSpacing: 10, mainAxisSpacing: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
      // FAB clear cache (hanya Galeri Tim)
      floatingActionButton: !widget.myFilesOnly ? FloatingActionButton.small(
        onPressed: _clearAllCache,
        backgroundColor: AppTheme.greenMid,
        foregroundColor: AppTheme.gold,
        tooltip: 'Hapus semua cache thumbnail',
        child: const Icon(Icons.cleaning_services_outlined),
      ) : null,
    );
  }

  Widget _buildStats() {
    final s = _stats!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GridView.count(
          crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.0,
          children: [
            StatCard(emoji: '📁', label: 'Total', value: '${s.total}'),
            StatCard(emoji: '📷', label: 'Foto', value: '${s.foto}'),
            StatCard(emoji: '🎬', label: 'Video', value: '${s.video}'),
            StatCard(emoji: '👥', label: 'Tim', value: '${s.pengirim}'),
          ],
        ),
        const SizedBox(height: 10),
        if (s.rekap.isNotEmpty) ...[
          const Text('Per Divisi:', style: TextStyle(color: AppTheme.goldLight, fontSize: 12)),
          const SizedBox(height: 6),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
            children: s.rekap.map((r) => Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.greenMid,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.greenRim),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(r['divisi'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Text('${r['jml']}', style: const TextStyle(color: AppTheme.gold, fontSize: 10))),
              ]),
            )).toList(),
          )),
        ],
      ]),
    );
  }

  Widget _buildFilter() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
    child: Column(children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
        children: [
          DivisiChip(label: 'Semua', selected: _filterTipe.isEmpty,
            onTap: () { setState(() => _filterTipe = ''); _load(reset: true); }),
          const SizedBox(width: 8),
          DivisiChip(label: '📷 Foto', selected: _filterTipe == 'foto',
            onTap: () { setState(() => _filterTipe = 'foto'); _load(reset: true); }),
          const SizedBox(width: 8),
          DivisiChip(label: '🎬 Video', selected: _filterTipe == 'video',
            onTap: () { setState(() => _filterTipe = 'video'); _load(reset: true); }),
          if (!widget.myFilesOnly && _stats != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showPengirimFilter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _filterNama.isNotEmpty ? AppTheme.gold.withOpacity(0.2) : AppTheme.greenMid,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _filterNama.isNotEmpty ? AppTheme.gold : AppTheme.greenRim),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    _filterNama.isEmpty ? '👤 Pengirim' : '👤 $_filterNama',
                    style: TextStyle(
                      color: _filterNama.isNotEmpty ? AppTheme.goldLight : Colors.white70,
                      fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: AppTheme.greenRim, size: 16),
                ]),
              ),
            ),
          ],
        ],
      )),
      if (!widget.myFilesOnly && _stats != null) ...[
        const SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
          children: [
            DivisiChip(label: 'Semua Divisi', selected: _filterDivisi.isEmpty,
              onTap: () { setState(() => _filterDivisi = ''); _load(reset: true); }),
            ...(_stats!.rekap.map((r) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: DivisiChip(
                label: r['divisi'],
                selected: _filterDivisi == r['divisi'],
                onTap: () { setState(() => _filterDivisi = r['divisi']); _load(reset: true); }),
            ))),
          ],
        )),
      ],
    ]),
  );

  void _showPengirimFilter() => showModalBottomSheet(
    context: context, backgroundColor: AppTheme.greenCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: AppTheme.greenRim, borderRadius: BorderRadius.circular(2))),
      const Text('Filter Pengirim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      ListTile(
        leading: const Text('👥', style: TextStyle(fontSize: 20)),
        title: const Text('Semua Pengirim', style: TextStyle(color: Colors.white)),
        onTap: () { Navigator.pop(context); setState(() => _filterNama = ''); _load(reset: true); },
      ),
      ...(_stats?.pengirimList ?? []).map((n) => ListTile(
        leading: const Text('👤', style: TextStyle(fontSize: 20)),
        title: Text(n, style: const TextStyle(color: Colors.white)),
        trailing: _filterNama == n ? const Icon(Icons.check, color: AppTheme.gold) : null,
        onTap: () { Navigator.pop(context); setState(() => _filterNama = n); _load(reset: true); },
      )),
      const SizedBox(height: 8),
    ]),
  );
}
