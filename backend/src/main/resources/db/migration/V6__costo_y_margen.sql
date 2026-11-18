-- Costo de cada producto (lo que le cuesta al tendero) y cuánto quiere ganar el negocio.
-- Opcionales: las versiones anteriores de la app no los envían y siguen funcionando igual.
ALTER TABLE producto ADD COLUMN costo    BIGINT;
ALTER TABLE producto ADD COLUMN costo_en TIMESTAMP WITH TIME ZONE;
ALTER TABLE usuario  ADD COLUMN margen   INT;
