-- Fact Order Items: grain is one row per order line item
-- Most granular transaction fact — enables product-level analysis

DROP TABLE IF EXISTS fact_order_items CASCADE;

CREATE TABLE fact_order_items (
    order_item_key      BIGSERIAL PRIMARY KEY,
    order_item_id       INT NOT NULL,
    order_id            INT NOT NULL,               -- Degenerate dimension
    customer_key        INT NOT NULL REFERENCES dim_customers(customer_key),
    product_key         INT NOT NULL REFERENCES dim_products(product_key),
    store_key           INT NOT NULL REFERENCES dim_stores(store_key),
    order_date_key      INT NOT NULL REFERENCES dim_date(date_key),

    -- Measures
    quantity            INT NOT NULL,
    unit_price          DECIMAL(10,2) NOT NULL,
    unit_cost           DECIMAL(10,2) NOT NULL,
    discount_pct        DECIMAL(5,2) NOT NULL DEFAULT 0,
    discount_amount     DECIMAL(10,2) NOT NULL DEFAULT 0,
    line_total          DECIMAL(12,2) NOT NULL,     -- quantity * unit_price * (1 - discount_pct)
    line_cost           DECIMAL(12,2) NOT NULL,     -- quantity * unit_cost
    line_margin         DECIMAL(12,2) NOT NULL,     -- line_total - line_cost
    margin_pct          DECIMAL(5,2) NOT NULL,

    -- ETL metadata
    etl_batch_id        BIGINT,
    etl_loaded_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (order_id, order_item_id)
);

CREATE INDEX idx_fact_items_product ON fact_order_items(product_key);
CREATE INDEX idx_fact_items_customer ON fact_order_items(customer_key);
CREATE INDEX idx_fact_items_date ON fact_order_items(order_date_key);
CREATE INDEX idx_fact_items_order ON fact_order_items(order_id);

COMMENT ON TABLE fact_order_items IS 'Line-item grain fact enabling product-level revenue, margin, and basket analysis';
