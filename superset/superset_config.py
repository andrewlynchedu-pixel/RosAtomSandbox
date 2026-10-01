# Superset config для учебного стенда АЭС
import os

SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY", "CHANGE_ME_super_secret_key_12345")
SQLALCHEMY_DATABASE_URI = "sqlite:////app/superset_home/superset.db"

# Русский язык по умолчанию (если доступен в образе)
BABEL_DEFAULT_LOCALE = "ru"
LANGUAGES = {
    "en": {"flag": "us", "name": "English"},
    "ru": {"flag": "ru", "name": "Russian"},
}

# Позволяет подключать Postgres по internal hostname `postgres`
PREVENT_UNSAFE_DB_CONNECTIONS = False

# Убираем CSRF-проблемы при локальной работе
WTF_CSRF_ENABLED = True
WTF_CSRF_TIME_LIMIT = None

FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
}

ROW_LIMIT = 10000
