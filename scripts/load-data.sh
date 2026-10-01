#!/usr/bin/env bash
# Загрузка CSV в Postgres (Linux/macOS/Git Bash).
# Запуск из корня репо:  bash ./scripts/load-data.sh
set -e
psql_exec() { docker compose exec -T postgres psql -U npp_analyst -d npp -c "$1"; }

echo "== load employees =="
psql_exec "COPY employees(id, full_name, department_id, position, hire_date, skill_level, salary_rub) FROM '/seed-data/employees.csv' CSV;"
echo "== load sensor_readings =="
psql_exec "COPY sensor_readings(ts, sensor_id, value, quality) FROM '/seed-data/sensor_readings.csv' CSV;"
echo "== load power_generation =="
psql_exec "COPY power_generation(ts, unit_id, power_mw, plan_mw) FROM '/seed-data/power_generation.csv' CSV;"
echo "== load alarms =="
psql_exec "COPY alarms(id, ts, sensor_id, unit_id, severity, message, acknowledged_by, resolved_at) FROM '/seed-data/alarms.csv' CSV NULL AS '\N';"
echo "== load maintenance =="
psql_exec "COPY maintenance(work_id, unit_id, system_id, title, work_type, start_date, end_date, cost_rub, contractor) FROM '/seed-data/maintenance.csv' CSV;"
echo "== load shift_schedule =="
psql_exec "COPY shift_schedule(id, employee_id, shift_id, work_date) FROM '/seed-data/shift_schedule.csv' CSV;"
echo "== load dosimetry =="
psql_exec "COPY dosimetry(id, employee_id, measure_date, dose_msv) FROM '/seed-data/dosimetry.csv' CSV;"
echo "== fix sequences =="
psql_exec "SELECT setval('employees_id_seq',(SELECT MAX(id) FROM employees)); SELECT setval('alarms_id_seq',(SELECT MAX(id) FROM alarms)); SELECT setval('maintenance_work_id_seq',(SELECT MAX(work_id) FROM maintenance)); SELECT setval('shift_schedule_id_seq',(SELECT MAX(id) FROM shift_schedule)); SELECT setval('dosimetry_id_seq',(SELECT MAX(id) FROM dosimetry));"
echo "== counts =="
psql_exec "SELECT 'employees' t, COUNT(*) FROM employees UNION ALL SELECT 'sensor_readings', COUNT(*) FROM sensor_readings UNION ALL SELECT 'power_generation', COUNT(*) FROM power_generation UNION ALL SELECT 'alarms', COUNT(*) FROM alarms UNION ALL SELECT 'maintenance', COUNT(*) FROM maintenance UNION ALL SELECT 'shift_schedule', COUNT(*) FROM shift_schedule UNION ALL SELECT 'dosimetry', COUNT(*) FROM dosimetry ORDER BY 1;"
echo "DONE. Дальше: tasks/tasks.md"
