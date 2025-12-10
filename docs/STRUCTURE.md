# Documentation Structure Guide

This document explains the documentation structure and naming conventions to help new developers navigate the codebase.

## 📁 Documentation Organization

```
docs/
├── README.md                    # Main documentation overview (start here)
├── INDEX.md                     # Master documentation index (complete navigation)
├── STRUCTURE.md                 # This file - explains documentation structure
│
├── ONBOARDING.md                # Complete onboarding guide for new developers
├── QUICK_START.md               # Quick setup guide
├── QUICK_REFERENCE.md           # Quick reference for common tasks
│
├── ARCHITECTURE.md              # System architecture (frontend + backend overview)
├── CODE_STRUCTURE.md            # Frontend code structure
├── API_REFERENCE.md             # Frontend API reference (Flutter classes, providers)
│
├── REFACTORING.md               # Consolidated refactoring documentation
├── REFACTORING_GUIDE.md         # Refactoring patterns and best practices
├── REFACTORING_2025.md          # ⚠️ DEPRECATED - See REFACTORING.md
│
├── SEQUENCE_DIAGRAMS.md         # User flow sequence diagrams
├── PERFORMANCE_OPTIMIZATIONS.md # Performance best practices
├── CONTRIBUTING.md              # Contribution guidelines
├── CHANGELOG.md                 # Documentation changelog
│
├── backend/                     # Backend documentation
│   ├── INDEX.md                 # Backend documentation index
│   ├── GETTING_STARTED.md       # Backend quick start
│   ├── ARCHITECTURE.md          # Backend-specific architecture
│   ├── CODE_STRUCTURE.md       # Backend code structure
│   ├── API_REFERENCE.md        # Backend REST API endpoints
│   ├── CONFIGURATION.md         # Backend configuration guide
│   ├── SECURITY.md              # Backend security practices
│   ├── DEVELOPMENT.md           # Backend development guide
│   ├── REFACTORING_CHANGES.md   # Backend-specific refactoring
│   └── CLEARING_DATABASE.md     # Database clearing guide
│
├── frontend/                    # Frontend documentation
│   ├── INDEX.md                 # Frontend documentation index
│   ├── GETTING_STARTED.md       # Frontend quick start
│   ├── DEVELOPMENT_GUIDE.md     # Complete frontend development guide
│   ├── CORE_COMPONENTS.md       # Core components documentation
│   ├── THEME_SYSTEM.md          # Theme system guide
│   ├── FEATURES.md              # Features overview
│   ├── VISUAL_FLOWS.md          # Visual flow diagrams
│   └── features/                # Feature-specific documentation
│       ├── AUTH.md
│       ├── HOME.md
│       ├── RECEIVER.md
│       ├── CREATE_CAPSULE.md
│       ├── CAPSULE.md
│       ├── RECIPIENTS.md
│       ├── PROFILE.md
│       ├── NAVIGATION.md
│       └── ANIMATIONS.md
│
└── supabase/                    # Supabase documentation
    ├── README.md                # Supabase documentation overview
    ├── GETTING_STARTED.md       # Supabase quick start
    ├── LOCAL_SETUP.md           # Complete local setup guide
    └── DATABASE_SCHEMA.md       # Database schema reference
```

## 📝 Naming Conventions

### File Naming

- **UPPERCASE_WITH_UNDERSCORES.md** - Main documentation files
- **README.md** - Overview/index files for directories
- **INDEX.md** - Navigation index files
- **GETTING_STARTED.md** - Quick start guides
- **ARCHITECTURE.md** - Architecture documentation
- **API_REFERENCE.md** - API documentation
- **CODE_STRUCTURE.md** - Code organization documentation

### Directory Structure

- **Component-based**: `backend/`, `frontend/`, `supabase/`
- **Feature-based**: `frontend/features/` for feature-specific docs
- **Flat structure**: Main docs at root level of `docs/`

## 🔍 Understanding File Purposes

### Main Documentation Files

| File | Purpose | Audience |
|------|---------|----------|
| `README.md` | Documentation overview and navigation | All developers |
| `INDEX.md` | Complete documentation index | All developers |
| `ONBOARDING.md` | Complete onboarding guide | New developers |
| `QUICK_START.md` | Quick setup instructions | New developers |
| `QUICK_REFERENCE.md` | Common tasks reference | All developers |
| `ARCHITECTURE.md` | System architecture overview | All developers |
| `CODE_STRUCTURE.md` | Frontend code organization | Frontend developers |
| `API_REFERENCE.md` | Frontend API reference | Frontend developers |
| `REFACTORING.md` | Consolidated refactoring docs | All developers |
| `REFACTORING_GUIDE.md` | Refactoring patterns | Developers making changes |
| `SEQUENCE_DIAGRAMS.md` | User flow diagrams | All developers |
| `PERFORMANCE_OPTIMIZATIONS.md` | Performance best practices | All developers |
| `CONTRIBUTING.md` | Contribution guidelines | Contributors |
| `CHANGELOG.md` | Documentation changelog | All developers |

### Component-Specific Documentation

#### Backend (`docs/backend/`)

| File | Purpose |
|------|---------|
| `INDEX.md` | Backend documentation navigation |
| `GETTING_STARTED.md` | Backend setup guide |
| `ARCHITECTURE.md` | Backend architecture (Python/FastAPI) |
| `CODE_STRUCTURE.md` | Backend code organization |
| `API_REFERENCE.md` | Backend REST API endpoints |
| `CONFIGURATION.md` | Backend configuration |
| `SECURITY.md` | Backend security practices |
| `DEVELOPMENT.md` | Backend development guide |
| `REFACTORING_CHANGES.md` | Backend-specific refactoring |
| `CLEARING_DATABASE.md` | Database clearing guide |

#### Frontend (`docs/frontend/`)

| File | Purpose |
|------|---------|
| `INDEX.md` | Frontend documentation navigation |
| `GETTING_STARTED.md` | Frontend setup guide |
| `DEVELOPMENT_GUIDE.md` | Complete frontend development guide |
| `CORE_COMPONENTS.md` | Core components documentation |
| `THEME_SYSTEM.md` | Theme system guide |
| `FEATURES.md` | Features overview |
| `VISUAL_FLOWS.md` | Visual flow diagrams |
| `features/*.md` | Feature-specific documentation |

#### Supabase (`docs/supabase/`)

| File | Purpose |
|------|---------|
| `README.md` | Supabase documentation overview |
| `GETTING_STARTED.md` | Supabase quick start |
| `LOCAL_SETUP.md` | Complete local setup guide |
| `DATABASE_SCHEMA.md` | Database schema reference |

## 🚫 Avoiding Confusion

### Similar File Names

1. **API_REFERENCE.md**
   - `docs/API_REFERENCE.md` → **Frontend** API (Flutter classes, providers, models)
   - `docs/backend/API_REFERENCE.md` → **Backend** API (REST endpoints)

2. **ARCHITECTURE.md**
   - `docs/ARCHITECTURE.md` → **System** architecture (overview)
   - `docs/backend/ARCHITECTURE.md` → **Backend** architecture (Python/FastAPI)

3. **CODE_STRUCTURE.md**
   - `docs/CODE_STRUCTURE.md` → **Frontend** code structure (Flutter)
   - `docs/backend/CODE_STRUCTURE.md` → **Backend** code structure (Python)

4. **GETTING_STARTED.md**
   - `docs/QUICK_START.md` → Quick setup (general)
   - `docs/backend/GETTING_STARTED.md` → Backend setup
   - `docs/frontend/GETTING_STARTED.md` → Frontend setup
   - `docs/supabase/GETTING_STARTED.md` → Supabase setup

5. **README.md**
   - Root `README.md` → Project overview
   - `docs/README.md` → Documentation overview
   - `docs/supabase/README.md` → Supabase documentation overview

### Refactoring Documentation

- **`REFACTORING.md`** → ✅ **Use this** - Consolidated refactoring documentation
- **`REFACTORING_GUIDE.md`** → Refactoring patterns and best practices
- **`REFACTORING_2025.md`** → ⚠️ DEPRECATED - See REFACTORING.md
- **`backend/REFACTORING_CHANGES.md`** → Backend-specific refactoring details

## 🎯 Quick Navigation Guide

### For New Developers

1. Start with **[README.md](./README.md)** - Documentation overview
2. Read **[ONBOARDING.md](./ONBOARDING.md)** - Complete onboarding
3. Follow **[QUICK_START.md](./QUICK_START.md)** - Quick setup
4. Bookmark **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Common tasks

### For Understanding Architecture

1. **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System overview
2. **[backend/ARCHITECTURE.md](./backend/ARCHITECTURE.md)** - Backend details
3. **[CODE_STRUCTURE.md](./CODE_STRUCTURE.md)** - Frontend structure
4. **[backend/CODE_STRUCTURE.md](./backend/CODE_STRUCTURE.md)** - Backend structure

### For API Integration

1. **[backend/API_REFERENCE.md](./backend/API_REFERENCE.md)** - REST API endpoints
2. **[API_REFERENCE.md](./API_REFERENCE.md)** - Frontend classes/providers

### For Database Work

1. **[supabase/README.md](./supabase/README.md)** - Supabase overview
2. **[supabase/DATABASE_SCHEMA.md](./supabase/DATABASE_SCHEMA.md)** - Schema reference
3. **[supabase/LOCAL_SETUP.md](./supabase/LOCAL_SETUP.md)** - Local setup

## ✅ Documentation Standards

### What Each File Should Include

1. **Clear title and purpose** at the top
2. **Table of contents** for long documents
3. **Cross-references** to related documentation
4. **Examples** where applicable
5. **Last updated** date

### What to Avoid

- ❌ Duplicate information across files
- ❌ Conflicting information
- ❌ Unclear file names
- ❌ Missing cross-references
- ❌ Outdated information

## 📚 Maintenance

### When Adding New Documentation

1. **Check for existing docs** - Don't duplicate
2. **Use consistent naming** - Follow conventions
3. **Add to INDEX.md** - Update navigation
4. **Cross-reference** - Link to related docs
5. **Update README.md** - If it's a major addition

### When Updating Documentation

1. **Check all cross-references** - Update links
2. **Update INDEX.md** - If structure changes
3. **Update CHANGELOG.md** - Document changes
4. **Remove deprecated content** - Don't leave outdated info

---

**Last Updated**: January 2025  
**Maintained By**: Development Team

