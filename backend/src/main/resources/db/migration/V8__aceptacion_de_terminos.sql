-- Qué versión de los términos y condiciones aceptó el dueño y cuándo (registro de la aceptación).
ALTER TABLE usuario ADD COLUMN terminos_version     VARCHAR(20);
ALTER TABLE usuario ADD COLUMN terminos_aceptados_en TIMESTAMP WITH TIME ZONE;
