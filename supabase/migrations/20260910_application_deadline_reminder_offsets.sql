-- Store selected application-deadline reminder offsets without changing existing alert behavior.
ALTER TABLE board_pulse.alert_subscriptions
  ADD COLUMN IF NOT EXISTS reminder_offsets_days integer[];

UPDATE board_pulse.alert_subscriptions
SET reminder_offsets_days = ARRAY[7]
WHERE alert_type = 'application_deadline'
  AND reminder_offsets_days IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'alert_subscriptions_reminder_offsets_days_check'
      AND conrelid = 'board_pulse.alert_subscriptions'::regclass
  ) THEN
    ALTER TABLE board_pulse.alert_subscriptions
      ADD CONSTRAINT alert_subscriptions_reminder_offsets_days_check
      CHECK (
        reminder_offsets_days IS NULL
        OR alert_type = 'application_deadline'
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'alert_subscriptions_reminder_offsets_values_check'
      AND conrelid = 'board_pulse.alert_subscriptions'::regclass
  ) THEN
    ALTER TABLE board_pulse.alert_subscriptions
      ADD CONSTRAINT alert_subscriptions_reminder_offsets_values_check
      CHECK (
        reminder_offsets_days IS NULL
        OR (
          cardinality(reminder_offsets_days) BETWEEN 1 AND 4
          AND reminder_offsets_days <@ ARRAY[1, 7, 14, 30]::integer[]
        )
      );
  END IF;
END $$;
