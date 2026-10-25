package dev.portfolio.workforce.employee;
import jakarta.persistence.*;
import java.time.Instant;
/** Store metadata in RDS; file bytes go to S3 or a local folder, never in MySQL. */
@Entity @Table(name="employee_documents")
public class DocumentMetadata {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id;
    @Column(nullable=false) public Long employeeId;
    @Column(nullable=false) public String originalFilename;
    @Column(nullable=false) public String storageKey;
    @Column(nullable=false) public String contentType;
    public long sizeBytes;
    public Instant createdAt;
    protected DocumentMetadata() {}
    public DocumentMetadata(Long employeeId,String originalFilename,String storageKey,String contentType,long sizeBytes) {
        this.employeeId=employeeId;this.originalFilename=originalFilename;this.storageKey=storageKey;
        this.contentType=contentType;this.sizeBytes=sizeBytes;this.createdAt=Instant.now();
    }
}
