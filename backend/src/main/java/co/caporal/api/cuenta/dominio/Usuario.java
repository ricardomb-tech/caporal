package co.caporal.api.cuenta.dominio;

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
    @Column(name = "nombre_persona")
    private String nombrePersona;
    private String correo;
    @Column(name = "tipo_negocio")
    private String tipoNegocio;
    @Column(name = "llave_breb")
    private String llaveBreB;
    @Column(name = "compartir_cifras", nullable = false)
    private boolean compartirCifras;
    /** Cuándo se cambió el perfil en el teléfono (null si nunca se ha enviado). */
    @Column(name = "perfil_en")
    private Instant perfilEn;
    /** Cuánto quiere ganar sobre el costo de cada producto, en % (null si no lo ha elegido). */
    private Integer margen;

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

    public String getMunicipio() { return municipio; }
    public String getNombrePersona() { return nombrePersona; }
    public String getCorreo() { return correo; }
    public String getTipoNegocio() { return tipoNegocio; }
    public String getLlaveBreB() { return llaveBreB; }
    public boolean isCompartirCifras() { return compartirCifras; }
    public Instant getPerfilEn() { return perfilEn; }
    public Integer getMargen() { return margen; }

    /**
     * Aplica el perfil que manda el teléfono solo si es más reciente que el guardado: así un
     * celular viejo que se conecta tarde no borra lo que se cambió después en otro.
     * Devuelve true si lo aplicó.
     */
    public boolean actualizarPerfil(Perfil p, Instant modificadoEn) {
        if (perfilEn != null && !modificadoEn.isAfter(perfilEn)) {
            return false;
        }
        nombreNegocio = p.nombreNegocio().trim();
        municipio = p.municipio().trim();
        nombrePersona = vacioANulo(p.nombrePersona());
        correo = vacioANulo(p.correo());
        tipoNegocio = vacioANulo(p.tipoNegocio());
        llaveBreB = vacioANulo(p.llaveBreB());
        compartirCifras = p.compartirCifras();
        margen = p.margen();
        perfilEn = modificadoEn;
        return true;
    }

    private static String vacioANulo(String s) {
        return s == null || s.isBlank() ? null : s.trim();
    }

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

    public void cambiarClave(String nuevoHash) {
        this.passwordHash = nuevoHash;
        registrarIngreso();
    }

    public void registrarIngreso() {
        intentosFallidos = 0;
        bloqueadoHasta = null;
    }
}
