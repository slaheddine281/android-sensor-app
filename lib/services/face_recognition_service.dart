import 'face_recognition/face_recognition_types.dart';
import 'face_recognition/face_recognition_stub.dart'
    if (dart.library.html) 'face_recognition/face_recognition_web.dart';

export 'face_recognition/face_recognition_types.dart';

/// Service centralisé de Reconnaissance Faciale pour StepQuest
/// Utilise les modèles face-api.js situés dans le dossier models/
class FaceRecognitionService {
  final FaceRecognitionPlatformImpl _impl = FaceRecognitionPlatformImpl();
  bool _modelsLoaded = false;

  bool get modelsLoaded => _modelsLoaded;

  /// Charger les modèles (ssd_mobilenetv1, face_landmark_68, face_recognition)
  Future<bool> initializeModels() async {
    if (_modelsLoaded) return true;
    _modelsLoaded = await _impl.loadModels();
    return _modelsLoaded;
  }

  /// Activer le flux de la caméra immédiatement
  Future<bool> startCamera({String elementId = 'stepquest-camera-preview'}) async {
    return await _impl.startCamera(elementId: elementId);
  }

  /// Arrêter et masquer la caméra
  Future<void> stopCamera({String elementId = 'stepquest-camera-preview'}) async {
    await _impl.stopCamera(elementId: elementId);
  }

  /// Détecter le visage et extraire le vecteur d'empreinte faciale
  Future<FaceDetectionResult> scanFace({
    String elementId = 'stepquest-camera-preview',
  }) async {
    return await _impl.detectAndExtractFace(elementId: elementId);
  }

  /// Comparer deux empreintes faciales et retourner le résultat
  FaceMatchResult compareFaces({
    required String storedEmbedding,
    required String liveEmbedding,
  }) {
    return _impl.compareFaces(storedEmbedding, liveEmbedding);
  }
}

