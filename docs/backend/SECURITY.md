# Backend Security Guide

Comprehensive guide to security practices and features in the OpenOn backend.

## 🔐 Security Overview

The backend implements multiple layers of security to protect user data and prevent common vulnerabilities.

## 🛡️ Security Layers

### 1. Authentication

#### JWT Tokens

- **Access Tokens**: Short-lived (30 minutes default)
- **Refresh Tokens**: Long-lived (7 days default)
- **Algorithm**: HS256 (HMAC SHA-256)
- **Token Storage**: Client-side (not stored in database)

#### Password Security

- **Hashing**: BCrypt with automatic salt generation
- **Password Limits**: 8-128 characters
- **No Plain Text**: Passwords never stored in plain text
- **Truncation**: Passwords > 72 bytes are truncated (BCrypt limit)

```python
# Password hashing
hashed = get_password_hash(password)

# Password verification
is_valid = verify_password(plain_password, hashed_password)
```

### 2. Authorization

#### Owner-Based Access Control

- Users can only access their own resources
- Ownership verified for all operations
- State-based permissions for capsules

#### Permission Checks

```python
# Example: Verify ownership
if capsule.sender_id != current_user.id:
    raise HTTPException(status_code=403, detail="Access denied")
```

### 3. Input Validation

#### Pydantic Schemas

All requests validated using Pydantic v2:

```python
class UserCreate(BaseModel):
    email: EmailStr
    username: str = Field(min_length=3, max_length=100)
    password: str = Field(min_length=8, max_length=128)
    first_name: str = Field(min_length=1, max_length=100)
    last_name: str = Field(min_length=1, max_length=100)
```

#### Custom Validators

```python
@field_validator("scheduled_unlock_at")
@classmethod
def validate_unlock_time(cls, v: datetime) -> datetime:
    """Validate unlock time is in the future."""
    # Validation logic
    ...
```

### 4. Input Sanitization

#### Text Sanitization

All user inputs are sanitized:

```python
def sanitize_text(text: str, max_length: Optional[int] = None) -> str:
    """Sanitize text input by removing harmful characters."""
    if not isinstance(text, str):
        text = str(text)
    
    # Remove null bytes and control characters
    text = text.replace('\x00', '').replace('\r', '')
    
    # Strip leading/trailing whitespace
    text = text.strip()
    
    # Truncate if needed
    if max_length and len(text) > max_length:
        text = text[:max_length]
    
    return text
```

#### Sanitization Applied To

- Email addresses
- Usernames
- Names (first, last, full)
- Capsule titles
- Capsule content
- Search queries
- Theme names

### 5. SQL Injection Prevention

#### SQLAlchemy ORM

- **Parameterized Queries**: All queries use parameters
- **No String Concatenation**: Never build queries with string concatenation
- **Type Safety**: SQLAlchemy handles type conversion

```python
# ✅ Safe
query = select(User).where(User.email == email)

# ❌ Never do this
query = f"SELECT * FROM users WHERE email = '{email}'"
```

### 6. CORS Configuration

#### Allowed Origins

```python
cors_origins: list[str] = ["http://localhost:3000", "http://localhost:8000"]
```

- Configured via environment variables
- Only specified origins allowed
- Prevents unauthorized cross-origin requests

### 7. Error Message Security

#### No Information Leakage

Error messages don't expose:
- Database structure
- Internal implementation details
- User IDs or sensitive data
- Stack traces (in production)

```python
# ✅ Good
raise HTTPException(status_code=400, detail="Invalid credentials")

# ❌ Bad
raise HTTPException(status_code=400, detail=f"User {user_id} with password {password} failed")
```

## 🔒 Security Best Practices

### 1. Secret Key Management

#### Development

```env
SECRET_KEY=CHANGE_THIS_IN_PRODUCTION_USE_RANDOM_SECRET_KEY_HERE
```

#### Production

```bash
# Generate strong secret key
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

```env
SECRET_KEY=<generated-strong-key>
```

### 2. Password Requirements

- **Minimum Length**: 8 characters
- **Maximum Length**: 128 characters
- **No Complexity Requirements**: (can be added)
- **BCrypt Hashing**: Automatic salt generation

### 3. Token Security

- **Short Expiration**: Access tokens expire quickly
- **Refresh Tokens**: Separate long-lived tokens
- **Token Type Verification**: Ensures correct token type
- **No Token Storage**: Tokens not stored server-side

### 4. Database Security

#### Connection Security

- **Parameterized Queries**: SQLAlchemy ORM
- **Connection Pooling**: Efficient connection management
- **No Raw SQL**: All queries through ORM

#### Data Protection

- **Hashed Passwords**: Never stored in plain text
- **Sensitive Data**: Encrypted at rest (database level)
- **Backup Security**: Encrypted backups

### 5. API Security

#### Rate Limiting

- **Implementation**: `RateLimitingMiddleware` with sliding window algorithm
- **Default**: 60 requests per minute per IP
- **Configurable**: Via `RATE_LIMIT_PER_MINUTE` environment variable
- **Prevents**: Brute force attacks, DoS
- **Location**: `app/middleware/rate_limiting.py`
- **Note**: Uses in-memory storage. For multi-server deployments, consider Redis-based rate limiting.

#### Request Validation

- **Pydantic**: Automatic validation
- **Type Checking**: Type hints enforced
- **Length Limits**: All fields have max lengths

#### HTTPS

- **Production**: Always use HTTPS
- **TLS**: Encrypt all traffic
- **Certificate**: Valid SSL certificate

## 🚨 Common Vulnerabilities Prevented

### 1. SQL Injection

**Prevention**: SQLAlchemy ORM with parameterized queries

```python
# ✅ Safe
user = await session.execute(
    select(User).where(User.email == email)
)

# ❌ Vulnerable (never do this)
user = await session.execute(
    f"SELECT * FROM users WHERE email = '{email}'"
)
```

### 2. XSS (Cross-Site Scripting)

**Prevention**: Input sanitization, output encoding

- All inputs sanitized
- Special characters removed
- Length limits enforced

### 3. CSRF (Cross-Site Request Forgery)

**Prevention**: CORS configuration, token-based auth

- CORS restricts origins
- JWT tokens required
- Same-origin policy

### 4. Authentication Bypass

**Prevention**: Strong password hashing, token verification

- BCrypt password hashing
- JWT signature verification
- Token expiration

### 5. Information Disclosure

**Prevention**: Generic error messages, no stack traces

- Generic error messages
- No internal details exposed
- Production mode hides stack traces

### 6. Insecure Direct Object References

**Prevention**: Owner verification, state checks

```python
# Verify ownership
if capsule.sender_id != current_user.id:
    raise HTTPException(status_code=403, detail="Access denied")
```

## 🔍 Security Checklist

### Development

- [ ] Use strong secret key
- [ ] Enable debug mode only in development
- [ ] Use Supabase for development (local PostgreSQL)
- [ ] Test authentication flows
- [ ] Verify input validation

### Production

- [ ] Change default secret key
- [ ] Disable debug mode
- [ ] Use PostgreSQL
- [ ] Enable HTTPS
- [ ] Configure CORS properly
- [ ] Set up rate limiting
- [ ] Enable logging
- [ ] Regular security updates
- [ ] Database backups encrypted
- [ ] Monitor for suspicious activity

## 📊 Security Features Summary

| Feature | Implementation | Status |
|---------|---------------|--------|
| Password Hashing | BCrypt | ✅ |
| JWT Authentication | HS256 | ✅ |
| Input Validation | Pydantic | ✅ |
| Input Sanitization | Custom helpers | ✅ |
| SQL Injection Prevention | SQLAlchemy ORM | ✅ |
| CORS | FastAPI CORS | ✅ |
| Rate Limiting | Middleware (60 req/min) | ✅ |
| Request Logging | Middleware | ✅ |
| Error Message Security | Generic messages | ✅ |
| Owner Verification | Custom checks | ✅ |
| HTTPS | Production requirement | ⚠️ |

## 🛠️ Security Tools

### Password Generation

```python
import secrets

# Generate secure password
password = secrets.token_urlsafe(16)
```

### Secret Key Generation

```python
import secrets

# Generate secret key
secret_key = secrets.token_urlsafe(32)
```

### Token Verification

```python
from app.core.security import decode_token, verify_token_type

# Verify token
try:
    payload = decode_token(token)
    if verify_token_type(payload, "access"):
        user_id = payload.get("sub")
except ValueError:
    # Invalid token
    ...
```

## 📚 Related Documentation

- [CONFIGURATION.md](./CONFIGURATION.md) - Security configuration
- [API_REFERENCE.md](./API_REFERENCE.md) - API authentication
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Security architecture

---

**Last Updated**: 2025

