# Documentation Structure Guide

## Overview

This document explains the organization and structure of all OpenOn documentation. It serves as a guide for maintaining consistency and ensuring comprehensive coverage.

---

## Documentation Principles

### 1. Single Source of Truth
- Each topic has ONE primary document
- Cross-references link to primary sources
- No duplicate information

### 2. Hierarchical Organization
- Clear parent-child relationships
- Logical grouping by component/feature
- Easy navigation paths

### 3. Comprehensive Coverage
- All features documented
- All APIs documented
- All architecture decisions documented

### 4. Production Ready
- Accurate and up-to-date
- Suitable for due diligence
- Clear for new developers

---

## Directory Structure

```
docs/
├── README.md                    # Main documentation hub
├── INDEX.md                     # Master navigation index
├── ONBOARDING.md                # Complete onboarding guide
├── QUICK_START.md               # Quick setup guide
├── QUICK_REFERENCE.md           # Quick reference for common tasks
├── ARCHITECTURE.md               # System architecture overview
├── CODE_STRUCTURE.md             # Code organization
├── SEQUENCE_DIAGRAMS.md         # User flow diagrams
├── CHANGES_2025.md              # Comprehensive changes documentation ⭐
├── REFACTORING.md               # Refactoring documentation
├── PERFORMANCE_OPTIMIZATIONS.md # Performance guide
├── CONTRIBUTING.md              # Contribution guidelines
│
├── backend/                     # Backend documentation
│   ├── INDEX.md                 # Backend navigation index
│   ├── GETTING_STARTED.md       # Backend setup
│   ├── ARCHITECTURE.md          # Backend architecture
│   ├── API_REFERENCE.md         # REST API endpoints (includes Connections) ⭐
│   ├── CODE_STRUCTURE.md       # Backend code organization
│   ├── CONFIGURATION.md         # Configuration guide
│   ├── SECURITY.md              # Security practices
│   └── DEVELOPMENT.md           # Development guide
│
├── frontend/                    # Frontend documentation
│   ├── INDEX.md                 # Frontend navigation index
│   ├── GETTING_STARTED.md       # Frontend setup
│   ├── DEVELOPMENT_GUIDE.md    # Development guide
│   ├── CORE_COMPONENTS.md       # Core components
│   ├── THEME_SYSTEM.md          # Theming system
│   ├── FEATURES.md              # Features overview
│   ├── VISUAL_FLOWS.md          # Visual flow diagrams
│   └── features/                # Feature-specific docs
│       ├── AUTH.md              # Authentication
│       ├── HOME.md              # Home screen
│       ├── RECEIVER.md          # Receiver screen
│       ├── CREATE_CAPSULE.md   # Letter creation
│       ├── CAPSULE.md           # Capsule viewing
│       ├── CONNECTIONS.md       # Connections & friend requests ⭐ NEW
│       ├── RECIPIENTS.md        # Recipient management
│       ├── PROFILE.md           # Profile & settings
│       ├── NAVIGATION.md        # Navigation system
│       └── ANIMATIONS.md        # Animation system
│
└── supabase/                    # Database documentation
    ├── README.md                # Supabase overview
    ├── GETTING_STARTED.md       # Supabase setup
    ├── LOCAL_SETUP.md           # Local development
    └── DATABASE_SCHEMA.md       # Complete database schema (includes Connections) ⭐
```

---

## Documentation Categories

### 1. Getting Started
**Purpose**: Help new developers get started quickly

**Files**:
- `ONBOARDING.md` - Complete onboarding guide
- `QUICK_START.md` - Quick setup
- `QUICK_REFERENCE.md` - Quick reference
- `backend/GETTING_STARTED.md` - Backend setup
- `frontend/GETTING_STARTED.md` - Frontend setup
- `supabase/GETTING_STARTED.md` - Database setup

### 2. Architecture & Design
**Purpose**: Explain system design and architecture

**Files**:
- `ARCHITECTURE.md` - System architecture
- `CODE_STRUCTURE.md` - Code organization
- `backend/ARCHITECTURE.md` - Backend architecture
- `backend/CODE_STRUCTURE.md` - Backend code structure
- `SEQUENCE_DIAGRAMS.md` - User flows

### 3. Feature Documentation
**Purpose**: Document each feature in detail

**Location**: `frontend/features/`

**Files**:
- `AUTH.md` - Authentication
- `HOME.md` - Home screen
- `RECEIVER.md` - Receiver screen
- `CREATE_CAPSULE.md` - Letter creation
- `CAPSULE.md` - Capsule viewing
- `CONNECTIONS.md` - Connections ⭐ NEW
- `RECIPIENTS.md` - Recipient management
- `PROFILE.md` - Profile & settings
- `NAVIGATION.md` - Navigation
- `ANIMATIONS.md` - Animations

### 4. API Documentation
**Purpose**: Document all API endpoints

**Files**:
- `backend/API_REFERENCE.md` - Backend REST API (includes Connections) ⭐
- `API_REFERENCE.md` - Frontend API patterns

### 5. Database Documentation
**Purpose**: Document database schema and structure

**Files**:
- `supabase/DATABASE_SCHEMA.md` - Complete schema (includes Connections) ⭐
- `supabase/GETTING_STARTED.md` - Setup guide
- `supabase/LOCAL_SETUP.md` - Local development

### 6. Changes & Refactoring
**Purpose**: Document changes and improvements

**Files**:
- `CHANGES_2025.md` - Comprehensive changes documentation ⭐ NEW
- `REFACTORING.md` - Refactoring documentation
- `backend/REFACTORING_CHANGES.md` - Backend-specific changes

### 7. Development Guides
**Purpose**: Guide development workflow

**Files**:
- `CONTRIBUTING.md` - Contribution guidelines
- `backend/DEVELOPMENT.md` - Backend development
- `frontend/DEVELOPMENT_GUIDE.md` - Frontend development
- `PERFORMANCE_OPTIMIZATIONS.md` - Performance guide

### 8. Security Documentation
**Purpose**: Document security practices

**Files**:
- `backend/SECURITY.md` - Backend security
- `SECURITY_AUDIT.md` (root) - Security audit report
- `supabase/DATABASE_SCHEMA.md` - RLS policies

---

## Documentation Standards

### File Naming

- **UPPERCASE.md** for main documents (README, INDEX, etc.)
- **PascalCase.md** for feature documents (AUTH.md, CONNECTIONS.md)
- **snake_case.md** for technical documents (API_REFERENCE.md, CODE_STRUCTURE.md)

### Content Structure

Each document should include:

1. **Title & Overview** - What this document covers
2. **Table of Contents** - Navigation within document
3. **Main Content** - Organized sections
4. **Examples** - Code examples where applicable
5. **Related Documentation** - Cross-references
6. **Last Updated** - Date and maintainer

### Cross-References

- Use relative paths: `[Connections](./frontend/features/CONNECTIONS.md)`
- Link to related topics
- Maintain navigation consistency

---

## Navigation Flow

### For New Developers

```
ONBOARDING.md
    ↓
QUICK_START.md
    ↓
ARCHITECTURE.md
    ↓
Component-specific GETTING_STARTED.md
    ↓
Feature-specific documentation
```

### For Feature Development

```
Feature Documentation (e.g., CONNECTIONS.md)
    ↓
Backend API Reference (if applicable)
    ↓
Database Schema (if applicable)
    ↓
Frontend Development Guide
```

### For API Integration

```
Backend API Reference
    ↓
Authentication Guide
    ↓
Example Requests
    ↓
Error Handling
```

---

## Maintenance Guidelines

### When to Update Documentation

1. **New Feature Added**: Create feature documentation
2. **API Changed**: Update API reference
3. **Architecture Changed**: Update architecture docs
4. **Breaking Change**: Document in CHANGES_2025.md
5. **Bug Fix**: Update relevant documentation if needed

### Update Process

1. Update primary document
2. Update cross-references
3. Update INDEX.md if structure changed
4. Update CHANGES_2025.md for significant changes
5. Verify all links work

### Review Checklist

- [ ] Information is accurate
- [ ] All links work
- [ ] Examples are current
- [ ] No duplicate information
- [ ] Structure is logical
- [ ] Cross-references are correct

---

## Documentation Index Files

### Master Index
- `docs/INDEX.md` - Complete navigation hub

### Component Indexes
- `docs/backend/INDEX.md` - Backend navigation
- `docs/frontend/INDEX.md` - Frontend navigation
- `docs/supabase/README.md` - Database navigation

### Feature Index
- `docs/frontend/FEATURES.md` - Features overview

---

## Key Documentation Files

### Must-Read for All
1. `README.md` - Documentation overview
2. `ONBOARDING.md` - Complete onboarding
3. `ARCHITECTURE.md` - System architecture

### Component-Specific
- **Backend**: `backend/INDEX.md`
- **Frontend**: `frontend/INDEX.md`
- **Database**: `supabase/README.md`

### Feature-Specific
- **Connections**: `frontend/features/CONNECTIONS.md` ⭐
- **Authentication**: `frontend/features/AUTH.md`
- **Capsules**: `frontend/features/CAPSULE.md`

### Reference Documents
- `QUICK_REFERENCE.md` - Common tasks
- `backend/API_REFERENCE.md` - API endpoints
- `supabase/DATABASE_SCHEMA.md` - Database schema

---

## Recent Additions (2025)

### New Documentation

1. **Connections Feature**:
   - `frontend/features/CONNECTIONS.md` - Complete connections documentation
   - Added to `backend/API_REFERENCE.md` - Connection endpoints
   - Added to `supabase/DATABASE_SCHEMA.md` - Connection tables

2. **Changes Documentation**:
   - `CHANGES_2025.md` - Comprehensive changes record

3. **Security Documentation**:
   - `SECURITY_AUDIT.md` (root) - Security audit report
   - `FINAL_CODE_REVIEW.md` (root) - Code review summary

### Removed Documentation

- Removed duplicate connection docs from root:
  - `CONNECTIONS_FEATURE.md` (consolidated)
  - `CONNECTIONS_COMPLETE.md` (consolidated)
  - `CONNECTIONS_IMPLEMENTATION_COMPLETE.md` (consolidated)

---

## Documentation Quality Standards

### Accuracy
- ✅ All information verified
- ✅ Code examples tested
- ✅ Links validated

### Completeness
- ✅ All features documented
- ✅ All APIs documented
- ✅ All architecture decisions documented

### Clarity
- ✅ Clear language
- ✅ Logical organization
- ✅ Visual aids where helpful

### Maintenance
- ✅ Regularly updated
- ✅ Version controlled
- ✅ Change tracked

---

## For Documentation Contributors

### Adding New Documentation

1. **Choose Location**: Place in appropriate directory
2. **Follow Structure**: Use standard document structure
3. **Add to Index**: Update relevant INDEX.md files
4. **Cross-Reference**: Link to related documents
5. **Review**: Ensure accuracy and completeness

### Updating Existing Documentation

1. **Update Primary**: Modify the main document
2. **Update Index**: Update INDEX.md if structure changed
3. **Update Cross-Refs**: Update related documents
4. **Track Changes**: Document in CHANGES_2025.md if significant

### Best Practices

- Write clearly and concisely
- Use code examples
- Include diagrams where helpful
- Maintain consistency
- Keep up-to-date

---

**Last Updated**: January 2025  
**Maintained By**: Development Team  
**Status**: Production Ready ✅
