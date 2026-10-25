package dev.portfolio.workforce.common;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.MDC;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.UUID;

/** Correlate requests across services. The actual cross-service client forwards this header. */
public final class RequestIdFilter extends OncePerRequestFilter {
    @Override protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String provided = req.getHeader("X-Request-ID");
        // Keep IDs short/printable: otherwise user input can pollute logs.
        String id = provided != null && provided.matches("[A-Za-z0-9_-]{1,64}")
            ? provided : UUID.randomUUID().toString();
        MDC.put("requestId", id);
        res.setHeader("X-Request-ID", id);
        try { chain.doFilter(req, res); } finally { MDC.remove("requestId"); }
    }
}
