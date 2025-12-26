# Visual Flows and Diagrams

This document provides visual representations of key flows, architectures, and relationships in the OpenOn app.

## Table of Contents

1. [App Flow Diagram](#app-flow-diagram)
2. [State Management Flow](#state-management-flow)
3. [Navigation Flow](#navigation-flow)
4. [Theme System Flow](#theme-system-flow)
5. [Data Flow](#data-flow)
6. [Feature Architecture](#feature-architecture)

---

## App Flow Diagram

### High-Level User Journey

```
┌─────────────┐
│   App Start │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Welcome   │ ◄──┐
│   Screen    │    │ (Not authenticated)
└──────┬──────┘    │
       │           │
       ▼           │
┌─────────────┐    │
│  Login/     │    │
│  Signup     │    │
└──────┬──────┘    │
       │           │
       ▼           │
┌─────────────┐    │
│  Main App   │    │
│  (Shell)    │    │
└──────┬──────┘    │
       │           │
   ┌───┴───┐       │
   │       │       │
   ▼       ▼       │
┌─────┐ ┌─────┐    │
│Home │ │Inbox│    │
└──┬──┘ └──┬──┘    │
   │       │       │
   └───┬───┘       │
       │           │
       ▼           │
┌─────────────┐    │
│   Feature   │    │
│   Screens   │    │
└─────────────┘    │
```

### Authentication Flow

```
┌─────────────┐
│   Welcome   │
└──────┬──────┘
       │
   ┌───┴───┐
   │       │
   ▼       ▼
┌─────┐ ┌──────┐
│Login│ │Signup│
└──┬──┘ └──┬───┘
   │       │
   └───┬───┘
       │
       ▼
┌─────────────┐
│  Authenticated│
│  → Inbox     │
└─────────────┘
```

---

## State Management Flow

### Riverpod Provider Flow

```
┌─────────────────────┐
│   Repository        │
│   (Data Source)     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Provider          │
│   (State Provider)  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Widget            │
│   (ref.watch)       │
└─────────────────────┘
           │
           ▼
┌─────────────────────┐
│   UI Updates        │
│   (Reactive)        │
└─────────────────────┘
```

### Provider Dependency Chain

```
User Action
    │
    ▼
┌──────────────┐
│   Widget     │
│   (onTap)    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Repository │
│   (Method)   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Provider   │
│   (Invalidate)│
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Widget     │
│   (Rebuild)  │
└──────────────┘
```

---

## Navigation Flow

### Route Structure

```
/ (root)
│
├── /welcome
│   ├── /login
│   └── /signup
│
└── /inbox (ShellRoute - PRIMARY)
    │
    ├── /inbox (Tab 0 - PRIMARY)
    │   └── /capsule/:id
    │       ├── /capsule/:id/opening
    │       └── /capsule/:id/opened
    │
    └── /home (Tab 1 - SECONDARY/Outbox)
        ├── /create-capsule
        ├── /drafts
        ├── /recipients
        │   └── /recipients/add
        ├── /profile
        │   └── /profile/color-scheme
        └── /capsule/:id
            ├── /capsule/:id/opening
            └── /capsule/:id/opened
```

### Navigation Guard Flow

```
Route Request
    │
    ▼
┌──────────────┐
│   Guard      │
│   (redirect) │
└──────┬───────┘
       │
   ┌───┴───┐
   │       │
   ▼       ▼
┌─────┐ ┌──────┐
│Auth │ │Allow │
│Route│ │Route │
└─────┘ └──────┘
```

---

## Theme System Flow

### Theme Application Flow

```
User Selects Theme
    │
    ▼
┌─────────────────────┐
│ ColorSchemeService  │
│ (Save to Storage)   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ selectedColorScheme  │
│ Provider (Update)    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ DynamicTheme         │
│ buildTheme()         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ MaterialApp         │
│ (theme property)     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ All Widgets         │
│ (Rebuild with theme) │
└─────────────────────┘
```

### Gradient Generation

```
ColorScheme
    │
    ├── primary1 ──┐
    ├── primary2 ──┤
    │              │
    ├── secondary1 ─┤──► Dreamy Gradient
    ├── secondary2 ─┤
    │              │
    └── accent ─────┘
         │
         ├──► Soft Gradient
         └──► Warm Gradient
```

---

## Data Flow

### Create Capsule Flow

```
User Input
    │
    ▼
┌──────────────┐
│   Form       │
│   Validation │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Model      │
│   (Capsule)  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Repository │
│   (create)   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Provider   │
│   (Invalidate)│
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   UI Update  │
│   (New item) │
└──────────────┘
```

### Data Fetching Flow

```
Widget Build
    │
    ▼
┌──────────────┐
│ ref.watch()  │
│ (Provider)   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Provider   │
│   (Fetch)     │
└──────┬───────┘
       │
   ┌───┴───┐
   │       │
   ▼       ▼
┌─────┐ ┌──────┐
│Repo │ │Cache │
└──┬──┘ └──┬───┘
   │       │
   └───┬───┘
       │
       ▼
┌──────────────┐
│   Data      │
│   (Return)  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Widget    │
│   (Display) │
└──────────────┘
```

---

## Feature Architecture

### Feature Module Structure

```
feature/
├── screen.dart          # Main screen
├── widgets/            # Feature-specific widgets
└── providers/          # Feature-specific providers
```

### Feature Integration

```
┌─────────────────┐
│   Feature       │
│   Screen        │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌──────┐  ┌────────┐
│Core  │  │Other   │
│Widgets│  │Features│
└──────┘  └────────┘
    │         │
    └────┬────┘
         │
         ▼
┌─────────────────┐
│   Providers     │
│   (State)       │
└─────────────────┘
```

---

## Component Relationships

### Core Layer Dependencies

```
┌─────────────┐
│  Features   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Providers  │
└──────┬──────┘
       │
   ┌───┴───┐
   │       │
   ▼       ▼
┌─────┐ ┌──────┐
│Repo │ │Models│
└──┬──┘ └──┬───┘
   │       │
   └───┬───┘
       │
       ▼
┌─────────────┐
│  Constants  │
│  Utils      │
└─────────────┘
```

---

## Animation Flow

### Opening Animation Sequence

```
User Taps Capsule
    │
    ▼
┌──────────────┐
│  Check       │
│  Can Open?   │
└──────┬───────┘
       │
   ┌───┴───┐
   │       │
   ▼       ▼
┌─────┐ ┌──────┐
│Yes  │ │No    │
└──┬──┘ └──┬───┘
   │       │
   ▼       │
┌──────────┴──┐
│  Animation  │
│  Screen     │
└──────┬──────┘
       │
       ▼
┌──────────────┐
│  Mark Opened │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Opened      │
│  Letter      │
└──────────────┘
```

---

## Error Handling Flow

```
Operation
    │
    ▼
┌──────────────┐
│   Try        │
│   Execute    │
└──────┬───────┘
       │
   ┌───┴───┐
   │       │
   ▼       ▼
┌─────┐ ┌──────┐
│Success│ │Error│
└──┬──┘ └──┬───┘
   │       │
   │       ▼
   │   ┌──────────────┐
   │   │  Catch       │
   │   │  Exception   │
   │   └──────┬───────┘
   │          │
   │          ▼
   │      ┌──────────────┐
   │      │  Logger      │
   │      │  (Log Error) │
   │      └──────┬───────┘
   │             │
   │             ▼
   │         ┌──────────────┐
   │         │  User        │
   │         │  Notification│
   │         └──────────────┘
   │
   ▼
┌──────────────┐
│  Continue    │
│  Normal Flow │
└──────────────┘
```

---

## Related Documentation

- [Architecture](./ARCHITECTURE.md) - Detailed architecture
- [Navigation](./features/NAVIGATION.md) - Navigation details
- [Theme System](./THEME_SYSTEM.md) - Theme details
- [Core Components](./CORE_COMPONENTS.md) - Component details

---

## Name Filter Flow

### Filter Interaction Flow

```
User Action Flow:
┌─────────────────────────────────────────────────────────┐
│  User Taps Search Icon                                  │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  Filter Bar Expands (250ms animation)                   │
│  Text Field Auto-Focuses                                │
│  Keyboard Appears                                       │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  User Types Query                                       │
│  Input Debounced (200ms)                                │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  Filter Applied                                         │
│  List Updates to Show Matching Letters                  │
└─────────────────────────────────────────────────────────┘
```

### Filter State Management Flow

```
State Provider Hierarchy:
┌─────────────────────────────────────────────────────────┐
│  Filter State Providers                                 │
│  ├── receiveFilterExpandedProvider (bool)               │
│  ├── receiveFilterQueryProvider (String)                │
│  ├── sendFilterExpandedProvider (bool)                  │
│  └── sendFilterQueryProvider (String)                   │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  Filtered List Providers                                │
│  ├── receiveFilteredOpeningSoonCapsulesProvider         │
│  ├── receiveFilteredReadyCapsulesProvider               │
│  ├── receiveFilteredOpenedCapsulesProvider              │
│  ├── sendFilteredUnlockingSoonCapsulesProvider         │
│  ├── sendFilteredUpcomingCapsulesProvider               │
│  └── sendFilteredOpenedCapsulesProvider                 │
│                                                          │
│  Each provider:                                         │
│  ├── Watches base provider (e.g., incomingOpeningSoon)  │
│  ├── Watches filter query provider                     │
│  └── Returns filtered list when query non-empty        │
└─────────────────────────────────────────────────────────┘
```

### Filter Matching Algorithm Flow

```
Query Matching Process:
┌─────────────────────────────────────────────────────────┐
│  Input: Query String + Display Name                      │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  Step 1: Early Returns                                  │
│  ├── Empty query? → Return true (match all)             │
│  └── Empty name? → Return false (no match)              │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  Step 2: Normalize Inputs                               │
│  ├── Trim whitespace                                    │
│  ├── Convert to lowercase                               │
│  └── Normalize multiple spaces                           │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  Step 3: Matching Strategies (in order)                  │
│  ├── Substring Match: normalizedName.contains(query)   │
│  ├── Initials Match: query == initials                  │
│  └── Multi-Token Match: all tokens present in name     │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  Result: Boolean (match or no match)                    │
└─────────────────────────────────────────────────────────┘
```

**Related Documentation**: **[NAME_FILTER.md](./features/NAME_FILTER.md)** - Complete name filter feature documentation

---

**Last Updated**: December 2025

