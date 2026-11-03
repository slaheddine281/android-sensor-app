/**
 * StepQuest — Pont de Reconnaissance Faciale via face-api.js & TensorFlow.js
 * Avec chargement non bloquant et extracteur haute performance en temps réel.
 * La caméra est injectée dans un élément <video> existant créé par Flutter
 * via platformViewRegistry (HtmlElementView) pour une intégration native.
 */

(function () {
  window.StepQuestFaceAPI = {
    isLoaded: false,
    isLoading: false,
    modelLoadPromise: null,
    activeStreams: {},

    async loadModels(modelsPath = 'models') {
      if (this.isLoaded) return true;
      if (this.modelLoadPromise) return this.modelLoadPromise;

      this.isLoading = true;
      this.modelLoadPromise = (async () => {
        try {
          if (typeof faceapi === 'undefined') {
            console.warn('StepQuest: face-api.js non disponible');
            return false;
          }

          // Essayer les chemins dans l'ordre jusqu'au succès
          const paths = [modelsPath, 'assets/models', '/models', '/assets/models'];
          for (const p of paths) {
            try {
              await Promise.all([
                faceapi.nets.ssdMobilenetv1.loadFromUri(p),
                faceapi.nets.faceLandmark68Net.loadFromUri(p),
                faceapi.nets.faceRecognitionNet.loadFromUri(p),
              ]);
              this.isLoaded = true;
              console.log('✅ StepQuest: Modèles IA chargés depuis :', p);
              return true;
            } catch (e) {
              // Continuer vers le chemin suivant
            }
          }
          return false;
        } catch (err) {
          return false;
        }
      })();

      try {
        const result = await this.modelLoadPromise;
        if (!result) this.modelLoadPromise = null;
        return result;
      } finally {
        this.isLoading = false;
      }
    },

    // Démarrer la webcam sur l'élément vidéo créé par Flutter (HtmlElementView)
    // Si l'élément n'existe pas encore, on réessaie jusqu'à 2 secondes
    async startCamera(videoElementId = 'stepquest-camera-preview') {
      try {
        // Chercher le <video> créé par Flutter via platformViewRegistry
        let video = null;
        let attempts = 0;
        while (!video && attempts < 20) {
          video = document.getElementById(videoElementId);
          if (!video) {
            await new Promise((r) => setTimeout(r, 100));
            attempts++;
          }
        }

        // Si toujours pas trouvé, créer un élément flottant en secours
        if (!video) {
          console.warn('StepQuest: Élément vidéo Flutter introuvable, création en mode secours');
          video = document.createElement('video');
          video.id = videoElementId;
          video.setAttribute('autoplay', '');
          video.setAttribute('muted', '');
          video.setAttribute('playsinline', '');
          video.style.position = 'fixed';
          video.style.zIndex = '99999';
          video.style.top = '14%';
          video.style.left = '50%';
          video.style.transform = 'translateX(-50%)';
          video.style.width = '260px';
          video.style.height = '320px';
          video.style.borderRadius = '24px';
          video.style.objectFit = 'cover';
          video.style.pointerEvents = 'none';
          document.body.appendChild(video);
        }

        const stream = await navigator.mediaDevices.getUserMedia({
          video: {
            width: { ideal: 640 },
            height: { ideal: 480 },
            facingMode: 'user',
          },
          audio: false,
        });

        video.srcObject = stream;
        video.style.display = 'block';
        await video.play();

        this.activeStreams[videoElementId] = stream;

        // Charger les modèles IA en arrière-plan sans bloquer
        this.loadModels().catch(() => {});

        console.log('✅ StepQuest: Caméra démarrée sur #' + videoElementId);
        return true;
      } catch (err) {
        console.error('StepQuest: Erreur accès caméra :', err.name, err.message);
        return false;
      }
    },

    // Arrêter la webcam proprement
    stopCamera(videoElementId = 'stepquest-camera-preview') {
      try {
        const stream = this.activeStreams[videoElementId];
        if (stream) {
          stream.getTracks().forEach((track) => track.stop());
          delete this.activeStreams[videoElementId];
        }
        const video = document.getElementById(videoElementId);
        if (video) {
          video.srcObject = null;
          video.style.display = 'none';
          // Ne supprimer que les éléments flottants (hors Flutter tree)
          if (video.parentNode && video.parentNode !== document.body.querySelector('flt-glass-pane')) {
            if (video.parentNode === document.body) {
              video.parentNode.removeChild(video);
            }
          }
        }
        return true;
      } catch (err) {
        return false;
      }
    },

    async detectFaceDescriptor(videoElementId = 'stepquest-camera-preview') {
      const video = document.getElementById(videoElementId);

      if (!this.isLoaded || typeof faceapi === 'undefined' || !video || !video.videoWidth) {
        return null;
      }

      try {
        const detection = await faceapi
          .detectSingleFace(video)
          .withFaceLandmarks()
          .withFaceDescriptor();

        if (!detection || !detection.descriptor) return null;
        console.log('✅ StepQuest: Détection faciale réussie');
        return Array.from(detection.descriptor);
      } catch (err) {
        console.error('StepQuest: Erreur de détection faciale :', err);
        return null;
      }
    },

    // Capture photo haute résolution pour l'avatar (format JPEG base64)
    capturePhoto(videoElementId = 'stepquest-camera-preview') {
      try {
        const video = document.getElementById(videoElementId);
        if (!video || !video.videoWidth) return null;

        const canvas = document.createElement('canvas');
        canvas.width = 320;
        canvas.height = 320;
        const ctx = canvas.getContext('2d');
        const minDim = Math.min(video.videoWidth, video.videoHeight);
        const sx = (video.videoWidth - minDim) / 2;
        const sy = (video.videoHeight - minDim) / 2;

        ctx.drawImage(video, sx, sy, minDim, minDim, 0, 0, 320, 320);
        return canvas.toDataURL('image/jpeg', 0.85);
      } catch (err) {
        return null;
      }
    },

    // Comparaison de deux descripteurs faciaux (distance euclidienne)
    compareDescriptors(descriptor1, descriptor2, threshold = 0.55) {
      if (!descriptor1 || !descriptor2) return { match: false, distance: 1.0, confidence: 0 };
      const d1 = Array.isArray(descriptor1) ? descriptor1 : JSON.parse(descriptor1);
      const d2 = Array.isArray(descriptor2) ? descriptor2 : JSON.parse(descriptor2);

      let sum = 0;
      const len = Math.min(d1.length, d2.length);
      for (let i = 0; i < len; i++) {
        const diff = d1[i] - d2[i];
        sum += diff * diff;
      }
      const distance = Math.sqrt(sum);
      const match = distance < threshold;
      const confidence = Math.max(0, Math.min(100, Math.round((1 - distance / threshold) * 100)));

      return {
        match: match,
        distance: distance,
        confidence: confidence,
      };
    },
  };
})();
