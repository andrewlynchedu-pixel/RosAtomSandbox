-- ============================================================
-- АЭС "Учебная": схема базы данных
-- Блоки, системы, датчики, выработка, тревоги, ремонты,
-- сотрудники, смены, график, дозиметрия, календарь
-- ============================================================

CREATE TABLE IF NOT EXISTS power_units (
    id            SMALLINT PRIMARY KEY,
    name          TEXT NOT NULL,          -- Энергоблок-1 ...
    reactor_type  TEXT NOT NULL,          -- ВВЭР-1000, ВВЭР-1200
    capacity_mw   INTEGER NOT NULL CHECK (capacity_mw > 0),
    commission_date DATE NOT NULL,
    status        TEXT NOT NULL DEFAULT 'in_service'
        CHECK (status IN ('in_service','maintenance','decommissioned'))
);

CREATE TABLE IF NOT EXISTS systems (
    id          SERIAL PRIMARY KEY,
    unit_id     SMALLINT NOT NULL REFERENCES power_units(id),
    name        TEXT NOT NULL,            -- Реакторное отделение, Турбинный зал ...
    description TEXT
);

CREATE TABLE IF NOT EXISTS sensor_types (
    id          SMALLINT PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE,     -- temp_reactor, pressure, neutron_flux ...
    unit_measure TEXT NOT NULL,           -- °C, МПа, % ...
    min_normal  DOUBLE PRECISION NOT NULL,
    max_normal  DOUBLE PRECISION NOT NULL,
    CHECK (min_normal < max_normal)
);

CREATE TABLE IF NOT EXISTS sensors (
    id              SERIAL PRIMARY KEY,
    system_id       INTEGER NOT NULL REFERENCES systems(id),
    sensor_type_id  SMALLINT NOT NULL REFERENCES sensor_types(id),
    tag             TEXT NOT NULL UNIQUE, -- T-RO-1-01 ...
    location        TEXT NOT NULL,
    installed_on    DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS sensor_readings (
    ts          TIMESTAMP NOT NULL,
    sensor_id   INTEGER NOT NULL REFERENCES sensors(id),
    value       DOUBLE PRECISION NOT NULL,
    quality     SMALLINT NOT NULL DEFAULT 1 CHECK (quality IN (0,1,2))
);

CREATE TABLE IF NOT EXISTS power_generation (
    ts        TIMESTAMP PRIMARY KEY,
    unit_id   SMALLINT NOT NULL REFERENCES power_units(id),
    power_mw  DOUBLE PRECISION NOT NULL CHECK (power_mw >= 0),
    plan_mw   DOUBLE PRECISION NOT NULL CHECK (plan_mw >= 0)
);
-- NOTE: для простоты учебного стенда power_generation хранит один блок-ряд.
-- Если захочешь 2 блока почасово — смотри tasks (средний уровень) как переделать в (ts, unit_id).

CREATE TABLE IF NOT EXISTS alarms (
    id             SERIAL PRIMARY KEY,
    ts             TIMESTAMP NOT NULL,
    sensor_id      INTEGER REFERENCES sensors(id),
    unit_id        SMALLINT REFERENCES power_units(id),
    severity       TEXT NOT NULL CHECK (severity IN ('info','warning','critical')),
    message        TEXT NOT NULL,
    acknowledged_by INTEGER,
    resolved_at    TIMESTAMP
);

CREATE TABLE IF NOT EXISTS maintenance (
    work_id     SERIAL PRIMARY KEY,
    unit_id     SMALLINT REFERENCES power_units(id),
    system_id   INTEGER REFERENCES systems(id),
    title       TEXT NOT NULL,
    work_type   TEXT NOT NULL CHECK (work_type IN ('ППР','аварийный','текущий')),
    start_date  DATE NOT NULL,
    end_date    DATE NOT NULL,
    cost_rub    BIGINT CHECK (cost_rub >= 0),
    contractor  TEXT,
    CHECK (start_date <= end_date)
);

CREATE TABLE IF NOT EXISTS departments (
    id   SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE  -- РЦ-1, ТЦ-2, ЭЦ, ЦТАИ, ХЦ, ОЯБиН ...
);

CREATE TABLE IF NOT EXISTS employees (
    id           SERIAL PRIMARY KEY,
    full_name    TEXT NOT NULL,
    department_id INTEGER REFERENCES departments(id),
    position     TEXT NOT NULL,
    hire_date    DATE NOT NULL,
    skill_level  SMALLINT CHECK (skill_level BETWEEN 1 AND 5),
    salary_rub   INTEGER CHECK (salary_rub > 0)
);

-- Добавляем chief после создания employees (циклическая ссылка отделы<->начальники)
-- ALTER сделали идемпотентным через DO-блок:
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='departments' AND column_name='chief_id'
    ) THEN
        ALTER TABLE departments ADD COLUMN chief_id INTEGER REFERENCES employees(id);
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS shifts (
    id         SERIAL PRIMARY KEY,
    name       TEXT NOT NULL UNIQUE, -- Смена А, Смена Б, Смена В, День
    start_time TIME NOT NULL,
    end_time   TIME NOT NULL
);

CREATE TABLE IF NOT EXISTS shift_schedule (
    id          SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(id),
    shift_id    INTEGER NOT NULL REFERENCES shifts(id),
    work_date   DATE NOT NULL,
    UNIQUE (employee_id, work_date)
);

CREATE TABLE IF NOT EXISTS dosimetry (
    id           SERIAL PRIMARY KEY,
    employee_id  INTEGER NOT NULL REFERENCES employees(id),
    measure_date DATE NOT NULL,
    dose_msv     DOUBLE PRECISION NOT NULL CHECK (dose_msv >= 0),
    UNIQUE (employee_id, measure_date)
);

CREATE TABLE IF NOT EXISTS calendars (
    date_value DATE PRIMARY KEY,
    is_weekend BOOLEAN NOT NULL DEFAULT FALSE,
    is_holiday BOOLEAN NOT NULL DEFAULT FALSE,
    day_type   TEXT NOT NULL DEFAULT 'workday'
        CHECK (day_type IN ('workday','weekend','holiday'))
);

-- Индексы под учебные запросы
CREATE INDEX IF NOT EXISTS idx_readings_sensor_ts ON sensor_readings (sensor_id, ts);
CREATE INDEX IF NOT EXISTS idx_readings_ts ON sensor_readings (ts);
CREATE INDEX IF NOT EXISTS idx_generation_ts ON power_generation (ts);
CREATE INDEX IF NOT EXISTS idx_alarms_ts ON alarms (ts);
CREATE INDEX IF NOT EXISTS idx_alarms_severity ON alarms (severity);
CREATE INDEX IF NOT EXISTS idx_schedule_date ON shift_schedule (work_date);
CREATE INDEX IF NOT EXISTS idx_schedule_emp ON shift_schedule (employee_id);
CREATE INDEX IF NOT EXISTS idx_dosimetry_date ON dosimetry (measure_date);
CREATE INDEX IF NOT EXISTS idx_maintenance_dates ON maintenance (start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_sensors_type ON sensors (sensor_type_id);

-- Удобные VIEW для старта
CREATE OR REPLACE VIEW v_daily_avg_temp AS
SELECT
    date_trunc('day', r.ts)::date AS day,
    s.tag,
    st.name AS sensor_type,
    AVG(r.value)::numeric(10,2) AS avg_value,
    MAX(r.value)::numeric(10,2) AS max_value,
    COUNT(*) AS n_readings
FROM sensor_readings r
JOIN sensors s ON s.id = r.sensor_id
JOIN sensor_types st ON st.id = s.sensor_type_id
WHERE st.name = 'temp_reactor'
GROUP BY 1, 2, 3;

CREATE OR REPLACE VIEW v_unit_load_factor AS
SELECT
    date_trunc('month', ts)::date AS month,
    AVG(power_mw / NULLIF(plan_mw, 0))::numeric(10,4) AS load_factor,
    AVG(power_mw)::numeric(10,1) AS avg_power_mw,
    SUM(power_mw)::numeric(14,1) AS sum_mwh
FROM power_generation
GROUP BY 1;
