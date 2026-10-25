package dev.portfolio.workforce.leave;
import jakarta.persistence.*;
import java.time.*;
/** No SQL foreign key to the Employee Service database: each microservice owns its data. */
@Entity @Table(name="leave_requests")
public class LeaveRequest {
    public enum Status {PENDING,APPROVED,REJECTED}
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id;
    @Column(nullable=false) public Long employeeId;
    @Column(nullable=false) public LocalDate startDate;
    @Column(nullable=false) public LocalDate endDate;
    @Column(nullable=false) public int daysRequested;
    @Enumerated(EnumType.STRING) @Column(nullable=false) public Status status=Status.PENDING;
    @Column(nullable=false) public String requestedBy;
    public String approvedBy;
    public Instant decidedAt;
    public String decisionComment;
    public Instant createdAt=Instant.now();
    @Version public Long version;
    protected LeaveRequest() {}
    public LeaveRequest(Long employeeId,LocalDate start,LocalDate end,int days,String requester) {
        this.employeeId=employeeId;this.startDate=start;this.endDate=end;
        this.daysRequested=days;this.requestedBy=requester;
    }
}
