# Superset — подключение учебной базы АЭС

Superset уже поднимается через `docker compose up -d`:
- URL: http://localhost:8088
- Логин/пароль: из `.env` (`SUPERSET_ADMIN` / `SUPERSET_PASSWORD`, по умолчанию `admin / admin123`)
- Первый старт долгий (2-5 мин): `db upgrade + create-admin + init`.

## 1. Добавить Database

1. Открой **Settings → Database Connections → + Database**.
2. Выбери **PostgreSQL**.
3. Host: `postgres` (имя сервиса в docker-сети!), Port: `5432`.
4. Database: `npp`, Username: `npp_analyst`, Password: `npp_password_123` (или свои из `.env`).
5. **SQLAlchemy URI** целиком выглядит так:
   ```
   postgresql://npp_analyst:npp_password_123@postgres:5432/npp
   ```
6. Test Connection → Connect.

> Ошибка "could not translate host name postgres"? Значит добавляешь базу из браузера
> вне Docker — тогда Host = `localhost`. Внутри Superset-контейнера всегда `postgres`.

## 2. Что построить (соответствует заданиям С-3 и С-5)

Dataset 1: `power_generation`
- Chart A (Line): X=`ts` (Time Grain: Day), Metric=`AVG(power_mw)` + второй слой `AVG(plan_mw)`.
- Видно: ППР в июле (0), просадка в марте и октябре.

Dataset 2: `alarms`
- Chart B (Bar, Stacked): X=`month(ts)`, Group by=`severity`, Metric=`COUNT(*)`.
- Видно: всплеск critical в марте, warning в августе.

Dashboard "АЭС-2025":
- Добавь Chart A + Chart B + Markdown с выводом: "КИУМ июля = 0% из-за ППР".

## 3. Лёгкий режим (если мало RAM)

Superset самый прожорливый. Можно работать без него:
```
docker compose up -d postgres cloudbeaver jupyter
```
Jupyter-ноутбук `03-viz.ipynb` строит те же графики через matplotlib.

## 4. Сброс пароля админа

```
docker compose exec superset superset fab reset-password --username admin
# или пересоздать:
docker compose exec superset superset fab create-admin --username admin --firstname A --lastname B --email a@b.c --password newpass
```
