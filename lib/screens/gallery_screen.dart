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
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 && !_loadingMore && _hasMore) {
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
            // Stats (hanya di tab Galeri Tim)
            if (!widget.myFilesOnly && _stats != null)
              SliverToBoxAdapter(child: _buildStats()),

            // Filter bar
            SliverToBoxAdapter(child: _buildFilter()),

            // Grid
            if (_loading)
              const SliverFillRemaining(child: Center(
                child: CircularProgressIndicator(color: AppTheme.gold)))
            else if (_files.isEmpty)
              const SliverFillRemaining(child: EmptyState(
                emoji: '📂', title: 'Belum ada file',
                subtitle: 'File yang diupload akan muncul di sini'))
            else
              SliverPadding(
                padding: const EdgeInsets.all(12),
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
                          builder: (_) => PreviewScreen(file: _files[i], files: _files, index: i))),
                      );
                    },
                    childCount: _files.length + (_loadingMore ? 1 : 0),
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10, mainAxisSpacing: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final s = _stats!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GridView.count(
          crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.9,
          children: [
            StatCard(emoji: '📁', label: 'Total', value: '${s.total}'),
            StatCard(emoji: '📷', label: 'Foto', value: '${s.foto}'),
            StatCard(emoji: '🎬', label: 'Video', value: '${s.video}'),
            StatCard(emoji: '👥', label: 'Tim', value: '${s.pengirim}'),
          ],
        ),
        const SizedBox(height: 10),
        // Rekap divisi chips
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
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
    child: Column(children: [
      // Filter tipe
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
            // Dropdown pengirim
            GestureDetector(
              onTap: _showPengirimFilter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _filterNama.isNotEmpty ? AppTheme.gold.withOpacity(0.2) : AppTheme.greenMid,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _filterNama.isNotEmpty ? AppTheme.gold : AppTheme.greenRim),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_filterNama.isEmpty ? '👤 Pengirim' : '👤 $_filterNama',
                    style: TextStyle(color: _filterNama.isNotEmpty ? AppTheme.goldLight : Colors.white70, fontSize: 12)),
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
        // Filter divisi
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
          children: [
            DivisiChip(label: 'Semua Divisi', selected: _filterDivisi.isEmpty,
              onTap: () { setState(() => _filterDivisi = ''); _load(reset: true); }),
            ...(_stats!.rekap.map((r) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: DivisiChip(label: r['divisi'],
                selected: _filterDivisi == r['divisi'],
                onTap: () { setState(() => _filterDivisi = r['divisi']); _load(reset: true); }),
            ))),
          ],
        )),
      ],
    ]),
  );

  void _showPengirimFilter() {
    showModalBottomSheet(
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
}
