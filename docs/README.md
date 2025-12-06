# OpenOn Documentation

Welcome to the OpenOn App documentation! This comprehensive guide will help you understand the codebase structure, architecture, and how to work with it.

## 📚 Documentation Structure

> **Quick Navigation**: See [INDEX.md](./INDEX.md) for complete documentation index organized by category and role.

```
docs/
├── README.md (this file)              # Overview and navigation
├── INDEX.md                           # Master documentation index
├── ONBOARDING.md                      # Complete onboarding guide for new developers
├── QUICK_REFERENCE.md                 # Quick reference for common tasks
├── QUICK_START.md                     # Quick setup guide
├── ARCHITECTURE.md                    # System architecture overview
├── CODE_STRUCTURE.md                  # Code organization
├── SEQUENCE_DIAGRAMS.md               # Detailed sequence diagrams for all user flows
├── REFACTORING_2025.md                # Comprehensive refactoring documentation
├── PERFORMANCE_OPTIMIZATIONS.md       # Performance best practices
├── CONTRIBUTING.md                    # Contribution guidelines
├── CHANGELOG.md                       # Documentation changelog
│
├── backend/                           # Backend documentation
│   ├── INDEX.md                       # Navigation index
│   ├── GETTING_STARTED.md             # Quick start guide
│   ├── ARCHITECTURE.md                # Architecture overview
│   ├── CODE_STRUCTURE.md             # Code organization
│   ├── API_REFERENCE.md              # Complete API documentation
│   ├── SECURITY.md                    # Security practices
│   ├── CONFIGURATION.md              # Configuration guide
│   ├── REFACTORING_CHANGES.md        # Backend-specific refactoring
│   └── DEVELOPMENT.md                # Development guide
│
├── frontend/                          # Frontend documentation
│   ├── INDEX.md                       # Navigation index
│   ├── FEATURES.md                    # Features overview
│   ├── GETTING_STARTED.md             # Beginner-friendly guide
│   ├── DEVELOPMENT_GUIDE.md          # Complete development guide
│   ├── CORE_COMPONENTS.md            # Core components documentation
│   ├── THEME_SYSTEM.md               # Theme system guide
│   ├── VISUAL_FLOWS.md               # Visual flow diagrams
│   └── features/                      # Feature-specific documentation
│       ├── AUTH.md                   # Authentication feature
│       ├── HOME.md                    # Home screen (sender)
│       ├── RECEIVER.md                # Receiver screen (inbox)
│       ├── CREATE_CAPSULE.md         # Letter creation
│       ├── CAPSULE.md                # Capsule viewing
│       ├── RECIPIENTS.md             # Recipient management
│       ├── PROFILE.md                # Profile and settings
│       ├── NAVIGATION.md             # Navigation system
│       └── ANIMATIONS.md             # Animation system
│
└── supabase/                         # Supabase documentation
    ├── README.md                     # Documentation overview
    ├── GETTING_STARTED.md            # Quick start guide
    ├── LOCAL_SETUP.md                # Complete local development guide
    └── DATABASE_SCHEMA.md            # Complete database schema reference
```

## 🚀 Quick Navigation

> **For complete navigation, see [INDEX.md](./INDEX.md)**

### Backend
- **New to backend?** Start with [backend/GETTING_STARTED.md](./backend/GETTING_STARTED.md)
- **Backend architecture?** See [backend/ARCHITECTURE.md](./backend/ARCHITECTURE.md)
- **API reference?** See [backend/API_REFERENCE.md](./backend/API_REFERENCE.md)
- **Backend navigation?** See [backend/INDEX.md](./backend/INDEX.md)

### Frontend
- **New to the project?** Start with [frontend/GETTING_STARTED.md](./frontend/GETTING_STARTED.md)
- **New developer?** Read [frontend/DEVELOPMENT_GUIDE.md](./frontend/DEVELOPMENT_GUIDE.md)
- **Navigation index?** See [frontend/INDEX.md](./frontend/INDEX.md)
- **Core components?** See [frontend/CORE_COMPONENTS.md](./frontend/CORE_COMPONENTS.md)
- **Theme system?** See [frontend/THEME_SYSTEM.md](./frontend/THEME_SYSTEM.md)

### Supabase (Database)
- **New to Supabase?** Start with [supabase/GETTING_STARTED.md](./supabase/GETTING_STARTED.md)
- **Local setup?** See [supabase/LOCAL_SETUP.md](./supabase/LOCAL_SETUP.md)
- **Database schema?** See [supabase/DATABASE_SCHEMA.md](./supabase/DATABASE_SCHEMA.md)

### Features
- **All features overview?** Check [frontend/FEATURES.md](./frontend/FEATURES.md)
- **Specific feature?** See [frontend/features/](./frontend/features/) directory

### Technical
- **Performance concerns?** Check [PERFORMANCE_OPTIMIZATIONS.md](./PERFORMANCE_OPTIMIZATIONS.md)
- **Recent refactoring?** See [REFACTORING_2025.md](./REFACTORING_2025.md)
- **Frontend API details?** See [API_REFERENCE.md](./API_REFERENCE.md) (Frontend classes/patterns)
- **Backend API details?** See [backend/API_REFERENCE.md](./backend/API_REFERENCE.md) (REST API endpoints)
- **Complete user flows?** See [SEQUENCE_DIAGRAMS.md](./SEQUENCE_DIAGRAMS.md) (Detailed sequence diagrams for all user actions with method-level detail)
- **System architecture?** See [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Code structure?** See [CODE_STRUCTURE.md](./CODE_STRUCTURE.md)
- **Contributing?** Follow [CONTRIBUTING.md](./CONTRIBUTING.md)

### New Developers
- **Getting started?** Read [ONBOARDING.md](./ONBOARDING.md) (Complete onboarding guide)
- **Master index?** See [INDEX.md](./INDEX.md) (Complete documentation index)

## 📖 What is OpenOn?

OpenOn is a Flutter-based time-locked letters application that allows users to:
- Create time capsules (letters) that unlock at a future date
- Send letters to recipients
- Receive and open incoming letters
- Customize themes and color schemes
- Manage recipients with relationships

## 🏗️ Project Structure

```
frontend/lib/
├── core/           # Core functionality (constants, models, providers, etc.)
├── features/       # Feature modules (auth, home, capsule, etc.)
├── animations/     # Animation widgets and effects
└── main.dart       # Application entry point
```

## 🎯 Key Features

1. **Time-Locked Letters**: Create letters that unlock at specific dates
2. **Dual Home Screens**: 
   - **Inbox** (Tab 0 - PRIMARY): Receive and view incoming letters
   - **Outbox** (Tab 1 - SECONDARY): Manage sent letters
3. **Tab Organization**:
   - **Inbox tabs**: Sealed, Ready, Opened
   - **Outbox tabs**: Sealed, Ready, Opened
4. **Theme Customization**: 10+ color schemes with dynamic theming
5. **Recipient Management**: Add and manage recipients with relationships
6. **Magical Animations**: Premium animations for unlocking and revealing letters

## 🛠️ Technology Stack

- **Framework**: Flutter 3.0+
- **State Management**: Riverpod 2.4.9
- **Navigation**: GoRouter 13.0.0
- **Backend**: Python + FastAPI
- **Database**: Supabase (PostgreSQL)
- **Animations**: Custom painters and animation controllers
- **Architecture**: Feature-based modular architecture

## 📝 Recent Improvements

This codebase has been extensively refactored and optimized for:
- ✅ Production-ready code quality
- ✅ Performance optimizations (60fps animations)
- ✅ Comprehensive error handling
- ✅ Input validation and security
- ✅ Code maintainability
- ✅ Best practices compliance

**For detailed information**, see [REFACTORING_2025.md](./REFACTORING_2025.md)

## 🔗 Next Steps

### For New Developers
1. **Onboarding**: Start with [ONBOARDING.md](./ONBOARDING.md) - Complete guide for new team members
2. **Quick Reference**: Bookmark [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) for common tasks
3. **Quick Start**: Follow [QUICK_START.md](./QUICK_START.md) to set up
4. **Development Guide**: Read [frontend/DEVELOPMENT_GUIDE.md](./frontend/DEVELOPMENT_GUIDE.md) for complete workflow
5. **Core Components**: Understand [frontend/CORE_COMPONENTS.md](./frontend/CORE_COMPONENTS.md)
6. **Architecture**: Explore [ARCHITECTURE.md](./ARCHITECTURE.md)
7. **Refactoring**: Review [REFACTORING_2025.md](./REFACTORING_2025.md) to understand recent changes

### For Understanding the Codebase
1. **Navigation**: Start with [frontend/INDEX.md](./frontend/INDEX.md)
2. **Visual Guide**: Review [CODE_STRUCTURE.md](./CODE_STRUCTURE.md)
3. **Features**: Check [frontend/FEATURES.md](./frontend/FEATURES.md) and feature docs
4. **Theme System**: Learn [frontend/THEME_SYSTEM.md](./frontend/THEME_SYSTEM.md)
5. **User Flows**: Study [SEQUENCE_DIAGRAMS.md](./SEQUENCE_DIAGRAMS.md) for complete flow understanding

### For Advanced Topics
1. **Performance**: See [PERFORMANCE_OPTIMIZATIONS.md](./PERFORMANCE_OPTIMIZATIONS.md)
2. **Refactoring Patterns**: Review [REFACTORING_2025.md](./REFACTORING_2025.md)
3. **APIs**: Check [API_REFERENCE.md](./API_REFERENCE.md) and [backend/API_REFERENCE.md](./backend/API_REFERENCE.md)
4. **Contributing**: Read [CONTRIBUTING.md](./CONTRIBUTING.md)

---

**Last Updated**: January 2025  
**Version**: 1.0.0
