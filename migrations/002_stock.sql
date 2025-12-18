-- 002_stock: append-only stock ledger
CREATE TYPE movement_reason AS ENUM ('receipt', 'sale', 'adjustment', 'return');

CREATE TABLE stock_movements (
  id         bigserial PRIMARY KEY,
  part_id    uuid NOT NULL REFERENCES parts(id) ON DELETE RESTRICT,
  delta      integer NOT NULL CHECK (delta <> 0),
  reason     movement_reason NOT NULL,
  reference  text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX stock_movements_part_idx ON stock_movements (part_id, created_at DESC);
