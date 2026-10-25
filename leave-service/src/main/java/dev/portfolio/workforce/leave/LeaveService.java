package dev.portfolio.workforce.leave;

import dev.portfolio.workforce.common.Identity;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

/**
 * A single database transaction protects approval + balance + audit + outbox.
 * A distributed transaction with Employee Service is purposefully NOT used.
 */
@Service
public class LeaveService {
    private final LeaveRequestRepository requests;
    private final LeaveBalanceRepository balances;
    private final LeaveAuditRepository audits;
    private final OutboxRepository outbox;
    private final EmployeeDirectoryClient employeeClient;
    public LeaveService(LeaveRequestRepository requests,LeaveBalanceRepository balances,
                        LeaveAuditRepository audits,OutboxRepository outbox,EmployeeDirectoryClient employeeClient) {
        this.requests=requests;this.balances=balances;this.audits=audits;this.outbox=outbox;this.employeeClient=employeeClient;
    }
    public record CreateLeave(@NotNull Long employeeId,@NotNull LocalDate startDate,@NotNull LocalDate endDate) {}
    public record DecideLeave(String comment) {}
    public record LeaveView(Long id,Long employeeId,LocalDate startDate,LocalDate endDate,
                            int daysRequested,String status,String requestedBy,String approvedBy) {
        static LeaveView from(LeaveRequest r) {return new LeaveView(r.id,r.employeeId,r.startDate,r.endDate,
                r.daysRequested,r.status.name(),r.requestedBy,r.approvedBy);}
    }
    public record BalanceView(Long employeeId,int remainingDays) {}

    @Transactional
    public LeaveView request(CreateLeave input) {
        if (!Identity.hasRole("EMPLOYEE") && !Identity.hasRole("HR"))
            throw new org.springframework.security.access.AccessDeniedException("Only employee or HR can request leave");
        // Employee service validates self ownership / HR access before changing this DB.
        employeeClient.lookup(input.employeeId());
        if (input.endDate().isBefore(input.startDate()) || input.startDate().isBefore(LocalDate.now()))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Choose current/future dates, end >= start");
        long duration=ChronoUnit.DAYS.between(input.startDate(),input.endDate())+1;
        if (duration>30) throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"At most 30 calendar days per request");
        if (requests.existsByEmployeeIdAndStatusInAndStartDateLessThanEqualAndEndDateGreaterThanEqual(
                input.employeeId(),List.of(LeaveRequest.Status.PENDING,LeaveRequest.Status.APPROVED),
                input.endDate(),input.startDate()))
            throw new ResponseStatusException(HttpStatus.CONFLICT,"Overlapping pending or approved leave");
        LeaveRequest r=requests.save(new LeaveRequest(input.employeeId(),input.startDate(),input.endDate(),(int)duration,Identity.subject()));
        audits.save(new LeaveAudit(r.id,Identity.subject(),"REQUESTED",null));
        return LeaveView.from(r);
    }

    @Transactional
    public LeaveView decide(Long id, boolean approve, DecideLeave decision) {
        Identity.require(Identity.hasRole("MANAGER") || Identity.hasRole("HR"));
        LeaveRequest r=requests.findById(id).orElseThrow(()->new ResponseStatusException(HttpStatus.NOT_FOUND,"Leave not found"));
        // Critical ownership rule: managers may approve only people reporting to them.
        var employee=employeeClient.lookup(r.employeeId);
        Identity.require(Identity.hasRole("HR") || Identity.subject().equals(employee.managerSubject()));
        if (r.status!=LeaveRequest.Status.PENDING)
            throw new ResponseStatusException(HttpStatus.CONFLICT,"Request has already been decided");
        if (approve) {
            // Seed a 20-day balance for a first-time employee. For concurrent first approvals,
            // UNIQUE employee_id guards creation; conflicts should be retried by clients.
            LeaveBalance b=balances.findById(r.employeeId).orElseGet(()->balances.save(new LeaveBalance(r.employeeId,20)));
            if (b.remainingDays<r.daysRequested)
                throw new ResponseStatusException(HttpStatus.CONFLICT,"Insufficient leave balance");
            b.remainingDays-=r.daysRequested;
            balances.save(b); // @Version detects concurrent overwrites at commit time.
        }
        r.status=approve?LeaveRequest.Status.APPROVED:LeaveRequest.Status.REJECTED;
        r.approvedBy=Identity.subject();r.decidedAt=java.time.Instant.now();
        r.decisionComment=decision==null?null:decision.comment();
        requests.save(r);
        audits.save(new LeaveAudit(r.id,Identity.subject(),r.status.name(),r.decisionComment));
        // Payload contains an eventId for consumer deduplication, not PII.
        String eventId=UUID.randomUUID().toString();
        String payload="{\"eventId\":\""+eventId+"\",\"eventType\":\"Leave"+r.status.name()+"\",\"leaveId\":"+r.id+",\"employeeId\":"+r.employeeId+"}";
        outbox.save(new OutboxEvent(eventId,"Leave"+r.status.name(),payload));
        return LeaveView.from(r);
    }
    @Transactional(readOnly=true)
    public List<LeaveView> listForEmployee(Long employeeId) {
        employeeClient.lookup(employeeId);
        return requests.findByEmployeeIdOrderByIdDesc(employeeId).stream().map(LeaveView::from).toList();
    }
    @Transactional(readOnly=true)
    public BalanceView getBalance(Long employeeId) {
        employeeClient.lookup(employeeId);
        return new BalanceView(employeeId,balances.findById(employeeId).map(x->x.remainingDays).orElse(20));
    }
    @Transactional(readOnly=true)
    public List<LeaveAudit> audit(Long id) {
        LeaveRequest r=requests.findById(id).orElseThrow(()->new ResponseStatusException(HttpStatus.NOT_FOUND,"Leave not found"));
        employeeClient.lookup(r.employeeId);
        return audits.findByRequestIdOrderByIdAsc(id);
    }
}
