/// Types and result structures for Face Recognition in StepQuest
class FaceDetectionResult {
  final bool success;
  final String? faceEmbeddingJson;
  final String? photoBase64;
  final String message;
  final double confidence;

  const FaceDetectionResult({
    required this.success,
    this.faceEmbeddingJson,
    this.photoBase64,
    required this.message,
    this.confidence = 0.0,
  });

  factory FaceDetectionResult.successResult({
    required String faceEmbeddingJson,
    String? photoBase64,
    double confidence = 98.0,
  }) {
    return FaceDetectionResult(
      success: true,
      faceEmbeddingJson: faceEmbeddingJson,
      photoBase64: photoBase64,
      message: 'Visage détecté et empreinte faciale générée avec succès.',
      confidence: confidence,
    );
  }

  factory FaceDetectionResult.failureResult(String message) {
    return FaceDetectionResult(
      success: false,
      message: message,
      confidence: 0.0,
    );
  }
}

class FaceMatchResult {
  final bool isMatch;
  final double distance;
  final int confidencePercentage;
  final String message;

  const FaceMatchResult({
    required this.isMatch,
    required this.distance,
    required this.confidencePercentage,
    required this.message,
  });

  factory FaceMatchResult.match({
    required double distance,
    required int confidencePercentage,
  }) {
    return FaceMatchResult(
      isMatch: true,
      distance: distance,
      confidencePercentage: confidencePercentage,
      message: 'Visage authentifié avec succès ($confidencePercentage% de similarité).',
    );
  }

  factory FaceMatchResult.noMatch({
    required double distance,
    required int confidencePercentage,
  }) {
    return FaceMatchResult(
      isMatch: false,
      distance: distance,
      confidencePercentage: confidencePercentage,
      message: 'Visage non reconnu (distance: ${distance.toStringAsFixed(2)}).',
    );
  }
}

