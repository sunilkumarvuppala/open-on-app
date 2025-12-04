# OpenOn - Time-Locked Letters Application

A production-ready Flutter application for creating and sending time-locked emotional letters (capsules) that unlock at a future date.

## 🚀 Quick Start

### Backend
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run
```

## 📚 Documentation

**For new developers**: Start with [docs/ONBOARDING.md](./docs/ONBOARDING.md)

**Complete documentation**: See [docs/README.md](./docs/README.md)

**Quick reference**: See [docs/QUICK_REFERENCE.md](./docs/QUICK_REFERENCE.md)

## 🏗️ Architecture

- **Backend**: Python + FastAPI with SQLAlchemy ORM
- **Frontend**: Flutter + Dart with Riverpod state management
- **Architecture**: Clean Architecture with feature-based structure

## ✨ Features

- Time-locked letters (capsules) that unlock at future dates
- Dual home screens (Inbox/Outbox)
- Theme customization (15+ color schemes)
- Draft management
- Recipient management
- Magical animations

## 🔒 Security

- Input validation and sanitization
- JWT authentication
- Access control via state machine
- BCrypt password hashing
- SQL injection prevention

## 📖 Key Documentation

- [Onboarding Guide](./docs/ONBOARDING.md) - For new developers
- [Architecture](./docs/ARCHITECTURE.md) - System architecture
- [Refactoring 2025](./docs/REFACTORING_2025.md) - Recent refactoring
- [Quick Reference](./docs/QUICK_REFERENCE.md) - Common tasks
- [Backend API](./docs/backend/API_REFERENCE.md) - API endpoints

## 🛠️ Technology Stack

- **Backend**: Python 3.11+, FastAPI, SQLAlchemy, Pydantic
- **Frontend**: Flutter 3.0+, Dart 3.0+, Riverpod, GoRouter
- **Database**: SQLite (development), PostgreSQL (production-ready)

## 📝 Status

✅ **Production Ready** - Codebase is production-ready and company acquisition ready

---

For complete documentation, see [docs/README.md](./docs/README.md)
