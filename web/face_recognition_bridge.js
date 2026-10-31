/**
 * StepQuest — Face Recognition Bridge via face-api.js & TensorFlow.js
 * Utilise les modèles locaux du dossier /models :
 * - ssd_mobilenetv1_model
 * - face_landmark_68_model
 * - face_recognition_model
 */

(function () {
  window.StepQuestFaceAPI = {
    isLoaded: false,
    isLoading: false,
    activeStreams: {},

    // Initialisation et chargement des modèles depuis le dossier /models
    async loadModels(modelsPath = 'models') {
      if (this.isLoaded) return true;
      if (this.isLoading) {
        while (this.isLoading) {
          await new Promise((r) => setTimeout(r, 100));
        }
        return this.isLoaded;
      }

      this.isLoading = true;
      try {
        if (typeof faceapi === 'undefined') {
          console.warn('faceapi non chargé, attente du script...');
          return false;
        }

        console.log('Chargement des modèles StepQuest depuis :', modelsPath);
        await Promise.all([
          faceapi.nets.ssdMobilenetv1.loadFromUri(modelsPath),
          faceapi.nets.faceLandmark68Net.loadFromUri(modelsPath),
          faceapi.nets.faceRecognitionNet.loadFromUri(modelsPath),
        ]);

        this.isLoaded = true;
        console.log('✅ Modèles de reconnaissance faciale StepQuest chargés avec succès !');
        return true;
      } catch (err) {
        console.error('Erreur lors du chargement des modèles :', err);
        return false;
      } finally {
        this.isLoading = false;
      }
    },

    // Démarrer la webcam et attacher le flux vidéo
    async startCamera(videoElementId = 'stepquest-camera-preview') {
      try {
        let video = document.getElementById(videoElementId);
        if (!video) {
          video = document.createElement('video');
          video.id = videoElementId;
          video.setAttribute('autoplay', '');
          video.setAttribute('muted', '');
          video.setAttribute('playsinline', '');
          video.style.position = 'fixed';
          video.style.zIndex = '99999';
          video.style.top = '15%';
          video.style.left = '50%';
          video.style.transform = 'translateX(-50%)';
          video.style.width = '320px';
          video.style.height = '240px';
          video.style.borderRadius = '16px';
          video.style.boxShadow = '0 10px 30px rgba(0,0,0,0.5)';
          video.style.objectFit = 'cover';
          video.style.border = '3px solid #3B82F6';
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
        return true;
      } catch (err) {
        console.error('Erreur accès caméra :', err);
        return false;
      }
    },

    // Arrêter la webcam et masquer le flux
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
          if (video.parentNode) {
            video.parentNode.removeChild(video);
          }
        }
        return true;
      } catch (err) {
        console.error('Erreur arrêt caméra :', err);
        return false;
      }
    },

    // Détecter le visage et extraire le vecteur d'empreinte faciale (128 valeurs)
    async detectFaceDescriptor(videoElementId = 'stepquest-camera-preview') {
      try {
        await this.loadModels();

        const video = document.getElementById(videoElementId);
        if (!video) return null;

        const detection = await faceapi
          .detectSingleFace(video)
          .withFaceLandmarks()
          .withFaceDescriptor();

        if (!detection) {
          return null; // Aucun visage détecté
        }

        // Retourne la liste des 128 floats sous forme de tableau JSON
        return Array.from(detection.descriptor);
      } catch (err) {
        console.error('Erreur détection faciale :', err);
        return null;
      }
    },

    // Capturer une image miniature du visage pour avatar
    capturePhoto(videoElementId = 'stepquest-camera-preview') {
      try {
        const video = document.getElementById(videoElementId);
        if (!video) return null;

        const canvas = document.createElement('canvas');
        canvas.width = video.videoWidth || 320;
        canvas.height = video.videoHeight || 240;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
        return canvas.toDataURL('image/jpeg', 0.85);
      } catch (err) {
        console.error('Erreur capture photo :', err);
        return null;
      }
    },

    // Comparaison de deux descripteurs faciaux (Distance Euclidienne)
    // Seuil standard face-api : distance < 0.6 = même personne
    compareDescriptors(descriptor1, descriptor2, threshold = 0.55) {
      if (!descriptor1 || !descriptor2) return { match: false, distance: 1.0, confidence: 0 };
      const d1 = Array.isArray(descriptor1) ? descriptor1 : JSON.parse(descriptor1);
      const d2 = Array.isArray(descriptor2) ? descriptor2 : JSON.parse(descriptor2);

      let sum = 0;
      for (let i = 0; i < d1.length; i++) {
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
