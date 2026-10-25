package dev.portfolio.workforce.leave;
import dev.portfolio.workforce.common.Identity;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import java.time.LocalDate;
import java.util.List;

@Repository interface AttendanceRepository extends JpaRepository<Attendance,Long> {
    List<Attendance> findByEmployeeIdOrderByWorkDateDesc(Long employeeId);
    boolean existsByEmployeeIdAndWorkDate(Long employeeId,LocalDate date);
}
/** An intentionally small feature to teach CRUD, ownership checks and unique constraints. */
@RestController @RequestMapping("/api/attendance")
public class AttendanceController {
    private final AttendanceRepository attendance;
    private final EmployeeDirectoryClient employees;
    public AttendanceController(AttendanceRepository attendance,EmployeeDirectoryClient employees) {
        this.attendance=attendance;this.employees=employees;
    }
    public record MarkAttendance(@NotNull Long employeeId,@NotNull LocalDate date,@NotNull Attendance.Status status) {}
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public Attendance mark(@Valid @RequestBody MarkAttendance r) {
        // GET /employees/{id} checks ownership before we store sensitive data.
        employees.lookup(r.employeeId());
        Identity.require(Identity.hasRole("EMPLOYEE") || Identity.hasRole("HR"));
        if (r.date().isAfter(LocalDate.now()))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Cannot record future attendance");
        if (attendance.existsByEmployeeIdAndWorkDate(r.employeeId(),r.date()))
            throw new ResponseStatusException(HttpStatus.CONFLICT,"Attendance already recorded for this date");
        return attendance.save(new Attendance(r.employeeId(),r.date(),r.status(),Identity.subject()));
    }
    @GetMapping("/employee/{employeeId}")
    public List<Attendance> list(@PathVariable Long employeeId) {
        employees.lookup(employeeId);
        return attendance.findByEmployeeIdOrderByWorkDateDesc(employeeId);
    }
}
