-- Determines if a patient is ventilated on the first day of their ICU stay.
-- Creates a table with the result.
-- Requires the `ventdurations` table, generated by ../ventilation-durations.sql

DROP MATERIALIZED VIEW IF EXISTS ventfirstday CASCADE;
CREATE MATERIALIZED VIEW ventfirstday AS
select
  ie.subject_id, ie.hadm_id, ie.icustay_id
  -- if vd.icustay_id is not null, then they have a valid ventilation event
  -- in this case, we say they are ventilated
  -- otherwise, they are not
  , max(case
      when vd.icustay_id is not null then 1
    else 0 end) as vent
from icustays ie
left join ventdurations vd
  on ie.icustay_id = vd.icustay_id
  and
  (
    -- ventilation duration overlaps with ICU admission -> vented on admission
    (vd.starttime <= ie.intime and vd.endtime >= ie.intime)
    -- ventilation started during the first day
    OR (vd.starttime >= ie.intime and vd.starttime <= ie.intime + interval '1' day)
  )
group by ie.subject_id, ie.hadm_id, ie.icustay_id
order by ie.subject_id, ie.hadm_id, ie.icustay_id;