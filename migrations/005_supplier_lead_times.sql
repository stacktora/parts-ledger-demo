-- 005_supplier_lead_times: per-part override of the supplier default
ALTER TABLE parts ADD COLUMN lead_time_days smallint;
COMMENT ON COLUMN parts.lead_time_days IS 'overrides suppliers.lead_time_days when set';
