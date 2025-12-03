# Backend Configuration Guide

Complete guide to configuring the OpenOn backend application.

## 📋 Configuration Overview

The backend uses environment variables for configuration, loaded via Pydantic Settings. All configuration is centralized in `app/core/config.py`.

## 🔧 Environment Variables

### Application Settings

```env
# Application
APP_NAME=OpenOn API
APP_VERSION=1.0.0
DEBUG=false
```

- **APP_NAME**: Application name (default: "OpenOn API")
- **APP_VERSION**: Application version (default: "1.0.0")
- **DEBUG**: Enable debug mode (default: false)

### Database Configuration

```env
# Database
DATABASE_URL=sqlite+aiosqlite:///./openon.db
DB_ECHO=false
```

- **DATABASE_URL**: Database connection string
  - SQLite (default): `sqlite+aiosqlite:///./openon.db`
  - PostgreSQL: `postgresql+asyncpg://user:password@localhost/openon`
- **DB_ECHO**: Echo SQL queries to console (default: false)

### Security Settings

```env
# Security
SECRET_KEY=your-super-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
```

- **SECRET_KEY**: JWT secret key (**CHANGE IN PRODUCTION!**)
- **ALGORITHM**: JWT algorithm (default: "HS256")
- **ACCESS_TOKEN_EXPIRE_MINUTES**: Access token expiration (default: 30)
- **REFRESH_TOKEN_EXPIRE_DAYS**: Refresh token expiration (default: 7)

### CORS Configuration

```env
# CORS
CORS_ORIGINS=["http://localhost:3000","http://localhost:8000"]
```

- **CORS_ORIGINS**: Allowed origins for CORS (JSON array)

### Rate Limiting

```env
# Rate Limiting
RATE_LIMIT_PER_MINUTE=60
```

- **RATE_LIMIT_PER_MINUTE**: Requests per minute per IP (default: 60)

### Capsule Constraints

```env
# Capsule Settings
MIN_UNLOCK_MINUTES=1
MAX_UNLOCK_YEARS=5
EARLY_VIEW_THRESHOLD_DAYS=3
```

- **MIN_UNLOCK_MINUTES**: Minimum unlock time in minutes (default: 1)
- **MAX_UNLOCK_YEARS**: Maximum unlock time in years (default: 5)
- **EARLY_VIEW_THRESHOLD_DAYS**: Days before unlock for early view (default: 3)

### Pagination Defaults

```env
# Pagination (configured in code, not env)
# default_page_size: 20
# max_page_size: 100
# min_page_size: 1
```

These are configured in `app/core/config.py` and can be overridden via environment variables.

### Search Constraints

```env
# Search (configured in code, not env)
# min_search_query_length: 2
# max_search_query_length: 100
# default_search_limit: 10
# max_search_limit: 50
```

### Username Constraints

```env
# Username (configured in code, not env)
# min_username_length: 3
# max_username_length: 100
```

### Name Constraints

```env
# Name (configured in code, not env)
# min_name_length: 1
# max_name_length: 100
# max_full_name_length: 255
```

### Content Constraints

```env
# Content (configured in code, not env)
# min_content_length: 1
# max_content_length: 10000
# max_title_length: 255
# max_theme_length: 50
```

### Background Worker

```env
# Background Worker
WORKER_CHECK_INTERVAL_SECONDS=60
```

- **WORKER_CHECK_INTERVAL_SECONDS**: Interval for checking unlock times (default: 60)

### Notifications (Optional)

```env
# Notifications
FCM_API_KEY=your-fcm-api-key
APNS_KEY_PATH=/path/to/apns/key.pem
EMAIL_SMTP_HOST=smtp.gmail.com
EMAIL_SMTP_PORT=587
```

- **FCM_API_KEY**: Firebase Cloud Messaging API key
- **APNS_KEY_PATH**: Apple Push Notification Service key path
- **EMAIL_SMTP_HOST**: SMTP server host
- **EMAIL_SMTP_PORT**: SMTP server port

## 📝 Configuration File Structure

### `.env` File Example

```env
# Application
DEBUG=true
APP_NAME=OpenOn API
APP_VERSION=1.0.0

# Database
DATABASE_URL=sqlite+aiosqlite:///./openon.db
DB_ECHO=false

# Security (CHANGE IN PRODUCTION!)
SECRET_KEY=CHANGE_THIS_IN_PRODUCTION_USE_RANDOM_SECRET_KEY_HERE
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS
CORS_ORIGINS=["http://localhost:3000","http://localhost:8000"]

# Rate Limiting
RATE_LIMIT_PER_MINUTE=60

# Capsule Settings
MIN_UNLOCK_MINUTES=1
MAX_UNLOCK_YEARS=5
EARLY_VIEW_THRESHOLD_DAYS=3

# Background Worker
WORKER_CHECK_INTERVAL_SECONDS=60
```

## 🔐 Production Configuration

### Security Checklist

1. **Change SECRET_KEY**: Generate a strong random key
   ```bash
   python -c "import secrets; print(secrets.token_urlsafe(32))"
   ```

2. **Set DEBUG=false**: Disable debug mode

3. **Use PostgreSQL**: Switch from SQLite to PostgreSQL
   ```env
   DATABASE_URL=postgresql+asyncpg://user:password@localhost/openon
   ```

4. **Configure CORS**: Set allowed origins
   ```env
   CORS_ORIGINS=["https://yourdomain.com"]
   ```

5. **Set Rate Limits**: Adjust based on expected load
   ```env
   RATE_LIMIT_PER_MINUTE=100
   ```

### Environment-Specific Configuration

#### Development

```env
DEBUG=true
DATABASE_URL=sqlite+aiosqlite:///./openon.db
CORS_ORIGINS=["http://localhost:3000","http://localhost:8000"]
```

#### Staging

```env
DEBUG=false
DATABASE_URL=postgresql+asyncpg://user:password@staging-db/openon
CORS_ORIGINS=["https://staging.yourdomain.com"]
```

#### Production

```env
DEBUG=false
DATABASE_URL=postgresql+asyncpg://user:password@prod-db/openon
CORS_ORIGINS=["https://yourdomain.com"]
SECRET_KEY=<strong-random-key>
```

## 🔄 Configuration Loading

### Loading Order

1. Default values in `Settings` class
2. Environment variables
3. `.env` file (if present)

### Accessing Configuration

```python
from app.core.config import settings

# Use settings
max_length = settings.max_username_length
database_url = settings.database_url
```

## 📊 Configuration Constants Reference

### All Available Constants

| Constant | Default | Description |
|----------|---------|-------------|
| `default_page_size` | 20 | Default pagination page size |
| `max_page_size` | 100 | Maximum page size |
| `min_page_size` | 1 | Minimum page size |
| `min_search_query_length` | 2 | Minimum search query length |
| `max_search_query_length` | 100 | Maximum search query length |
| `default_search_limit` | 10 | Default search results limit |
| `max_search_limit` | 50 | Maximum search results |
| `min_username_length` | 3 | Minimum username length |
| `max_username_length` | 100 | Maximum username length |
| `min_name_length` | 1 | Minimum name length |
| `max_name_length` | 100 | Maximum name length |
| `max_full_name_length` | 255 | Maximum full name length |
| `min_content_length` | 1 | Minimum content length |
| `max_content_length` | 10000 | Maximum content length |
| `max_title_length` | 255 | Maximum title length |
| `max_theme_length` | 50 | Maximum theme length |

## 🛠️ Configuration Validation

### Automatic Validation

Pydantic automatically validates:
- Type checking
- Required fields
- Field constraints (min/max length, etc.)

### Custom Validators

```python
@field_validator("secret_key")
@classmethod
def validate_secret_key(cls, v: str) -> str:
    """Ensure secret key is changed in production."""
    if v == "CHANGE_THIS_IN_PRODUCTION_USE_RANDOM_SECRET_KEY_HERE":
        import warnings
        warnings.warn("Using default secret key! Change this in production!")
    return v
```

## 🔍 Troubleshooting

### Configuration Not Loading

1. Check `.env` file exists in `backend/` directory
2. Verify environment variable names match exactly
3. Check for typos in variable names
4. Restart the server after changing `.env`

### Default Values Not Working

1. Check `app/core/config.py` for default values
2. Verify no environment variables override defaults
3. Check `.env` file for conflicting values

### Database Connection Issues

1. Verify `DATABASE_URL` format
2. Check database server is running
3. Verify credentials are correct
4. Check network connectivity

## 📚 Related Documentation

- [GETTING_STARTED.md](./GETTING_STARTED.md) - Setup guide
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture
- [SECURITY.md](./SECURITY.md) - Security practices

---

**Last Updated**: 2025

