package dev.portfolio.workforce.leave;
import dev.portfolio.workforce.common.*;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Import;
import org.springframework.scheduling.annotation.EnableScheduling;
@SpringBootApplication
@EnableScheduling
@Import({SecurityConfiguration.class,CommonWebConfiguration.class,ApiExceptionHandler.class})
public class LeaveApplication {
    public static void main(String[] args) { SpringApplication.run(LeaveApplication.class,args); }
}
