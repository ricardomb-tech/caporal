-- Sesiones renovables: el teléfono guarda un token de renovación de un solo uso.
-- Solo se guarda su huella SHA-256, nunca el token. Cada renovación revoca el anterior y apunta al nuevo;
-- si llega uno ya revocado (posible robo), se cierran todas las sesiones de esa cuenta.
CREATE TABLE sesion (
    id              UUID PRIMARY KEY,
    usuario_id      UUID        NOT NULL REFERENCES usuario (id),
    token_hash      VARCHAR(64) NOT NULL UNIQUE,
    creado_en       TIMESTAMP WITH TIME ZONE NOT NULL,
    expira_en       TIMESTAMP WITH TIME ZONE NOT NULL,
    revocado_en     TIMESTAMP WITH TIME ZONE,
    reemplazada_por UUID
);

CREATE INDEX idx_sesion_usuario ON sesion (usuario_id);

-- Argon2id con prefijo {argon2} ocupa más de 100 caracteres.
ALTER TABLE usuario ALTER COLUMN password_hash TYPE VARCHAR(255);
