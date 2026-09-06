-- 004_ledger_index: the ledger read path scans by part and time
CREATE INDEX CONCURRENTLY stock_movements_part_created_idx
  ON stock_movements (part_id, created_at DESC);
