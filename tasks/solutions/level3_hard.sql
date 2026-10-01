-- Решения: Сложненький (Т-1 .. Т-5)

-- Т-1. Эпизоды 3+ дня подряд со средней > 310
WITH daily AS (
  SELECT date_trunc('day', r.ts)::date AS day, AVG(r.value) AS avg_temp
  FROM sensor_readings r
  WHERE r.sensor_id IN (1,2) AND r.quality = 1
  GROUP BY 1
),
flagged AS (
  SELECT day, avg_temp,
         day - (row_number() OVER (ORDER BY day))::int AS grp
  FROM daily
  WHERE avg_temp > 310
)
SELECT MIN(day) AS start_day, MAX(day) AS end_day,
       COUNT(*) AS days, AVG(avg_temp)::numeric(10,2) AS avg_episode
FROM flagged
GROUP BY grp
HAVING COUNT(*) >= 3
ORDER BY start_day;
-- Ответ: 2025-03-10 .. 2025-03-12.

-- Т-2. Скользящее среднее 7 дней по суточной мощности
WITH daily AS (
  SELECT date_trunc('day', ts)::date AS day, AVG(power_mw) AS avg_mw
  FROM power_generation GROUP BY 1
)
SELECT day, avg_mw::numeric(10,1),
       AVG(avg_mw) OVER (ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)::numeric(10,1) AS ma7
FROM daily
ORDER BY day;
-- День первого падения MA7 < 500: начало июля (ППР).
-- График: см. 02-pandas.ipynb (rolling 7).

-- Т-3. Топ-3 датчика по тревогам + доля подтверждённых
SELECT s.tag,
       COUNT(*) AS total,
       COUNT(a.acknowledged_by) AS confirmed,
       (COUNT(a.acknowledged_by)::float / COUNT(*))::numeric(10,3) AS confirm_rate
FROM alarms a
JOIN sensors s ON s.id = a.sensor_id
GROUP BY 1
ORDER BY total DESC
LIMIT 3;

-- Т-4. Часы в ППР vs доза (июль) — SQL-часть, корреляция в pandas
WITH shifts_july AS (
  SELECT employee_id, COUNT(*) AS n_shifts
  FROM shift_schedule
  WHERE work_date >= '2025-07-01' AND work_date < '2025-08-01'
  GROUP BY 1
),
dose_july AS (
  SELECT employee_id, SUM(dose_msv) AS dose
  FROM dosimetry
  WHERE measure_date >= '2025-07-01' AND measure_date < '2025-08-01'
  GROUP BY 1
)
SELECT e.full_name, d2.name AS dept, s.n_shifts, dz.dose
FROM shifts_july s
JOIN dose_july dz USING (employee_id)
JOIN employees e ON e.id = s.employee_id
JOIN departments d2 ON d2.id = e.department_id
ORDER BY dz.dose DESC
LIMIT 15;
-- Python:
--   import pandas as pd
--   df = pd.read_sql(QUERY, engine)
--   print(df[['n_shifts','dose']].corr())
-- Ожидается положительная корреляция ~0.5-0.8.

-- Т-5. Superset — см. superset/README.md. Эталонный вывод:
-- "Март — перегрев 1 контура (critical 10-12.03, разгрузка блока);
--  Июль — ППР Блока-1 (мощность 0, КИУМ 0, рост доз у ремонтников);
--  Август — всплеск вибрации турбины (warning 05.08);
--  Октябрь — кратковременная разгрузка Блока-2 (15-16.10)."
