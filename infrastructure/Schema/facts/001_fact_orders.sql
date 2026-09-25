-- Fact Orders: grain is one row per order
-- Contains measures at the order header level

DROP TABLE IF EXISTS fact_orders CASCADE;

CREATE TABLE fact_orders (
    order_key           BIGSERIAL PRIMARY KEY,
    order_id            INT NOT NULL UNIQUE,        -- Degenerate dimension (natural key)
    customer_key        INT NOT NULL REFERENCES dim_customers(customer_key),
    store_key           INT NOT NULL REFERENCES dim_stores(store_key),
    order_date_key      INT NOT NULL REFERENCES dim_date(date_key),
    ship_date_key       INT REFERENCES dim_date(date_key),
    delivery_date_key   INT REFERENCES dim_date(date_key),

    -- Degenerate dimensions
    order_status        VARCHAR(30) NOT NULL,       -- Pending, Shipped, Delivered, Cancelled, Returned
    payment_method      VARCHAR(30) NOT NULL,       -- Credit Card, Debit, PayPal, COD
    shipping_method     VARCHAR(50),                -- Standard, Express, Next-Day, Pickup

    -- Measures
    item_count          INT NOT NULL,
    gross_amount        DECIMAL(12,2) NOT NULL,     -- Before discounts/tax
    discount_amount     DECIMAL(10,2) NOT NULL DEFAULT 0,
    net_amount          DECIMAL(12,2) NOT NULL,     -- After discounts, before tax
    tax_amount          DECIMAL(10,2) NOT NULL DEFAULT 0,
    shipping_cost       DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_amount        DECIMAL(12,2) NOT NULL,     -- Final charged amount

    -- Time-to-event measures (in days)
    days_to_ship        INT,
    days_to_deliver     INT,
    days_since_prior_order INT,                     -- Gap from customer's previous order

    -- Flags
    is_first_order      BOOLEAN NOT NULL DEFAULT FALSE,
    has_return          BOOLEAN NOT NULL DEFAULT FALSE,
    currency_code       CHAR(3) NOT NULL DEFAULT 'USD',

    -- ETL metadata
    etl_batch_id        BIGINT,
    etl_loaded_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fact_orders_customer ON fact_orders(customer_key);
CREATE INDEX idx_fact_orders_date ON fact_orders(order_date_key);
CREATE INDEX idx_fact_orders_store ON fact_orders(store_key);
CREATE INDEX idx_fact_orders_status ON fact_orders(order_status);

COMMENT ON TABLE fact_orders IS 'Order-grain fact table with measures for revenue, shipping, and time-to-event';
