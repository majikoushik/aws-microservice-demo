package dev.portfolio.workforce.common;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.client.RestClientException;
import java.time.Instant;
import java.util.Map;
import java.util.stream.Collectors;

/** Consistent, safe API errors: never send stack traces or database credentials to callers. */
@RestControllerAdvice
public class ApiExceptionHandler {
    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<?> validation(MethodArgumentNotValidException e) {
        String detail = e.getBindingResult().getFieldErrors().stream()
            .map(f -> f.getField() + ": " + f.getDefaultMessage())
            .collect(Collectors.joining("; "));
        return body(HttpStatus.BAD_REQUEST, detail);
    }
    @ExceptionHandler(AccessDeniedException.class)
    ResponseEntity<?> denied(AccessDeniedException e) { return body(HttpStatus.FORBIDDEN, e.getMessage()); }
    @ExceptionHandler(ResponseStatusException.class)
    ResponseEntity<?> status(ResponseStatusException e) {
        return body(HttpStatus.valueOf(e.getStatusCode().value()), e.getReason());
    }
    @ExceptionHandler(DataIntegrityViolationException.class)
    ResponseEntity<?> duplicate(DataIntegrityViolationException e) {
        return body(HttpStatus.CONFLICT, "Conflicting or duplicate database value");
    }
    @ExceptionHandler(RestClientException.class)
    ResponseEntity<?> upstream(RestClientException e) {
        return body(HttpStatus.BAD_GATEWAY, "Upstream employee service could not be contacted");
    }
    private ResponseEntity<?> body(HttpStatus status, String message) {
        return ResponseEntity.status(status).body(Map.of("time", Instant.now().toString(),
            "status", status.value(), "message", message == null ? status.getReasonPhrase() : message));
    }
}
