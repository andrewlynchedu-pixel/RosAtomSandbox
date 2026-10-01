# Задания по аналитике АЭС (SQL в приоритете)

База `npp`, год данных — **2025**. Ответы не подглядывай: решения в `solutions/`.
В CloudBeaver/Jupyter подключайся и выполняй по порядку. Норматива по времени нет.

Схема-шпаргалка:
- `power_units(id, name, reactor_type, capacity_mw, ...)` — блоки
- `systems(id, unit_id, name)` — цеха/системы
- `sensor_types(id, name, unit_measure, min_normal, max_normal)` — `temp_reactor, pressure, neutron_flux, vibration, water_level, temp_turbine_oil`
- `sensors(id, system_id, sensor_type_id, tag, location)` — 14 датчиков
- `sensor_readings(ts, sensor_id, value, quality)` — quality: 1=ок, 0=обрыв, 2=недостоверно
- `power_generation(ts, unit_id, power_mw, plan_mw)` — почасовка Блока-1
- `alarms(id, ts, sensor_id, unit_id, severity, message, acknowledged_by, resolved_at)`
- `maintenance(work_id, unit_id, system_id, title, work_type, start_date, end_date, cost_rub, contractor)`
- `departments(id, name)`, `employees(id, full_name, department_id, position, hire_date, skill_level, salary_rub)`
- `shifts(id, name)`, `shift_schedule(id, employee_id, shift_id, work_date)`
- `dosimetry(id, employee_id, measure_date, dose_msv)`
- `calendars(date_value, is_weekend, is_holiday, day_type)`
- VIEW: `v_daily_avg_temp(day, tag, sensor_type, avg_value, max_value)`, `v_unit_load_factor(month, load_factor, avg_power_mw)`

---

## Уровень 0 — Очень лёгкий (SELECT, WHERE, ORDER BY, LIMIT)

### ОЛ-1. Топ-10 самых горячих замеров
Найди 10 самых высоких значений температуры реактора за весь год.
Выведи `ts, tag, value`. Таблица-подсказка: `sensor_readings + sensors + sensor_types (name='temp_reactor')`.

### ОЛ-2. Все сотрудники ЦТАИ
Выведи `full_name, position, salary_rub` всех сотрудников отдела `ЦТАИ` (id=4 или LIKE '%ЦТАИ%').
Отсортируй по зарплате по убыванию.

### ОЛ-3. Все ППР 2025 года
Выведи `title, unit_id, start_date, end_date` из `maintenance`, где `work_type='ППР'`.

### ОЛ-4. Критические тревоги марта
Посчитай количество строк в `alarms`, где `severity='critical'` и `ts` в марте 2025.
Затем выведи их все (`ts, message`) по порядку времени.

### ОЛ-5. Датчики вибрации
Выведи `tag, location` всех датчиков типа `vibration`. Сколько их?

### ОЛ-6. Кто нанят после 2020 года
Выведи `full_name, position, hire_date` сотрудников с `hire_date >= '2020-01-01'`, сортировка по дате найма.

---

## Уровень 1 — Лёгкий (GROUP BY, JOIN, DATE_TRUNC, агрегаты)

### Л-1. Средняя температура по дням
Для датчиков температуры реактора посчитай среднюю температуру по дням за март 2025.
Колонки: `day, avg_temp`. Сортировка по дню. Вопрос: в какой день средняя была максимальной?

### Л-2. Выработка по месяцам
По `power_generation` посчитай по месяцам: `month, AVG(power_mw), SUM(power_mw), MIN(power_mw)`.
В каком месяце средняя минимальная и почему? (подсказка: ППР в июле).

### Л-3. Доза по сотрудникам за год
По `dosimetry` посчитай суммарную дозу каждого сотрудника за 2025: `employee_id, SUM(dose_msv)`.
Выведи топ-10 по дозе. Затем JOIN с `employees`, чтобы увидеть ФИО и отдел.

### Л-4. Тревоги по severity
Сгруппируй `alarms` по `severity`: `severity, COUNT(*)`. Каких больше всего?
Дополнительно: сгруппируй по месяцам + severity (`date_trunc('month', ts)`).

### Л-5. Смены в марте: кто сколько работал
Посчитай, сколько смен отработал каждый сотрудник в марте 2025 (`shift_schedule`, группировка по `employee_id`).
Выведи топ-10 самых загруженных + их ФИО через JOIN.

### Л-6. Средний КИУМ по месяцам (готовая VIEW)
`SELECT * FROM v_unit_load_factor ORDER BY month;`
Объясни своими словами: что такое load_factor и почему в июле он ~0?

---

## Уровень 2 — Средний (HAVING, CASE, подзапросы, оконные базовые, pandas)

### С-1. ⭐ Дни, когда средняя температура превышала уставку + визуализация
Найди дни, когда **среднедневная** температура реактора (датчики 1,2 — Блок-1) превышала **315°C**.
Выведи `day, avg_temp`. Затем построй график в Jupyter (`01-sql-starter.ipynb` или `02-pandas.ipynb`):
дневная температура за март + горизонтальная линия 315.
Ожидаешь увидеть 10–12 марта.

### С-2. КИУМ своими руками
Без VIEW посчитай по `power_generation` месячный КИУМ = `AVG(power_mw / plan_mw)`.
Колонки: `month, kium`. Сравни с `v_unit_load_factor`. Совпало?

### С-3. Смены с максимальной вибрацией (join по времени)
Найди 5 замеров вибрации с максимальным `value` (тип `vibration`, quality=1).
Для каждого найди, кто работал в этот день (join `shift_schedule ON work_date = reading::date`).
Выведи `ts, tag, value, full_name, position`. Подумай: почему людей много, а замер один?

### С-4. Кто работал во время аварии
Возьми критические тревоги 10–12 марта. Найди всех сотрудников, у которых `work_date` совпадает с датой тревоги.
Посчитай, сколько сменщиков было на станции в каждый из этих 3 дней.

### С-5. pandas: ресемпл + график мощности
В Jupyter загрузи `power_generation` в DataFrame, сделай среднесуточную мощность (`resample('D')`),
построй два графика: факт и план за год. Отметь ППР (июль — провал до 0).
Код-заготовка — в `03-viz.ipynb`.

### С-6. Доза vs отдел
Посчитай среднюю суммарную годовую дозу по отделам (JOIN `dosimetry+employees+departments`, GROUP BY отдел).
Какой цех «светится» больше и почему? (подсказка: кто работал в ППР в июле).

### С-7. Ремонты: цена вопроса
Посчитай суммарную стоимость ремонтов по `work_type` и по блокам (`unit_id`).
Какой тип работ самый дорогой? Выведи также самый дорогой единичный ремонт (`ORDER BY cost_rub DESC LIMIT 1`).

---

## Уровень 3 — Сложненький (LAG/LEAD, скользящие средние, эпизоды) — без жести

### Т-1. Эпизоды перегрева 3 дня подряд
Найди периоды, когда среднедневная температура > 310°C держалась **3+ дня подряд**.
Подсказка: CTE `daily`, затем `LAG(avg_temp) OVER (ORDER BY day)` и счётчик серий, либо разность `day - row_number`.
Эталонный ответ: 10–12 марта.

### Т-2. Скользящее среднее 7 дней по мощности
Посчитай `AVG(power_mw) OVER (ORDER BY ts ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)` по суточным данным.
Найди день, когда 7-дневное среднее впервые упало ниже 500 МВт летом (начало ППР).
Визуализируй в Jupyter: факт + MA7.

### Т-3. Топ-3 датчика по числу тревог + доля подтверждённых
По `alarms` сгруппируй по `sensor_id`: `COUNT(*)`, `COUNT(acknowledged_by)` (подтверждены).
Вычисли долю `confirmed/total`. Выведи топ-3 + `tag` датчика.
Вопрос: есть ли датчики с большим числом, но низкой подтверждаемостью (ложные)?

### Т-4. Связь «часы в ППР ↔ доза»
Для июля 2025 посчитай по сотрудникам: число смен (`COUNT` в `shift_schedule`) и дозу за июль (`dosimetry`).
Соедини два подзапроса по `employee_id`, посчитай корреляцию в pandas (`df.corr()`).
Правда ли, что кто больше работал в июле — тот больше «схватил»?

### Т-5. Мини-дашборд в Superset
Собери дашборд «АЭС-2025» (инструкция в `superset/README.md`):
1. Line: средняя дневная мощность vs план.
2. Bar stacked: тревоги по месяцам по severity.
3. Markdown-вывод: 2-3 предложения — что случилось в марте, июле, августе и октябре?
Скриншот дашборда сохрани себе в папку (не в git).

---

## Как проверяться
1. Решения — в `solutions/` (по одному файлу на уровень). Сначала реши сам, потом сверь.
2. В Jupyter есть заготовки `jupyter/work/*.ipynb` для С-1, С-5, Т-2.
3. Если запрос выполняется дольше 2-3 секунд — покажи его мне, разберём индексы.

Удачи! Если застрянешь на С-1 — это нормально, это ключевое задание уровня.
