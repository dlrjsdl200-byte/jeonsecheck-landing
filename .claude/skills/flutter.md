# Flutter 개발 스킬

## 프로젝트 구조
```
lib/
├── main.dart              # 앱 진입점
├── app.dart               # MaterialApp 설정
├── config/                # 환경변수, 상수
├── models/                # 데이터 모델
├── services/              # API, AI, 결제 등 비즈니스 로직
├── providers/             # 상태관리 (Provider/Riverpod)
├── screens/               # 화면 단위 위젯
├── widgets/               # 재사용 위젯
└── utils/                 # 유틸리티 함수
```

## 핵심 패키지 (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0       # Backend (Auth, DB, Storage)
  provider: ^6.0.0               # 상태관리
  go_router: ^10.0.0             # 라우팅
  dio: ^5.0.0                    # HTTP 클라이언트
  image_picker: ^1.0.0           # 사진 촬영/선택
  file_picker: ^6.0.0            # PDF/파일 선택
  printing: ^5.10.0              # PDF 생성
  pdf: ^3.10.0                   # PDF 위젯
  tosspayments_widget_sdk_flutter # 토스페이먼츠 결제
```

## 상태관리 (Provider 패턴)
```dart
// ChangeNotifier 기반
class AnalysisProvider extends ChangeNotifier {
  AnalysisResult? _result;
  bool _isLoading = false;

  Future<void> analyze(File file) async {
    _isLoading = true;
    notifyListeners();
    _result = await analysisService.run(file);
    _isLoading = false;
    notifyListeners();
  }
}

// 위젯에서 사용
context.watch<AnalysisProvider>().result;
```

## 라우팅 (GoRouter)
```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => HomeScreen()),
    GoRoute(path: '/upload', builder: (_, __) => UploadScreen()),
    GoRoute(path: '/result/:id', builder: (_, state) =>
      ResultScreen(id: state.pathParameters['id']!)),
  ],
);
```

## 파일 업로드 (이미지/PDF)
```dart
// 이미지 촬영 또는 갤러리 선택
final picker = ImagePicker();
final XFile? image = await picker.pickImage(source: ImageSource.camera);

// PDF 파일 선택
final result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['pdf'],
);
```

## PDF 리포트 생성
```dart
import 'package:pdf/widgets.dart' as pw;

final pdf = pw.Document();
pdf.addPage(pw.Page(
  build: (context) => pw.Column(children: [
    pw.Text('계약체크 분석 리포트', style: pw.TextStyle(fontSize: 24)),
    pw.Text('안전 점수: 85/100'),
  ]),
));
final bytes = await pdf.save();
```

## 플랫폼 설정
- **Android**: `AndroidManifest.xml` — 인터넷 권한, 카메라 권한, `usesCleartextTraffic=true`
- **iOS**: `Info.plist` — `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription`
- **Web**: `index.html` — meta viewport, favicon 설정
