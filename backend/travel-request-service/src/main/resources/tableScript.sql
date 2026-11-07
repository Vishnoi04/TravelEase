-- Infy_TravelEase :: travel-request-service
-- Run this script in MySQL Workbench / CLI once per environment to create the
-- service-owned database, tables, and dummy seed data for manual/API testing.
-- Usage: mysql -u root -p < tableScript.sql
-- Note: employee_id / approver_id are logical references to admin-service's
-- user_account.id (seeded in admin-service/tableScript.sql) - no cross-DB FK.

CREATE DATABASE IF NOT EXISTS travelease_travelrequest;
USE travelease_travelrequest;

DROP TABLE IF EXISTS approval_decision;
DROP TABLE IF EXISTS travel_request_document;
DROP TABLE IF EXISTS travel_request;

CREATE TABLE travel_request (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    employee_id         BIGINT NOT NULL,
    destination         VARCHAR(255) NOT NULL,
    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,
    justification       VARCHAR(2000) NOT NULL,
    status              VARCHAR(20) NOT NULL,
    approver_id         BIGINT NULL,
    rejection_reason    VARCHAR(1000) NULL,
    resubmission_of_id  BIGINT NULL,
    created_at          DATETIME NOT NULL,
    created_by          VARCHAR(255) NOT NULL,
    updated_at          DATETIME NOT NULL,
    updated_by          VARCHAR(255) NOT NULL,
    deleted             BOOLEAN NOT NULL DEFAULT FALSE,
    version             BIGINT,
    INDEX idx_travel_request_employee_status (employee_id, status),
    INDEX idx_travel_request_approver_status (approver_id, status)
);

CREATE TABLE travel_request_document (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    travel_request_id   BIGINT NOT NULL,
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
    CONSTRAINT fk_travel_request_document_travel_request FOREIGN KEY (travel_request_id) REFERENCES travel_request (id)
);

CREATE TABLE approval_decision (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    travel_request_id   BIGINT NOT NULL,
    decided_by          BIGINT NOT NULL,
    decision            VARCHAR(20) NOT NULL,
    reason              VARCHAR(1000) NULL,
    decided_at          DATETIME NOT NULL,
    CONSTRAINT fk_approval_decision_travel_request FOREIGN KEY (travel_request_id) REFERENCES travel_request (id)
);

-- Dummy data: employee/manager ids match admin-service seed
-- (1=Alice employee, 2=Bob manager, 3=Carol employee, 4=Dan top manager, 5=Fiona finance)
INSERT INTO travel_request (id, employee_id, destination, start_date, end_date, justification, status, approver_id, rejection_reason, resubmission_of_id, created_at, created_by, updated_at, updated_by, deleted, version) VALUES
(1, 3, 'New York', '2025-06-10', '2025-06-20', 'Client workshop', 'APPROVED', 2, NULL, NULL, NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(2, 1, 'London', '2025-07-01', '2025-07-05', 'Sales conference', 'PENDING', 2, NULL, NULL, NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(3, 2, 'Berlin', '2025-07-15', '2025-07-18', 'Manager summit', 'PENDING', 4, NULL, NULL, NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(4, 1, 'Paris', '2025-05-01', '2025-05-03', 'Partner review', 'REJECTED', 2, 'Budget not approved for this quarter', NULL, NOW(), 'seed', NOW(), 'seed', FALSE, 0);

INSERT INTO travel_request_document (travel_request_id, file_name, file_type, file_size_bytes, storage_reference, upload_status, created_at, created_by, updated_at, updated_by, deleted, version) VALUES
(1, 'itinerary.pdf', 'PDF', 204800, 's3://travelease-docs/travel-request/1/itinerary.pdf', 'CONFIRMED', NOW(), 'seed', NOW(), 'seed', FALSE, 0);

INSERT INTO approval_decision (travel_request_id, decided_by, decision, reason, decided_at) VALUES
(1, 2, 'APPROVED', NULL, NOW()),
(4, 2, 'REJECTED', 'Budget not approved for this quarter', NOW());
