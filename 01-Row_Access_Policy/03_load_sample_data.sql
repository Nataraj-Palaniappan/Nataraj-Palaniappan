-- ============================================================
-- FILE: 03_load_sample_data.sql
-- PURPOSE: Create and populate the hotel revenue table
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE RAP_WH;
USE DATABASE HOSPITALITY_DB;
USE SCHEMA HOSPITALITY_DB.FINANCE;

-- Create table
CREATE OR REPLACE TABLE hotel_revenue (
    transaction_id     VARCHAR(20),
    hotel_name         VARCHAR(100),
    region             VARCHAR(20),   -- APAC | EMEA | AMER
    country            VARCHAR(50),
    city               VARCHAR(50),
    revenue_usd        NUMBER(12, 2),
    room_nights        INT,
    avg_daily_rate_usd NUMBER(10, 2),
    occupancy_rate_pct NUMBER(5, 2),
    transaction_date   DATE,
    segment            VARCHAR(30),   -- Leisure | Corporate | OTA
    loyalty_tier       VARCHAR(20)    -- Gold | Platinum | Standard
);

-- Insert sample hospitality financial data
INSERT INTO hotel_revenue VALUES
('TXN-001', 'The Grand Marina',      'APAC', 'Singapore',   'Singapore',    85000.00, 120, 708.33, 92.5, '2024-01-15', 'Corporate',  'Platinum'),
('TXN-002', 'Azure Sky Resort',      'APAC', 'Thailand',    'Bangkok',      62000.00,  98, 632.65, 88.0, '2024-01-18', 'Leisure',    'Gold'),
('TXN-003', 'Skyline Business Hotel','APAC', 'Japan',       'Tokyo',       110000.00, 200, 550.00, 95.0, '2024-01-20', 'Corporate',  'Platinum'),
('TXN-004', 'Harbor View Inn',       'APAC', 'Australia',   'Sydney',       74000.00, 150, 493.33, 85.0, '2024-01-22', 'OTA',        'Standard'),
('TXN-005', 'The Royal Palms',       'EMEA', 'UAE',         'Dubai',       145000.00, 180, 805.56, 96.0, '2024-01-10', 'Corporate',  'Platinum'),
('TXN-006', 'Eiffel Luxury Suites',  'EMEA', 'France',      'Paris',        98000.00, 160, 612.50, 89.0, '2024-01-12', 'Leisure',    'Gold'),
('TXN-007', 'Thames Business Lodge', 'EMEA', 'UK',          'London',      130000.00, 210, 619.05, 93.5, '2024-01-14', 'Corporate',  'Platinum'),
('TXN-008', 'Colosseum Grand',       'EMEA', 'Italy',       'Rome',         72000.00, 130, 553.85, 87.0, '2024-01-16', 'OTA',        'Standard'),
('TXN-009', 'Times Square Tower',    'AMER', 'USA',         'New York',    175000.00, 220, 795.45, 97.0, '2024-01-05', 'Corporate',  'Platinum'),
('TXN-010', 'Sunset Bay Resort',     'AMER', 'USA',         'Miami',        88000.00, 170, 517.65, 91.0, '2024-01-08', 'Leisure',    'Gold'),
('TXN-011', 'Maple Leaf Inn',        'AMER', 'Canada',      'Toronto',      65000.00, 145, 448.28, 84.0, '2024-01-09', 'OTA',        'Standard'),
('TXN-012', 'Copacabana Palace',     'AMER', 'Brazil',      'Rio de Janeiro',53000.00,110, 481.82, 82.0, '2024-01-11', 'Leisure',    'Gold'),
('TXN-013', 'Pearl Bay Hotel',       'APAC', 'India',       'Mumbai',       47000.00,  95, 494.74, 86.0, '2024-02-01', 'Corporate',  'Gold'),
('TXN-014', 'Alpine Chalet',         'EMEA', 'Switzerland', 'Zurich',      120000.00, 155, 774.19, 94.0, '2024-02-03', 'Corporate',  'Platinum'),
('TXN-015', 'Canyon View Lodge',     'AMER', 'USA',         'Las Vegas',    92000.00, 185, 497.30, 90.0, '2024-02-05', 'Leisure',    'Standard');

-- Grant SELECT to all region roles
GRANT SELECT ON TABLE HOSPITALITY_DB.FINANCE.hotel_revenue TO ROLE ROLE_REGION_APAC;
GRANT SELECT ON TABLE HOSPITALITY_DB.FINANCE.hotel_revenue TO ROLE ROLE_REGION_EMEA;
GRANT SELECT ON TABLE HOSPITALITY_DB.FINANCE.hotel_revenue TO ROLE ROLE_REGION_AMER;
GRANT SELECT ON TABLE HOSPITALITY_DB.FINANCE.hotel_revenue TO ROLE ROLE_FINANCE_ADMIN;

-- Preview data
SELECT * FROM hotel_revenue ORDER BY region, transaction_date;
