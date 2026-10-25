package dev.portfolio.workforce.leave;
import jakarta.persistence.*;
/** @Version detects lost updates when two approvers act on the same balance. */
@Entity @Table(name="leave_balances")
public class LeaveBalance {
    @Id public Long employeeId;
    @Column(nullable=false) public int remainingDays;
    @Version public Long version;
    protected LeaveBalance() {}
    public LeaveBalance(Long employeeId,int remainingDays) {this.employeeId=employeeId;this.remainingDays=remainingDays;}
}
