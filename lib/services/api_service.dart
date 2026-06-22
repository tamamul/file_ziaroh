import 'dart:io';
import 'package:dio/dio.dart';
import '../constants.dart';
import '../models/upload_file.dart';

class UploadResult {
  final bool success;
  final String message;
  final String filename;
  UploadResult({required this.success, required this.message, this.filename = ''});
}

class ApiService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 10),
    sendTimeout: const Duration(minutes: 10),
  ));

  static Future<UploadResult> uploadFile({
    required File file,
    required String nama,
    required String divisi,
    required String keterangan,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final fname = file.path.split('/').last;
      final form = FormData.fromMap({
        'nama': nama,
        'divisi': divisi,
        'keterangan': keterangan,
        'file': await MultipartFile.fromFile(file.path, filename: fname),
      });

      final res = await _dio.post(
        AppConstants.uploadUrl,
        data: form,
        onSendProgress: onProgress,
      );

      final data = res.data as Map<String, dynamic>;
      return UploadResult(
        success: data['success'] == true,
        message: data['message'] ?? '',
        filename: fname,
      );
    } on DioException catch (e) {
      String msg = 'Koneksi gagal';
      if (e.type == DioExceptionType.connectionTimeout) msg = 'Timeout koneksi';
      if (e.type == DioExceptionType.sendTimeout) msg = 'Timeout upload (file terlalu besar?)';
      if (e.response != null) msg = 'Server error ${e.response?.statusCode}';
      return UploadResult(success: false, message: msg);
    } catch (e) {
      return UploadResult(success: false, message: e.toString());
    }
  }

  static Future<List<UploadFile>> getFiles({
    String? nama, String? divisi, String? tipe,
    int limit = 50, int offset = 0,
  }) async {
    try {
      final params = <String, dynamic>{
        'action': 'list',
        'limit': limit,
        'offset': offset,
        if (nama != null && nama.isNotEmpty) 'nama': nama,
        if (divisi != null && divisi.isNotEmpty) 'divisi': divisi,
        if (tipe != null && tipe.isNotEmpty) 'tipe': tipe,
      };
      final res = await _dio.get(AppConstants.apiUrl, queryParameters: params);
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['data'] as List).map((e) => UploadFile.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<UploadStats?> getStats() async {
    try {
      final res = await _dio.get(AppConstants.apiUrl, queryParameters: {'action': 'stats'});
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true) return UploadStats.fromJson(data['data']);
    } catch (_) {}
    return null;
  }
}
