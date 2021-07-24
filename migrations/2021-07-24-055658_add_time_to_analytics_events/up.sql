ALTER TABLE analytics_event
ADD COLUMN event_time DOUBLE NOT NULL;

UPDATE analytics_event SET event_time = 0;