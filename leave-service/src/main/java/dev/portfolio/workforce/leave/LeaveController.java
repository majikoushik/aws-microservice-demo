package dev.portfolio.workforce.leave;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController @RequestMapping("/api/leaves")
public class LeaveController {
    private final LeaveService service;
    public LeaveController(LeaveService service) {this.service=service;}
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public LeaveService.LeaveView request(@Valid @RequestBody LeaveService.CreateLeave request) {return service.request(request);}
    @PostMapping("/{id}/approve") public LeaveService.LeaveView approve(@PathVariable Long id,
        @RequestBody(required=false) LeaveService.DecideLeave decision) {return service.decide(id,true,decision);}
    @PostMapping("/{id}/reject") public LeaveService.LeaveView reject(@PathVariable Long id,
        @RequestBody(required=false) LeaveService.DecideLeave decision) {return service.decide(id,false,decision);}
    @GetMapping("/employee/{employeeId}") public List<LeaveService.LeaveView> list(@PathVariable Long employeeId) {
        return service.listForEmployee(employeeId);
    }
    @GetMapping("/employee/{employeeId}/balance") public LeaveService.BalanceView balance(@PathVariable Long employeeId) {
        return service.getBalance(employeeId);
    }
    @GetMapping("/{id}/audit") public List<LeaveAudit> audit(@PathVariable Long id) {return service.audit(id);}
}
