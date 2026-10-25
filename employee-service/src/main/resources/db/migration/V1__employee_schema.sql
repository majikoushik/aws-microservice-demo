-- H2 runs in MySQL compatibility mode; this migration is portable across both engines.
CREATE TABLE employees (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
 identity_subject VARCHAR(128) NOT NULL UNIQUE,
 name VARCHAR(120) NOT NULL,
 email VARCHAR(200) NOT NULL UNIQUE,
 department VARCHAR(80) NOT NULL,
 manager_subject VARCHAR(128),
 version BIGINT
);
CREATE INDEX idx_employees_department ON employees (department);
CREATE INDEX idx_employees_manager ON employees (manager_subject);
CREATE TABLE employee_documents (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
 employee_id BIGINT NOT NULL,
 original_filename VARCHAR(255) NOT NULL,
 storage_key VARCHAR(255) NOT NULL,
 content_type VARCHAR(255) NOT NULL,
 size_bytes BIGINT NOT NULL,
 created_at TIMESTAMP(6),
 CONSTRAINT fk_document_employee FOREIGN KEY (employee_id) REFERENCES employees(id)
);
CREATE INDEX idx_employee_documents_owner ON employee_documents (employee_id);
