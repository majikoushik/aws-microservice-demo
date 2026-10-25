package dev.portfolio.workforce.employee;

import dev.portfolio.workforce.common.*;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Import;

@SpringBootApplication
@Import({SecurityConfiguration.class, CommonWebConfiguration.class, ApiExceptionHandler.class})
public class EmployeeApplication {
    public static void main(String[] args) { SpringApplication.run(EmployeeApplication.class, args); }
}
