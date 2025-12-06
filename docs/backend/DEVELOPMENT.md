# Backend Development Guide

Complete guide for developing and contributing to the OpenOn backend.

## 🚀 Development Setup

### Prerequisites

- Python 3.11+
- pip or Poetry
- Git
- IDE (VS Code, PyCharm, etc.)

### Initial Setup

```bash
# Clone repository
git clone <repository-url>
cd openon/backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Or with Poetry
poetry install

# Create .env file
cp .env.example .env

# Run development server
uvicorn app.main:app --reload
```

## 📁 Project Structure

See [CODE_STRUCTURE.md](./CODE_STRUCTURE.md) for detailed structure.

## 🧪 Testing

### Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_state_machine.py

# Run with verbose output
pytest -v

# Run specific test
pytest tests/test_state_machine.py::test_valid_transitions
```

### Writing Tests

#### Test Structure

```python
import pytest
from app.services.state_machine import CapsuleStateMachine
from app.db.models import Capsule, CapsuleStatus

def test_valid_transition():
    """Test valid state transition."""
    capsule = Capsule(status=CapsuleStatus.SEALED)
    can_transition, message = CapsuleStateMachine.can_transition(
        capsule, CapsuleStatus.READY
    )
    assert can_transition is True
```

#### Test Fixtures

```python
# tests/conftest.py
@pytest.fixture
async def db_session():
    """Create database session for testing."""
    # Setup
    yield session
    # Teardown
```

### Test Coverage

- **Target**: 80%+ coverage
- **Focus**: Business logic, state machine, repositories
- **Tools**: pytest-cov

## 💻 Code Style

### Type Hints

**Required**: All functions must have type hints

```python
def get_user(user_id: str) -> Optional[User]:
    """Get user by ID."""
    ...
```

### Docstrings

**Format**: Google style

```python
def create_capsule(
    capsule_data: CapsuleCreate,
    current_user: CurrentUser
) -> CapsuleResponse:
    """
    Create a new capsule.
    
    Args:
        capsule_data: Capsule creation data
        current_user: Authenticated user
    
    Returns:
        Created capsule response
    
    Raises:
        HTTPException: If validation fails
    """
    ...
```

### Naming Conventions

- **Files**: `snake_case.py`
- **Classes**: `PascalCase`
- **Functions**: `snake_case`
- **Constants**: `UPPER_SNAKE_CASE`
- **Variables**: `snake_case`

### Import Order

```python
# 1. Standard library
from datetime import datetime
from typing import Optional

# 2. Third-party
from fastapi import APIRouter, HTTPException
from sqlalchemy import select

# 3. Local imports
from app.core.config import settings
from app.db.models import User
```

## 🔄 Development Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes

- Write code following style guidelines
- Add tests for new functionality
- Update documentation if needed

### 3. Test Changes

```bash
# Run tests
pytest

# Check code style (if configured)
black app/
flake8 app/
```

### 4. Commit Changes

```bash
git add .
git commit -m "feat: add new feature"
```

### Commit Message Format

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `refactor:` - Code refactoring
- `test:` - Tests
- `chore:` - Maintenance

### 5. Push and Create PR

```bash
git push origin feature/your-feature-name
```

## 🐛 Debugging

### Enable Debug Mode

```env
DEBUG=true
```

### Logging

```python
from app.core.logging import get_logger

logger = get_logger(__name__)

logger.debug("Debug message")
logger.info("Info message")
logger.warning("Warning message")
logger.error("Error message")
```

### Database Debugging

```env
DB_ECHO=true
```

This will print all SQL queries to console.

### Common Issues

#### Import Errors

```bash
# Make sure virtual environment is activated
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

#### Database Errors

```bash
# Reset Supabase database
cd ../supabase
supabase db reset

# Restart server
uvicorn app.main:app --reload
```

#### Port Already in Use

```bash
# Find process
lsof -i :8000

# Kill process or use different port
uvicorn app.main:app --reload --port 8001
```

## 📝 Adding New Features

### 1. API Endpoint

```python
# app/api/your_resource.py
from fastapi import APIRouter
from app.models.schemas import YourResourceResponse
from app.dependencies import CurrentUser, DatabaseSession

router = APIRouter(prefix="/your-resource", tags=["Your Resource"])

@router.get("", response_model=YourResourceResponse)
async def get_resource(
    current_user: CurrentUser,
    session: DatabaseSession
) -> YourResourceResponse:
    """Get resource."""
    ...
```

### 2. Database Model

```python
# app/db/models.py
class YourResource(Base):
    """Your resource model."""
    __tablename__ = "your_resources"
    
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    # Add fields
    ...
```

### 3. Pydantic Schema

```python
# app/models/schemas.py
class YourResourceResponse(BaseModel):
    """Your resource response model."""
    id: str
    # Add fields
    ...
    
    class Config:
        from_attributes = True
```

### 4. Repository

```python
# app/db/repositories.py
class YourResourceRepository(BaseRepository[YourResource]):
    """Repository for your resource."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(YourResource, session)
    
    # Add custom methods
    ...
```

## 🔍 Code Review Checklist

### Before Submitting PR

- [ ] Code follows style guidelines
- [ ] All tests pass
- [ ] New code has tests
- [ ] Documentation updated
- [ ] No hardcoded values
- [ ] Input validation added
- [ ] Error handling implemented
- [ ] Logging added where appropriate
- [ ] Type hints added
- [ ] Docstrings added

### Review Focus Areas

- **Security**: Input validation, sanitization
- **Performance**: Query optimization, async usage
- **Error Handling**: Comprehensive error handling
- **Testing**: Test coverage, edge cases
- **Documentation**: Clear documentation

## 🛠️ Tools and Utilities

### Code Formatting

```bash
# Install black
pip install black

# Format code
black app/
```

### Linting

```bash
# Install flake8
pip install flake8

# Lint code
flake8 app/
```

### Type Checking

```bash
# Install mypy
pip install mypy

# Type check
mypy app/
```

## 📚 Learning Resources

### FastAPI

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [FastAPI Tutorial](https://fastapi.tiangolo.com/tutorial/)

### SQLAlchemy

- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [Async SQLAlchemy](https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html)

### Pydantic

- [Pydantic Documentation](https://docs.pydantic.dev/)
- [Pydantic v2 Migration](https://docs.pydantic.dev/2.0/migration/)

## 🎯 Best Practices

### 1. Always Use Type Hints

```python
# ✅ Good
def get_user(user_id: str) -> Optional[User]:
    ...

# ❌ Bad
def get_user(user_id):
    ...
```

### 2. Validate All Inputs

```python
# ✅ Good
from app.utils.helpers import sanitize_text
title = sanitize_text(capsule_data.title.strip(), max_length=255)

# ❌ Bad
title = capsule_data.title
```

### 3. Use Constants

```python
# ✅ Good
from app.core.config import settings
max_length = settings.max_title_length

# ❌ Bad
max_length = 255
```

### 4. Handle Errors Properly

```python
# ✅ Good
try:
    user = await user_repo.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
except Exception as e:
    logger.error(f"Error getting user: {e}")
    raise HTTPException(status_code=500, detail="Internal server error")

# ❌ Bad
user = await user_repo.get_by_id(user_id)  # May raise exception
```

### 5. Use Async Properly

```python
# ✅ Good
async def get_user(user_id: str) -> Optional[User]:
    result = await session.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()

# ❌ Bad
def get_user(user_id: str) -> Optional[User]:
    result = session.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()
```

## 📖 Related Documentation

- [GETTING_STARTED.md](./GETTING_STARTED.md) - Setup guide
- [CODE_STRUCTURE.md](./CODE_STRUCTURE.md) - Code organization
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture
- [API_REFERENCE.md](./API_REFERENCE.md) - API documentation

---

**Last Updated**: 2025

