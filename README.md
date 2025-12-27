# OpenOn - Time-Locked Letters Application

A production-ready Flutter application for creating and sending time-locked emotional letters (capsules) that unlock at a future date.

## 🚀 Quick Start

### Backend (Python/FastAPI)
```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip3 install -r requirements.txt
python3 -m uvicorn app.main:app --reload
```

### Supabase (Database)
```bash
# Install Supabase CLI (macOS)
brew install supabase/tap/supabase

# Start Supabase locally
cd supabase
supabase init      # First time only
supabase start     # Start local Supabase
```

**Access:**
- **Studio (Web UI)**: http://localhost:54323
- **API**: http://localhost:54321

See [docs/supabase/LOCAL_SETUP.md](./docs/supabase/LOCAL_SETUP.md) for detailed setup.

### Frontend
```bash
cd frontend
flutter pub get
flutter run
```

**Note**: See [docs/getting-started/QUICK_START.md](./docs/getting-started/QUICK_START.md) for complete setup guide.

## 📚 Documentation

**📖 Complete Documentation**: See [docs/README.md](./docs/README.md) for documentation overview (start here!)

**🚀 Quick Start**:
- **New developers**: Start with [docs/getting-started/ONBOARDING.md](./docs/getting-started/ONBOARDING.md)
- **Quick setup**: See [docs/getting-started/QUICK_START.md](./docs/getting-started/QUICK_START.md)
- **Quick reference**: See [docs/getting-started/QUICK_REFERENCE.md](./docs/getting-started/QUICK_REFERENCE.md)

**📊 User Flows**: See [docs/architecture/SEQUENCE_DIAGRAMS.md](./docs/architecture/SEQUENCE_DIAGRAMS.md) for detailed sequence diagrams with method-level detail

**🏗️ Architecture**: See [docs/architecture/ARCHITECTURE.md](./docs/architecture/ARCHITECTURE.md) for system architecture

## 🏗️ Architecture

- **Backend**: Python + FastAPI with SQLAlchemy ORM
- **Frontend**: Flutter + Dart with Riverpod state management
- **Architecture**: Clean Architecture with feature-based structure

## ✨ Features

- Time-locked letters (capsules) that unlock at future dates
- Dual home screens (Inbox/Outbox)
- Theme customization (10+ color schemes)
- Recipient management with relationships
- Anonymous letters (temporary identity hiding)
- Magical animations

## 🔒 Security

- Input validation and sanitization
- JWT authentication
- Access control via state machine
- BCrypt password hashing
- SQL injection prevention

## 📖 Key Documentation

- [Onboarding Guide](./docs/getting-started/ONBOARDING.md) - For new developers
- [Architecture](./docs/architecture/ARCHITECTURE.md) - System architecture
- [Refactoring](./docs/development/REFACTORING.md) - Consolidated refactoring documentation
- [Quick Reference](./docs/getting-started/QUICK_REFERENCE.md) - Common tasks
- [Backend API](./docs/backend/API_REFERENCE.md) - Backend REST API endpoints
- [Frontend API](./docs/reference/API_REFERENCE.md) - Frontend API reference (Flutter classes)

## 🛠️ Technology Stack

- **Backend**: Python 3.11+, FastAPI, SQLAlchemy, Pydantic
- **Frontend**: Flutter 3.0+, Dart 3.0+, Riverpod, GoRouter
- **Database**: Supabase (PostgreSQL) - Production-ready with local development support

## 📝 Status

✅ **Production Ready** - Codebase is production-ready and company acquisition ready

---

For complete documentation, see [docs/README.md](./docs/README.md)
