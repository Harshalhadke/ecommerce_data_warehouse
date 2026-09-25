-- Fact Inventory Movements: grain is one row per inventory event
-- Tracks stock receipts, sales, returns, adjustments, and transfers

DROP TABLE IF EXISTS fact_inventory CASCADE;

CREATE TABLE fact_inventory (
    inventory_key       BIGSERIAL PRIMARY KEY,
    inventory_id        INT NOT NULL,
    product_key         INT NOT NULL REFERENCES dim_products(product_key),
    store_key           INT NOT NULL REFERENCES dim_stores(store_key),
    movement_date_key   INT NOT NULL REFERENCES dim_date(date_key),
    movement_timestamp  TIMESTAMP NOT NULL,

    -- Degenerate dimension
    movement_type       VARCHAR(30) NOT NULL,       -- RECEIPT, SALE, RETURN, ADJUSTMENT, TRANSFER
    reference_id        INT,                        -- Links to order_id or transfer_id

    -- Measures
    quantity_change     INT NOT NULL,               -- Positive for in, negative for out
    running_balance     INT,                        -- Current stock after this movement

    -- ETL metadata
    etl_batch_id        BIGINT,
    etl_loaded_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fact_inv_product ON fact_inventory(product_key);
CREATE INDEX idx_fact_inv_store ON fact_inventory(store_key);
CREATE INDEX idx_fact_inv_date ON fact_inventory(movement_date_key);
CREATE INDEX idx_fact_inv_type ON fact_inventory(movement_type);

COMMENT ON TABLE fact_inventory IS 'Inventory movement fact tracking stock changes across all channels';
