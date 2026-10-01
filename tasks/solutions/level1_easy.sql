-- Решения: Лёгкий (Л-1 .. Л-6)

-- Л-1. Средняя температура по дням, март 2025
SELECT date_trunc('day', r.ts)::date AS day,
       AVG(r.value)::numeric(10,2) AS avg_temp
FROM sensor_readings r
JOIN sensors s ON s.id = r.sensor_id
JOIN sensor_types st ON st.id = s.sensor_type_id
WHERE st.name = 'temp_reactor'
  AND r.ts >= '2025-03-01' AND r.ts < '2025-04-01'
GROUP BY 1
ORDER BY 1;
-- Максимум: 2025-03-11 (эпицентр перегрева).

-- Л-2. Выработка по месяцам
SELECT date_trunc('month', ts)::date AS month,
       AVG(power_mw)::numeric(10,1) AS avg_mw,
       SUM(power_mw)::numeric(14,1) AS sum_mwh,
       MIN(power_mw) AS min_mw
FROM power_generation
GROUP BY 1
ORDER BY 1;
-- Минимум средней — июль 2025 (ППР, мощность 0).

-- Л-3. Доза по сотрудникам за год, топ-10
SELECT e.id, e.full_name, d2.name AS dept, SUM(d.dose_msv)::numeric(10,2) AS total_dose
FROM dosimetry d
JOIN employees e ON e.id = d.employee_id
JOIN departments d2 ON d2.id = e.department_id
WHERE d.measure_date >= '2025-01-01' AND d.measure_date < '2026-01-01'
GROUP BY 1, 2, 3
ORDER BY total_dose DESC
LIMIT 10;

-- Л-4. Тревоги по severity + по месяцам
SELECT severity, COUNT(*) FROM alarms GROUP BY 1 ORDER BY 2 DESC;

SELECT date_trunc('month', ts)::date AS month, severity, COUNT(*)
FROM alarms
GROUP BY 1, 2
ORDER BY 1, 2;

-- Л-5. Смены в марте по сотрудникам, топ-10
SELECT e.full_name, COUNT(*) AS n_shifts
FROM shift_schedule sc
JOIN employees e ON e.id = sc.employee_id
WHERE sc.work_date >= '2025-03-01' AND sc.work_date < '2025-04-01'
GROUP BY 1
ORDER BY n_shifts DESC
LIMIT 10;

-- Л-6. Готовая VIEW
SELECT * FROM v_unit_load_factor ORDER BY month;
-- load_factor = факт/план. В июле ~0 потому что блок стоял в ППР.
