-- Infy_TravelEase :: admin-service
-- Run this script in MySQL Workbench / CLI once per environment to create the
-- service-owned database, tables, and dummy seed data for manual/API testing.
-- Usage: mysql -u root -p < tableScript.sql

CREATE DATABASE IF NOT EXISTS travelease_admin;
USE travelease_admin;

DROP TABLE IF EXISTS user_role;
DROP TABLE IF EXISTS user_account;
DROP TABLE IF EXISTS employee_manager_mapping;
DROP TABLE IF EXISTS expense_category;
DROP TABLE IF EXISTS policy_config;

CREATE TABLE user_account (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    full_name   VARCHAR(255) NOT NULL,
    email       VARCHAR(255) NOT NULL,
    password_hash VARCHAR(100) NOT NULL,
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  DATETIME NOT NULL,
    created_by  VARCHAR(255) NOT NULL,
    updated_at  DATETIME NOT NULL,
    updated_by  VARCHAR(255) NOT NULL,
    deleted     BOOLEAN NOT NULL DEFAULT FALSE,
    version     BIGINT,
    CONSTRAINT uk_user_account_email UNIQUE (email)
);

CREATE TABLE user_role (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    role        VARCHAR(20) NOT NULL,
    created_at  DATETIME NOT NULL,
    created_by  VARCHAR(255) NOT NULL,
    updated_at  DATETIME NOT NULL,
    updated_by  VARCHAR(255) NOT NULL,
    deleted     BOOLEAN NOT NULL DEFAULT FALSE,
    version     BIGINT,
    CONSTRAINT uk_user_role_user_role UNIQUE (user_id, role),
    CONSTRAINT fk_user_role_user_account FOREIGN KEY (user_id) REFERENCES user_account (id)
);

CREATE TABLE employee_manager_mapping (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    employee_id     BIGINT NOT NULL,
    manager_id      BIGINT NULL,
    effective_from  DATE NOT NULL,
    created_at      DATETIME NOT NULL,
    created_by      VARCHAR(255) NOT NULL,
    updated_at      DATETIME NOT NULL,
    updated_by      VARCHAR(255) NOT NULL,
    deleted         BOOLEAN NOT NULL DEFAULT FALSE,
    version         BIGINT,
    CONSTRAINT uk_employee_manager_mapping_employee_id UNIQUE (employee_id)
);

CREATE TABLE expense_category (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    code        VARCHAR(50) NOT NULL,
    label       VARCHAR(255) NOT NULL,
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  DATETIME NOT NULL,
    created_by  VARCHAR(255) NOT NULL,
    updated_at  DATETIME NOT NULL,
    updated_by  VARCHAR(255) NOT NULL,
    deleted     BOOLEAN NOT NULL DEFAULT FALSE,
    version     BIGINT,
    CONSTRAINT uk_expense_category_code UNIQUE (code)
);

CREATE TABLE policy_config (
    id                      BIGINT AUTO_INCREMENT PRIMARY KEY,
    category_code           VARCHAR(50) NOT NULL,
    receipt_threshold_amount DECIMAL(19,4) NOT NULL,
    currency                VARCHAR(3) NOT NULL,
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              DATETIME NOT NULL,
    created_by              VARCHAR(255) NOT NULL,
    updated_at              DATETIME NOT NULL,
    updated_by              VARCHAR(255) NOT NULL,
    deleted                 BOOLEAN NOT NULL DEFAULT FALSE,
    version                 BIGINT
);

-- Dummy data: 1=Employee, 2=Manager (reports to 4), 3=Employee (reports to 2),
-- 4=top-level Manager (no manager -> Finance fallback), 5=Finance, 6=Admin
-- Development login password for each seeded user: TravelEase123!
-- The value is a BCrypt hash, not a plaintext password.
INSERT INTO user_account (id, full_name, email, password_hash, active, created_at, created_by, updated_at, updated_by, deleted, version) VALUES
(1, 'Alice Employee', 'alice.employee@travelease.com', '$2a$10$IKBiOJ9.jsjAWrH.YEbZTOTOgD3JWu4YApNgcM60m/Tv64hXSEJim', TRUE, NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(2, 'Bob Manager', 'bob.manager@travelease.com', '$2a$10$IKBiOJ9.jsjAWrH.YEbZTOTOgD3JWu4YApNgcM60m/Tv64hXSEJim', TRUE, NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(3, 'Carol Employee', 'carol.employee@travelease.com', '$2a$10$IKBiOJ9.jsjAWrH.YEbZTOTOgD3JWu4YApNgcM60m/Tv64hXSEJim', TRUE, NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(4, 'Dan TopManager', 'dan.topmanager@travelease.com', '$2a$10$IKBiOJ9.jsjAWrH.YEbZTOTOgD3JWu4YApNgcM60m/Tv64hXSEJim', TRUE, NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(5, 'Fiona Finance', 'fiona.finance@travelease.com', '$2a$10$IKBiOJ9.jsjAWrH.YEbZTOTOgD3JWu4YApNgcM60m/Tv64hXSEJim', TRUE, NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(6, 'Zara Admin', 'zara.admin@travelease.com', '$2a$10$IKBiOJ9.jsjAWrH.YEbZTOTOgD3JWu4YApNgcM60m/Tv64hXSEJim', TRUE, NOW(), 'seed', NOW(), 'seed', FALSE, 0);

INSERT INTO user_role (user_id, role, created_at, created_by, updated_at, updated_by, deleted, version) VALUES
(1, 'EMPLOYEE', NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(2, 'EMPLOYEE', NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(2, 'MANAGER', NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(3, 'EMPLOYEE', NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(4, 'MANAGER', NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(5, 'FINANCE', NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(6, 'ADMIN', NOW(), 'seed', NOW(), 'seed', FALSE, 0);

INSERT INTO employee_manager_mapping (employee_id, manager_id, effective_from, created_at, created_by, updated_at, updated_by, deleted, version) VALUES
(1, 2, '2025-01-01', NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(3, 2, '2025-01-01', NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(2, 4, '2025-01-01', NOW(), 'seed', NOW(), 'seed', FALSE, 0),
(4, NULL, '2025-01-01', NOW(), 'seed', NOW(), 'seed', FALSE, 0);

INSERT INTO expense_category (code, label, active, created_at, created_by, updated_at, updated_by, deleted, version) VALUES
('TRANSPORT', 'Transport', TRUE, NOW(), 'seed', NOW(), 'seed', FALSE, 0),
('LODGING', 'Lodging', TRUE, NOW(), 'seed', NOW(), 'seed', FALSE, 0),
('MEALS', 'Meals', TRUE, NOW(), 'seed', NOW(), 'seed', FALSE, 0);

INSERT INTO policy_config (category_code, receipt_threshold_amount, currency, active, created_at, created_by, updated_at, updated_by, deleted, version) VALUES
('TRANSPORT', 50.0000, 'USD', TRUE, NOW(), 'seed', NOW(), 'seed', FALSE, 0),
('LODGING', 0.0000, 'USD', TRUE, NOW(), 'seed', NOW(), 'seed', FALSE, 0),
('MEALS', 25.0000, 'USD', TRUE, NOW(), 'seed', NOW(), 'seed', FALSE, 0);
