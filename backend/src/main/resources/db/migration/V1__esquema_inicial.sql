-- Esquema inicial de Caporal
CREATE TABLE usuario (
    id                UUID PRIMARY KEY,
    celular           VARCHAR(15)  NOT NULL UNIQUE,
    nombre_negocio    VARCHAR(120) NOT NULL,
    municipio         VARCHAR(80)  NOT NULL,
    password_hash     VARCHAR(100) NOT NULL,
    intentos_fallidos INT          NOT NULL DEFAULT 0,
    bloqueado_hasta   TIMESTAMP WITH TIME ZONE,
    acepta_datos_en   TIMESTAMP WITH TIME ZONE NOT NULL,
    creado_en         TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Los movimientos son inmutables: nunca se actualizan ni se borran.
-- Una corrección es un movimiento nuevo con reverso_de apuntando al original.
CREATE TABLE movimiento (
    id                    UUID PRIMARY KEY,
    usuario_id            UUID         NOT NULL REFERENCES usuario (id),
    tipo                  VARCHAR(10)  NOT NULL,
    valor                 BIGINT       NOT NULL,
    descripcion           VARCHAR(200),
    cliente_nombre        VARCHAR(120),
    medio_pago            VARCHAR(20),
    dispositivo_id        VARCHAR(64)  NOT NULL,
    creado_en_dispositivo TIMESTAMP WITH TIME ZONE NOT NULL,
    reverso_de            UUID,
    recibido_en           TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_movimiento_usuario_recibido ON movimiento (usuario_id, recibido_en);
