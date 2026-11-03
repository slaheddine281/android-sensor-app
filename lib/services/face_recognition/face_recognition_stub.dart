import 'dart:convert';
import 'dart:math';
import 'face_recognition_types.dart';

/// Face recognition is currently available only in the web implementation.
class FaceRecognitionPlatformImpl {
  Future<bool> loadModels() async {
    return false;
  }

  Future<bool> startCamera({String elementId = 'stepquest-camera-preview'}) async {
    return false;
  }

  Future<void> stopCamera({String elementId = 'stepquest-camera-preview'}) async {}

  Future<FaceDetectionResult> detectAndExtractFace({
    String elementId = 'stepquest-camera-preview',
  }) async {
    return FaceDetectionResult.failureResult(
      'La reconnaissance faciale est disponible dans la version Web uniquement.',
    );
  }

  FaceMatchResult compareFaces(String storedEmbedding, String currentEmbedding) {
    try {
      final List<dynamic> d1 = jsonDecode(storedEmbedding);
      final List<dynamic> d2 = jsonDecode(currentEmbedding);

      double sum = 0;
      for (int i = 0; i < d1.length && i < d2.length; i++) {
        final diff = (d1[i] as num).toDouble() - (d2[i] as num).toDouble();
        sum += diff * diff;
      }
      final distance = sqrt(sum);
      final isMatch = distance < 0.55;
      final confidence = ((1 - (distance / 0.55)).clamp(0.0, 1.0) * 100).round();

      if (isMatch) {
        return FaceMatchResult.match(
          distance: distance,
          confidencePercentage: confidence,
        );
      } else {
        return FaceMatchResult.noMatch(
          distance: distance,
          confidencePercentage: confidence,
        );
      }
    } catch (e) {
      return FaceMatchResult.noMatch(distance: 1.0, confidencePercentage: 0);
    }
  }
}
