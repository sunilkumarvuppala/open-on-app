# OpenOn Documentation Hub

> **📖 Welcome to OpenOn Documentation!**  
> This is the **main entry point** for all project documentation.  
> For project overview, see [../README.md](../README.md) in the root directory.

---

## 🎯 Quick Start for New Developers

**Never worked on this project before?** Start here:

1. **[getting-started/ONBOARDING.md](./getting-started/ONBOARDING.md)** - Complete onboarding guide (start here!)
2. **[getting-started/QUICK_START.md](./getting-started/QUICK_START.md)** - Quick setup instructions
3. **[architecture/ARCHITECTURE.md](./architecture/ARCHITECTURE.md)** - System architecture overview
4. **[INDEX.md](./INDEX.md)** - Master navigation index

---

## 📚 Documentation Structure

### Naming Conventions

**Clear and Consistent**:
- **Root level**: `README.md` (this file) - Main documentation hub
- **Component folders**: `INDEX.md` - Component overview (backend, frontend, supabase)
- **Feature docs**: `FEATURE_NAME.md` (PascalCase) - Located in `frontend/features/`
- **Guides**: `GUIDE_NAME.md` (UPPERCASE) - Development guides
- **Archive**: `archive/` folder - Historical documents (reviews, fixes, analysis)

**No Duplication**: Each topic has ONE primary document. Cross-references link to primary sources.

---

### Documentation Organization

**Root Level** (Navigation & Entry Points):
- **[README.md](./README.md)** - Documentation hub (this file)
- **[INDEX.md](./INDEX.md)** - Master navigation index

**Getting Started** (`getting-started/`):
- **[ONBOARDING.md](./getting-started/ONBOARDING.md)** - Complete onboarding guide
- **[QUICK_START.md](./getting-started/QUICK_START.md)** - Quick setup guide
- **[QUICK_REFERENCE.md](./getting-started/QUICK_REFERENCE.md)** - Common tasks reference

**Architecture** (`architecture/`):
- **[ARCHITECTURE.md](./architecture/ARCHITECTURE.md)** - System architecture
- **[ARCHITECTURE_IMPROVEMENTS.md](./architecture/ARCHITECTURE_IMPROVEMENTS.md)** - Architecture patterns
- **[CODE_STRUCTURE.md](./architecture/CODE_STRUCTURE.md)** - Code organization
- **[SEQUENCE_DIAGRAMS.md](./architecture/SEQUENCE_DIAGRAMS.md)** - User flow diagrams

**Development** (`development/`):
- **[DEVELOPER_GUIDE.md](./development/DEVELOPER_GUIDE.md)** - Complete developer reference
- **[REFACTORING.md](./development/REFACTORING.md)** - Refactoring history
- **[REFACTORING_GUIDE.md](./development/REFACTORING_GUIDE.md)** - Refactoring patterns
- **[PERFORMANCE_OPTIMIZATIONS.md](./development/PERFORMANCE_OPTIMIZATIONS.md)** - Performance guide

**Reference** (`reference/`):
- **[API_REFERENCE.md](./reference/API_REFERENCE.md)** - Frontend API reference
- **[FEATURES_LIST.md](./reference/FEATURES_LIST.md)** - Complete features checklist

**Project Management** (`project-management/`):
- **[CHANGELOG.md](./project-management/CHANGELOG.md)** - Documentation changelog
- **[CHANGES_2025.md](./project-management/CHANGES_2025.md)** - Code changes record
- **[CONTRIBUTING.md](./project-management/CONTRIBUTING.md)** - Contribution guidelines
- **[DOCUMENTATION_STRUCTURE.md](./project-management/DOCUMENTATION_STRUCTURE.md)** - Doc organization
- **[NAVIGATION_GUIDE.md](./project-management/NAVIGATION_GUIDE.md)** - Navigation reference

---

### Component Documentation

#### Backend (`backend/`)
- **[INDEX.md](./backend/INDEX.md)** - Backend documentation index
- **[GETTING_STARTED.md](./backend/GETTING_STARTED.md)** - Backend setup guide
- **[ARCHITECTURE.md](./backend/ARCHITECTURE.md)** - Backend architecture (Python/FastAPI)
- **[API_REFERENCE.md](./backend/API_REFERENCE.md)** - Backend REST API endpoints
- **[CODE_STRUCTURE.md](./backend/CODE_STRUCTURE.md)** - Backend code organization
- **[CONFIGURATION.md](./backend/CONFIGURATION.md)** - Configuration guide
- **[SECURITY.md](./backend/SECURITY.md)** - Security practices
- **[DEVELOPMENT.md](./backend/DEVELOPMENT.md)** - Development guide

#### Frontend (`frontend/`)
- **[INDEX.md](./frontend/INDEX.md)** - Frontend documentation index
- **[GETTING_STARTED.md](./frontend/GETTING_STARTED.md)** - Frontend setup guide
- **[DEVELOPMENT_GUIDE.md](./frontend/DEVELOPMENT_GUIDE.md)** - Complete development guide
- **[CORE_COMPONENTS.md](./frontend/CORE_COMPONENTS.md)** - Core components
- **[THEME_SYSTEM.md](./frontend/THEME_SYSTEM.md)** - Theming system
- **[FEATURES.md](./frontend/FEATURES.md)** - Features overview
- **[VISUAL_FLOWS.md](./frontend/VISUAL_FLOWS.md)** - Visual flow diagrams

**Feature Documentation** (`frontend/features/`):
- **[AUTH.md](./frontend/features/AUTH.md)** - Authentication
- **[HOME.md](./frontend/features/HOME.md)** - Home screen (sender/outbox)
- **[RECEIVER.md](./frontend/features/RECEIVER.md)** - Receiver screen (inbox)
- **[CREATE_CAPSULE.md](./frontend/features/CREATE_CAPSULE.md)** - Letter creation
- **[CAPSULE.md](./frontend/features/CAPSULE.md)** - Capsule viewing
- **[DRAFTS.md](./frontend/features/DRAFTS.md)** - Draft management
- **[CONNECTIONS.md](./frontend/features/CONNECTIONS.md)** - Connections & friend requests
- **[THOUGHTS.md](./frontend/features/THOUGHTS.md)** - Thoughts feature (presence signals)
- **[RECIPIENTS.md](./frontend/features/RECIPIENTS.md)** - Recipient management
- **[PROFILE.md](./frontend/features/PROFILE.md)** - Profile & settings
- **[NAVIGATION.md](./frontend/features/NAVIGATION.md)** - Navigation system
- **[ANIMATIONS.md](./frontend/features/ANIMATIONS.md)** - Animation system
- **[ANONYMOUS_LETTERS.md](./frontend/features/ANONYMOUS_LETTERS.md)** - Anonymous letters feature
- **[LETTERS_TO_SELF.md](./frontend/features/LETTERS_TO_SELF.md)** - Letters to self feature

**Special Feature Documentation** (`features/`):
- **[COUNTDOWN_SHARES.md](./features/COUNTDOWN_SHARES.md)** - Countdown Shares feature
- **[LETTER_REPLIES.md](./features/LETTER_REPLIES.md)** - Letter Replies feature ⭐ NEW
- **[ANONYMOUS_IDENTITY_HINTS.md](./features/ANONYMOUS_IDENTITY_HINTS.md)** - Anonymous Identity Hints feature ⭐ NEW

#### Supabase (`supabase/`)
- **[INDEX.md](./supabase/INDEX.md)** - Supabase documentation index
- **[GETTING_STARTED.md](./supabase/GETTING_STARTED.md)** - Supabase setup guide
- **[LOCAL_SETUP.md](./supabase/LOCAL_SETUP.md)** - Local development setup
- **[DATABASE_SCHEMA.md](./supabase/DATABASE_SCHEMA.md)** - Complete database schema reference
- **[DATABASE_OPTIMIZATIONS.md](./supabase/DATABASE_OPTIMIZATIONS.md)** - Database optimizations

---

### Archive (`archive/`)

Historical documents organized by category:

- **`archive/reviews/`** - Production readiness and security reviews
- **`archive/fixes/`** - Fix summaries and changelogs
- **`archive/analysis/`** - Capacity analysis and implementation reviews
- **`archive/updates/`** - Documentation update summaries

**Note**: Archive documents are kept for historical reference but are not actively maintained.

---

## 🔍 Finding Documentation

### By Role

**New Developer**:
1. Start with [getting-started/ONBOARDING.md](./getting-started/ONBOARDING.md)
2. Read [getting-started/QUICK_START.md](./getting-started/QUICK_START.md)
3. Review [architecture/ARCHITECTURE.md](./architecture/ARCHITECTURE.md)
4. Check component-specific `GETTING_STARTED.md`

**Frontend Developer**:
1. [frontend/INDEX.md](./frontend/INDEX.md)
2. [frontend/GETTING_STARTED.md](./frontend/GETTING_STARTED.md)
3. [frontend/DEVELOPMENT_GUIDE.md](./frontend/DEVELOPMENT_GUIDE.md)
4. Feature-specific docs in `frontend/features/`

**Backend Developer**:
1. [backend/INDEX.md](./backend/INDEX.md)
2. [backend/GETTING_STARTED.md](./backend/GETTING_STARTED.md)
3. [backend/ARCHITECTURE.md](./backend/ARCHITECTURE.md)
4. [backend/API_REFERENCE.md](./backend/API_REFERENCE.md)

**Database Developer**:
1. [supabase/INDEX.md](./supabase/INDEX.md)
2. [supabase/GETTING_STARTED.md](./supabase/GETTING_STARTED.md)
3. [supabase/DATABASE_SCHEMA.md](./supabase/DATABASE_SCHEMA.md)

### By Topic

**Understanding the System**:
- [architecture/ARCHITECTURE.md](./architecture/ARCHITECTURE.md) - System architecture
- [architecture/CODE_STRUCTURE.md](./architecture/CODE_STRUCTURE.md) - Code organization
- [architecture/SEQUENCE_DIAGRAMS.md](./architecture/SEQUENCE_DIAGRAMS.md) - User flows

**Working with Features**:
- [frontend/FEATURES.md](./frontend/FEATURES.md) - Features overview
- Feature-specific docs in `frontend/features/`

**Making Changes**:
- [development/REFACTORING_GUIDE.md](./development/REFACTORING_GUIDE.md) - Refactoring patterns
- [project-management/CONTRIBUTING.md](./project-management/CONTRIBUTING.md) - Contribution guidelines
- [getting-started/QUICK_REFERENCE.md](./getting-started/QUICK_REFERENCE.md) - Common tasks

**Performance & Optimization**:
- [development/PERFORMANCE_OPTIMIZATIONS.md](./development/PERFORMANCE_OPTIMIZATIONS.md) - Performance guide
- [supabase/DATABASE_OPTIMIZATIONS.md](./supabase/DATABASE_OPTIMIZATIONS.md) - Database optimizations

---

## 📋 Documentation Standards

### Quality Standards

- ✅ **Accuracy**: All information verified against codebase
- ✅ **Completeness**: Comprehensive coverage of all features
- ✅ **Clarity**: Clear and easy to understand
- ✅ **Organization**: Logical structure and navigation
- ✅ **No Duplication**: Single source of truth for each topic
- ✅ **Cross-Referenced**: Proper linking between documents

### Maintenance

- Documentation is updated when code changes
- New features include documentation
- Breaking changes are documented in [project-management/CHANGES_2025.md](./project-management/CHANGES_2025.md)
- See [project-management/DOCUMENTATION_STRUCTURE.md](./project-management/DOCUMENTATION_STRUCTURE.md) for maintenance guidelines

---

## 🆘 Need Help?

1. **New to the project?** → Start with [getting-started/ONBOARDING.md](./getting-started/ONBOARDING.md)
2. **Looking for specific feature?** → Check [frontend/FEATURES.md](./frontend/FEATURES.md) or [INDEX.md](./INDEX.md)
3. **Need quick reference?** → See [getting-started/QUICK_REFERENCE.md](./getting-started/QUICK_REFERENCE.md)
4. **Navigation help?** → Read [project-management/NAVIGATION_GUIDE.md](./project-management/NAVIGATION_GUIDE.md)

---

## 📝 Documentation Structure Summary

```
docs/
├── README.md (this file)           # Main documentation hub
├── INDEX.md                         # Master navigation index
│
├── getting-started/                # Getting started guides
│   ├── INDEX.md
│   ├── ONBOARDING.md
│   ├── QUICK_START.md
│   └── QUICK_REFERENCE.md
│
├── architecture/                   # Architecture & design
│   ├── INDEX.md
│   ├── ARCHITECTURE.md
│   ├── ARCHITECTURE_IMPROVEMENTS.md
│   ├── CODE_STRUCTURE.md
│   └── SEQUENCE_DIAGRAMS.md
│
├── development/                    # Development guides
│   ├── INDEX.md
│   ├── DEVELOPER_GUIDE.md
│   ├── REFACTORING.md
│   ├── REFACTORING_GUIDE.md
│   └── PERFORMANCE_OPTIMIZATIONS.md
│
├── reference/                      # Reference documentation
│   ├── INDEX.md
│   ├── API_REFERENCE.md
│   └── FEATURES_LIST.md
│
├── project-management/            # Project management
│   ├── INDEX.md
│   ├── CHANGELOG.md
│   ├── CHANGES_2025.md
│   ├── CONTRIBUTING.md
│   ├── DOCUMENTATION_STRUCTURE.md
│   └── NAVIGATION_GUIDE.md
│
├── backend/                        # Backend documentation
│   └── INDEX.md
│
├── frontend/                       # Frontend documentation
│   ├── INDEX.md
│   └── features/                   # Feature-specific docs
│
├── supabase/                       # Database documentation
│   └── INDEX.md
│
└── archive/                        # Historical documents
    ├── reviews/
    ├── fixes/
    ├── analysis/
    └── updates/
```

---

**Last Updated**: 2025-12-25  
**Maintainer**: Engineering Team  
**Status**: Production Ready
