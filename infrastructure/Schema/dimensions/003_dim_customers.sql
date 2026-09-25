-- Customer dimension with SCD Type 2 for tracking historical changes
-- Tracks: name, email, segment, geography changes over time

DROP TABLE IF EXISTS dim_customers CASCADE;

CREATE TABLE dim_customers (
    customer_key        SERIAL PRIMARY KEY,         -- Surrogate key
    customer_id         INT NOT NULL,               -- Natural/business key
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    email               VARCHAR(255) NOT NULL,
    phone               VARCHAR(20),
    customer_segment    VARCHAR(50) NOT NULL,       -- Premium, Standard, Basic
    loyalty_tier        VARCHAR(20),                -- Gold, Silver, Bronze, None
    geography_key       INT REFERENCES dim_geography(geography_key),
    acquisition_channel VARCHAR(50),                -- Organic, Paid, Referral, Social
    acquisition_date    DATE NOT NULL,
    lifetime_order_count INT DEFAULT 0,
    lifetime_revenue    DECIMAL(12,2) DEFAULT 0.00,

    -- SCD Type 2 columns
    effective_start_date DATE NOT NULL,
    effective_end_date   DATE NOT NULL DEFAULT '9999-12-31',
    is_current           BOOLEAN NOT NULL DEFAULT TRUE,
    version              INT NOT NULL DEFAULT 1,

    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_cust_natural_key ON dim_customers(customer_id);
CREATE INDEX idx_cust_current ON dim_customers(customer_id, is_current) WHERE is_current = TRUE;
CREATE INDEX idx_cust_segment ON dim_customers(customer_segment);
CREATE INDEX idx_cust_date_range ON dim_customers(effective_start_date, effective_end_date);

COMMENT ON TABLE dim_customers IS 'SCD Type 2 customer dimension tracking segment, tier, and geography changes';
