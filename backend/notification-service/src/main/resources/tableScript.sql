-- Infy_TravelEase :: notification-service
-- Run this script in MySQL Workbench / CLI once per environment to create the
-- service-owned database, table, and dummy seed data for manual/API testing.
-- Usage: mysql -u root -p < tableScript.sql

CREATE DATABASE IF NOT EXISTS travelease_notification;
USE travelease_notification;

DROP TABLE IF EXISTS notification_event;

CREATE TABLE notification_event (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    entity_type         VARCHAR(30) NOT NULL,
    entity_id           BIGINT NOT NULL,
    recipient_id        BIGINT NOT NULL,
    message             VARCHAR(500) NULL,
    notification_type   VARCHAR(20) NOT NULL,
    delivery_status      VARCHAR(30) NOT NULL,
    retry_count         INT NOT NULL DEFAULT 0,
    created_at          DATETIME NOT NULL,
    last_attempt_at     DATETIME NULL,
    is_read             BOOLEAN NOT NULL DEFAULT FALSE,
    INDEX idx_notification_event_status_last_attempt (delivery_status, last_attempt_at)
);

-- Dummy data mirroring the travel-request-service seed workflow (TR1 approved, TR4 rejected)
INSERT INTO notification_event (entity_type, entity_id, recipient_id, message, notification_type, delivery_status, retry_count, created_at, last_attempt_at, is_read) VALUES
('TRAVEL_REQUEST', 1, 3, 'Your travel request has been approved.', 'APPROVAL', 'SENT', 0, NOW(), NOW(), FALSE),
('TRAVEL_REQUEST', 4, 1, 'Your travel request has been rejected.', 'REJECTION', 'SENT', 0, NOW(), NOW(), FALSE),
('EXPENSE_CLAIM', 1, 3, 'Your expense claim has been reimbursed.', 'REIMBURSEMENT', 'FAILED_RETRYING', 1, NOW(), NOW(), FALSE);
