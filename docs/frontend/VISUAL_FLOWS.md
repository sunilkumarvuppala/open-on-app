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
│  → Home      │
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
└── /home (ShellRoute)
    │
    ├── /home (Tab 0)
    │   ├── /create-capsule
    │   ├── /drafts
    │   ├── /recipients
    │   │   └── /recipients/add
    │   ├── /profile
    │   │   └── /profile/color-scheme
    │   └── /capsule/:id
    │       ├── /capsule/:id/opening
    │       └── /capsule/:id/opened
    │
    └── /inbox (Tab 1)
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

**Last Updated**: 2024

