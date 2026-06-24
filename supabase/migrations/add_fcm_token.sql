-- Agregar columna fcm_token a la tabla usuarios
-- Ejecutar en: Supabase Dashboard → SQL Editor

ALTER TABLE usuarios 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Índice opcional para búsquedas rápidas por token
CREATE INDEX IF NOT EXISTS idx_usuarios_fcm_token 
ON usuarios(fcm_token) 
WHERE fcm_token IS NOT NULL;
