import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';
import 'face_recognition_types.dart';

@JS('StepQuestFaceAPI.loadModels')
external JSPromise<JSBoolean> _jsLoadModels(JSString path);

@JS('StepQuestFaceAPI.startCamera')
external JSPromise<JSBoolean> _jsStartCamera(JSString elementId);

@JS('StepQuestFaceAPI.stopCamera')
external void _jsStopCamera(JSString elementId);

@JS('StepQuestFaceAPI.detectFaceDescriptor')
external JSPromise<JSAny?> _jsDetectFaceDescriptor(JSString elementId);

@JS('StepQuestFaceAPI.capturePhoto')
external JSString? _jsCapturePhoto(JSString elementId);

/// Web implementation using modern dart:js_interop
class FaceRecognitionPlatformImpl {
  Future<bool> loadModels() async {
    try {
      final jsBool = await _jsLoadModels('models'.toJS).toDart;
      return jsBool.toDart;
    } catch (e) {
      return false;
    }
  }

  Future<bool> startCamera({String elementId = 'stepquest-camera-preview'}) async {
    try {
      final jsBool = await _jsStartCamera(elementId.toJS).toDart;
      return jsBool.toDart;
    } catch (e) {
      return false;
    }
  }

  Future<void> stopCamera({String elementId = 'stepquest-camera-preview'}) async {
    try {
      _jsStopCamera(elementId.toJS);
    } catch (_) {}
  }

  Future<FaceDetectionResult> detectAndExtractFace({
    String elementId = 'stepquest-camera-preview',
  }) async {
    try {
      final descriptorJs =
          await _jsDetectFaceDescriptor(elementId.toJS).toDart;

      if (descriptorJs == null) {
        return FaceDetectionResult.failureResult(
            'Aucun visage détecté. Veuillez bien regarder la caméra.');
      }

      // Convert JS Array of doubles to Dart List<double>
      final jsArray = descriptorJs as JSArray<JSNumber>;
      final dartList = jsArray.toDart.map((n) => n.toDartDouble).toList();

      if (dartList.isEmpty) {
        return FaceDetectionResult.failureResult(
            'Échec de l\'extraction des caractéristiques faciales.');
      }

      final photo = _jsCapturePhoto(elementId.toJS)?.toDart;
      final jsonStr = jsonEncode(dartList);

      return FaceDetectionResult.successResult(
        faceEmbeddingJson: jsonStr,
        photoBase64: photo,
        confidence: 98.0,
      );
    } catch (e) {
      return FaceDetectionResult.failureResult(
          'Erreur lors de la capture : $e');
    }
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
      // Seuil face-api standard : distance < 0.55 = même personne
      final isMatch = distance < 0.55;
      final confidence =
          ((1.0 - (distance / 0.55)).clamp(0.0, 1.0) * 100).round();

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
