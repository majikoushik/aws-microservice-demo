CREATE TABLE leave_requests (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
 employee_id BIGINT NOT NULL,
 start_date DATE NOT NULL,
 end_date DATE NOT NULL,
 days_requested INTEGER NOT NULL,
 status VARCHAR(20) NOT NULL,
 requested_by VARCHAR(255) NOT NULL,
 approved_by VARCHAR(255),
 decided_at TIMESTAMP(6),
 decision_comment VARCHAR(255),
 created_at TIMESTAMP(6),
 version BIGINT
);
CREATE INDEX idx_leave_employee_date ON leave_requests (employee_id, start_date, end_date);
CREATE TABLE leave_balances (
 employee_id BIGINT NOT NULL PRIMARY KEY,
 remaining_days INTEGER NOT NULL,
 version BIGINT
);
CREATE TABLE leave_audit (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
 request_id BIGINT NOT NULL,
 actor VARCHAR(255) NOT NULL,
 action VARCHAR(255) NOT NULL,
 occurred_at TIMESTAMP(6) NOT NULL,
 comment VARCHAR(255)
);
CREATE INDEX idx_audit_request ON leave_audit (request_id);
CREATE TABLE outbox_events (
 id VARCHAR(36) NOT NULL PRIMARY KEY,
 event_type VARCHAR(255) NOT NULL,
 payload VARCHAR(3000) NOT NULL,
 created_at TIMESTAMP(6) NOT NULL,
 published_at TIMESTAMP(6)
);
CREATE INDEX idx_outbox_unpublished ON outbox_events (published_at,created_at);
