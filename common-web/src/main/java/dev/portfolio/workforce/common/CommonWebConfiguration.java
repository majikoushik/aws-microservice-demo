package dev.portfolio.workforce.common;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
@Configuration
public class CommonWebConfiguration {
  @Bean RequestIdFilter requestIdFilter() { return new RequestIdFilter(); }
}
