package dev.portfolio.workforce.leave;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.List;

/* Package-private repositories keep the teaching repository compact. */
@Repository interface LeaveRequestRepository extends JpaRepository<LeaveRequest,Long> {
    List<LeaveRequest> findByEmployeeIdOrderByIdDesc(Long employeeId);
    boolean existsByEmployeeIdAndStatusInAndStartDateLessThanEqualAndEndDateGreaterThanEqual(
        Long employeeId,List<LeaveRequest.Status> statuses,LocalDate end,LocalDate start);
}
@Repository interface LeaveBalanceRepository extends JpaRepository<LeaveBalance,Long> {}
@Repository interface LeaveAuditRepository extends JpaRepository<LeaveAudit,Long> {
    List<LeaveAudit> findByRequestIdOrderByIdAsc(Long requestId);
}
@Repository interface OutboxRepository extends JpaRepository<OutboxEvent,String> {
    List<OutboxEvent> findTop20ByPublishedAtIsNullOrderByCreatedAtAsc();
}
