-- Project 1: Sanlam life, wealth and retirement training warehouse
-- PostgreSQL 14+. This is a cleaned analytics model; load raw CSVs to staging first.
-- Synthetic learner data only. No clear-text direct identifiers belong in reporting.

CREATE SCHEMA IF NOT EXISTS sanlam_dw;
SET search_path TO sanlam_dw, public;

CREATE TABLE IF NOT EXISTS dim_date (
    date_key          integer PRIMARY KEY, -- YYYYMMDD
    calendar_date     date NOT NULL UNIQUE,
    calendar_year     smallint NOT NULL,
    calendar_quarter  smallint NOT NULL,
    calendar_month    smallint NOT NULL,
    month_name        text NOT NULL,
    is_month_end      boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS dim_channel (
    channel_sk        smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    channel_code      text NOT NULL UNIQUE,
    channel_name      text NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_client (
    client_sk         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_bk         text NOT NULL,
    client_hash       text,
    province          text,
    gender            text,
    birth_date        date,
    valid_from        date NOT NULL,
    valid_to          date NOT NULL DEFAULT '9999-12-31',
    is_current        boolean NOT NULL DEFAULT true,
    CONSTRAINT dim_client_dates_ck CHECK (valid_to >= valid_from)
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_dim_client_current
    ON dim_client (client_bk) WHERE is_current;

CREATE TABLE IF NOT EXISTS dim_advisor (
    advisor_sk        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    advisor_bk        text NOT NULL,
    advisor_hash      text,
    fsp_number        text,
    channel_sk        smallint REFERENCES dim_channel(channel_sk),
    channel           text NOT NULL,
    network_name      text,
    province          text,
    valid_from        date NOT NULL,
    valid_to          date NOT NULL DEFAULT '9999-12-31',
    is_current        boolean NOT NULL DEFAULT true,
    CONSTRAINT dim_advisor_dates_ck CHECK (valid_to >= valid_from)
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_dim_advisor_current
    ON dim_advisor (advisor_bk) WHERE is_current;

CREATE TABLE IF NOT EXISTS dim_product (
    product_sk        smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_code      text NOT NULL UNIQUE,
    product_name      text NOT NULL,
    product_line      text NOT NULL,
    product_group     text NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_policy (
    policy_sk         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    policy_bk         text NOT NULL,
    client_bk         text NOT NULL,
    advisor_bk        text,
    product_code      text NOT NULL REFERENCES dim_product(product_code),
    inception_date    date NOT NULL,
    expiry_date       date,
    policy_status     text NOT NULL,
    currency_code     char(3) NOT NULL DEFAULT 'ZAR',
    CONSTRAINT dim_policy_dates_ck CHECK (expiry_date IS NULL OR expiry_date >= inception_date)
);
CREATE INDEX IF NOT EXISTS ix_dim_policy_client_bk ON dim_policy(client_bk);
CREATE INDEX IF NOT EXISTS ix_dim_policy_advisor_bk ON dim_policy(advisor_bk);

CREATE TABLE IF NOT EXISTS fact_policy_premium (
    premium_fact_sk   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_row_id     text NOT NULL UNIQUE,
    transaction_ref   text,
    policy_sk         bigint NOT NULL REFERENCES dim_policy(policy_sk),
    client_sk         bigint NOT NULL REFERENCES dim_client(client_sk),
    advisor_sk        bigint REFERENCES dim_advisor(advisor_sk),
    channel_sk        smallint REFERENCES dim_channel(channel_sk),
    product_sk        smallint NOT NULL REFERENCES dim_product(product_sk),
    transaction_date_key integer NOT NULL REFERENCES dim_date(date_key),
    premium_amount    numeric(16,2) NOT NULL,
    commission_amount numeric(16,2) NOT NULL DEFAULT 0,
    transaction_type  text NOT NULL,
    is_reversal       boolean NOT NULL DEFAULT false,
    source_file       text NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_fact_premium_date ON fact_policy_premium(transaction_date_key);
CREATE INDEX IF NOT EXISTS ix_fact_premium_policy ON fact_policy_premium(policy_sk);
CREATE INDEX IF NOT EXISTS ix_fact_premium_advisor ON fact_policy_premium(advisor_sk);

CREATE TABLE IF NOT EXISTS fact_claim (
    claim_fact_sk     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_row_id     text NOT NULL UNIQUE,
    claim_bk          text NOT NULL,
    policy_sk         bigint NOT NULL REFERENCES dim_policy(policy_sk),
    client_sk         bigint NOT NULL REFERENCES dim_client(client_sk),
    advisor_sk        bigint REFERENCES dim_advisor(advisor_sk),
    channel_sk        smallint REFERENCES dim_channel(channel_sk),
    product_sk        smallint NOT NULL REFERENCES dim_product(product_sk),
    loss_date_key     integer NOT NULL REFERENCES dim_date(date_key),
    report_date_key   integer REFERENCES dim_date(date_key),
    settlement_date_key integer REFERENCES dim_date(date_key),
    claim_status      text NOT NULL,
    claim_type        text NOT NULL,
    claim_amount      numeric(16,2) NOT NULL,
    paid_amount       numeric(16,2) NOT NULL DEFAULT 0,
    incurred_amount   numeric(16,2),
    source_file       text NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_fact_claim_loss_date ON fact_claim(loss_date_key);
CREATE INDEX IF NOT EXISTS ix_fact_claim_policy ON fact_claim(policy_sk);
CREATE INDEX IF NOT EXISTS ix_fact_claim_status ON fact_claim(claim_status);

CREATE TABLE IF NOT EXISTS fact_payment (
    payment_fact_sk  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_row_id    text NOT NULL UNIQUE,
    transaction_ref  text,
    policy_sk        bigint NOT NULL REFERENCES dim_policy(policy_sk),
    client_sk        bigint NOT NULL REFERENCES dim_client(client_sk),
    payment_date_key integer NOT NULL REFERENCES dim_date(date_key),
    amount_zar       numeric(16,2) NOT NULL,
    payment_method   text NOT NULL,
    payment_status   text NOT NULL,
    currency_code    char(3) NOT NULL DEFAULT 'ZAR',
    is_reversal      boolean NOT NULL DEFAULT false,
    source_file      text NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_fact_payment_date ON fact_payment(payment_date_key);
CREATE INDEX IF NOT EXISTS ix_fact_payment_policy ON fact_payment(policy_sk);

CREATE TABLE IF NOT EXISTS fact_two_pot_snapshot (
    pot_fact_sk      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_row_id    text NOT NULL UNIQUE,
    account_bk       text NOT NULL,
    client_sk        bigint NOT NULL REFERENCES dim_client(client_sk),
    policy_sk        bigint REFERENCES dim_policy(policy_sk),
    snapshot_date_key integer NOT NULL REFERENCES dim_date(date_key),
    savings_balance  numeric(16,2) NOT NULL,
    retirement_balance numeric(16,2) NOT NULL,
    vested_balance   numeric(16,2) NOT NULL,
    reported_total   numeric(16,2) NOT NULL,
    withdrawal_amount numeric(16,2) NOT NULL DEFAULT 0,
    withdrawal_count integer NOT NULL DEFAULT 0,
    source_file      text NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_fact_pot_date ON fact_two_pot_snapshot(snapshot_date_key);
CREATE INDEX IF NOT EXISTS ix_fact_pot_client ON fact_two_pot_snapshot(client_sk);

CREATE TABLE IF NOT EXISTS etl_quarantine (
    quarantine_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id         uuid NOT NULL,
    source_file      text NOT NULL,
    source_row_id    text NOT NULL,
    source_table     text NOT NULL,
    reason_code      text NOT NULL,
    reason_detail    text NOT NULL,
    raw_record       jsonb NOT NULL,
    status           text NOT NULL DEFAULT 'open'
                     CHECK (status IN ('open','resolved','rejected')),
    loaded_at        timestamptz NOT NULL DEFAULT now(),
    resolved_at      timestamptz,
    UNIQUE (batch_id, source_file, source_row_id, reason_code)
);
CREATE INDEX IF NOT EXISTS ix_sanlam_quarantine_status ON etl_quarantine(status, loaded_at);
CREATE INDEX IF NOT EXISTS ix_sanlam_quarantine_reason ON etl_quarantine(reason_code);

CREATE TABLE IF NOT EXISTS etl_change_audit (
    audit_id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id         uuid NOT NULL,
    source_file      text NOT NULL,
    source_row_id    text NOT NULL,
    entity_name      text NOT NULL,
    field_name       text NOT NULL,
    original_value   text,
    new_value        text,
    rule_code        text NOT NULL,
    changed_at       timestamptz NOT NULL DEFAULT now(),
    UNIQUE (batch_id, source_file, source_row_id, field_name, rule_code)
);
CREATE INDEX IF NOT EXISTS ix_sanlam_audit_entity ON etl_change_audit(entity_name, rule_code);

CREATE TABLE IF NOT EXISTS etl_entity_crosswalk (
    source_system    text NOT NULL,
    entity_type      text NOT NULL,
    source_bk        text NOT NULL,
    survivor_bk      text NOT NULL,
    match_method     text NOT NULL,
    reviewed         boolean NOT NULL DEFAULT false,
    created_at       timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (source_system, entity_type, source_bk)
);

-- Starter controls. Extend these views for the chosen accepted/rejected rules.
CREATE OR REPLACE VIEW v_sanlam_quality_counts AS
SELECT source_file, source_table, status, count(*) AS row_count
FROM etl_quarantine
GROUP BY source_file, source_table, status;

CREATE OR REPLACE VIEW v_sanlam_claim_paid_by_month AS
SELECT d.calendar_year, d.calendar_month, sum(f.paid_amount) AS paid_claims_zar
FROM fact_claim f
JOIN dim_date d ON d.date_key = f.settlement_date_key
GROUP BY d.calendar_year, d.calendar_month;

-- Example reconciliation control; populate a batch-control table or source
-- aggregates as part of ETL before treating this as production evidence.
CREATE OR REPLACE VIEW v_sanlam_warehouse_control_totals AS
SELECT 'premium'::text AS measure_name, count(*) AS row_count,
       coalesce(sum(premium_amount), 0)::numeric(18,2) AS amount_zar
FROM fact_policy_premium
UNION ALL
SELECT 'paid_claim', count(*),
       coalesce(sum(paid_amount), 0)::numeric(18,2)
FROM fact_claim
UNION ALL
SELECT 'payment', count(*),
       coalesce(sum(amount_zar), 0)::numeric(18,2)
FROM fact_payment;