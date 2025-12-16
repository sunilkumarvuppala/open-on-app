# Testing Plan: Draft Exit Popup

## Issue
The "Save as draft" popup is not appearing when trying to exit the draft screen.

## Testing Steps

### 1. **Basic Functionality Test**

#### Test Case 1.1: Empty Draft - Should Exit Immediately
1. Navigate to `/draft/new` (new draft screen)
2. Don't type anything
3. Tap the back button
4. **Expected**: Screen should exit immediately without popup
5. **Check logs**: Should see "No content, exiting without dialog"

#### Test Case 1.2: Draft with Content - Should Show Popup
1. Navigate to `/draft/new`
2. Type some text (e.g., "Hello, this is a test draft")
3. Wait for auto-save indicator to show "Saved"
4. Tap the back button
5. **Expected**: Bottom sheet popup should appear with 3 options
6. **Check logs**: Should see "Showing exit dialog" and "Building exit dialog UI"

### 2. **Popup Options Test**

#### Test Case 2.1: Save as Draft
1. Type content in draft
2. Tap back button
3. Popup appears
4. Tap "Save as draft" option
5. **Expected**: 
   - Draft should be saved
   - Screen should exit
   - Draft should appear in drafts list

#### Test Case 2.2: Discard
1. Type content in draft
2. Tap back button
3. Popup appears
4. Tap "Discard" option
5. **Expected**:
   - Screen should exit immediately
   - Draft should NOT be saved
   - Draft should NOT appear in drafts list

#### Test Case 2.3: Continue Writing
1. Type content in draft
2. Tap back button
3. Popup appears
4. Tap "Continue writing" option
5. **Expected**:
   - Popup should close
   - Screen should stay open
   - Content should still be visible

### 3. **System Back Gesture Test**

#### Test Case 3.1: Android/iOS Back Gesture
1. Type content in draft
2. Use system back gesture (swipe from edge)
3. **Expected**: Popup should appear
4. Test all three options work correctly

### 4. **Edge Cases**

#### Test Case 4.1: Very Long Content
1. Type a very long draft (1000+ characters)
2. Tap back button
3. **Expected**: Popup should still appear

#### Test Case 4.2: Only Whitespace
1. Type only spaces and newlines
2. Tap back button
3. **Expected**: Should exit without popup (whitespace is trimmed)

#### Test Case 4.3: Rapid Back Taps
1. Type content
2. Rapidly tap back button multiple times
3. **Expected**: Only one popup should appear (prevented by `_isExiting` flag)

#### Test Case 4.4: Editing Existing Draft
1. Open an existing draft from drafts list
2. Make changes
3. Tap back button
4. **Expected**: Popup should appear

### 5. **Debugging Checklist**

If popup doesn't appear, check:

1. **Check Console Logs**:
   - Look for "_handleExitIntent called"
   - Look for "Content check" log with state and controller values
   - Look for "Showing exit dialog"
   - Look for "Building exit dialog UI"

2. **Verify Content Detection**:
   - The popup only shows if content exists
   - Check if `draftState.content` is being updated correctly
   - Check if `_textController.text` has content

3. **Verify PopScope**:
   - `canPop: false` should prevent immediate exit
   - `onPopInvokedWithResult` should be called

4. **Verify Back Button**:
   - Back button should call `_handleExitIntent()`
   - Check if the handler is being called

5. **Check Context**:
   - Ensure `context` is valid when showing dialog
   - Ensure widget is still mounted

## Quick Debug Test

Add this temporary button to test the dialog directly:

```dart
// Add to AppBar actions temporarily
IconButton(
  icon: Icon(Icons.bug_report),
  onPressed: () {
    Logger.debug('Manual test - calling _showExitDialog');
    _showExitDialog().then((result) {
      Logger.debug('Dialog result: $result');
    });
  },
),
```

## Expected Log Output

When working correctly, you should see:

```
[_handleExitIntent] _handleExitIntent called
[_handleExitIntent] Content check - state: "Hello, this is a test draft", controller: "Hello, this is a test draft", hasContent: true
[_handleExitIntent] Showing exit dialog
[_showExitDialog] _showExitDialog called
[_showExitDialog] Showing modal bottom sheet
[_showExitDialog] Building exit dialog UI
[_handleExitIntent] Exit dialog result: ExitAction.save
```

## Common Issues & Solutions

### Issue 1: Popup doesn't appear
**Possible causes**:
- Content check is failing (content is empty)
- PopScope not intercepting navigation
- Context is invalid

**Solution**: Check logs to see which condition is failing

### Issue 2: Popup appears but options don't work
**Possible causes**:
- Navigator.pop() not returning correct value
- Context mismatch

**Solution**: Verify the bottom sheet is using the correct context

### Issue 3: Multiple popups appear
**Possible causes**:
- `_isExiting` flag not working
- Multiple navigation events

**Solution**: Check if flag is being reset correctly

## Manual Testing Commands

1. **Navigate to new draft**:
   ```dart
   context.push('/draft/new');
   ```

2. **Navigate to existing draft**:
   ```dart
   context.push('/draft/{draftId}');
   ```

3. **Check drafts list**:
   ```dart
   context.push('/drafts');
   ```

