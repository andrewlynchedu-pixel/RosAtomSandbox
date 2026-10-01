# Проверка стенда: counts + контрольный запрос С-1 (должен вернуть 10-12 марта 2025).
# Запуск: powershell -ExecutionPolicy Bypass -File ./scripts/check.ps1
$ErrorActionPreference = "Stop"
docker compose exec -T postgres psql -U npp_analyst -d npp -c "SELECT 'sensor_readings' t, COUNT(*) FROM sensor_readings UNION ALL SELECT 'power_generation', COUNT(*) FROM power_generation UNION ALL SELECT 'alarms', COUNT(*) FROM alarms UNION ALL SELECT 'employees', COUNT(*) FROM employees ORDER BY 1;"
docker compose exec -T postgres psql -U npp_analyst -d npp -c "SELECT date_trunc('day', r.ts)::date AS day, AVG(r.value)::numeric(10,2) FROM sensor_readings r WHERE r.sensor_id IN (1,2) AND r.quality=1 GROUP BY 1 HAVING AVG(r.value) > 315 ORDER BY 1;"
Write-Host "OK: vyshe dolzhno byt 3 stroki (2025-03-10..12) - znachit dannye korrektny."
