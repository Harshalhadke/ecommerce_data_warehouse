-- Fact Customer Events: grain is one row per customer interaction event
-- Enables sessionization, funnel analysis, and behavioral segmentation

DROP TABLE IF EXISTS fact_customer_events CASCADE;

CREATE TABLE fact_customer_events (
    event_key           BIGSERIAL PRIMARY KEY,
    event_id            BIGINT NOT NULL UNIQUE,
    customer_key        INT NOT NULL REFERENCES dim_customers(customer_key),
    event_date_key      INT NOT NULL REFERENCES dim_date(date_key),
    event_timestamp     TIMESTAMP NOT NULL,

    -- Event classification
    event_type          VARCHAR(50) NOT NULL,       -- page_view, add_to_cart, purchase, review, support
    event_category      VARCHAR(30) NOT NULL,       -- browsing, transaction, engagement, support

    -- Session context
    session_id          VARCHAR(100),
    session_sequence    INT,                        -- Event order within session
    is_session_start    BOOLEAN DEFAULT FALSE,
    is_session_end      BOOLEAN DEFAULT FALSE,

    -- Device/channel context
    device_type         VARCHAR(30),                -- desktop, mobile, tablet
    browser             VARCHAR(50),
    referrer_source     VARCHAR(100),               -- google, direct, email, social

    -- Event payload (flexible schema for event-specific data)
    page_url            VARCHAR(500),
    event_properties    JSONB,

    -- Measures
    event_value         DECIMAL(10,2),              -- Monetary value if applicable

    -- ETL metadata
    etl_batch_id        BIGINT,
    etl_loaded_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Partition-ready: if table grows large, partition by event_date_key range
CREATE INDEX idx_fact_events_customer ON fact_customer_events(customer_key);
CREATE INDEX idx_fact_events_date ON fact_customer_events(event_date_key);
CREATE INDEX idx_fact_events_type ON fact_customer_events(event_type);
CREATE INDEX idx_fact_events_session ON fact_customer_events(session_id);
CREATE INDEX idx_fact_events_props ON fact_customer_events USING GIN(event_properties);

COMMENT ON TABLE fact_customer_events IS 'Customer interaction events supporting sessionization and funnel analysis';
