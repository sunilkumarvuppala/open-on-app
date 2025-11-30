# Contributing Guide

Thank you for your interest in contributing to OpenOn! This guide will help you understand how to contribute effectively.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Coding Standards](#coding-standards)
5. [Commit Guidelines](#commit-guidelines)
6. [Pull Request Process](#pull-request-process)
7. [Testing](#testing)
8. [Documentation](#documentation)

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Follow the project's coding standards
- Help others learn and grow

## Getting Started

1. **Fork the repository**
2. **Clone your fork**
   ```bash
   git clone <your-fork-url>
   cd openon
   ```

3. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Install dependencies**
   ```bash
   cd frontend
   flutter pub get
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Development Workflow

### 1. Plan Your Changes

- Understand the existing architecture
- Review related code
- Plan your implementation
- Consider edge cases

### 2. Make Your Changes

- Follow coding standards
- Write clean, maintainable code
- Add proper error handling
- Optimize for performance

### 3. Test Your Changes

- Test on multiple devices
- Test edge cases
- Verify performance
- Check for regressions

### 4. Update Documentation

- Update relevant docs
- Add code comments if needed
- Update API reference if applicable

### 5. Submit Pull Request

- Write clear description
- Reference related issues
- Include screenshots if UI changes
- Wait for review

## Coding Standards

### 1. Constants

✅ **DO**: Use `AppConstants` for all magic numbers

```dart
// ✅ Good
Container(height: AppConstants.createButtonHeight)

// ❌ Bad
Container(height: 56)
```

### 2. Error Handling

✅ **DO**: Use custom exceptions and proper error handling

```dart
// ✅ Good
try {
  final capsule = await repository.getCapsule(id);
} on NotFoundException catch (e) {
  Logger.error('Capsule not found', error: e);
  // Handle error
}

// ❌ Bad
final capsule = await repository.getCapsule(id);
```

### 3. Logging

✅ **DO**: Use `Logger` instead of `print`

```dart
// ✅ Good
Logger.info('User logged in');
Logger.error('Error occurred', error: e);

// ❌ Bad
print('User logged in');
print('Error: $e');
```

### 4. Validation

✅ **DO**: Validate all user inputs

```dart
// ✅ Good
if (!Validation.isValidEmail(email)) {
  throw ValidationException('Invalid email format');
}

// ❌ Bad
// No validation
```

### 5. Performance

✅ **DO**: Optimize for performance

```dart
// ✅ Good - Reuse Paint objects
final Paint _paint = Paint()..style = PaintingStyle.fill;

// ✅ Good - Use RepaintBoundary
RepaintBoundary(
  child: AnimatedWidget(...),
)

// ✅ Good - Add keys to ListView items
ListView.builder(
  itemBuilder: (context, index) {
    return Padding(
      key: ValueKey('item_$index'),
      child: ItemWidget(...),
    );
  },
)
```

### 6. Widget Structure

✅ **DO**: Follow widget best practices

```dart
// ✅ Good - Const constructor
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(...);
  }
}

// ✅ Good - Proper disposal
class _MyStatefulWidget extends State<MyStatefulWidget> {
  late AnimationController _controller;
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 7. Code Organization

✅ **DO**: Organize code logically

```dart
// ✅ Good - Clear structure
class MyWidget extends ConsumerWidget {
  // Constants
  static const _padding = EdgeInsets.all(16);
  
  // Constructor
  const MyWidget({super.key});
  
  // Build method
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Implementation
  }
  
  // Helper methods
  Widget _buildHeader() { ... }
}
```

## Commit Guidelines

### Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding tests
- `chore`: Maintenance tasks

### Examples

```
feat: Add draft management feature

- Add Draft model
- Create DraftsScreen
- Add draft repository
- Integrate with home screen

Closes #123
```

```
fix: Resolve ListView scroll position issue

- Add PageStorageKey to ListView
- Preserve scroll position on tab switch

Fixes #456
```

```
perf: Optimize animation performance

- Reuse Paint objects in CustomPainters
- Reduce particle counts
- Add RepaintBoundary to animations

Improves animation FPS from 30 to 60
```

## Pull Request Process

### 1. Before Submitting

- [ ] Code follows coding standards
- [ ] All tests pass
- [ ] No linter errors
- [ ] Documentation updated
- [ ] Performance tested
- [ ] Error handling implemented

### 2. PR Description

Include:
- **What**: What changes were made
- **Why**: Why these changes were needed
- **How**: How the changes work
- **Testing**: How to test the changes
- **Screenshots**: If UI changes

### 3. Review Process

- Address review comments
- Make requested changes
- Update PR if needed
- Wait for approval

## Testing

### Manual Testing

Test on:
- iOS Simulator
- Android Emulator
- Physical devices (if possible)

Test scenarios:
- Happy path
- Error cases
- Edge cases
- Performance
- UI/UX

### Code Quality Checks

```bash
# Run linter
flutter analyze

# Check formatting
dart format --set-exit-if-changed .

# Run tests (if available)
flutter test
```

## Documentation

### When to Update Documentation

- Adding new features
- Changing APIs
- Fixing bugs that affect behavior
- Performance improvements
- Architecture changes

### Documentation Files

- `README.md`: Project overview
- `ARCHITECTURE.md`: Architecture details
- `API_REFERENCE.md`: API documentation
- `PERFORMANCE_OPTIMIZATIONS.md`: Performance details
- `REFACTORING_GUIDE.md`: Code quality guidelines

## Code Review Checklist

Before requesting review, ensure:

- [ ] Code follows Dart/Flutter conventions
- [ ] All constants in `AppConstants`
- [ ] Error handling implemented
- [ ] Input validation added
- [ ] Logger used (no print statements)
- [ ] Animations use RepaintBoundary
- [ ] Paint objects reused
- [ ] Controllers properly disposed
- [ ] ListView items have keys
- [ ] No duplicate code
- [ ] Documentation updated
- [ ] Performance optimized
- [ ] Security best practices followed

## Common Issues

### Issue: Linter Errors

**Solution**: Run `flutter analyze` and fix all errors

### Issue: Performance Problems

**Solution**: 
- Check [PERFORMANCE_OPTIMIZATIONS.md](./PERFORMANCE_OPTIMIZATIONS.md)
- Use RepaintBoundary
- Reuse Paint objects
- Optimize animations

### Issue: Build Errors

**Solution**:
- Run `flutter clean`
- Run `flutter pub get`
- Check dependencies

## Getting Help

- Review existing documentation
- Check code examples in the codebase
- Ask questions in PR comments
- Review similar implementations

## Next Steps

- Read [QUICK_START.md](./QUICK_START.md) for setup
- Review [ARCHITECTURE.md](./ARCHITECTURE.md) for structure
- Check [API_REFERENCE.md](./API_REFERENCE.md) for APIs

---

Thank you for contributing! 🎉

**Last Updated**: 2024

