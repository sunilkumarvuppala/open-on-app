# Documentation Navigation Guide

> **Quick reference for finding documentation.**  
> For complete documentation overview, see [README.md](./README.md).  
> For master index, see [INDEX.md](./INDEX.md).

## 🎯 Quick Navigation

### I'm New Here - Where Do I Start?

1. **First Time Setup**: [ONBOARDING.md](./ONBOARDING.md) → [QUICK_START.md](./QUICK_START.md)
2. **Understanding the System**: [ARCHITECTURE.md](./ARCHITECTURE.md) → [CODE_STRUCTURE.md](./CODE_STRUCTURE.md)
3. **Learning to Code**: [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md) → [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)

### I Need to Find Specific Information

**Setup & Installation**:
- General: [QUICK_START.md](./QUICK_START.md)
- Backend: [backend/GETTING_STARTED.md](./backend/GETTING_STARTED.md)
- Frontend: [frontend/GETTING_STARTED.md](./frontend/GETTING_STARTED.md)
- Database: [supabase/GETTING_STARTED.md](./supabase/GETTING_STARTED.md)

**API Documentation**:
- Backend API: [backend/API_REFERENCE.md](./backend/API_REFERENCE.md)
- Frontend API: [API_REFERENCE.md](./API_REFERENCE.md)

**Architecture**:
- System: [ARCHITECTURE.md](./ARCHITECTURE.md)
- Backend: [backend/ARCHITECTURE.md](./backend/ARCHITECTURE.md)
- Improvements: [ARCHITECTURE_IMPROVEMENTS.md](./ARCHITECTURE_IMPROVEMENTS.md)

**Code Structure**:
- Frontend: [CODE_STRUCTURE.md](./CODE_STRUCTURE.md)
- Backend: [backend/CODE_STRUCTURE.md](./backend/CODE_STRUCTURE.md)

**Database**:
- Schema: [supabase/DATABASE_SCHEMA.md](./supabase/DATABASE_SCHEMA.md)
- Setup: [supabase/LOCAL_SETUP.md](./supabase/LOCAL_SETUP.md)

**Features**:
- All features: [frontend/features/](./frontend/features/)
- Specific feature: See [frontend/INDEX.md](./frontend/INDEX.md) for list

**Development**:
- Guide: [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md)
- Reference: [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)
- Patterns: [REFACTORING_GUIDE.md](./REFACTORING_GUIDE.md)

**Refactoring**:
- Overview: [REFACTORING.md](./REFACTORING.md)
- Patterns: [REFACTORING_GUIDE.md](./REFACTORING_GUIDE.md)
- Changes: [CHANGES_2025.md](./CHANGES_2025.md)

---

## 📋 File Naming Conventions

### Understanding File Names

**UPPERCASE_WITH_UNDERSCORES.md** = Main documentation files
- `GETTING_STARTED.md` = Detailed setup guide (component-specific)
- `QUICK_START.md` = Quick setup (general, high-level)
- `API_REFERENCE.md` = API documentation
- `CODE_STRUCTURE.md` = Code organization

**README.md** = Overview/index files
- Root `README.md` = Project overview
- `docs/README.md` = Documentation hub
- `docs/supabase/INDEX.md` = Supabase docs overview

**INDEX.md** = Navigation index files
- `docs/INDEX.md` = Master navigation index
- `docs/backend/INDEX.md` = Backend navigation
- `docs/frontend/INDEX.md` = Frontend navigation

### Component-Specific Files

Files with the same name in different directories serve different purposes:

**GETTING_STARTED.md**:
- `docs/backend/GETTING_STARTED.md` → Backend setup
- `docs/frontend/GETTING_STARTED.md` → Frontend setup
- `docs/supabase/GETTING_STARTED.md` → Supabase setup

**ARCHITECTURE.md**:
- `docs/ARCHITECTURE.md` → System architecture (overview)
- `docs/backend/ARCHITECTURE.md` → Backend architecture (detailed)

**CODE_STRUCTURE.md**:
- `docs/CODE_STRUCTURE.md` → Frontend code structure
- `docs/backend/CODE_STRUCTURE.md` → Backend code structure

**API_REFERENCE.md**:
- `docs/API_REFERENCE.md` → Frontend API (Flutter)
- `docs/backend/API_REFERENCE.md` → Backend API (REST)

---

## 🔍 Search Tips

### By Role

**Backend Developer**: Start with [backend/INDEX.md](./backend/INDEX.md)

**Frontend Developer**: Start with [frontend/INDEX.md](./frontend/INDEX.md)

**Full-Stack Developer**: Start with [ARCHITECTURE.md](./ARCHITECTURE.md)

**New Developer**: Start with [ONBOARDING.md](./ONBOARDING.md)

### By Task

**Setting up environment**: [QUICK_START.md](./QUICK_START.md)

**Understanding codebase**: [ARCHITECTURE.md](./ARCHITECTURE.md) → [CODE_STRUCTURE.md](./CODE_STRUCTURE.md)

**Making changes**: [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md) → [REFACTORING_GUIDE.md](./REFACTORING_GUIDE.md)

**Finding API endpoints**: [backend/API_REFERENCE.md](./backend/API_REFERENCE.md)

**Understanding features**: [frontend/features/](./frontend/features/)

---

## 📚 Documentation Hierarchy

```
docs/
├── README.md (START HERE)          # Documentation hub
├── INDEX.md                        # Master navigation
├── ONBOARDING.md                   # New developer guide
├── QUICK_START.md                  # Quick setup
│
├── Component Documentation
│   ├── backend/                    # Backend docs
│   ├── frontend/                   # Frontend docs
│   └── supabase/                   # Database docs
│
└── Reference Documentation
    ├── ARCHITECTURE.md             # System architecture
    ├── CODE_STRUCTURE.md           # Code organization
    ├── API_REFERENCE.md            # Frontend API
    ├── REFACTORING.md              # Refactoring docs
    └── ...
```

---

**Last Updated**: January 2025
