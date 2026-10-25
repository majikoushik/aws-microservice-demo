
package dev.portfolio.workforce.employee;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

@Configuration
@Profile("local")
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {

        return new OpenAPI()
                .components(new Components()

                        // Local demonstration role
                        .addSecuritySchemes("DemoRole",
                                new SecurityScheme()
                                        .type(SecurityScheme.Type.APIKEY)
                                        .in(SecurityScheme.In.HEADER)
                                        .name("X-Demo-Role"))

                        // Local demonstration subject
                        .addSecuritySchemes("DemoSubject",
                                new SecurityScheme()
                                        .type(SecurityScheme.Type.APIKEY)
                                        .in(SecurityScheme.In.HEADER)
                                        .name("X-Demo-Subject"))
                )

                // Both headers are required for authenticated APIs
                .addSecurityItem(new SecurityRequirement()
                        .addList("DemoRole")
                        .addList("DemoSubject"));
    }
}
