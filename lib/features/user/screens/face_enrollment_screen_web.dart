import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

/// Identifiant du type de vue plateforme pour la caméra faciale StepQuest
const String _kCameraViewType = 'stepquest-face-camera-view';

/// Enregistre la factory de vue caméra une seule fois au démarrage
bool _registered = false;

@JS('document.createElement')
external JSObject _createElement(JSString tag);

extension _JSObjectExt on JSObject {
  @JS('id')
  external set id(JSString v);
  @JS('autoplay')
  external set autoplay(JSBoolean v);
  @JS('muted')
  external set muted(JSBoolean v);
  @JS('style')
  external JSObject get style;
  @JS('setAttribute')
  external void setAttribute(JSString name, JSString value);
}

extension _StyleExt on JSObject {
  @JS('width')
  external set width(JSString v);
  @JS('height')
  external set height(JSString v);
  @JS('objectFit')
  external set objectFit(JSString v);
  @JS('display')
  external set display(JSString v);
}

void _ensureRegistered() {
  if (_registered) return;
  _registered = true;

  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(
    _kCameraViewType,
    (int viewId) {
      // Créer l'élément <video> via JS interop sans dart:html
      final video = _createElement('video'.toJS);
      video.id = 'stepquest-camera-preview'.toJS;
      video.autoplay = true.toJS;
      video.muted = true.toJS;
      video.setAttribute('playsinline'.toJS, 'true'.toJS);
      final style = video.style;
      style.width = '100%'.toJS;
      style.height = '100%'.toJS;
      style.objectFit = 'cover'.toJS;
      style.display = 'block'.toJS;
      return video;
    },
  );
}

/// Retourne un widget Flutter contenant le flux vidéo de la caméra.
/// À appeler depuis le build() de FaceEnrollmentScreen sur le Web.
Widget buildCameraView() {
  _ensureRegistered();
  return const HtmlElementView(viewType: _kCameraViewType);
}
