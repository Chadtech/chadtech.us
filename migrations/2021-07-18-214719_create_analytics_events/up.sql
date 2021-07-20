CREATE TABLE analytics_event (
  id INTEGER PRIMARY KEY,
  name VARCHAR(256) NOT NULL,
  zasedani_id CHAR(36) NOT NULL,
  page_name VARCHAR(256) NOT NULL,
  props_json VARCHAR(512) NOT NULL
);