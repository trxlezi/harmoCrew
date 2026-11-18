import os


def load_local_env():
    env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env")
    if not os.path.exists(env_path):
        return

    with open(env_path, "r", encoding="utf-8") as env_file:
        for raw_line in env_file:
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue

            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = value


def get_env(name, default=None):
    value = os.getenv(name)
    if value is None or value == "":
        return default
    return value


load_local_env()

MYSQL_HOST = get_env("MYSQL_HOST", "localhost")
MYSQL_PORT = int(get_env("MYSQL_PORT", "3306"))
MYSQL_USER = get_env("MYSQL_USER", "root")
MYSQL_PASSWORD = get_env("MYSQL_PASSWORD", "")
MYSQL_DATABASE = get_env("MYSQL_DATABASE", "harmocrew")
HARMOCREW_SECRET_KEY = get_env(
    "HARMOCREW_SECRET_KEY",
    "change-me-before-production",
)
