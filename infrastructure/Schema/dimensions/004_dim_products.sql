-- Product dimension with SCD Type 2 for price and category changes
-- Hierarchical categories: department > category > subcategory

DROP TABLE IF EXISTS dim_products CASCADE;

CREATE TABLE dim_products (
    product_key         SERIAL PRIMARY KEY,         -- Surrogate key
    product_id          INT NOT NULL,               -- Natural/business key
    sku                 VARCHAR(50) NOT NULL,
    product_name        VARCHAR(255) NOT NULL,
    description         TEXT,
    brand               VARCHAR(100),
    department          VARCHAR(100) NOT NULL,      -- Top-level: Electronics, Clothing, Home
    category            VARCHAR(100) NOT NULL,      -- Mid-level: Laptops, Shirts, Kitchen
    subcategory         VARCHAR(100),               -- Granular: Gaming Laptops, Polo Shirts
    unit_price          DECIMAL(10,2) NOT NULL,
    unit_cost           DECIMAL(10,2) NOT NULL,
    margin_pct          DECIMAL(5,2) GENERATED ALWAYS AS (
                            CASE WHEN unit_price > 0
                                THEN ((unit_price - unit_cost) / unit_price * 100)
                                ELSE 0
                            END
                        ) STORED,
    weight_kg           DECIMAL(8,3),
    supplier_id         INT,
    supplier_name       VARCHAR(200),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    launch_date         DATE,

    -- SCD Type 2 columns
    effective_start_date DATE NOT NULL,
    effective_end_date   DATE NOT NULL DEFAULT '9999-12-31',
    is_current           BOOLEAN NOT NULL DEFAULT TRUE,
    version              INT NOT NULL DEFAULT 1,

    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_prod_natural_key ON dim_products(product_id);
CREATE INDEX idx_prod_current ON dim_products(product_id, is_current) WHERE is_current = TRUE;
CREATE INDEX idx_prod_category ON dim_products(department, category, subcategory);
CREATE INDEX idx_prod_brand ON dim_products(brand);
CREATE INDEX idx_prod_sku ON dim_products(sku);

COMMENT ON TABLE dim_products IS 'SCD Type 2 product dimension with hierarchical categories and computed margin';
