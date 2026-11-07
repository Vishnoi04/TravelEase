-- Infy_TravelEase :: audit-service
-- Run this script in MySQL Workbench / CLI once per environment to create the
-- service-owned database, table, and dummy seed data for manual/API testing.
-- Usage: mysql -u root -p < tableScript.sql
-- Note: audit_record is append-only (no soft-delete / audit columns by design).

CREATE DATABASE IF NOT EXISTS travelease_audit;
USE travelease_audit;

DROP TABLE IF EXISTS audit_record;

CREATE TABLE audit_record (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    entity_type     VARCHAR(30) NOT NULL,
    entity_id       BIGINT NOT NULL,
    actor_id        BIGINT NOT NULL,
    action          VARCHAR(20) NOT NULL,
    before_status   VARCHAR(20) NULL,
    after_status    VARCHAR(20) NOT NULL,
    occurred_at     DATETIME NOT NULL,
    INDEX idx_audit_record_entity_occurred (entity_type, entity_id, occurred_at)
);

-- Dummy data mirroring the travel-request-service seed workflow (TR1 approved, TR4 rejected)
INSERT INTO audit_record (entity_type, entity_id, actor_id, action, before_status, after_status, occurred_at) VALUES
('TRAVEL_REQUEST', 1, 3, 'CREATED', NULL, 'PENDING', NOW()),
('TRAVEL_REQUEST', 1, 2, 'APPROVED', 'PENDING', 'APPROVED', NOW()),
('TRAVEL_REQUEST', 4, 1, 'CREATED', NULL, 'PENDING', NOW()),
('TRAVEL_REQUEST', 4, 2, 'REJECTED', 'PENDING', 'REJECTED', NOW()),
('EXPENSE_CLAIM', 1, 3, 'CREATED', NULL, 'PENDING', NOW()),
('EXPENSE_CLAIM', 1, 5, 'REIMBURSED', 'APPROVED', 'REIMBURSED', NOW());
