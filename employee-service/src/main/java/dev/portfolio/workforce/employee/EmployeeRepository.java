package dev.portfolio.workforce.employee;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface EmployeeRepository extends JpaRepository<Employee, Long> {
    boolean existsByEmailIgnoreCase(String email);
    boolean existsByIdentitySubject(String identitySubject);
    Optional<Employee> findByIdentitySubject(String subject);
    Page<Employee> findByDepartmentIgnoreCase(String department, Pageable pageable);
    Page<Employee> findByManagerSubject(String subject, Pageable pageable);
}
