-- ============================================================
-- Step 1: Setup - Add sensitive columns to HOTEL_REVENUE table
-- ============================================================
-- Run with: LAB_ADMIN role
-- Database: MASKING_LAB_DB.LAB_SCHEMA
-- ============================================================

USE ROLE LAB_ADMIN;
USE DATABASE MASKING_LAB_DB;
USE SCHEMA LAB_SCHEMA;

CREATE OR REPLACE TABLE HOTEL_REVENUE (
    TRANSACTION_ID     VARCHAR(20),
    HOTEL_NAME         VARCHAR(100),
    REGION             VARCHAR(20),
    COUNTRY            VARCHAR(50),
    CITY               VARCHAR(50),
    REVENUE_USD        NUMBER(12, 2),
    ROOM_NIGHTS        INT,
    AVG_DAILY_RATE_USD NUMBER(10, 2),
    OCCUPANCY_RATE_PCT NUMBER(5, 2),
    TRANSACTION_DATE   DATE,
    SEGMENT            VARCHAR(30),
    LOYALTY_TIER       VARCHAR(20),
    CREDIT_CARD_NUMBER VARCHAR(19),
    ACCOUNT_NUMBER     VARCHAR(20)
);

INSERT INTO HOTEL_REVENUE VALUES
('TXN-001', 'The Grand Marina',      'APAC', 'Singapore',   'Singapore',    85000.00, 120, 708.33, 92.5, '2024-01-15', 'Corporate',  'Platinum', '4111-1111-1111-1111', 'ACC-2024-SG-00101'),
('TXN-002', 'Azure Sky Resort',      'APAC', 'Thailand',    'Bangkok',      62000.00,  98, 632.65, 88.0, '2024-01-18', 'Leisure',    'Gold',     '4222-2222-2222-2222', 'ACC-2024-TH-00202'),
('TXN-003', 'Skyline Business Hotel','APAC', 'Japan',       'Tokyo',       110000.00, 200, 550.00, 95.0, '2024-01-20', 'Corporate',  'Platinum', '5333-3333-3333-3333', 'ACC-2024-JP-00303'),
('TXN-004', 'Harbor View Inn',       'APAC', 'Australia',   'Sydney',       74000.00, 150, 493.33, 85.0, '2024-01-22', 'OTA',        'Standard', '5444-4444-4444-4444', 'ACC-2024-AU-00404'),
('TXN-005', 'The Royal Palms',       'EMEA', 'UAE',         'Dubai',       145000.00, 180, 805.56, 96.0, '2024-01-10', 'Corporate',  'Platinum', '4555-5555-5555-5555', 'ACC-2024-AE-00505'),
('TXN-006', 'Eiffel Luxury Suites',  'EMEA', 'France',      'Paris',        98000.00, 160, 612.50, 89.0, '2024-01-12', 'Leisure',    'Gold',     '3714-496353-98431',   'ACC-2024-FR-00606'),
('TXN-007', 'Thames Business Lodge', 'EMEA', 'UK',          'London',      130000.00, 210, 619.05, 93.5, '2024-01-14', 'Corporate',  'Platinum', '6011-6011-6011-6011', 'ACC-2024-UK-00707'),
('TXN-008', 'Colosseum Grand',       'EMEA', 'Italy',       'Rome',         72000.00, 130, 553.85, 87.0, '2024-01-16', 'OTA',        'Standard', '4888-8888-8888-8888', 'ACC-2024-IT-00808'),
('TXN-009', 'Times Square Tower',    'AMER', 'USA',         'New York',    175000.00, 220, 795.45, 97.0, '2024-01-05', 'Corporate',  'Platinum', '5199-9999-9999-9999', 'ACC-2024-US-00909'),
('TXN-010', 'Sunset Bay Resort',     'AMER', 'USA',         'Miami',        88000.00, 170, 517.65, 91.0, '2024-01-08', 'Leisure',    'Gold',     '4000-1234-5678-9010', 'ACC-2024-US-01010'),
('TXN-011', 'Maple Leaf Inn',        'AMER', 'Canada',      'Toronto',      65000.00, 145, 448.28, 84.0, '2024-01-09', 'OTA',        'Standard', '5100-1111-2222-3333', 'ACC-2024-CA-01111'),
('TXN-012', 'Copacabana Palace',     'AMER', 'Brazil',      'Rio de Janeiro',53000.00,110, 481.82, 82.0, '2024-01-11', 'Leisure',    'Gold',     '3782-822463-10005',   'ACC-2024-BR-01212'),
('TXN-013', 'Pearl Bay Hotel',       'APAC', 'India',       'Mumbai',       47000.00,  95, 494.74, 86.0, '2024-02-01', 'Corporate',  'Gold',     '6011-0009-9013-9424', 'ACC-2024-IN-01313'),
('TXN-014', 'Alpine Chalet',         'EMEA', 'Switzerland', 'Zurich',      120000.00, 155, 774.19, 94.0, '2024-02-03', 'Corporate',  'Platinum', '4917-6100-0000-0000', 'ACC-2024-CH-01414'),
('TXN-015', 'Canyon View Lodge',     'AMER', 'USA',         'Las Vegas',    92000.00, 185, 497.30, 90.0, '2024-02-05', 'Leisure',    'Standard', '5425-2334-3010-9903', 'ACC-2024-US-01515');

SELECT TRANSACTION_ID, HOTEL_NAME, REGION, CREDIT_CARD_NUMBER, ACCOUNT_NUMBER
FROM HOTEL_REVENUE;
