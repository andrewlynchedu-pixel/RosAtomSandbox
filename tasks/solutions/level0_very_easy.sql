-- Решения: Очень лёгкий (ОЛ-1 .. ОЛ-6)

-- ОЛ-1. Топ-10 самых горячих замеров
SELECT r.ts, s.tag, r.value
FROM sensor_readings r
JOIN sensors s ON s.id = r.sensor_id
JOIN sensor_types st ON st.id = s.sensor_type_id
WHERE st.name = 'temp_reactor'
ORDER BY r.value DESC
LIMIT 10;

-- ОЛ-2. Все сотрудники ЦТАИ
SELECT e.full_name, e.position, e.salary_rub
FROM employees e
JOIN departments d ON d.id = e.department_id
WHERE d.name LIKE '%ЦТАИ%'
ORDER BY e.salary_rub DESC;

-- ОЛ-3. Все ППР 2025
SELECT title, unit_id, start_date, end_date
FROM maintenance
WHERE work_type = 'ППР'
ORDER BY start_date;

-- ОЛ-4. Критические тревоги марта
SELECT COUNT(*) FROM alarms
WHERE severity = 'critical'
  AND ts >= '2025-03-01' AND ts < '2025-04-01';

SELECT ts, message FROM alarms
WHERE severity = 'critical'
  AND ts >= '2025-03-01' AND ts < '2025-04-01'
ORDER BY ts;

-- ОЛ-5. Датчики вибрации
SELECT s.tag, s.location
FROM sensors s
JOIN sensor_types st ON st.id = s.sensor_type_id
WHERE st.name = 'vibration';
-- Ответ: 2 (V-TURB-1-01, V-TURB-2-01)

-- ОЛ-6. Нанятые после 2020
SELECT full_name, position, hire_date
FROM employees
WHERE hire_date >= '2020-01-01'
ORDER BY hire_date;
