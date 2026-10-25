package dev.portfolio.workforce.leave;
import jakarta.persistence.*;
import java.time.Instant;
@Entity @Table(name="leave_audit")
public class LeaveAudit {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id;
    @Column(nullable=false) public Long requestId;
    @Column(nullable=false) public String actor;
    @Column(nullable=false) public String action;
    @Column(nullable=false) public Instant occurredAt;
    public String comment;
    protected LeaveAudit() {}
    public LeaveAudit(Long requestId,String actor,String action,String comment) {
        this.requestId=requestId;this.actor=actor;this.action=action;
        this.comment=comment;this.occurredAt=Instant.now();
    }
}
