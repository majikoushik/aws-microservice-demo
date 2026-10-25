package dev.portfolio.workforce.employee;

import dev.portfolio.workforce.common.Identity;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/** An important interview topic: object-level authorization is enforced here. */
@Service
public class EmployeeService {
    private final EmployeeRepository repository;
    public EmployeeService(EmployeeRepository repository) { this.repository = repository; }

    public record UpsertRequest(@NotBlank String identitySubject, @NotBlank String name,
                                @NotBlank @Email String email, @NotBlank String department,
                                String managerSubject) {}
    public record View(Long id, String identitySubject, String name, String email,
                       String department, String managerSubject) {
        static View from(Employee e) {
            return new View(e.id,e.identitySubject,e.name,e.email,e.department,e.managerSubject);
        }
    }

    @Transactional(readOnly=true)
    public View get(Long id) {
        Employee e = getEntity(id);
        Identity.require(canRead(e));
        return View.from(e);
    }
    @Transactional(readOnly=true)
    public Page<View> list(String department, Pageable page) {
        Identity.require(Identity.hasRole("HR") || Identity.hasRole("MANAGER"));
        // A manager can view ONLY their own reporting line, not the whole company.
        if (Identity.hasRole("MANAGER") && !Identity.hasRole("HR")) {
            return repository.findByManagerSubject(Identity.subject(), page).map(View::from);
        }
        return (department == null || department.isBlank()
                ? repository.findAll(page) : repository.findByDepartmentIgnoreCase(department,page)).map(View::from);
    }
    @Transactional
    public View create(UpsertRequest r) {
        Identity.require(Identity.hasRole("HR"));
        if (repository.existsByEmailIgnoreCase(r.email()) || repository.existsByIdentitySubject(r.identitySubject()))
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email or identity subject already exists");
        return View.from(repository.save(new Employee(r.identitySubject(),r.name(),r.email(),r.department(),r.managerSubject())));
    }
    @Transactional
    public View update(Long id, UpsertRequest r) {
        Identity.require(Identity.hasRole("HR"));
        Employee e = getEntity(id);
        // A real identity change is a deliberate privileged operation; uniqueness is enforced by DB.
        e.identitySubject=r.identitySubject(); e.name=r.name(); e.email=r.email();
        e.department=r.department(); e.managerSubject=r.managerSubject();
        return View.from(repository.save(e));
    }
    @Transactional(readOnly=true)
    public Employee getAuthorizedEntity(Long id) {
        Employee e = getEntity(id);
        Identity.require(canRead(e));
        return e;
    }
    private Employee getEntity(Long id) {
        return repository.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,"Employee not found"));
    }
    private boolean canRead(Employee e) {
        return Identity.hasRole("HR") || e.identitySubject.equals(Identity.subject())
            || (Identity.hasRole("MANAGER") && Identity.subject().equals(e.managerSubject));
    }
}
