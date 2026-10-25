package dev.portfolio.workforce.employee;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
@Configuration @Profile("local")
public class LocalSeedData {
    @Bean CommandLineRunner sampleEmployees(EmployeeRepository employees) {
        return args -> {
            if (employees.count()>0) return;
            // Stable demonstration subjects. Local header identities MUST NOT be enabled in AWS.
            employees.save(new Employee("employee-alice","Alice Sharma","alice@example.test","Engineering","manager-maria"));
            employees.save(new Employee("employee-bob","Bob Kumar","bob@example.test","Engineering","manager-maria"));
            employees.save(new Employee("manager-maria","Maria Roy","maria@example.test","Engineering",null));
        };
    }
}
