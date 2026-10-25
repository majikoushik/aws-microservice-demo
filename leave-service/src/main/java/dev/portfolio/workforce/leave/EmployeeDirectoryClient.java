package dev.portfolio.workforce.leave;

import dev.portfolio.workforce.common.Identity;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.security.access.AccessDeniedException;
import java.time.Duration;

/** Calls Employee Service via REST. No cross-service database queries. */
@Component
public class EmployeeDirectoryClient {
    public record EmployeeSnapshot(Long id,String identitySubject,String name,String email,
        String department,String managerSubject) {}
    private final RestClient client;
    private final HttpServletRequest currentRequest;
    public EmployeeDirectoryClient(RestClient employeeRestClient,HttpServletRequest currentRequest) {
        this.client=employeeRestClient;this.currentRequest=currentRequest;
    }

    @CircuitBreaker(name="employeeDirectory")
    public EmployeeSnapshot lookup(Long id) {
        try {
            return client.get().uri("/api/employees/{id}",id).headers(h -> {
                // Token propagation in this learning project: employee service independently
                // verifies the JWT, so a manager cannot fetch an employee outside their team.
                for (String header : new String[]{"Authorization","X-Demo-Role","X-Demo-Subject","X-Request-ID"}) {
                    String value=currentRequest.getHeader(header);
                    if (value!=null) h.set(header,value);
                }
                if (currentRequest.getHeader("X-Request-ID") == null) {
                    String generatedId = org.slf4j.MDC.get("requestId");
                    if (generatedId != null) h.set("X-Request-ID", generatedId);
                }
            }).retrieve().body(EmployeeSnapshot.class);
        } catch(HttpClientErrorException.Forbidden e) {
            throw new AccessDeniedException("Cannot access employee record " + id);
        } catch(HttpClientErrorException.NotFound e) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,"Employee not found");
        }
    }
}
@Configuration
class EmployeeRestClientConfiguration {
    @Bean RestClient employeeRestClient(@Value("${app.employee-service-url}") String url) {
        SimpleClientHttpRequestFactory http=new SimpleClientHttpRequestFactory();
        http.setConnectTimeout(Duration.ofSeconds(2));
        http.setReadTimeout(Duration.ofSeconds(3));
        return RestClient.builder().baseUrl(url).requestFactory(http).build();
    }
}
