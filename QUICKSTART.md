# QUICKSTART — инструкция для человека, который скопировал этот репозиторий

Тебе досталась папка `RosAtomSandbox` — учебный стенд аналитика данных АЭС.
Иди строго по шагам ниже, всё займёт ~15 минут (плюс скачивание образов Docker).

## Шаг 0. Что нужно заранее (ставится один раз)

| Программа | Зачем | Где скачать |
|---|---|---|
| Docker Desktop (Windows, включает WSL2) | запускает Postgres, Jupyter, CloudBeaver, Superset | https://www.docker.com/products/docker-desktop/ , инструкция: https://docs.docker.com/desktop/setup/install/windows-install/ |
| Git | забрать репо / обновляться | https://git-scm.com/download/win |
| Python 3.12+ | один раз сгенерировать данные (~88k строк) | https://www.python.org/downloads/ (при установке поставь галочку Add to PATH) |

Требования: Windows 10/11 64-bit, 8+ ГБ RAM, ~10 ГБ места.
После установки Docker Desktop: запусти его, дождись статуса **Running** (кит в трее зелёный).

Проверка в PowerShell:
```powershell
docker --version
docker compose version
python --version
git --version
```
Все 4 команды должны ответить версиями без ошибок.

## Шаг 1. Забрать репозиторий

Вариант А — склонировать (если дали ссылку):
```powershell
git clone <ссылка-от-автора> RosAtomSandbox
cd RosAtomSandbox
```

Вариант Б — скопировать папку (zip / флешка / общая папка):
просто открой её в терминале:
```powershell
cd C:\путь\к\RosAtomSandbox
```

## Шаг 2. Создать свои пароли (.env)

Файл `.env` в репо **не лежит** специально (он у каждого свой и в git не едет).
Создай его из шаблона:
```powershell
copy .env.example .env
```

Что внутри и что делать:

| Переменная | Значение по умолчанию | Надо ли менять / создавать? |
|---|---|---|
| `POSTGRES_USER / PASSWORD / DB` | `npp_analyst / npp_password_123 / npp` | менять не надо, это учебные |
| `POSTGRES_PORT` | `5432` | меняй только если порт занят (например `5433`) |
| `JUPYTER_PORT / TOKEN` | `8888 / npp-learning` | токен — это твой пароль от Jupyter, менять не надо |
| `CLOUDBEAVER_PORT` | `8978` | менять только если занят |
| `SUPERSET_PORT / ADMIN / PASSWORD` | `8088 / admin / admin123` | это логин в Superset, менять не надо |
| `SUPERSET_SECRET_KEY` | `CHANGE_ME...` | для учёбы можно не трогать |

Ничего руками придумывать не нужно, кроме **одного места**:
- При первом входе в **CloudBeaver** (веб-DBeaver, http://localhost:8978) он попросит **придумать локального админа** (логин+пароль) — придумай любые, это только у тебя в браузере. Затем создай подключение: Host=`postgres`, Port=`5432`, Database=`npp`, User/Password из `.env`.

## Шаг 3. Сгенерировать данные

Нужен только Python, ставится один раз (см. Шаг 0). CSV в git не лежат — каждый генерирует сам:
```powershell
python postgres/seed/generate.py
```
Увидишь примерно:
```
employees: 80
sensor_readings: 61320
power_generation: 8760
alarms: 1543
...
TOTAL fact+dict rows: 88252
```
Если ошибка `python не найден` — поставь Python с python.org и перезапусти терминал.

## Шаг 4. Запустить контейнеры

**Вариант 1 — всё разом (если 8+ ГБ RAM):**
```powershell
docker compose up -d --build
```

**Вариант 2 — без Superset (если мало RAM или Superset не нужен):**
```powershell
docker compose up -d postgres cloudbeaver jupyter
```
Superset самый тяжёлый, без него всё остальное работает. Добрать его позже:
```powershell
docker compose up -d superset
```

Проверка:
```powershell
docker compose ps
docker compose logs -f postgres   # выход: Ctrl+C
```
Первый старт Superset долгий (2–5 мин) — это нормально.

Остановка:
```powershell
docker compose down        # стоп, данные сохранятся
docker compose down -v     # СТОП + УДАЛИТЬ БАЗУ (потом заново Шаги 3-5)
```

## Шаг 5. Загрузить данные в Postgres (один раз)

Схема (таблицы, блоки, датчики) создалась сама при первом старте.
Факты (замеры, тревоги...) загрузи скриптом:
```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/load-data.ps1
```
На Linux/mac: `bash ./scripts/load-data.sh`

Проверка что всё встало:
```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/check.ps1
```
Эталон: запрос про температуру должен вернуть 3 строки — `2025-03-10, 03-11, 03-12` (перегрев).

## Шаг 6. Куда заходить (пароли)

| Сервис | Адрес | Логин |
|---|---|---|
| Jupyter Lab | http://localhost:8888 | токен из `.env` (`npp-learning`) — вводит в поле Token |
| CloudBeaver (веб-DBeaver) | http://localhost:8978 | админа придумай сам (Шаг 2), подключение: Host `postgres`, `npp / npp_analyst / npp_password_123` |
| Superset | http://localhost:8088 | `admin / admin123` (из `.env`) |
| Postgres напрямую | `localhost:5432` | база `npp`, `npp_analyst / npp_password_123` |

Строка подключения для DBeaver Desktop / Python:
```
postgresql://npp_analyst:npp_password_123@localhost:5432/npp
```
А **изнутри** контейнеров (код в Jupyter, добавление базы в Superset) хост другой:
```
postgresql://npp_analyst:npp_password_123@postgres:5432/npp
```
Правило: в браузере/программах на твоём ПК — `localhost`, внутри Docker (Superset, Jupyter) — `postgres`.

## Шаг 7. Как работать с задачами

1. Открой `tasks/tasks.md` — там 24 задания, иди по порядку:
   - `ОЛ` очень лёгкие (SELECT/WHERE) → `Л` лёгкие (GROUP BY/JOIN) → `С` средние (HAVING, pandas, графики) → `Т` сложненькие (окна, эпизоды).
2. SQL пиши в CloudBeaver (http://localhost:8978) или в ноутбуке `jupyter/work/01-sql-starter.ipynb`.
3. pandas/графики — ноутбуки `02-pandas.ipynb`, `03-viz.ipynb`.
4. Дашборд Superset — инструкция `superset/README.md` (задание Т-5).
5. Решения лежат в `tasks/solutions/` — сначала реши сам, потом сверь.
6. Застрял — спроси автора, приложив свой запрос и текст ошибки.

## Частые проблемы

- **Порт занят** (`port is already allocated`) — поменяй порт в `.env` (например `JUPYTER_PORT=8889`) и снова `docker compose up -d`.
- **Superset не открывается** — подожди 3–5 мин, смотри `docker compose logs -f superset`.
- **CloudBeaver: could not translate host name** — в поле Host пиши `postgres`, а не `localhost` (ты внутри docker-сети).
- **Jupyter просит token/password** — введи `npp-learning` (или свой `JUPYTER_TOKEN` из `.env`).
- **Хочу начать с нуля** — `docker compose down -v`, затем Шаги 3–5 заново.
- **OneDrive ругается на файлы** — CSV и база в git не едут и из OneDrive их лучше исключить; для базы используются именованные volumes, это ок.
