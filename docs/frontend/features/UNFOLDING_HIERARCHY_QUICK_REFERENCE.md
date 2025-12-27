# Unfolding Hierarchy - Quick Reference

> **Quick reference guide for the Unfolding Hierarchy feature.**  
> For complete documentation, see [UNFOLDING_HIERARCHY.md](./UNFOLDING_HIERARCHY.md).

---

## Classification Rules

| Category | Criteria | Visual Treatment |
|----------|----------|------------------|
| **Within 48h** | Wait time ≤ 48h OR Ready age ≤ 36h | Full cards, full opacity, animations |
| **Waiting** | Ready age > 36h | Collapsed capsule, muted, no animations |
| **Beyond 48h** | Wait time > 48h | Full cards, 70% opacity, softened |

---

## Rendering Order

```
1. Within 48h (full cards)
   ↓
2. Waiting Capsule (if not empty)
   ↓
3. Beyond 48h (softened cards)
```

---

## Constants

**File**: `frontend/lib/core/constants/app_constants.dart`

```dart
// Thresholds
readyFreshThreshold = Duration(hours: 36)
waitTime48hThreshold = Duration(hours: 48)

// Visual
waitingCapsuleOpacity = 0.8
beyond48hCapsuleOpacity = 0.7

// Text
waitingForTheMomentText = 'Waiting for the moment'
oneLetterText = 'One letter'
severalLettersText = 'Several letters'
```

---

## Key Functions

### Classification

```dart
_UnfoldingClassification _classifyCapsules(List<Capsule> capsules)
```

- **Complexity**: O(n)
- **Returns**: `_UnfoldingClassification` with three lists
- **Sorting**: Applied to each category

### Waiting Capsule

```dart
class _WaitingCapsule extends ConsumerStatefulWidget {
  final List<Capsule> waitingCapsules;
}
```

- **State**: Local UI state (`_isExpanded`)
- **Rendering**: `ListView.builder` for performance
- **Interaction**: Two taps required (expand → tap card)

---

## Filter Override

When `filterQuery.trim().isNotEmpty`:
- ✅ All grouping disabled
- ✅ Flat list shown
- ✅ Waiting capsule hidden
- ✅ Sorted by time remaining

---

## Performance

- ✅ O(n) classification
- ✅ Single `DateTime.now()` call
- ✅ `ListView.builder` for lazy rendering
- ✅ No per-frame rebuilds
- ✅ Optimized for 500K+ users

---

## Edge Cases

- ✅ Negative durations handled
- ✅ Empty sections not rendered
- ✅ Loading states show previous data
- ✅ Defensive programming throughout

---

## Related Documentation

- **[UNFOLDING_HIERARCHY.md](./UNFOLDING_HIERARCHY.md)** - Complete documentation
- **[HOME.md](./HOME.md)** - Home Screen feature
- **[NAME_FILTER.md](./NAME_FILTER.md)** - Name filter integration

---

**Last Updated**: January 2025

