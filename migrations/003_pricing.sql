-- 003_pricing: quantity price bands
CREATE TABLE price_bands (
  part_id          uuid NOT NULL REFERENCES parts(id) ON DELETE CASCADE,
  min_quantity     integer NOT NULL CHECK (min_quantity >= 1),
  unit_price_cents integer NOT NULL CHECK (unit_price_cents >= 0),
  PRIMARY KEY (part_id, min_quantity)
);

CREATE TABLE price_history (
  id               bigserial PRIMARY KEY,
  part_id          uuid NOT NULL REFERENCES parts(id) ON DELETE CASCADE,
  unit_price_cents integer NOT NULL,
  changed_at       timestamptz NOT NULL DEFAULT now(),
  changed_by       text NOT NULL
);

CREATE INDEX price_history_part_idx ON price_history (part_id, changed_at DESC);
