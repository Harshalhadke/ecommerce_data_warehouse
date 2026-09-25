-- Staging tables: landing zone for raw source data before transformation
-- These tables are TRUNCATED before each load (full refresh pattern)
-- No constraints here — validation happens in the quality layer

CREATE SCHEMA IF NOT EXISTS staging;

DROP TABLE IF EXISTS staging.stg_customers CASCADE;
CREATE TABLE staging.stg_customers (
    customer_id         INT,
    first_name          VARCHAR(100),
    last_name           VARCHAR(100),
    email               VARCHAR(255),
    phone               VARCHAR(20),
    customer_segment    VARCHAR(50),
    loyalty_tier        VARCHAR(20),
    postal_code         VARCHAR(20),
    city                VARCHAR(100),
    state_province      VARCHAR(100),
    country_code        CHAR(2),
    acquisition_channel VARCHAR(50),
    acquisition_date    DATE,
    loaded_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source_file         VARCHAR(255)
);

DROP TABLE IF EXISTS staging.stg_products CASCADE;
CREATE TABLE staging.stg_products (
    product_id          INT,
    sku                 VARCHAR(50),
    product_name        VARCHAR(255),
    description         TEXT,
    brand               VARCHAR(100),
    department          VARCHAR(100),
    category            VARCHAR(100),
    subcategory         VARCHAR(100),
    unit_price          DECIMAL(10,2),
    unit_cost           DECIMAL(10,2),
    weight_kg           DECIMAL(8,3),
    supplier_id         INT,
    supplier_name       VARCHAR(200),
    is_active           BOOLEAN,
    launch_date         DATE,
    loaded_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source_file         VARCHAR(255)
);

DROP TABLE IF EXISTS staging.stg_orders CASCADE;
CREATE TABLE staging.stg_orders (
    order_id            INT,
    customer_id         INT,
    store_id            INT,
    order_date          TIMESTAMP,
    ship_date           TIMESTAMP,
    delivery_date       TIMESTAMP,
    order_status        VARCHAR(30),
    payment_method      VARCHAR(30),
    shipping_method     VARCHAR(50),
    discount_amount     DECIMAL(10,2),
    shipping_cost       DECIMAL(10,2),
    tax_amount          DECIMAL(10,2),
    total_amount        DECIMAL(12,2),
    currency_code       CHAR(3),
    loaded_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source_file         VARCHAR(255)
);

DROP TABLE IF EXISTS staging.stg_order_items CASCADE;
CREATE TABLE staging.stg_order_items (
    order_item_id       INT,
    order_id            INT,
    product_id          INT,
    quantity            INT,
    unit_price          DECIMAL(10,2),
    discount_pct        DECIMAL(5,2),
    line_total          DECIMAL(12,2),
    loaded_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source_file         VARCHAR(255)
);

DROP TABLE IF EXISTS staging.stg_inventory CASCADE;
CREATE TABLE staging.stg_inventory (
    inventory_id        INT,
    product_id          INT,
    store_id            INT,
    movement_type       VARCHAR(30),   -- RECEIPT, SALE, RETURN, ADJUSTMENT, TRANSFER
    quantity            INT,
    movement_date       TIMESTAMP,
    reference_id        INT,           -- order_id or transfer_id
    loaded_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source_file         VARCHAR(255)
);

DROP TABLE IF EXISTS staging.stg_customer_events CASCADE;
CREATE TABLE staging.stg_customer_events (
    event_id            BIGINT,
    customer_id         INT,
    event_type          VARCHAR(50),   -- page_view, add_to_cart, purchase, review, support_ticket
    event_timestamp     TIMESTAMP,
    session_id          VARCHAR(100),
    page_url            VARCHAR(500),
    device_type         VARCHAR(30),
    browser             VARCHAR(50),
    referrer_source     VARCHAR(100),
    event_properties    JSONB,
    loaded_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source_file         VARCHAR(255)
);

COMMENT ON SCHEMA staging IS 'Landing zone for raw source data — truncated before each load cycle';
