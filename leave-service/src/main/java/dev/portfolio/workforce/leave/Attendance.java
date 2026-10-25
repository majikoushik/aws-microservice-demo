package dev.portfolio.workforce.leave;
import jakarta.persistence.*;
import java.time.LocalDate;
/** Simplified attendance: one record per employee per date. */
@Entity @Table(name="attendance",uniqueConstraints=@UniqueConstraint(columnNames={"employee_id","work_date"}))
public class Attendance {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id;
    @Column(nullable=false) public Long employeeId;
    @Column(nullable=false) public LocalDate workDate;
    @Enumerated(EnumType.STRING) @Column(nullable=false) public Status status;
    @Column(nullable=false) public String recordedBy;
    public enum Status { PRESENT, REMOTE, ABSENT }
    protected Attendance() {}
    public Attendance(Long employeeId,LocalDate workDate,Status status,String recordedBy) {
        this.employeeId=employeeId;this.workDate=workDate;this.status=status;this.recordedBy=recordedBy;
    }
}
