# RosAtomSandbox — учебный стенд аналитика данных АЭС

Переход с инженера АЭС в аналитику данных. В репо поднимается всё одной командой:
**PostgreSQL + CloudBeaver (веб-DBeaver) + Jupyter + Superset**, плюс учебная база «почти боевая»
(датчики, блоки, выработка, тревоги, ремонты, сотрудники, смены, дозиметрия) и 24 задания с решениями.

> **Новичок? Скопировал репо и не знаешь с чего начать? → открой [`QUICKSTART.md`](QUICKSTART.md).**
> Там по шагам: что поставить, как скачать Docker, где взять пароли, как запустить
> всё разом или без Superset, как работать с задачами.

## Состав стенда

```
docker-compose.yml      4 сервиса: postgres:16, cloudbeaver:24, jupyter (pandas/matplotlib), superset:4
.env.example            шаблон паролей/портов (свой .env каждый создаёт сам, в git не едет)
QUICKSTART.md           пошаговая инструкция для новичка (старт за ~15 мин)
scripts/                load-data.ps1/.sh (загрузка CSV одной командой), check.ps1 (проверка)
postgres/init/          01-schema.sql (таблицы+VIEW+индексы), 02-seed.sql (блоки/цеха/датчики/смены/календарь)
postgres/seed/          generate.py (генератор 2025 года + аномалии) + load.sql
jupyter/work/           01-sql-starter.ipynb, 02-pandas.ipynb, 03-viz.ipynb
superset/               superset_config.py + README.md (как добавить базу и собрать дашборд)
tasks/tasks.md          24 задания: очень лёгкий → лёгкий → средний → сложненький (SQL в приоритете)
tasks/solutions/        решения по уровням (сначала реши сам!)
```

### Сценарий данных 2025 (чтобы задания имели смысл)
- **Блок-1** ВВЭР-1000: ППР **01.07–30.07** (мощность 0, КИУМ 0), перегрев **10–12.03** (critical), вибрация турбины **05.08**.
- **Блок-2** ВВЭР-1200: стабилен, кратковременная разгрузка **15–16.10**.
- 80 сотрудников (РЦ, ТЦ, ЭЦ, ЦТАИ, ХЦ, ОЯБиН), график 2/2 + дневные 5/2, отпуска в августе.
- Дозиметрия: фон 0.08–0.15 мЗв/мес, у ремонтников всплеск в июле.

## Короткая шпаргалка (подробности — в QUICKSTART)

```powershell
copy .env.example .env
python postgres/seed/generate.py
docker compose up -d --build                                  # всё разом
# или лёгкий режим без Superset:
docker compose up -d postgres cloudbeaver jupyter
powershell -ExecutionPolicy Bypass -File ./scripts/load-data.ps1
```

| Сервис | URL | Логин |
|---|---|---|
| Jupyter Lab | http://localhost:8888 | токен `npp-learning` (из `.env`) |
| CloudBeaver (веб-DBeaver) | http://localhost:8978 | админа придумай сам, подключение `postgres:5432 / npp` |
| Superset | http://localhost:8088 | `admin / admin123` (из `.env`, первый старт 2-5 мин) |
| Postgres | `localhost:5432` | `npp_analyst / npp_password_123`, база `npp` |

## Git: что надо знать

- `.env` и `postgres/seed/data/*.csv` в git **не коммитятся** (см. `.gitignore`) — каждый генерирует их сам.
- Типовой цикл: `git status --short`, `git add ...`, `git commit -m "..."`.
- Remote добавляет автор сам (`git remote add origin <url>`, `git push -u origin main`).

## Учёба

1. Открой `tasks/tasks.md` — иди ОЛ → Л → С → Т.
2. SQL — CloudBeaver или `01-sql-starter.ipynb`; pandas/графики — `02/03-*.ipynb`.
3. Дашборд — `superset/README.md` (задание Т-5). Решения — в `tasks/solutions/`.
