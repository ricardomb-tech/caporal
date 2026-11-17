-- Catálogo de productos. Cada campo guarda cuándo cambió: al sincronizar, el cambio más reciente
-- de cada campo gana (el celular y el servidor llegan al mismo resultado sin importar el orden).
CREATE TABLE producto (
    id             UUID PRIMARY KEY,
    usuario_id     UUID         NOT NULL REFERENCES usuario (id),
    nombre         VARCHAR(60)  NOT NULL,
    precio         BIGINT       NOT NULL,
    controla_stock BOOLEAN      NOT NULL,
    activo         BOOLEAN      NOT NULL,
    nombre_en      TIMESTAMP WITH TIME ZONE NOT NULL,
    precio_en      TIMESTAMP WITH TIME ZONE NOT NULL,
    controla_en    TIMESTAMP WITH TIME ZONE NOT NULL,
    activo_en      TIMESTAMP WITH TIME ZONE NOT NULL,
    recibido_en    TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_producto_usuario ON producto (usuario_id);

-- Movimientos de inventario: inmutables, como los de dinero. La cantidad de un producto es la suma
-- de sus delta. producto_id no tiene llave foránea a propósito: el servidor no debe depender del
-- orden en que llegan el producto y sus cantidades.
CREATE TABLE mov_inventario (
    id                    UUID PRIMARY KEY,
    usuario_id            UUID        NOT NULL REFERENCES usuario (id),
    producto_id           UUID        NOT NULL,
    delta                 INT         NOT NULL,
    motivo                VARCHAR(10) NOT NULL,
    movimiento_id         UUID,
    precio_unitario       BIGINT,
    dispositivo_id        VARCHAR(64) NOT NULL,
    creado_en_dispositivo TIMESTAMP WITH TIME ZONE NOT NULL,
    recibido_en           TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_inventario_usuario_producto ON mov_inventario (usuario_id, producto_id);
