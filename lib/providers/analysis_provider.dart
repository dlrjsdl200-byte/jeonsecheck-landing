import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/storage_service.dart';
import '../models/analysis_result.dart';

class AnalysisProvider extends ChangeNotifier {
  final _storage = StorageService();
  final _supabase = Supabase.instance.client;

  bool _isAnalyzing = false;
  String _currentStep = '';
  AnalysisResult? _result;

  bool get isAnalyzing => _isAnalyzing;
  String get currentStep => _currentStep;
  AnalysisResult? get result => _result;

  // 분석 실행
  Future<String?> analyze({
    Uint8List? contractBytes,
    Uint8List? registryBytes,
    Uint8List? buildingBytes,
  }) async {
    _isAnalyzing = true;
    _currentStep = '서류 업로드 중...';
    notifyListeners();

    try {
      final uploadedPaths = <String>[];
      final docTypes = <String>[];

      // 1. 파일 업로드
      if (contractBytes != null) {
        _currentStep = '계약서 업로드 중...';
        notifyListeners();
        final path = await _storage.uploadFile(
          fileName: 'contract_${DateTime.now().millisecondsSinceEpoch}.jpg',
          fileBytes: contractBytes,
          mimeType: 'image/jpeg',
        );
        uploadedPaths.add(path);
        docTypes.add('contract');
      }

      if (registryBytes != null) {
        _currentStep = '등기부등본 업로드 중...';
        notifyListeners();
        final path = await _storage.uploadFile(
          fileName: 'registry_${DateTime.now().millisecondsSinceEpoch}.jpg',
          fileBytes: registryBytes,
          mimeType: 'image/jpeg',
        );
        uploadedPaths.add(path);
        docTypes.add('registry');
      }

      if (buildingBytes != null) {
        _currentStep = '건축물대장 업로드 중...';
        notifyListeners();
        final path = await _storage.uploadFile(
          fileName: 'building_${DateTime.now().millisecondsSinceEpoch}.jpg',
          fileBytes: buildingBytes,
          mimeType: 'image/jpeg',
        );
        uploadedPaths.add(path);
        docTypes.add('building');
      }

      // 2. Edge Function 호출 (AI 분석)
      _currentStep = 'AI 분석 중...';
      notifyListeners();

      final response = await _supabase.functions.invoke(
        'analyze',
        body: {
          'paths': uploadedPaths,
          'doc_types': docTypes,
        },
      );

      final resultData = response.data as Map<String, dynamic>;

      // 3. 결과 DB 저장
      _currentStep = '결과 저장 중...';
      notifyListeners();

      final inserted = await _supabase.from('analyses').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'score': resultData['score'],
        'grade': resultData['grade'],
        'result_json': resultData,
        'documents_uploaded': docTypes,
      }).select().single();

      _result = AnalysisResult.fromJson(inserted);

      // 4. 원본 파일 즉시 삭제 (보안)
      _currentStep = '원본 파일 삭제 중...';
      notifyListeners();

      for (final path in uploadedPaths) {
        await _storage.deleteFile(path);
      }

      _isAnalyzing = false;
      _currentStep = '';
      notifyListeners();

      return _result!.id;
    } catch (e) {
      _isAnalyzing = false;
      _currentStep = '';
      notifyListeners();
      rethrow;
    }
  }

  // 결과 조회
  Future<AnalysisResult> getResult(String id) async {
    final data = await _supabase
        .from('analyses')
        .select()
        .eq('id', id)
        .single();
    _result = AnalysisResult.fromJson(data);
    notifyListeners();
    return _result!;
  }
}
