import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../constants.dart';
import '../services/api_service.dart';
import '../services/pref_service.dart';
import '../widgets/app_widgets.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State createState() => UploadScreenState();
}

class UploadScreenState extends State<UploadScreen> {
  final _namaCtrl = TextEditingController();
  final _ketCtrl = TextEditingController();
  String _divisi = '';
  String _divisiCustom = '';
  bool _customDivisi = false;
  List<File> selectedFiles = [];
  bool _uploading = false;

  // Progress per file
  List<_FileStatus> _statuses = [];

  @override
  void initState() {
    super.initState();
    _namaCtrl.text = PrefService.nama;
    _divisi = PrefService.divisi;
    if (_divisi.isNotEmpty && !AppConstants.divisiList.contains(_divisi)) {
      _customDivisi = true;
      _divisiCustom = _divisi;
      _divisi = 'custom';
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _ketCtrl.dispose();
    super.dispose();
  }

  String get _activeDivisi => _customDivisi ? _divisiCustom : _divisi;

  String _formatBytes(int b) {
    if (b >= 1073741824) return '${(b / 1073741824).toStringAsFixed(1)} GB';
    if (b >= 1048576) return '${(b / 1048576).toStringAsFixed(1)} MB';
    if (b >= 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '$b B';
  }

  Future _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultipleMedia();
    if (picked.isNotEmpty) {
      setState(() => selectedFiles.addAll(picked.map((e) => File(e.path))));
    }
  }

  Future _pickFromCamera() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 95);
    if (img != null) setState(() => selectedFiles.add(File(img.path)));
  }

  Future _pickVideoCamera() async {
    final picker = ImagePicker();
    final vid = await picker.pickVideo(source: ImageSource.camera);
    if (vid != null) setState(() => selectedFiles.add(File(vid.path)));
  }

  Future _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'heic', 'webp', 'mp4', 'mov', 'avi', 'mkv', 'mts', 'm2ts'],
    );
    if (result != null) {
      setState(() => selectedFiles.addAll(result.paths.whereType<String>().map((e) => File(e))));
    }
  }

  Future _startUpload() async {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) {
      _showSnack('Nama wajib diisi');
      return;
    }
    if (_activeDivisi.isEmpty) {
      _showSnack('Pilih divisi terlebih dahulu');
      return;
    }
    if (selectedFiles.isEmpty) {
      _showSnack('Pilih file terlebih dahulu');
      return;
    }

    // Simpan identitas
    await PrefService.saveNama(nama);
    await PrefService.saveDivisi(_activeDivisi);

    setState(() {
      _uploading = true;
      _statuses = selectedFiles.map((f) => _FileStatus(file: f)).toList();
    });

    for (int i = 0; i < selectedFiles.length; i++) {
      setState(() => _statuses[i].status = FileUploadStatus.uploading);

      final res = await ApiService.uploadFile(
        file: selectedFiles[i],
        nama: nama,
        divisi: _activeDivisi,
        keterangan: _ketCtrl.text.trim(),
        onProgress: (sent, total) {
          if (total > 0) setState(() => _statuses[i].progress = sent / total);
        },
      );

      setState(() {
        _statuses[i].status = res.success ? FileUploadStatus.done : FileUploadStatus.error;
        _statuses[i].message = res.message;
      });
    }

    final done = _statuses.where((s) => s.status == FileUploadStatus.done).length;
    setState(() => _uploading = false);

    if (done == selectedFiles.length) {
      _showSuccessDialog(done);
      setState(() {
        selectedFiles = [];
        _statuses = [];
        _ketCtrl.clear();
      });
    }
  }

  void _showSuccessDialog(int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.greenCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.gold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Upload Berhasil!',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '$count file berhasil dikirim',
              style: const TextStyle(color: Color(0xFF5A8A6A)),
            ),
            const SizedBox(height: 4),
            Text(
              _activeDivisi,
              style: const TextStyle(color: AppTheme.gold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Upload Lagi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.greenMid,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

  void _showPickerSheet() => showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.greenCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.greenRim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _sheetTile('📷', 'Foto & Video dari Galeri', _pickFromGallery),
              _sheetTile('📸', 'Kamera Foto', _pickFromCamera),
              _sheetTile('🎥', 'Kamera Video', _pickVideoCamera),
              _sheetTile('📁', 'File Manager', _pickFiles),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

  ListTile _sheetTile(String emoji, String label, VoidCallback fn) => ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        onTap: () {
          Navigator.pop(context);
          fn();
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Arabic
              Center(
                child: Column(
                  children: [
                    const Text(
                      'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 20,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.appSubtitle,
                      style: const TextStyle(color: Color(0xFF5A8A6A), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const GoldDivider(),

              // Identitas
              _sectionTitle('① Identitas Tim'),
              const SizedBox(height: 10),

              TextFormField(
                controller: _namaCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap *',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.greenRim),
                ),
              ),
              const SizedBox(height: 10),

              // Divisi chips
              const Text(
                'Divisi *',
                style: TextStyle(color: AppTheme.goldLight, fontSize: 12),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...AppConstants.divisiList.map(
                    (d) => DivisiChip(
                      label: d,
                      selected: !_customDivisi && _divisi == d,
                      onTap: () => setState(() {
                        _divisi = d;
                        _customDivisi = false;
                      }),
                    ),
                  ),
                  DivisiChip(
                    label: '✏️ Lainnya',
                    selected: _customDivisi,
                    onTap: () => setState(() {
                      _customDivisi = true;
                      _divisi = 'custom';
                    }),
                  ),
                ],
              ),

              if (_customDivisi) ...[
                const SizedBox(height: 8),
                TextFormField(
                  onChanged: (v) => setState(() => _divisiCustom = v),
                  initialValue: _divisiCustom,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nama Divisi Custom',
                    prefixIcon: Icon(Icons.edit, color: AppTheme.greenRim),
                  ),
                ),
              ],

              const SizedBox(height: 10),

              TextFormField(
                controller: _ketCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Keterangan (opsional)',
                  prefixIcon: Icon(Icons.notes, color: AppTheme.greenRim),
                ),
              ),

              const GoldDivider(),

              // File picker
              _sectionTitle('② Pilih File'),
              const SizedBox(height: 10),

              // Drop zone / pick button
              GestureDetector(
                onTap: _uploading ? null : _showPickerSheet,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.greenMid.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.greenRim,
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text('📁', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap untuk pilih file',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'JPG, PNG, HEIC, MP4, MOV, MKV...',
                        style: const TextStyle(color: Color(0xFF5A8A6A), fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Maks. 500 MB/file',
                        style: TextStyle(color: AppTheme.gold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),

              // File list
              if (selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${selectedFiles.length} file dipilih',
                      style: const TextStyle(
                        color: AppTheme.goldLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!_uploading)
                      TextButton(
                        onPressed: () => setState(() {
                          selectedFiles = [];
                          _statuses = [];
                        }),
                        child: const Text(
                          'Hapus Semua',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                ...selectedFiles.asMap().entries.map((e) {
                  final i = e.key;
                  final f = e.value;
                  final status = _statuses.length > i ? _statuses[i] : null;
                  final size = f.lengthSync();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.greenMid,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: status?.status == FileUploadStatus.error
                            ? Colors.red.withOpacity(0.5)
                            : AppTheme.greenRim.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_getFileIcon(f.path), style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.basename(f.path),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _formatBytes(size),
                                    style: TextStyle(
                                      color: size > 500 * 1024 * 1024
                                          ? Colors.red
                                          : const Color(0xFF5A8A6A),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (status != null) ...[
                              if (status.status == FileUploadStatus.done)
                                const Icon(Icons.check_circle, color: Colors.green, size: 20)
                              else if (status.status == FileUploadStatus.error)
                                const Icon(Icons.error, color: Colors.red, size: 20)
                              else if (status.status == FileUploadStatus.uploading)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.gold,
                                  ),
                                ),
                            ] else if (!_uploading)
                              GestureDetector(
                                onTap: () => setState(() => selectedFiles.removeAt(i)),
                                child: const Icon(Icons.close, color: Colors.red, size: 20),
                              ),
                          ],
                        ),
                        if (status?.status == FileUploadStatus.uploading) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: status!.progress,
                              backgroundColor: AppTheme.greenRim.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation(AppTheme.gold),
                              minHeight: 4,
                            ),
                          ),
                          Text(
                            '${(status.progress * 100).toInt()}%',
                            style: const TextStyle(color: AppTheme.gold, fontSize: 10),
                          ),
                        ],
                        if (status?.status == FileUploadStatus.error)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              status!.message,
                              style: const TextStyle(color: Colors.red, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 16),

              // Upload button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_uploading || selectedFiles.isEmpty) ? null : _startUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.greenRim,
                    disabledBackgroundColor: AppTheme.greenMid,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _uploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.gold,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Mengupload...',
                              style: TextStyle(color: AppTheme.goldLight),
                            ),
                          ],
                        )
                      : const Text(
                          '🚀 Upload Semua File',
                          style: TextStyle(
                            color: AppTheme.goldLight,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Row(
        children: [
          Text(
            t,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );

  String _getFileIcon(String path) {
    final ext = p.extension(path).toLowerCase().replaceAll('.', '');
    const photos = ['jpg', 'jpeg', 'png', 'heic', 'webp', 'raw', 'cr2', 'nef'];
    const videos = ['mp4', 'mov', 'avi', 'mkv', 'mts', 'm2ts'];
    if (photos.contains(ext)) return '📷';
    if (videos.contains(ext)) return '🎬';
    return '📄';
  }
}

enum FileUploadStatus { idle, uploading, done, error }

class _FileStatus {
  final File file;
  FileUploadStatus status;
  double progress;
  String message;

  _FileStatus({
    required this.file,
    this.status = FileUploadStatus.idle,
    this.progress = 0,
    this.message = '',
  });
}