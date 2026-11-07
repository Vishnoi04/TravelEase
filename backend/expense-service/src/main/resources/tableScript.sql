-- Infy_TravelEase :: expense-service
-- Run this script in MySQL Workbench / CLI once per environment to create the
-- service-owned database, tables, and dummy seed data for manual/API testing.
-- Usage: mysql -u root -p < tableScript.sql
-- Note: employee_id and travel_request_id are logical references to
-- admin-service / travel-request-service ids (seeded in their own scripts) - no cross-DB FK.

CREATE DATABASE IF NOT EXISTS travelease_expense;
USE travelease_expense;

DROP TABLE IF EXISTS expense_document;
DROP TABLE IF EXISTS expense_claim;

CREATE TABLE expense_claim (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    employee_id         BIGINT NOT NULL,
    travel_request_id   BIGINT NOT NULL,
    amount              DECIMAL(19,4) NOT NULL,
    currency            VARCHAR(3) NOT NULL,
    category             VARCHAR(50) NOT NULL,
    expense_date        DATE NOT NULL,
    status              VARCHAR(20) NOT NULL,
    duplicate_flag      BOOLEAN NOT NULL DEFAULT FALSE,
    rejection_reason    VARCHAR(1000) NULL,
    reimbursed_at       DATETIME NULL,
    created_at          DATETIME NOT NULL,
    created_by          VARCHAR(255) NOT NULL,
    updated_at          DATETIME NOT NULL,
    updated_by          VARCHAR(255) NOT NULL,
    deleted             BOOLEAN NOT NULL DEFAULT FALSE,
    version             BIGINT,
    INDEX idx_expense_claim_employee_status (employee_id, status),
    INDEX idx_expense_claim_status (status),
    INDEX idx_expense_claim_duplicate_lookup (travel_request_id, amount, expense_date, category)
);

CREATE TABLE expense_document (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    expense_claim_id    BIGINT NOT NULL,
    file_name           VARCHAR(255) NOT NULL,
    file_type           VARCHAR(10) NOT NULL,
    file_size_bytes     BIGINT NOT NULL,
    storage_reference   VARCHAR(500) NOT NULL,
    upload_status       VARCHAR(20) NOT NULL,
    created_at          DATETIME NOT NULL,
    created_by          VARCHAR(255) NOT NULL,
    updated_at          DATETIME NOT NULL,
    updated_by          VARCHAR(255) NOT NULL,
    deleted             BOOLEAN NOT NULL DEFAULT FALSE,
    version             BIGINT,
    CONSTRAINT fk_expense_document_expense_claim FOREIGN KEY (expense_claim_id) REFERENCES expense_claim (id)
);

-- Dummy data: travel_request_id=1 matches the APPROVED "New York" trip (employee 3)
-- seeded in travel-request-service/tableScript.sql; EX1/EX2 form a duplicate pair.
INSERT INTO expense_claim (id, employee_id, travel_request_id, amount, currency, category, expense_date, status, duplicate_flag, rejection_reason, reimbursed_at, created_at, created_by, updated_at, updated_by, deleted, version) VALUES
(1, 3, 1, 45.00, 'USD', 'MEALS', '2025-06-12', 'REIMBURSED', FALSE, NULL, NOW(), NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(2, 3, 1, 45.00, 'USD', 'MEALS', '2025-06-12', 'PENDING', TRUE, NULL, NULL, NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(3, 3, 1, 120.00, 'USD', 'LODGING', '2025-06-15', 'APPROVED', FALSE, NULL, NULL, NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(4, 3, 1, 15.00, 'USD', 'TRANSPORT', '2025-06-18', 'REJECTED', FALSE, 'Receipt illegible', NULL, NOW(), 'seed', NOW(), 'seed', FALSE, 0);

INSERT INTO expense_document (expense_claim_id, file_name, file_type, file_size_bytes, storage_reference, upload_status, created_at, created_by, updated_at, updated_by, deleted, version) VALUES
(3, 'hotel-receipt.jpg', 'JPG', 153600, 's3://travelease-docs/expense-claim/3/hotel-receipt.jpg', 'CONFIRMED', NOW(), 'seed', NOW(), 'seed', FALSE, 0);
