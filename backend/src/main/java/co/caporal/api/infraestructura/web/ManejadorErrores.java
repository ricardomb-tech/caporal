package co.caporal.api.infraestructura.web;

import co.caporal.api.comun.ErrorDeNegocio;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

/**
 * Errores de la API en un formato único: {"status", "detail"} con el mensaje en español.
 * La app muestra `detail` tal cual, así que debe ser un texto que el dueño del negocio entienda.
 */
@RestControllerAdvice
public class ManejadorErrores extends ResponseEntityExceptionHandler {

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(MethodArgumentNotValidException ex,
                                                                  HttpHeaders headers, HttpStatusCode status,
                                                                  WebRequest request) {
        String mensaje = ex.getBindingResult().getFieldErrors().stream()
                .map(e -> e.getDefaultMessage())
                .findFirst()
                .orElse("Revise los datos e intente de nuevo");
        return ResponseEntity.badRequest().body(ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, mensaje));
    }

    /** Traduce las reglas del negocio que no se cumplieron al código HTTP que les corresponde. */
    @ExceptionHandler(ErrorDeNegocio.class)
    ResponseEntity<ProblemDetail> errorDeNegocio(ErrorDeNegocio ex) {
        HttpStatus estado = switch (ex.getTipo()) {
            case CONFLICTO -> HttpStatus.CONFLICT;
            case NO_AUTORIZADO -> HttpStatus.UNAUTHORIZED;
            case DEMASIADOS_INTENTOS -> HttpStatus.TOO_MANY_REQUESTS;
        };
        return ResponseEntity.status(estado).body(ProblemDetail.forStatusAndDetail(estado, ex.getMessage()));
    }
}
