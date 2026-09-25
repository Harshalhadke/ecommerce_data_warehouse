-- Geography dimension: hierarchical location data (country > state > city > postal)
-- Enables drill-down analysis across geographic levels

DROP TABLE IF EXISTS dim_geography CASCADE;

CREATE TABLE dim_geography (
    geography_key       SERIAL PRIMARY KEY,
    postal_code         VARCHAR(20) NOT NULL,
    city                VARCHAR(100) NOT NULL,
    state_province      VARCHAR(100) NOT NULL,
    state_code          VARCHAR(10),
    country             VARCHAR(100) NOT NULL,
    country_code        CHAR(2) NOT NULL,
    region              VARCHAR(50) NOT NULL,       -- e.g., North America, Europe, Asia
    sub_region          VARCHAR(50),                -- e.g., Western Europe, South Asia
    latitude            DECIMAL(9,6),
    longitude           DECIMAL(9,6),
    timezone            VARCHAR(50),
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (postal_code, city, country_code)
);

CREATE INDEX idx_geo_country ON dim_geography(country_code);
CREATE INDEX idx_geo_state ON dim_geography(state_province);
CREATE INDEX idx_geo_region ON dim_geography(region);

COMMENT ON TABLE dim_geography IS 'Geographic hierarchy dimension supporting multi-level drill-down analysis';
