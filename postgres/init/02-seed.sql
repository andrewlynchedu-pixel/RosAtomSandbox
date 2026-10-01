-- ============================================================
-- Справочники: блоки, системы, типы датчиков, датчики,
-- отделы, смены, календарь
-- Факты (readings, generation...) грузятся из CSV через load.sql
-- ============================================================

INSERT INTO power_units (id, name, reactor_type, capacity_mw, commission_date, status) VALUES
(1, 'Энергоблок-1', 'ВВЭР-1000', 1000, '1985-12-20', 'in_service'),
(2, 'Энергоблок-2', 'ВВЭР-1200', 1200, '2018-03-15', 'in_service')
ON CONFLICT (id) DO NOTHING;

INSERT INTO systems (id, unit_id, name, description) VALUES
(1, 1, 'Реакторное отделение', 'Реактор, первый контур'),
(2, 1, 'Турбинный зал', 'Турбина К-1000, генератор'),
(3, 1, 'САОЗ', 'Системы аварийного охлаждения зоны'),
(4, 2, 'Реакторное отделение', 'Реактор ВВЭР-1200'),
(5, 2, 'Турбинный зал', 'Турбина К-1200'),
(6, 2, 'Электроцех', 'Генератор, трансформаторы')
ON CONFLICT (id) DO NOTHING;
SELECT setval('systems_id_seq', (SELECT MAX(id) FROM systems));

INSERT INTO sensor_types (id, name, unit_measure, min_normal, max_normal) VALUES
(1, 'temp_reactor',    '°C',  280, 325),
(2, 'pressure',        'МПа', 15.0, 16.5),
(3, 'neutron_flux',    '%',   85,  105),
(4, 'vibration',       'мм/с', 0,   4.5),
(5, 'water_level',     'м',    8.0, 12.0),
(6, 'temp_turbine_oil','°C',  35,  65)
ON CONFLICT (id) DO NOTHING;

-- Датчики: по 3-4 на каждый тип, привязаны к системам
INSERT INTO sensors (id, system_id, sensor_type_id, tag, location, installed_on) VALUES
(1,  1, 1, 'T-RO-1-01', 'Петля ГЦК-1, Блок-1', '2020-01-10'),
(2,  1, 1, 'T-RO-1-02', 'Петля ГЦК-2, Блок-1', '2020-01-10'),
(3,  4, 1, 'T-RO-2-01', 'Петля ГЦК-1, Блок-2', '2018-03-01'),
(4,  4, 1, 'T-RO-2-02', 'Петля ГЦК-3, Блок-2', '2018-03-01'),
(5,  1, 2, 'P-1K-1-01', 'Компенсатор давления, Блок-1', '2020-02-01'),
(6,  4, 2, 'P-1K-2-01', 'Компенсатор давления, Блок-2', '2018-03-01'),
(7,  1, 3, 'N-FLUX-1-01', 'ИК вне реактора, Блок-1', '2021-06-01'),
(8,  4, 3, 'N-FLUX-2-01', 'ИК вне реактора, Блок-2', '2018-03-01'),
(9,  2, 4, 'V-TURB-1-01', 'Подшипник №3 турбины, Блок-1', '2019-09-12'),
(10, 5, 4, 'V-TURB-2-01', 'Подшипник №3 турбины, Блок-2', '2018-04-20'),
(11, 1, 5, 'L-KD-1-01', 'Компенсатор давления уровень, Блок-1', '2020-02-01'),
(12, 4, 5, 'L-KD-2-01', 'Компенсатор давления уровень, Блок-2', '2018-03-01'),
(13, 2, 6, 'T-OIL-1-01', 'Маслобак турбины, Блок-1', '2019-09-12'),
(14, 5, 6, 'T-OIL-2-01', 'Маслобак турбины, Блок-2', '2018-04-20')
ON CONFLICT (id) DO NOTHING;
SELECT setval('sensors_id_seq', (SELECT MAX(id) FROM sensors));

INSERT INTO departments (id, name) VALUES
(1, 'РЦ-1 Реакторный цех'),
(2, 'ТЦ-2 Турбинный цех'),
(3, 'ЭЦ Электроцех'),
(4, 'ЦТАИ Цех ТАИ'),
(5, 'ХЦ Химцех'),
(6, 'ОЯБиН Отдел ядерной безопасности')
ON CONFLICT (id) DO NOTHING;
SELECT setval('departments_id_seq', (SELECT MAX(id) FROM departments));

INSERT INTO shifts (id, name, start_time, end_time) VALUES
(1, 'Смена А (день)',   '08:00', '20:00'),
(2, 'Смена Б (ночь)',  '20:00', '08:00'),
(3, 'Дневная 5/2',     '09:00', '18:00')
ON CONFLICT (id) DO NOTHING;
SELECT setval('shifts_id_seq', (SELECT MAX(id) FROM shifts));

-- Календарь 2024-2025: выходные + праздники РФ (упрощенно)
INSERT INTO calendars (date_value, is_weekend, is_holiday, day_type)
SELECT d::date,
       EXTRACT(ISODOW FROM d) IN (6,7),
       FALSE,
       CASE WHEN EXTRACT(ISODOW FROM d) IN (6,7) THEN 'weekend' ELSE 'workday' END
FROM generate_series('2024-01-01'::date, '2025-12-31'::date, '1 day') d
ON CONFLICT (date_value) DO NOTHING;

UPDATE calendars SET is_holiday = TRUE, day_type = 'holiday'
WHERE date_value IN (
 '2024-01-01','2024-01-02','2024-01-07','2024-02-23','2024-03-08','2024-05-01','2024-05-09','2024-06-12','2024-11-04',
 '2025-01-01','2025-01-02','2025-01-07','2025-02-23','2025-03-08','2025-05-01','2025-05-09','2025-06-12','2025-11-04'
);
