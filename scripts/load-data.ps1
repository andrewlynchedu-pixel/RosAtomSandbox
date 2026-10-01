# Загрузка сгенерированных CSV в Postgres (Windows PowerShell).
# Запуск из корня репо:  powershell -ExecutionPolicy Bypass -File ./scripts/load-data.ps1
# Требует: поднятый postgres (docker compose up -d postgres) + CSV из python postgres/seed/generate.py
$ErrorActionPreference = "Stop"

function Exec-Sql($sql) {
    docker compose exec -T postgres psql -U npp_analyst -d npp -c $sql
    if ($LASTEXITCODE -ne 0) { throw "psql failed: $sql" }
}

Write-Host "== load employees =="
Exec-Sql "COPY employees(id, full_name, department_id, position, hire_date, skill_level, salary_rub) FROM '/seed-data/employees.csv' CSV;"
Write-Host "== load sensor_readings (долго, ~60k) =="
Exec-Sql "COPY sensor_readings(ts, sensor_id, value, quality) FROM '/seed-data/sensor_readings.csv' CSV;"
Write-Host "== load power_generation =="
Exec-Sql "COPY power_generation(ts, unit_id, power_mw, plan_mw) FROM '/seed-data/power_generation.csv' CSV;"
Write-Host "== load alarms =="
Exec-Sql "COPY alarms(id, ts, sensor_id, unit_id, severity, message, acknowledged_by, resolved_at) FROM '/seed-data/alarms.csv' CSV NULL AS '\N';"
Write-Host "== load maintenance =="
Exec-Sql "COPY maintenance(work_id, unit_id, system_id, title, work_type, start_date, end_date, cost_rub, contractor) FROM '/seed-data/maintenance.csv' CSV;"
Write-Host "== load shift_schedule =="
Exec-Sql "COPY shift_schedule(id, employee_id, shift_id, work_date) FROM '/seed-data/shift_schedule.csv' CSV;"
Write-Host "== load dosimetry =="
Exec-Sql "COPY dosimetry(id, employee_id, measure_date, dose_msv) FROM '/seed-data/dosimetry.csv' CSV;"
Write-Host "== fix sequences =="
Exec-Sql "SELECT setval('employees_id_seq',(SELECT MAX(id) FROM employees)); SELECT setval('alarms_id_seq',(SELECT MAX(id) FROM alarms)); SELECT setval('maintenance_work_id_seq',(SELECT MAX(work_id) FROM maintenance)); SELECT setval('shift_schedule_id_seq',(SELECT MAX(id) FROM shift_schedule)); SELECT setval('dosimetry_id_seq',(SELECT MAX(id) FROM dosimetry));"
Write-Host "== counts =="
Exec-Sql "SELECT 'employees' t, COUNT(*) FROM employees UNION ALL SELECT 'sensor_readings', COUNT(*) FROM sensor_readings UNION ALL SELECT 'power_generation', COUNT(*) FROM power_generation UNION ALL SELECT 'alarms', COUNT(*) FROM alarms UNION ALL SELECT 'maintenance', COUNT(*) FROM maintenance UNION ALL SELECT 'shift_schedule', COUNT(*) FROM shift_schedule UNION ALL SELECT 'dosimetry', COUNT(*) FROM dosimetry ORDER BY 1;"
Write-Host "DONE. Дальше: tasks/tasks.md"
