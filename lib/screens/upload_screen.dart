import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/analysis_provider.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  Uint8List? _contractBytes;
  Uint8List? _registryBytes;
  Uint8List? _buildingBytes;

  String? _contractName;
  String? _registryName;
  String? _buildingName;

  Future<void> _pickFile(String type) async {
    final picker = ImagePicker();

    // 선택지: 카메라 or 파일
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF 파일 선택'),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    Uint8List? bytes;
    String? name;

    if (source == 'camera') {
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        bytes = await image.readAsBytes();
        name = image.name;
      }
    } else if (source == 'gallery') {
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        bytes = await image.readAsBytes();
        name = image.name;
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        bytes = result.files.single.bytes!;
        name = result.files.single.name;
      }
    }

    if (bytes == null) return;

    setState(() {
      switch (type) {
        case 'contract':
          _contractBytes = bytes;
          _contractName = name;
        case 'registry':
          _registryBytes = bytes;
          _registryName = name;
        case 'building':
          _buildingBytes = bytes;
          _buildingName = name;
      }
    });
  }

  bool get _hasAtLeastOne =>
      _contractBytes != null ||
      _registryBytes != null ||
      _buildingBytes != null;

  Future<void> _startAnalysis() async {
    final auth = context.read<AuthProvider>();
    final analysis = context.read<AnalysisProvider>();

    // 분석권 차감
    final credited = await auth.useCredit();
    if (!credited) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('분석권이 부족합니다')),
        );
      }
      return;
    }

    if (mounted) {
      context.go('/analyzing');
    }

    try {
      final resultId = await analysis.analyze(
        contractBytes: _contractBytes,
        registryBytes: _registryBytes,
        buildingBytes: _buildingBytes,
      );

      if (mounted && resultId != null) {
        context.go('/result/$resultId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('분석 중 오류가 발생했습니다: $e')),
        );
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('서류 업로드'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '체크할 서류를 올려주세요',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '1개만 올려도 분석 가능, 3개 모두 올리면 교차 검증까지',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            _DocumentCard(
              title: '계약서',
              icon: Icons.description_outlined,
              fileName: _contractName,
              onTap: () => _pickFile('contract'),
            ),
            const SizedBox(height: 12),
            _DocumentCard(
              title: '등기부등본',
              icon: Icons.account_balance_outlined,
              fileName: _registryName,
              onTap: () => _pickFile('registry'),
            ),
            const SizedBox(height: 12),
            _DocumentCard(
              title: '건축물대장',
              icon: Icons.apartment_outlined,
              fileName: _buildingName,
              onTap: () => _pickFile('building'),
            ),

            const Spacer(),

            // 분석 시작 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _hasAtLeastOne ? _startAnalysis : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '분석 시작',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? fileName;
  final VoidCallback onTap;

  const _DocumentCard({
    required this.title,
    required this.icon,
    this.fileName,
    required this.onTap,
  });

  bool get _isUploaded => fileName != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isUploaded ? AppColors.success.withAlpha(10) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isUploaded ? AppColors.success : AppColors.border,
            width: _isUploaded ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _isUploaded ? AppColors.success : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _isUploaded
                          ? AppColors.success
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (_isUploaded)
                    Text(
                      fileName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              _isUploaded ? Icons.check_circle : Icons.add_circle_outline,
              color: _isUploaded ? AppColors.success : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
