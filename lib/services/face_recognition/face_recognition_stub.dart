import 'dart:convert';
import 'dart:math';
import 'face_recognition_types.dart';

/// Implementation for non-web environments (Desktop / Tests)
class FaceRecognitionPlatformImpl {
  bool isCameraActive = false;

  Future<bool> loadModels() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  Future<bool> startCamera({String elementId = 'stepquest-camera-preview'}) async {
    isCameraActive = true;
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  Future<void> stopCamera({String elementId = 'stepquest-camera-preview'}) async {
    isCameraActive = false;
  }

  Future<FaceDetectionResult> detectAndExtractFace({
    String elementId = 'stepquest-camera-preview',
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Generate a consistent pseudo-random 128D embedding vector for simulation
    final rnd = Random(42);
    final vector = List<double>.generate(128, (_) => (rnd.nextDouble() * 2) - 1);
    final jsonStr = jsonEncode(vector);

    return FaceDetectionResult.successResult(
      faceEmbeddingJson: jsonStr,
      confidence: 96.5,
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
