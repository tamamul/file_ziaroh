class UploadFile {
  final int id;
  final String nama;
  final String divisi;
  final String keterangan;
  String filenameOri;
  final String filenameSaved;
  final String filepath;
  final String filetype;
  final int filesize;
  final String filesizeFmt;
  final String ext;
  final String url;
  final String? thumbUrl;
  final DateTime createdAt;

  UploadFile({
    required this.id,
    required this.nama,
    required this.divisi,
    required this.keterangan,
    required this.filenameOri,
    required this.filenameSaved,
    required this.filepath,
    required this.filetype,
    required this.filesize,
    required this.filesizeFmt,
    required this.ext,
    required this.url,
    this.thumbUrl,
    required this.createdAt,
  });

  bool get isPhoto => filetype == 'foto';
  bool get isVideo => filetype == 'video';
  bool get hasThumb => (thumbUrl ?? '').isNotEmpty;

  factory UploadFile.fromJson(Map<String, dynamic> j) {
    return UploadFile(
      id: int.tryParse(j['id']?.toString() ?? '') ?? 0,
      nama: j['nama']?.toString() ?? '',
      divisi: j['divisi']?.toString() ?? '',
      keterangan: j['keterangan']?.toString() ?? '',
      filenameOri: j['filename_ori']?.toString() ?? '',
      filenameSaved: j['filename_saved']?.toString() ?? '',
      filepath: j['filepath']?.toString() ?? '',
      filetype: j['filetype']?.toString() ?? '',
      filesize: int.tryParse(j['filesize']?.toString() ?? '') ?? 0,
      filesizeFmt: j['filesize_fmt']?.toString() ?? '',
      ext: j['ext']?.toString() ?? '',
      url: j['url']?.toString() ?? '',
      thumbUrl: j['thumb_url']?.toString(),
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}