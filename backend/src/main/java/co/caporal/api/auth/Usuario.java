package co.caporal.api.auth;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "usuario")
public class Usuario {
    @Id
    private UUID id;
    @Column(nullable = false, unique = true)
    private String celular;
    @Column(name = "nombre_negocio", nullable = false)
    private String nombreNegocio;
    @Column(nullable = false)
    private String municipio;
    @Column(name = "password_hash", nullable = false)
    private String passwordHash;
    @Column(name = "intentos_fallidos", nullable = false)
    private int intentosFallidos;
    @Column(name = "bloqueado_hasta")
    private Instant bloqueadoHasta;
    @Column(name = "acepta_datos_en", nullable = false)
    private Instant aceptaDatosEn;
    @Column(name = "creado_en", nullable = false)
    private Instant creadoEn;

    protected Usuario() {
    }

    public Usuario(String celular, String nombreNegocio, String municipio, String passwordHash, Instant ahora) {
        this.id = UUID.randomUUID();
        this.celular = celular;
        this.nombreNegocio = nombreNegocio;
        this.municipio = municipio;
        this.passwordHash = passwordHash;
        this.aceptaDatosEn = ahora;
        this.creadoEn = ahora;
    }

    public UUID getId() { return id; }
    public String getCelular() { return celular; }
    public String getNombreNegocio() { return nombreNegocio; }
    public String getPasswordHash() { return passwordHash; }

    public boolean estaBloqueado(Instant ahora) {
        return bloqueadoHasta != null && bloqueadoHasta.isAfter(ahora);
    }

    public void registrarFallo(int maximo, Instant bloquearHasta) {
        intentosFallidos++;
        if (intentosFallidos >= maximo) {
            bloqueadoHasta = bloquearHasta;
            intentosFallidos = 0;
        }
    }

    public void registrarIngreso() {
        intentosFallidos = 0;
        bloqueadoHasta = null;
    }
}
