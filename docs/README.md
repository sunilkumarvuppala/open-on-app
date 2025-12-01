# OpenOn App Documentation

Welcome to the OpenOn App documentation! This comprehensive guide will help you understand the codebase structure, architecture, and how to work with it.

## 📚 Documentation Structure

```
docs/
├── README.md (this file)              # Overview and navigation
├── CHANGELOG.md                       # Documentation changelog
│
└── frontend/                          # Frontend documentation
    ├── INDEX.md                       # Navigation index
    ├── FEATURES.md                    # Features overview
    │
    ├── QUICK_START.md                 # Getting started guide
    ├── GETTING_STARTED.md             # Beginner-friendly guide
    ├── DEVELOPMENT_GUIDE.md           # Complete development guide
    ├── CORE_COMPONENTS.md             # Core components documentation
    ├── THEME_SYSTEM.md                 # Theme system guide
    ├── VISUAL_FLOWS.md                 # Visual flow diagrams
    │
    └── (Note: ARCHITECTURE.md, CODE_STRUCTURE.md, PERFORMANCE_OPTIMIZATIONS.md,
        REFACTORING_GUIDE.md, API_REFERENCE.md, CONTRIBUTING.md are in parent docs/ folder)
    │
    └── features/                      # Feature-specific documentation
        ├── AUTH.md                    # Authentication feature
        ├── HOME.md                    # Home screen (sender)
        ├── RECEIVER.md                # Receiver screen (inbox)
        ├── CREATE_CAPSULE.md          # Letter creation
        ├── CAPSULE.md                 # Capsule viewing
        ├── DRAFTS.md                  # Draft management
        ├── RECIPIENTS.md              # Recipient management
        ├── PROFILE.md                 # Profile and settings
        ├── NAVIGATION.md              # Navigation system
        └── ANIMATIONS.md              # Animation system
```

## 🚀 Quick Navigation

### Getting Started
- **New to the project?** Start with [frontend/QUICK_START.md](./frontend/QUICK_START.md)
- **New developer?** Read [frontend/DEVELOPMENT_GUIDE.md](./frontend/DEVELOPMENT_GUIDE.md)
- **Navigation index?** See [frontend/INDEX.md](./frontend/INDEX.md)
- **Understanding the codebase?** Read [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Visual code structure?** See [CODE_STRUCTURE.md](./CODE_STRUCTURE.md)
- **Core components?** See [frontend/CORE_COMPONENTS.md](./frontend/CORE_COMPONENTS.md)
- **Theme system?** See [frontend/THEME_SYSTEM.md](./frontend/THEME_SYSTEM.md)

### Features
- **All features overview?** Check [frontend/FEATURES.md](./frontend/FEATURES.md)
- **Specific feature?** See [frontend/features/](./frontend/features/) directory

### Technical
- **Performance concerns?** Check [PERFORMANCE_OPTIMIZATIONS.md](./PERFORMANCE_OPTIMIZATIONS.md)
- **Making changes?** Review [REFACTORING_GUIDE.md](./REFACTORING_GUIDE.md)
- **API details?** See [API_REFERENCE.md](./API_REFERENCE.md)
- **Contributing?** Follow [CONTRIBUTING.md](./CONTRIBUTING.md)

## 📖 What is OpenOn?

OpenOn is a Flutter-based time-locked letters application that allows users to:
- Create time capsules (letters) that unlock at a future date
- Send letters to recipients
- Receive and open incoming letters
- Customize themes and color schemes
- Save drafts for later editing

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
   - **Outbox tabs**: Unfolding, Sealed, Revealed
4. **Theme Customization**: 15+ color schemes with dynamic theming
5. **Draft Management**: Save and edit letter drafts
6. **Recipient Management**: Add and manage recipients
7. **Magical Animations**: Premium animations for unlocking and revealing letters

## 🛠️ Technology Stack

- **Framework**: Flutter 3.0+
- **State Management**: Riverpod 2.4.9
- **Navigation**: GoRouter 13.0.0
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

## 🔗 Next Steps

### For New Developers
1. **Quick Start**: Follow [frontend/QUICK_START.md](./frontend/QUICK_START.md) to set up
2. **Development Guide**: Read [frontend/DEVELOPMENT_GUIDE.md](./frontend/DEVELOPMENT_GUIDE.md) for complete workflow
3. **Core Components**: Understand [frontend/CORE_COMPONENTS.md](./frontend/CORE_COMPONENTS.md)
4. **Architecture**: Explore [ARCHITECTURE.md](./ARCHITECTURE.md)

### For Understanding the Codebase
1. **Navigation**: Start with [frontend/INDEX.md](./frontend/INDEX.md)
2. **Visual Guide**: Review [CODE_STRUCTURE.md](./CODE_STRUCTURE.md)
3. **Features**: Check [frontend/FEATURES.md](./frontend/FEATURES.md) and feature docs
4. **Theme System**: Learn [frontend/THEME_SYSTEM.md](./frontend/THEME_SYSTEM.md)

### For Advanced Topics
1. **Performance**: See [PERFORMANCE_OPTIMIZATIONS.md](./PERFORMANCE_OPTIMIZATIONS.md)
2. **Code Quality**: Review [REFACTORING_GUIDE.md](./REFACTORING_GUIDE.md)
3. **APIs**: Check [API_REFERENCE.md](./API_REFERENCE.md)
4. **Contributing**: Read [CONTRIBUTING.md](./CONTRIBUTING.md)

---

**Last Updated**: 2025
**Version**: 1.0.0

