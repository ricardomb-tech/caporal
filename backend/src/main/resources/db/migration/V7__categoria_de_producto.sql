-- Categoría del producto (Bebidas, Aseo, ...) para buscarlo rápido al vender. Opcional.
ALTER TABLE producto ADD COLUMN categoria    VARCHAR(40);
ALTER TABLE producto ADD COLUMN categoria_en TIMESTAMP WITH TIME ZONE;
