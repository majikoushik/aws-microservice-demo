package dev.portfolio.workforce.common;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.core.*;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.www.BasicAuthenticationFilter;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.List;
import java.util.Locale;

/**
 * Security profiles deliberately have DIFFERENT trust models:
 * local: an explicit demonstration-only identity in HTTP headers (NOT secure!).
 * aws: signed OAuth2 JWTs validated by Spring Security against Cognito JWKS.
 * NEVER enable the local filter in the AWS profile.
 */
@Configuration
@EnableMethodSecurity
public class SecurityConfiguration {
    @Bean
    @Profile("local")
    SecurityFilterChain localSecurity(HttpSecurity http) throws Exception {
        System.out.println(">>> LOCAL SECURITY CONFIGURATION LOADED <<<");
        return http
                .csrf(csrf -> csrf.disable())

                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )

                .authorizeHttpRequests(auth -> auth

                        // Allow health check
                        .requestMatchers(
                                "/actuator/health",
                                "/actuator/health/**"
                        ).permitAll()

                        // Allow Swagger UI and OpenAPI documentation
                        .requestMatchers(
                                "/swagger-ui/**",
                                "/swagger-ui.html",
                                "/v3/api-docs",
                                "/v3/api-docs/**",
                                "/error"
                        ).permitAll()

                        // Other REST APIs require authentication
                        .anyRequest().authenticated()
                )

                .exceptionHandling(exception ->
                        exception.authenticationEntryPoint(
                                (request, response, ex) -> response.sendError(401)
                        )
                )

                .addFilterBefore(
                        new LocalIdentityFilter(),
                        BasicAuthenticationFilter.class
                )

                .build();
    }

    @Bean
    @Profile("aws")
    SecurityFilterChain awsSecurity(HttpSecurity http) throws Exception {
        System.out.println(">>> AWS SECURITY CONFIGURATION LOADED <<<");
        return http.csrf(csrf -> csrf.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a -> a.requestMatchers(
                            "/actuator/health",
                            "/actuator/health/**",
                            "/swagger-ui/**",
                            "/swagger-ui.html",
                            "/v3/api-docs/**",
                            "/error"
                    ).permitAll()
                .anyRequest().authenticated())
            .oauth2ResourceServer(o -> o.jwt(j -> j.jwtAuthenticationConverter(cognitoConverter())))
            .build();
    }

    /**
     * Defense in depth: the API Gateway JWT authorizer also validates audience.
     * Cognito *access* tokens carry client_id (unlike most ID tokens carrying aud).
     * Reject ID tokens and tokens for a different application even if signed.
     */
    @Bean
    @Profile("aws")
    JwtDecoder cognitoJwtDecoder(
            @Value("${spring.security.oauth2.resourceserver.jwt.issuer-uri}") String issuer,
            @Value("${app.security.cognito-client-id}") String clientId) {
        NimbusJwtDecoder decoder = NimbusJwtDecoder.withJwkSetUri(issuer + "/.well-known/jwks.json").build();
        OAuth2TokenValidator<Jwt> cognitoClaims = jwt -> {
            if (!"access".equals(jwt.getClaimAsString("token_use")) ||
                    !clientId.equals(jwt.getClaimAsString("client_id"))) {
                return OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token",
                    "Expected a Cognito access token for this client", null));
            }
            return OAuth2TokenValidatorResult.success();
        };
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
            JwtValidators.createDefaultWithIssuer(issuer), cognitoClaims));
        return decoder;
    }

    /** Cognito supplies application roles in the cognito:groups claim. */
    private JwtAuthenticationConverter cognitoConverter() {
        JwtAuthenticationConverter c = new JwtAuthenticationConverter();
        c.setJwtGrantedAuthoritiesConverter(jwt -> {
            List<String> groups = jwt.getClaimAsStringList("cognito:groups");
            if (groups == null) return List.of();
            return groups.stream().map(g -> (org.springframework.security.core.GrantedAuthority) new SimpleGrantedAuthority("ROLE_" + g.toUpperCase(Locale.ROOT)))
                .toList();
        });
        return c;
    }

    /** This class is intentionally NOT a Spring component, to avoid AWS activation. */
    static final class LocalIdentityFilter extends OncePerRequestFilter {
        @Override protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
                throws ServletException, IOException {
            String role = request.getHeader("X-Demo-Role");
            String subject = request.getHeader("X-Demo-Subject");
            if (role != null && subject != null && !subject.isBlank()) {
                role = role.toUpperCase(Locale.ROOT);
                if (List.of("HR", "MANAGER", "EMPLOYEE").contains(role)) {
                    var token = new UsernamePasswordAuthenticationToken(subject, null,
                        List.of(new SimpleGrantedAuthority("ROLE_" + role)));
                    SecurityContextHolder.getContext().setAuthentication(token);
                }
            }
            try { chain.doFilter(request, response); }
            finally { SecurityContextHolder.clearContext(); }
        }

        @Override
        protected boolean shouldNotFilter(HttpServletRequest request) {

            String path = request.getServletPath();

            return path.equals("/swagger-ui.html")
                    || path.startsWith("/swagger-ui/")
                    || path.equals("/v3/api-docs")
                    || path.startsWith("/v3/api-docs/")
                    || path.equals("/actuator/health")
                    || path.startsWith("/actuator/health/")
                    || path.equals("/error");
        }
    }
}
