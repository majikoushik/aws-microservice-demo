package dev.portfolio.workforce.employee;

import jakarta.persistence.*;

/** Every employee has an identity-provider subject, not a password in this database. */
@Entity
@Table(name = "employees", uniqueConstraints = @UniqueConstraint(columnNames = "identity_subject"))
public class Employee {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) public Long id;
    @Column(name = "identity_subject", nullable = false, length = 128) public String identitySubject;
    @Column(nullable = false, length = 120) public String name;
    @Column(nullable = false, unique = true, length = 200) public String email;
    @Column(nullable = false, length = 80) public String department;
    @Column(name = "manager_subject", length = 128) public String managerSubject;
    @Version public Long version;
    protected Employee() {}
    public Employee(String identitySubject, String name, String email, String department, String managerSubject) {
        this.identitySubject=identitySubject; this.name=name; this.email=email;
        this.department=department; this.managerSubject=managerSubject;
    }
}
