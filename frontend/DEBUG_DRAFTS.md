# Debug Guide: Drafts Not Appearing

## 🔍 Quick Debug Steps

### 1. Check Console Logs

When you save a draft, look for these logs:

**When saving:**
```
[DraftStorage] Saving draft: <draftId> for user: <userId>, content length: <length>
[DraftStorage] Draft saved to key: draft_<draftId>, success: true
[DraftStorage] Draft save verified successfully
[DraftStorage] Updating draft list for user: <userId>, adding draft: <draftId>
[DraftStorage] Draft list saved: true, total drafts: <count>
```

**When loading:**
```
[LocalDraftRepository] Getting drafts for user: <userId>
[DraftStorage] Getting all drafts for user: <userId>
[DraftStorage] Draft list key: drafts_<userId>, JSON: <json>
[DraftStorage] Found <count> draft IDs: <ids>
[LocalDraftRepository] Retrieved <count> drafts for user: <userId>
[DraftsScreen] Drafts loaded: <count> for user <userId>
```

### 2. Check User ID Consistency

**Common Issue**: User ID mismatch between saving and loading

**Check:**
- When saving: What user ID is used?
- When loading: What user ID is used?
- Are they the same?

**Debug:**
```dart
// In console, check:
Logger.debug('Saving with userId: $userId');
Logger.debug('Loading with userId: $userId');
```

### 3. Check SharedPreferences

**Manual Check:**
1. Open app
2. Save a draft
3. Check console for: `Draft list key: drafts_<userId>`
4. Note the exact key used

**Verify Storage:**
- Drafts are stored under: `drafts_<userId>`
- Each draft is stored under: `draft_<draftId>`
- Make sure userId is consistent

### 4. Use Refresh Button

**In Drafts Screen:**
- Look for refresh icon (🔄) in top-right
- Tap it to manually reload drafts
- Check console logs after refresh

### 5. Test Draft Creation

**Create a test draft:**
1. Go to letter writing screen
2. Type some content
3. Wait for auto-save (check console)
4. Go to drafts list
5. Tap refresh button
6. Check console logs

### 6. Check for Errors

**Look for:**
- `Failed to save draft locally`
- `Failed to get all drafts`
- `Draft save verification failed`
- Any exception messages

## 🐛 Common Issues

### Issue 1: User ID Mismatch

**Symptoms:**
- Drafts saved but not appearing
- Different user IDs in logs

**Solution:**
- Ensure same user ID is used for save and load
- Check `currentUserProvider` returns consistent ID

### Issue 2: Provider Not Refreshing

**Symptoms:**
- Draft saved successfully
- Drafts list doesn't update
- Need to restart app to see drafts

**Solution:**
- Tap refresh button
- Or invalidate provider: `ref.invalidate(draftsProvider(userId))`

### Issue 3: Empty Content

**Symptoms:**
- Draft created but empty
- Content length is 0

**Solution:**
- Check if content is actually being passed
- Verify text controller has content

### Issue 4: Storage Failure

**Symptoms:**
- Save verification fails
- Draft not found after save

**Solution:**
- Check SharedPreferences permissions
- Check device storage space
- Check console for storage errors

## 🔧 Manual Debug Commands

### Check All Drafts in Storage

Add this temporary button to drafts screen:

```dart
// In debug mode only
if (kDebugMode)
  FloatingActionButton(
    onPressed: () async {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final draftKeys = keys.where((k) => k.startsWith('draft_')).toList();
      final listKeys = keys.where((k) => k.startsWith('drafts_')).toList();
      
      Logger.debug('=== DRAFT STORAGE DEBUG ===');
      Logger.debug('Draft keys: $draftKeys');
      Logger.debug('List keys: $listKeys');
      
      for (final key in listKeys) {
        final value = prefs.getString(key);
        Logger.debug('List $key: $value');
      }
      
      for (final key in draftKeys) {
        final value = prefs.getString(key);
        Logger.debug('Draft $key: ${value?.substring(0, value.length > 100 ? 100 : value.length)}...');
      }
    },
    child: Icon(Icons.bug_report),
  ),
```

## 📋 Debug Checklist

- [ ] Check console logs when saving draft
- [ ] Check console logs when loading drafts
- [ ] Verify user ID is consistent
- [ ] Check if drafts are actually in storage
- [ ] Try refresh button
- [ ] Check for error messages
- [ ] Verify content is not empty
- [ ] Check SharedPreferences keys

## 🎯 Expected Behavior

1. **Save Draft:**
   - Type content in letter screen
   - Auto-save triggers (800ms debounce)
   - Console shows: "Draft saved locally"
   - Draft appears in drafts list

2. **Load Drafts:**
   - Open drafts screen
   - Console shows: "Getting drafts for user: <userId>"
   - Console shows: "Retrieved <count> drafts"
   - Drafts appear in list

3. **Refresh:**
   - Tap refresh button
   - Provider invalidates
   - Drafts reload
   - Updated list appears

## 💡 Quick Fixes

### Fix 1: Force Refresh
```dart
// In drafts screen, add pull-to-refresh
RefreshIndicator(
  onRefresh: () async {
    ref.invalidate(draftsProvider(userId));
    await Future.delayed(Duration(milliseconds: 500));
  },
  child: ListView(...),
)
```

### Fix 2: Check User ID
```dart
// Add debug info
Logger.debug('Current user ID: ${user.id}');
Logger.debug('Draft user ID: ${draft.userId}');
```

### Fix 3: Verify Storage
```dart
// Check if draft exists
final draft = await DraftStorage.getDraft(draftId);
Logger.debug('Draft exists: ${draft != null}');
```

