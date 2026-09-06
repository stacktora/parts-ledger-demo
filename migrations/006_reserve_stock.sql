-- 006_reserve_stock: hold stock between quote and order
ALTER TABLE stock_movements ADD COLUMN reserved boolean NOT NULL DEFAULT false;
ALTER TABLE stock_movements ADD COLUMN reserved_until timestamptz;

DROP INDEX parts_supplier_idx;

CREATE INDEX stock_movements_reserved_idx
  ON stock_movements (part_id, reserved_until)
  WHERE reserved;
