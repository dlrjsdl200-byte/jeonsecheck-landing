import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  // 파일 업로드
  Future<String> uploadFile({
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    final path = '$_userId/$fileName';
    await _supabase.storage.from('documents').uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(contentType: mimeType),
        );
    return path;
  }

  // 파일 다운로드 (Edge Function에서 분석용)
  Future<Uint8List> downloadFile(String path) async {
    return await _supabase.storage.from('documents').download(path);
  }

  // 파일 삭제 (분석 완료 후 즉시 삭제 — PRD 보안 요구사항)
  Future<void> deleteFile(String path) async {
    await _supabase.storage.from('documents').remove([path]);
  }

  // 사용자 폴더 전체 삭제
  Future<void> deleteUserFolder() async {
    final files = await _supabase.storage.from('documents').list(path: _userId);
    if (files.isNotEmpty) {
      final paths = files.map((f) => '$_userId/${f.name}').toList();
      await _supabase.storage.from('documents').remove(paths);
    }
  }
}
