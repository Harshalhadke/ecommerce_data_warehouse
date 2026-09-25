-- Store/channel dimension representing sales channels
-- Covers: physical stores, online, marketplace, mobile app

DROP TABLE IF EXISTS dim_stores CASCADE;

CREATE TABLE dim_stores (
    store_key           SERIAL PRIMARY KEY,
    store_id            INT NOT NULL UNIQUE,
    store_name          VARCHAR(200) NOT NULL,
    store_type          VARCHAR(50) NOT NULL,       -- Physical, Online, Marketplace, Mobile
    geography_key       INT REFERENCES dim_geography(geography_key),
    store_size_sqft     INT,
    open_date           DATE NOT NULL,
    close_date          DATE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    manager_name        VARCHAR(200),
    employee_count      INT,
    annual_revenue_target DECIMAL(14,2),
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_store_type ON dim_stores(store_type);
CREATE INDEX idx_store_active ON dim_stores(is_active) WHERE is_active = TRUE;

COMMENT ON TABLE dim_stores IS 'Sales channel dimension covering physical, online, and marketplace channels';
