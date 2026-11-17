package co.caporal.api.auth;

import co.caporal.api.auditoria.RegistroSeguridad;
import co.caporal.api.catalogo.MovInventarioRepository;
import co.caporal.api.catalogo.ProductoRepository;
import co.caporal.api.sync.MovimientoRepository;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Caso de uso: borrar la cuenta y todo lo que el negocio guardó (sesiones, movimientos, productos e inventario). */
@Service
public class EliminarCuenta {
    private final UsuarioRepository usuarios;
    private final MovimientoRepository movimientos;
    private final ProductoRepository productos;
    private final MovInventarioRepository inventario;
    private final SesionRepository sesiones;
    private final RegistroSeguridad registro;

    public EliminarCuenta(UsuarioRepository usuarios, MovimientoRepository movimientos, ProductoRepository productos,
                          MovInventarioRepository inventario, SesionRepository sesiones,
                          RegistroSeguridad registro) {
        this.usuarios = usuarios;
        this.movimientos = movimientos;
        this.productos = productos;
        this.inventario = inventario;
        this.sesiones = sesiones;
        this.registro = registro;
    }

    @Transactional
    public void ejecutar(UUID usuarioId) {
        sesiones.borrarDeUsuario(usuarioId);
        inventario.borrarDeUsuario(usuarioId);
        productos.borrarDeUsuario(usuarioId);
        movimientos.borrarDeUsuario(usuarioId);
        usuarios.deleteById(usuarioId);
        registro.cuentaEliminada(usuarioId);
    }
}
