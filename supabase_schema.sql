-- ==============================================================================
-- STEPQUEST — SCHÉMA SUPABASE POSTGRESQL (MODULE GESTION DES UTILISATEURS)
-- ==============================================================================
-- Ce script est 100% compatible avec l'architecture StepQuest Flutter.
-- À exécuter directement dans l'éditeur SQL de votre tableau de bord Supabase :
-- Dashboard Supabase > SQL Editor > New query > Run.
-- ==============================================================================

-- 1. EXTENSIONS REQUISES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. TABLE DES PROFILS UTILISATEURS (public.profiles)
-- ==============================================================================
-- Liée directement à auth.users(id) avec suppression en cascade.
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended')),
    biometric_fingerprint_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    biometric_face_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    face_embedding TEXT,
    face_photo_url TEXT,
    height_cm INTEGER CHECK (height_cm IS NULL OR (height_cm > 0 AND height_cm < 300)),
    weight_kg NUMERIC(5,2) CHECK (weight_kg IS NULL OR (weight_kg > 0 AND weight_kg < 500)),
    birth_date DATE,
    level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
    device_info TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login_at TIMESTAMPTZ
);

-- ==============================================================================
-- 3. TABLE DES NOTIFICATIONS SYSTÈME & SÉCURITÉ (public.notifications)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN (
        'accountCreated',
        'accountSuspended',
        'accountReactivated',
        'loginDetected',
        'profileUpdated',
        'roleChanged',
        'accountDeleted',
        'securityAlert'
    )),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    related_user_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 4. INDEX DE PERFORMANCE
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(status);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON public.profiles(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- ==============================================================================
-- 5. FONCTIONS & DÉCLENCHEURS AUTOMATIQUES (TRIGGERS)
-- ==============================================================================

-- A. Création automatique du profil lors de l'inscription via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        full_name,
        email,
        role,
        status,
        level,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
        'active',
        1,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- B. Mise à jour automatique du champ updated_at lors d'une modification
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_profile_updated ON public.profiles;
CREATE TRIGGER on_profile_updated
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- C. Fonction utilitaire pour vérifier si l'utilisateur actuel est Administrateur
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin' AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ==============================================================================
-- 6. SÉCURITÉ AU NIVEAU DES LIGNES (ROW LEVEL SECURITY - RLS)
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Politiques de lecture / écriture pour les Profils
DROP POLICY IF EXISTS "Les utilisateurs et admins peuvent lire les profils" ON public.profiles;
CREATE POLICY "Les utilisateurs et admins peuvent lire les profils"
    ON public.profiles
    FOR SELECT
    USING (auth.uid() = id OR public.is_admin());

DROP POLICY IF EXISTS "Les utilisateurs modifient leur propre profil ou admin" ON public.profiles;
CREATE POLICY "Les utilisateurs modifient leur propre profil ou admin"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id OR public.is_admin());

DROP POLICY IF EXISTS "Insertion de profil autorisée pour le propriétaire ou admin" ON public.profiles;
CREATE POLICY "Insertion de profil autorisée pour le propriétaire ou admin"
    ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id OR public.is_admin());

DROP POLICY IF EXISTS "Suppression autorisée par le propriétaire ou admin" ON public.profiles;
CREATE POLICY "Suppression autorisée par le propriétaire ou admin"
    ON public.profiles
    FOR DELETE
    USING (auth.uid() = id OR public.is_admin());

-- Politiques pour les Notifications
DROP POLICY IF EXISTS "Consultation des notifications personnelles ou admin" ON public.notifications;
CREATE POLICY "Consultation des notifications personnelles ou admin"
    ON public.notifications
    FOR SELECT
    USING (auth.uid() = user_id OR user_id IS NULL OR public.is_admin());

DROP POLICY IF EXISTS "Mise à jour des notifications personnelles ou admin" ON public.notifications;
CREATE POLICY "Mise à jour des notifications personnelles ou admin"
    ON public.notifications
    FOR UPDATE
    USING (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Insertion de notification par utilisateur authentifié" ON public.notifications;
CREATE POLICY "Insertion de notification par utilisateur authentifié"
    ON public.notifications
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- ==============================================================================
-- 7. REQUÊTES UTILES POUR LA GESTION DES ADMINISTRATEURS
-- ==============================================================================
-- Pour promouvoir un utilisateur au rang d'Administrateur après son inscription :
-- UPDATE public.profiles SET role = 'admin' WHERE email = 'votre-email@example.com';

