import os
from pathlib import Path
from dotenv import load_dotenv
from datetime import timedelta

BASE_DIR = Path(__file__).resolve().parent.parent

# --- Load .env file if it exists ---
env_path = BASE_DIR / ".env"
if env_path.exists():
    load_dotenv(env_path)

SECRET_KEY = os.environ.get("SECRET_KEY", "django-insecure-CHANGE-ME-IN-PRODUCTION")
DEBUG = os.environ.get("DEBUG", "True") == "True"
ENABLE_FIELD_FILTER_PAGINATION = os.environ.get("ENABLE_FIELD_FILTER_PAGINATION", "False")
ALLOWED_HOSTS_str = os.environ.get("ALLOWED_HOSTS", "localhost,127.0.0.1")
ALLOWED_HOSTS = ALLOWED_HOSTS_str.split(",")

# --- Application Definitions ---
DJANGO_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
]

THIRD_PARTY_APPS = [
    "rest_framework",
    "rest_framework_simplejwt",
    "rest_framework_simplejwt.token_blacklist",
    "corsheaders",
    "storages",
    "django_filters",
    "drf_yasg"
]

LOCAL_APPS = [
    "accounts.apps.AccountsConfig",
    "authentication.apps.AuthenticationConfig",
    "billing.apps.BillingConfig",
    "common",
    "panel.apps.PanelConfig",
    "dashboard.apps.DashboardConfig",
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

# --- Middleware ---
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

# --- URLs and WSGI ---
ROOT_URLCONF = "config.urls"

# --- Templates ---
TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / 'templates'],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]
WSGI_APPLICATION = "config.wsgi.application"

# --- Custom User Model ---
AUTH_USER_MODEL = "accounts.User"

# --- Database Configuration ---
USE_SQLITE = os.environ.get("USE_SQLITE", "False") == "True"

if USE_SQLITE:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": os.environ.get('DB_NAME', 'base_project_db'),
            "USER": os.environ.get("DB_USER", 'base_project_user'),
            "PASSWORD": os.environ.get("DB_PASSWORD", 'strong_password_123'),
            "HOST": os.environ.get("DB_HOST", 'localhost'),
            "PORT": os.environ.get("DB_PORT", '5432'),
        }
    }

# --- Password Validation ---
AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

# --- Internationalization ---
LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

# --- CORS (Cross-Origin Resource Sharing) ---
CORS_ALLOWED_ORIGINS_str = os.environ.get("ALLOWED_CORS", "http://localhost:3000")
CORS_ALLOWED_ORIGINS = CORS_ALLOWED_ORIGINS_str.split(",")
CSRF_TRUSTED_ORIGINS_str = os.environ.get("CSRF_TRUSTED_ORIGINS", "http://localhost")
CSRF_TRUSTED_ORIGINS = CSRF_TRUSTED_ORIGINS_str.split(",")

# --- Static and Media Files (with MinIO/S3) ---
STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "mediafiles"

# MinIO (S3) Storage Settings
USE_MINIO = os.environ.get("USE_MINIO", "False") == "True"

if USE_MINIO:
    AWS_ACCESS_KEY_ID = os.environ.get("AWS_ACCESS_KEY_ID")
    AWS_SECRET_ACCESS_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY")
    AWS_STORAGE_BUCKET_NAME = os.environ.get("AWS_STORAGE_BUCKET_NAME")
    AWS_S3_ENDPOINT_URL = os.environ.get("AWS_S3_ENDPOINT_URL")
    AWS_S3_CUSTOM_DOMAIN = os.environ.get("AWS_S3_CUSTOM_DOMAIN")
    AWS_S3_OBJECT_PARAMETERS = {"CacheControl": "max-age=86400"}
    AWS_S3_FILE_OVERWRITE = False
    AWS_DEFAULT_ACL = 'public-read'
    AWS_QUERYSTRING_AUTH = False 
    AWS_S3_SIGNATURE_VERSION = 's3v4'
    AWS_S3_ADDRESSING_STYLE = 'path'
    AWS_S3_REGION_NAME = 'us-east-1'

    STORAGES = {
        "default": {
            "BACKEND": "storages.backends.s3boto3.S3Boto3Storage",
        },
        "staticfiles": {
            "BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage",
        },
    }
    
    # Construct the media URL from the custom domain
    protocol = os.environ.get('AWS_S3_URL_PROTOCOL', 'http:')
    if AWS_S3_CUSTOM_DOMAIN:
        MEDIA_URL = f"{protocol}//{AWS_S3_CUSTOM_DOMAIN}/"
    else:
        MEDIA_URL = f"{AWS_S3_ENDPOINT_URL}/{AWS_STORAGE_BUCKET_NAME}/"

# --- Default Primary Key Type ---
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# --- Django REST Framework (DRF) & JWT Settings ---
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework.authentication.SessionAuthentication",
        "rest_framework.authentication.BasicAuthentication",
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
    "DEFAULT_RENDERER_CLASSES": (
        "config.renderers.ApiRenderer",
        "rest_framework.renderers.BrowsableAPIRenderer",
    ),
    'DEFAULT_FILTER_BACKENDS': (
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ),
    "DEFAULT_PAGINATION_CLASS": "config.pagination.DefaultPagination",
    "PAGE_SIZE": 10,
}

# --- SimpleJWT Settings ---
SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=int(os.environ.get("JWT_ACCESS_LIFETIME_MINUTES", "60"))),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=int(os.environ.get("JWT_REFRESH_LIFETIME_DAYS", "7"))),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
}

# --- Payment Settings ---
NOWPAYMENTS_API_KEY = os.environ.get("NOWPAYMENTS_API_KEY")
NOWPAYMENTS_SANDBOX_API_KEY = os.environ.get("NOWPAYMENTS_SANDBOX_API_KEY")

ZARINPAL_MERCHANT_ID = os.environ.get("ZARINPAL_MERCHANT_ID")
CALLBACK_URL = os.environ.get("CALLBACK_URL", "https://example.com/payment/verify/")
CANCEL_URL = os.environ.get("CANCEL_URL", "https://example.com/payment/cancel/")

# --- Logging ---
LOGS_DIR = BASE_DIR / "logs"
LOGS_DIR.mkdir(parents=True, exist_ok=True)
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    
    "formatters": {
        "verbose": {
            "format": "{levelname} {asctime} [{module}:{lineno}] {message}",
            "style": "{",
        },
        "simple": {
            "format": "{levelname} {message}",
            "style": "{",
        },
    },
    
    "handlers": {
        "info_file": {
            "level": "INFO",
            "class": "logging.handlers.RotatingFileHandler",
            "filename": LOGS_DIR / "info.log",
            "maxBytes": 1024 * 1024 * 10,
            "backupCount": 5,
            "formatter": "verbose",
            "encoding": "utf-8",
        },
        "warning_file": {
            "level": "WARNING",
            "class": "logging.handlers.RotatingFileHandler",
            "filename": LOGS_DIR / "warning.log",
            "maxBytes": 1024 * 1024 * 10,
            "backupCount": 5,
            "formatter": "verbose",
            "encoding": "utf-8",
        },
        "error_file": {
            "level": "ERROR",
            "class": "logging.handlers.RotatingFileHandler",
            "filename": LOGS_DIR / "error.log",
            "maxBytes": 1024 * 1024 * 10,
            "backupCount": 5,
            "formatter": "verbose",
            "encoding": "utf-8",
        },
        "console": {
            "level": "DEBUG",
            "class": "logging.StreamHandler",
            "formatter": "simple",
        },
    },
    
    "loggers": {
        "django": {
            "handlers": ["console", "info_file", "warning_file", "error_file"],
            "level": "INFO",
            "propagate": True,
        },
        "django.request": {
            "handlers": ["error_file", "console"],
            "level": "ERROR",
            "propagate": False,
        },
    },
}