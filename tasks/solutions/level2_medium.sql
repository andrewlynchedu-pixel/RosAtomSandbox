-- Решения: Средний (С-1 .. С-7)

-- С-1. Дни со средней > 315 (Блок-1, датчики 1,2)
SELECT date_trunc('day', r.ts)::date AS day,
       AVG(r.value)::numeric(10,2) AS avg_temp
FROM sensor_readings r
WHERE r.sensor_id IN (1, 2) AND r.quality = 1
GROUP BY 1
HAVING AVG(r.value) > 315
ORDER BY 1;
-- Ответ: 2025-03-10, 03-11, 03-12.
-- График: см. jupyter/work/02-pandas.ipynb (axhline 315).

-- С-2. КИУМ своими руками
SELECT date_trunc('month', ts)::date AS month,
       AVG(power_mw / NULLIF(plan_mw, 0))::numeric(10,4) AS kium
FROM power_generation
GROUP BY 1
ORDER BY 1;

-- С-3. Топ-5 вибраций + кто работал в этот день
SELECT r.ts, s.tag, r.value, e.full_name, e.position
FROM sensor_readings r
JOIN sensors s ON s.id = r.sensor_id
JOIN sensor_types st ON st.id = s.sensor_type_id
JOIN shift_schedule sc ON sc.work_date = r.ts::date
JOIN employees e ON e.id = sc.employee_id
WHERE st.name = 'vibration' AND r.quality = 1
ORDER BY r.value DESC
LIMIT 5;
-- Людей много: join по дате даёт всех сменщиков дня (декартова связь замер×смена).

-- С-4. Сколько сменщиков было 10-12 марта
SELECT sc.work_date, COUNT(DISTINCT sc.employee_id) AS n_staff
FROM shift_schedule sc
WHERE sc.work_date IN ('2025-03-10','2025-03-11','2025-03-12')
GROUP BY 1
ORDER BY 1;

-- То же через тревоги:
SELECT DISTINCT sc.work_date, e.full_name
FROM alarms a
JOIN shift_schedule sc ON sc.work_date = a.ts::date
JOIN employees e ON e.id = sc.employee_id
WHERE a.severity = 'critical'
  AND a.ts >= '2025-03-10' AND a.ts < '2025-03-13'
ORDER BY 1, 2
LIMIT 20;

-- С-5. pandas — см. jupyter/work/03-viz.ipynb (resample D + plot факт/план).

-- С-6. Средняя годовая доза по отделам
SELECT d2.name AS dept, AVG(t.total)::numeric(10,3) AS avg_year_dose
FROM (
  SELECT employee_id, SUM(dose_msv) AS total
  FROM dosimetry GROUP BY 1
) t
JOIN employees e ON e.id = t.employee_id
JOIN departments d2 ON d2.id = e.department_id
GROUP BY 1
ORDER BY avg_year_dose DESC;
-- Выше всех РЦ-1 / ЦТАИ / ТЦ — работали в ППР в июле.

-- С-7. Стоимость ремонтов
SELECT work_type, SUM(cost_rub) AS total, COUNT(*) AS n
FROM maintenance GROUP BY 1 ORDER BY total DESC;

SELECT title, cost_rub FROM maintenance ORDER BY cost_rub DESC LIMIT 1;
-- Самый дорогой: ППР-2025 Блок-1 (~850 млн).
