-- Perfil del negocio en el servidor, para no perderlo al reinstalar o cambiar de celular.
-- perfil_en: cuándo se cambió en el teléfono; gana el cambio más reciente.
ALTER TABLE usuario ADD COLUMN nombre_persona   VARCHAR(120);
ALTER TABLE usuario ADD COLUMN correo           VARCHAR(120);
ALTER TABLE usuario ADD COLUMN tipo_negocio     VARCHAR(30);
ALTER TABLE usuario ADD COLUMN llave_breb       VARCHAR(60);
ALTER TABLE usuario ADD COLUMN compartir_cifras BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE usuario ADD COLUMN perfil_en        TIMESTAMP WITH TIME ZONE;
