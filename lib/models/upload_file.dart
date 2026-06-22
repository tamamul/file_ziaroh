class UploadFile {
  final int id;
  final String nama;
  final String divisi;
  final String keterangan;
  String filenameOri; // mutable untuk rename
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
  bool get hasThumb => thumbUrl != null && thumbUrl!.isNotEmpty;

  factory UploadFile.fromJson(Map<String, dynamic> j) => UploadFile(
    id: int.tryParse(j['id'].toString()) ?? 0,
    nama: j['nama'] ?? '',
    divisi: j['divisi'] ?? '',
    keterangan: j['keterangan'] ?? '',
    filenameOri: j['filename_ori'] ?? '',
    filenameSaved: j['filename_saved'] ?? '',
    filepath: j['filepath'] ?? '',
    filetype: j['filetype'] ?? '',
    filesize: int.tryParse(j['filesize'].toString()) ?? 0,
    filesizeFmt: j['filesize_fmt'] ?? '',
    ext: j['ext'] ?? '',
    url: j['url'] ?? '',
    thumbUrl: j['thumb_url'],
    createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
  );
}

class UploadStats {
  final int total, foto, video, pengirim;
  final int totalSize;
  final List<Map<String, dynamic>> rekap;
  final List<String> pengirimList;

  UploadStats({
    required this.total, required this.foto, required this.video,
    required this.pengirim, required this.totalSize,
    required this.rekap, required this.pengirimList,
  });

  factory UploadStats.fromJson(Map<String, dynamic> j) => UploadStats(
    total: j['total'] ?? 0,
    foto: j['foto'] ?? 0,
    video: j['video'] ?? 0,
    pengirim: j['pengirim'] ?? 0,
    totalSize: j['total_size'] ?? 0,
    rekap: List<Map<String, dynamic>>.from(j['rekap'] ?? []),
    pengirimList: List<String>.from(j['pengirim_list'] ?? []),
  );
}
