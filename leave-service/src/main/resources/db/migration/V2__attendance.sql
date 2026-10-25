CREATE TABLE attendance (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
 employee_id BIGINT NOT NULL,
 work_date DATE NOT NULL,
 status VARCHAR(20) NOT NULL,
 recorded_by VARCHAR(255) NOT NULL,
 CONSTRAINT uq_attendance_employee_day UNIQUE(employee_id,work_date)
);
