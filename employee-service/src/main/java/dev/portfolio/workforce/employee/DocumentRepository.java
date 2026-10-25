package dev.portfolio.workforce.employee;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface DocumentRepository extends JpaRepository<DocumentMetadata,Long> {
    List<DocumentMetadata> findByEmployeeIdOrderByIdDesc(Long employeeId);
}
