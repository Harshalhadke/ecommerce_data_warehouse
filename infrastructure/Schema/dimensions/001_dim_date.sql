-- Date dimension: pre-populated calendar table for time-based analysis
-- Covers 10 years (2020-2030) for historical and future queries

DROP TABLE IF EXISTS dim_date CASCADE;

CREATE TABLE dim_date (
    date_key            INT PRIMARY KEY,           -- YYYYMMDD format
    full_date           DATE NOT NULL UNIQUE,
    day_of_week         SMALLINT NOT NULL,         -- 1=Monday, 7=Sunday
    day_name            VARCHAR(10) NOT NULL,
    day_of_month        SMALLINT NOT NULL,
    day_of_year         SMALLINT NOT NULL,
    week_of_year        SMALLINT NOT NULL,
    iso_week            SMALLINT NOT NULL,
    month_number        SMALLINT NOT NULL,
    month_name          VARCHAR(10) NOT NULL,
    month_short         CHAR(3) NOT NULL,
    quarter             SMALLINT NOT NULL,
    year                SMALLINT NOT NULL,
    fiscal_quarter      SMALLINT NOT NULL,         -- Fiscal year starts April
    fiscal_year         SMALLINT NOT NULL,
    is_weekend          BOOLEAN NOT NULL,
    is_holiday          BOOLEAN NOT NULL DEFAULT FALSE,
    holiday_name        VARCHAR(50),
    week_start_date     DATE NOT NULL,
    week_end_date       DATE NOT NULL,
    month_start_date    DATE NOT NULL,
    month_end_date      DATE NOT NULL
);

-- Populate dim_date for 2020-2030
INSERT INTO dim_date
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INT AS date_key,
    d AS full_date,
    EXTRACT(ISODOW FROM d)::SMALLINT AS day_of_week,
    TO_CHAR(d, 'Day') AS day_name,
    EXTRACT(DAY FROM d)::SMALLINT AS day_of_month,
    EXTRACT(DOY FROM d)::SMALLINT AS day_of_year,
    EXTRACT(WEEK FROM d)::SMALLINT AS week_of_year,
    EXTRACT(ISODOW FROM d)::SMALLINT AS iso_week,
    EXTRACT(MONTH FROM d)::SMALLINT AS month_number,
    TO_CHAR(d, 'Month') AS month_name,
    TO_CHAR(d, 'Mon') AS month_short,
    EXTRACT(QUARTER FROM d)::SMALLINT AS quarter,
    EXTRACT(YEAR FROM d)::SMALLINT AS year,
    -- Fiscal quarter (April start)
    CASE
        WHEN EXTRACT(MONTH FROM d) IN (4,5,6) THEN 1
        WHEN EXTRACT(MONTH FROM d) IN (7,8,9) THEN 2
        WHEN EXTRACT(MONTH FROM d) IN (10,11,12) THEN 3
        ELSE 4
    END::SMALLINT AS fiscal_quarter,
    CASE
        WHEN EXTRACT(MONTH FROM d) >= 4
            THEN EXTRACT(YEAR FROM d)::SMALLINT
        ELSE (EXTRACT(YEAR FROM d) - 1)::SMALLINT
    END AS fiscal_year,
    EXTRACT(ISODOW FROM d) IN (6, 7) AS is_weekend,
    FALSE AS is_holiday,
    NULL AS holiday_name,
    d - (EXTRACT(ISODOW FROM d)::INT - 1) * INTERVAL '1 day' AS week_start_date,
    d + (7 - EXTRACT(ISODOW FROM d)::INT) * INTERVAL '1 day' AS week_end_date,
    DATE_TRUNC('month', d)::DATE AS month_start_date,
    (DATE_TRUNC('month', d) + INTERVAL '1 month' - INTERVAL '1 day')::DATE AS month_end_date
FROM GENERATE_SERIES('2020-01-01'::DATE, '2030-12-31'::DATE, '1 day'::INTERVAL) AS d;

COMMENT ON TABLE dim_date IS 'Calendar dimension covering 2020-2030 with fiscal year support (April start)';
