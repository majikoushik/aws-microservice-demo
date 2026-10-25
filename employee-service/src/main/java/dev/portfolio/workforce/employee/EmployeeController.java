package dev.portfolio.workforce.employee;

import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/employees")
public class EmployeeController {
    private final EmployeeService service;
    public EmployeeController(EmployeeService service) { this.service=service; }

    @GetMapping("/{id}") public EmployeeService.View get(@PathVariable Long id) { return service.get(id); }
    @GetMapping public Page<EmployeeService.View> list(@RequestParam(required=false) String department,
        @RequestParam(defaultValue="0") int page, @RequestParam(defaultValue="10") int size) {
        // Avoid clients asking for a million rows at once.
        return service.list(department, PageRequest.of(Math.max(0,page), Math.max(1,Math.min(size,100))));
    }
    @ResponseStatus(HttpStatus.CREATED)
    @PostMapping public EmployeeService.View create(@Valid @RequestBody EmployeeService.UpsertRequest request) {
        return service.create(request);
    }
    @PutMapping("/{id}") public EmployeeService.View update(@PathVariable Long id,
        @Valid @RequestBody EmployeeService.UpsertRequest request) { return service.update(id,request); }
}
