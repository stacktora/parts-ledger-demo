-- 001_init: parts and suppliers
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE suppliers (
  code          text PRIMARY KEY,
  name          text NOT NULL,
  lead_time_days smallint NOT NULL DEFAULT 14,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE parts (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sku           text NOT NULL UNIQUE,
  name          text NOT NULL,
  supplier_code text NOT NULL REFERENCES suppliers(code),
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX parts_supplier_idx ON parts (supplier_code);
