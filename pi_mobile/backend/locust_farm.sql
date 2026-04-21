-- PostgreSQL conversion of locust_farm database
-- Originally from MySQL/MariaDB dump

BEGIN;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS worker_invitations CASCADE;
DROP TABLE IF EXISTS feeding_schedules CASCADE;
DROP TABLE IF EXISTS container_sensor_history CASCADE;
DROP TABLE IF EXISTS container_workers CASCADE;
DROP TABLE IF EXISTS container_data CASCADE;
DROP TABLE IF EXISTS containers CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Create users table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE,
  full_name VARCHAR(255),
  hashed_password VARCHAR(255),
  is_active BOOLEAN,
  role VARCHAR(50),
  role_selected BOOLEAN DEFAULT FALSE,
  two_factor_enabled BOOLEAN NOT NULL DEFAULT FALSE
);

-- Create containers table
CREATE TABLE containers (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  created_by INTEGER NOT NULL REFERENCES users(id),
  latitude FLOAT NOT NULL,
  longitude FLOAT NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP
);

CREATE INDEX ix_containers_id ON containers(id);
CREATE INDEX idx_containers_created_by ON containers(created_by);

-- Create container_data table
CREATE TABLE container_data (
  id SERIAL PRIMARY KEY,
  container_id INTEGER NOT NULL UNIQUE REFERENCES containers(id),
  temperature FLOAT,
  humidity FLOAT,
  light_level FLOAT,
  gas_level FLOAT,
  heater_status BOOLEAN NOT NULL DEFAULT FALSE,
  fan_status BOOLEAN NOT NULL DEFAULT FALSE,
  light_status BOOLEAN NOT NULL DEFAULT FALSE,
  humidifier_status BOOLEAN NOT NULL DEFAULT FALSE,
  target_temperature FLOAT DEFAULT 25.0,
  target_humidity FLOAT DEFAULT 60.0,
  target_light_level FLOAT DEFAULT 75.0,
  target_gas_level FLOAT DEFAULT 350.0,
  last_updated TIMESTAMP,
  target_temperature_min FLOAT DEFAULT 20.0,
  target_humidity_min FLOAT DEFAULT 40.0,
  target_light_level_min FLOAT DEFAULT 30.0,
  target_gas_level_min FLOAT DEFAULT 150.0
);

CREATE INDEX ix_container_data_id ON container_data(id);

-- Create container_sensor_history table
CREATE TABLE container_sensor_history (
  id SERIAL PRIMARY KEY,
  container_id INTEGER NOT NULL REFERENCES containers(id),
  sensor_type VARCHAR(50) NOT NULL,
  value FLOAT NOT NULL,
  recorded_at TIMESTAMP NOT NULL
);

CREATE INDEX ix_container_sensor_history_id ON container_sensor_history(id);
CREATE INDEX ix_container_sensor_history_container_id ON container_sensor_history(container_id);
CREATE INDEX ix_container_sensor_history_sensor_type ON container_sensor_history(sensor_type);
CREATE INDEX ix_container_sensor_history_recorded_at ON container_sensor_history(recorded_at);

-- Create container_workers table (many-to-many)
CREATE TABLE container_workers (
  container_id INTEGER NOT NULL REFERENCES containers(id),
  worker_id INTEGER NOT NULL REFERENCES users(id),
  PRIMARY KEY (container_id, worker_id)
);

CREATE INDEX idx_container_workers_worker_id ON container_workers(worker_id);

-- Create feeding_schedules table
CREATE TABLE feeding_schedules (
  id SERIAL PRIMARY KEY,
  container_id INTEGER NOT NULL REFERENCES containers(id),
  feeding_at TIMESTAMP NOT NULL,
  amount FLOAT NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP
);

CREATE INDEX ix_feeding_schedules_id ON feeding_schedules(id);
CREATE INDEX ix_feeding_schedules_container_id ON feeding_schedules(container_id);
CREATE INDEX ix_feeding_schedules_feeding_at ON feeding_schedules(feeding_at);

-- Create worker_invitations table
CREATE TABLE worker_invitations (
  id SERIAL PRIMARY KEY,
  admin_id INTEGER NOT NULL REFERENCES users(id),
  worker_id INTEGER NOT NULL REFERENCES users(id),
  status VARCHAR(20) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  responded_at TIMESTAMP
);

CREATE INDEX ix_worker_invitations_id ON worker_invitations(id);
CREATE INDEX idx_worker_invitations_admin_id ON worker_invitations(admin_id);
CREATE INDEX idx_worker_invitations_worker_id ON worker_invitations(worker_id);

-- Set sequences to allow manual ID insertion
ALTER SEQUENCE users_id_seq RESTART WITH 21;
ALTER SEQUENCE containers_id_seq RESTART WITH 10;
ALTER SEQUENCE container_data_id_seq RESTART WITH 5;
ALTER SEQUENCE container_sensor_history_id_seq RESTART WITH 57;
ALTER SEQUENCE feeding_schedules_id_seq RESTART WITH 9;
ALTER SEQUENCE worker_invitations_id_seq RESTART WITH 4;

-- Insert data into users
INSERT INTO users (id, email, full_name, hashed_password, is_active, role, role_selected, two_factor_enabled) VALUES
(10, 'faresguermazi622@gmail.com', 'faresT', '$pbkdf2-sha256$29000$Pcf4P.e8VwqBsFZqbU1JaQ$SumpkEAVNC.XlaLPsPpWezlNkOSXDtDplcq4SlNdKls', true, 'ADMIN', true, false),
(11, 'g@gmail.com', 'G', '$pbkdf2-sha256$29000$mhOCUKr1XisF4Pw/J6T0ng$JAukwj9.v8yQuGsyaQIUkdFckliZ2pkXYou.oprfPWQ', true, 'FARMER', true, false),
(12, 'fg@gmail.com', 'g', '$pbkdf2-sha256$29000$IkTo/Z9zLqX0Xqs1BsAYww$7.jMEfLZrbkm0Y4OqtXz3TOVu5eLlPekwtDsQzWmSEs', true, 'ADMIN', true, false),
(14, 'ahmed@gmail.com', 'ahmed', '$pbkdf2-sha256$29000$6R0DQGgtJeRcizFmrDUmBA$d9YR/btmWKGu7C.tVKrrPcjWITehIk1yrIZXUsoXQ1Y', true, 'ADMIN', true, false),
(15, 'yousef@gmail.com', 'yousef', '$pbkdf2-sha256$29000$fW8N4bwXolRqDcHY.9/buw$5EHt34bDDPIjPbAt1RwOMTaT0nfNif5fNy5v1fhhRw4', true, 'FARMER', true, false),
(16, 'f@gmail.com', 'F', '$pbkdf2-sha256$29000$npNSao2xthZCiPG.lzKmlA$dk0RIYvzMmtGZMud2kjfKQsWMnX265zbRt.zhuVzKC4', true, 'ADMIN', true, false),
(19, 'D@gmail.com', '1', '$pbkdf2-sha256$29000$Q4gRwhjjPMeY03rP.V8LIQ$y88OWq3IoUcmCb.y4k45XkrfbVnh/jRiB026q2L58jo', true, 'ADMIN', true, false),
(20, 'farmer@gmail.com', 'farmer', '$pbkdf2-sha256$29000$2tvbG6M0BoCw1joHAEDonQ$U6CNuI4pXX1UDJqUwi8nh7c0RHPnpoHAuRZ25wA.GYk', true, 'ADMIN', true, false);

-- Insert data into containers
INSERT INTO containers (id, name, created_by, latitude, longitude, created_at, updated_at) VALUES
(5, 'A', 10, 36.7993, 10.1831, '2026-03-02 19:11:37', '2026-03-02 19:11:37'),
(6, '1', 12, 36.8008, 10.1839, '2026-03-02 20:02:04', '2026-03-02 20:02:04'),
(7, '1', 12, 36.8002, 10.1744, '2026-03-03 14:16:58', '2026-03-03 14:16:58'),
(8, 'h', 20, 36.8108, 10.1686, '2026-03-03 14:21:18', '2026-03-03 14:21:18'),
(9, 'g', 20, 36.8228, 10.1806, '2026-03-03 14:21:43', '2026-03-03 14:21:43');

-- Insert data into container_data
INSERT INTO container_data (id, container_id, temperature, humidity, light_level, gas_level, heater_status, fan_status, light_status, humidifier_status, target_temperature, target_humidity, target_light_level, target_gas_level, last_updated, target_temperature_min, target_humidity_min, target_light_level_min, target_gas_level_min) VALUES
(3, 8, 22, 53, 55.9219, 895, false, false, false, false, 25.6418, 60, 78.3571, 1000, '2026-04-07 18:02:18', 19.7651, 41.9531, 46.0488, 285.043),
(4, 9, 22, 51, 55.9219, 843, false, false, false, false, 25, 60, 75, 1000, '2026-04-03 13:13:38', 20.1159, 39.7605, 30.1138, 197.346);

-- Insert data into container_sensor_history
INSERT INTO container_sensor_history (id, container_id, sensor_type, value, recorded_at) VALUES
(1, 8, 'temperature', 30, '2026-04-02 13:23:42'),
(2, 8, 'humidity', 67.5, '2026-04-02 13:23:42'),
(3, 8, 'light_level', 436.8, '2026-04-02 13:23:42'),
(4, 8, 'gas_level', 416.8, '2026-04-02 13:23:42'),
(5, 8, 'temperature', 25, '2026-04-02 13:26:27'),
(6, 8, 'temperature', 22, '2026-04-02 13:26:53'),
(7, 8, 'humidity', 60, '2026-04-02 13:28:53'),
(8, 8, 'temperature', 26, '2026-04-02 13:38:40'),
(9, 8, 'temperature', 24, '2026-04-02 13:39:35'),
(10, 8, 'gas_level', 300, '2026-04-02 22:14:40'),
(11, 8, 'temperature', 20, '2026-04-02 22:15:33'),
(12, 8, 'temperature', 23, '2026-04-02 22:15:47'),
(13, 8, 'humidity', 80, '2026-04-02 22:16:01'),
(14, 8, 'humidity', 60, '2026-04-02 22:16:31'),
(15, 8, 'humidity', 30, '2026-04-02 22:16:39'),
(16, 8, 'humidity', 60, '2026-04-02 22:17:03'),
(17, 8, 'temperature', 27.9, '2026-04-03 12:02:30'),
(18, 8, 'humidity', 57.5, '2026-04-03 12:02:30'),
(19, 8, 'light_level', 61.0989, '2026-04-03 12:02:30'),
(20, 8, 'gas_level', 843, '2026-04-03 12:02:30'),
(21, 9, 'temperature', 23.3, '2026-04-03 12:04:03'),
(22, 9, 'humidity', 65.2, '2026-04-03 12:04:03'),
(23, 9, 'light_level', 679.5, '2026-04-03 12:04:03'),
(24, 9, 'gas_level', 452.3, '2026-04-03 12:04:03'),
(25, 8, 'temperature', 21.3, '2026-04-03 12:10:08'),
(26, 8, 'humidity', 40, '2026-04-03 12:10:08'),
(27, 8, 'light_level', 0, '2026-04-03 12:10:08'),
(28, 8, 'gas_level', 3628, '2026-04-03 12:10:08'),
(29, 8, 'humidity', 78.3, '2026-04-03 12:10:50'),
(30, 8, 'humidity', 40, '2026-04-03 12:10:50'),
(31, 8, 'gas_level', 843, '2026-04-03 12:11:04'),
(32, 8, 'humidity', 51, '2026-04-03 12:11:09'),
(33, 8, 'light_level', 55.9219, '2026-04-03 12:11:14'),
(34, 9, 'temperature', 21.3, '2026-04-03 12:11:39'),
(35, 9, 'humidity', 51, '2026-04-03 12:11:39'),
(36, 9, 'light_level', 55.9219, '2026-04-03 12:11:39'),
(37, 9, 'gas_level', 843, '2026-04-03 12:11:39'),
(38, 9, 'temperature', 25.7, '2026-04-03 12:11:59'),
(39, 9, 'temperature', 22, '2026-04-03 12:12:09'),
(40, 8, 'humidity', 53.5, '2026-04-06 16:38:59'),
(41, 8, 'light_level', 57.3871, '2026-04-06 16:38:59'),
(42, 8, 'temperature', 48.6, '2026-04-06 16:39:28'),
(43, 8, 'temperature', 22.7, '2026-04-06 16:45:28'),
(44, 8, 'temperature', 40.4, '2026-04-06 16:47:20'),
(45, 8, 'temperature', 23.5, '2026-04-06 16:47:34'),
(46, 8, 'humidity', 80.5, '2026-04-06 16:47:52'),
(47, 8, 'humidity', 21.5, '2026-04-06 16:48:09'),
(48, 8, 'humidity', 56.5, '2026-04-06 16:48:27'),
(49, 8, 'light_level', 85.9341, '2026-04-06 16:48:40'),
(50, 8, 'light_level', 92.5763, '2026-04-06 16:48:44'),
(51, 8, 'light_level', 71.453, '2026-04-06 16:49:01'),
(52, 8, 'light_level', 3.32112, '2026-04-06 16:49:05'),
(53, 8, 'light_level', 1.4652, '2026-04-06 16:49:14'),
(54, 8, 'light_level', 53.3822, '2026-04-06 16:49:24'),
(55, 8, 'gas_level', 1675, '2026-04-06 16:49:34'),
(56, 8, 'gas_level', 843, '2026-04-06 16:51:53');

-- Insert data into container_workers
INSERT INTO container_workers (container_id, worker_id) VALUES
(6, 15);

-- Insert data into feeding_schedules
INSERT INTO feeding_schedules (id, container_id, feeding_at, amount, created_at, updated_at) VALUES
(2, 6, '2026-03-03 01:18:34', 100, '2026-03-03 00:26:37', '2026-03-03 00:26:37'),
(5, 6, '2026-03-04 00:21:00', 200, '2026-03-03 00:26:37', '2026-03-03 00:26:37'),
(6, 6, '2026-03-04 00:21:00', 200, '2026-03-03 00:26:37', '2026-03-03 00:26:37'),
(7, 6, '2026-03-03 01:40:51', 100, '2026-03-03 00:41:06', '2026-03-03 00:41:06'),
(8, 8, '2026-04-02 13:29:43', 500, '2026-04-02 11:29:59', '2026-04-02 11:29:59');

-- Insert data into worker_invitations
INSERT INTO worker_invitations (id, admin_id, worker_id, status, created_at, responded_at) VALUES
(1, 10, 15, 'ACCEPTED', '2026-03-02 02:01:46', '2026-03-02 02:04:26'),
(2, 16, 15, 'ACCEPTED', '2026-03-02 18:45:52', '2026-03-02 18:47:27'),
(3, 12, 15, 'ACCEPTED', '2026-03-03 00:42:00', '2026-03-03 00:42:15');

COMMIT;
