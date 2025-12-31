# Migration Guide: Full Quran Navigation

## Overview
This guide helps you update your app to use the new full Quran navigation system.

## Key Changes

### 1. Constructor Parameter Update

**Before:**
```dart
const RecitationScreen({super.key, required this.pageNumber});
```

**After:**
```dart
const RecitationScreen({super.key, this.initialPageNumber = 1});
```

### 2. Usage Update in Your App

**Before:**
```dart
home: const RecitationScreen(pageNumber: 1),
```

**After:**
```dart
home: const RecitationScreen(initialPageNumber: 1),
```

Or simply:
```dart
home: const RecitationScreen(), // Defaults to page 1
```

## Migration Checklist

- [ ] Update all `RecitationScreen` instantiations to use `initialPageNumber` instead of `pageNumber`
- [ ] Remove any hardcoded page numbers if you were limiting to specific pages
- [ ] Test navigation with the new `PageNavigation` widget
- [ ] Verify Surah dropdown selection works correctly
- [ ] Test page transitions don't lose recitation state properly

## New Features to Explore

### 1. **Direct Page Navigation**
```dart
// Users can now navigate using the UI, or programmatically:
// (See RecitationScreen source for implementation)
```

### 2. **Page Navigation Widget**
The new `PageNavigation` widget is automatically included in RecitationScreen, but you can use it standalone:

```dart
import 'package:flutter_quran_tajwid/flutter_quran_tajwid.dart';

PageNavigation(
  currentPage: 1,
  totalPages: 604,
  onPageChanged: (newPage) {
    // Handle page change
  },
)
```

## Starting Pages by Surah

If you want to start users at specific Surahs, here are the page numbers:

| Surah | Name | Page |
|-------|------|------|
| 1 | Al-Fatiha | 1 |
| 2 | Al-Baqarah | 2 |
| 3 | Al-Imran | 50 |
| ... | ... | ... |
| 114 | An-Nas | 604 |

Get the page number programmatically:
```dart
final quranService = QuranJsonService();
await quranService.initialize();
final pageNumber = quranService.getPageForSurah(2); // For Al-Baqarah
home: RecitationScreen(initialPageNumber: pageNumber!),
```

## Troubleshooting

### Issue: "widget.pageNumber is undefined"
**Solution:** Change `widget.pageNumber` to `widget.initialPageNumber` or use the state variable `_currentPageNumber`

### Issue: Page doesn't update when changing
**Solution:** The `_changePage()` method handles this automatically. Make sure you're calling it through the PageNavigation widget or directly updating `_currentPageNumber`

### Issue: Navigation widget not showing
**Solution:** Verify that the RecitationScreen build method includes the `PageNavigation` widget at the bottom

## Advanced: Customizing Navigation

To customize the PageNavigation widget, modify `lib/widgets/page_navigation.dart`:

```dart
// Change the styling
Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    color: Colors.yourColor,
    // ... customize
  ),
  ...
)

// Add your custom navigation buttons
IconButton(
  onPressed: () => yourCustomAction(),
  icon: const Icon(Icons.your_icon),
)
```

## Testing Your Migration

1. **Test Page Navigation:**
   - Start app on page 1
   - Use arrow buttons to navigate
   - Enter page numbers manually
   - Verify page content updates

2. **Test Surah Selection:**
   - Select different Surahs from dropdown
   - Verify correct pages load
   - Check multi-Surah pages work correctly

3. **Test Recitation:**
   - Start recitation on any page
   - Change page (should reset)
   - Resume recitation on new page
   - Check highlighting works

4. **Test Edge Cases:**
   - Navigate to first page (page 1)
   - Navigate to last page (page 604)
   - Enter invalid page numbers
   - Verify error handling

## Support

For issues or questions:
1. Check the [FULL_QURAN_NAVIGATION.md](./FULL_QURAN_NAVIGATION.md) documentation
2. Review the example app: `example/lib/main.dart`
3. Examine the RecitationScreen implementation: `lib/screens/recitation_screen.dart`
4. Review the PageNavigation widget: `lib/widgets/page_navigation.dart`

## See Also

- [FULL_QURAN_NAVIGATION.md](./FULL_QURAN_NAVIGATION.md) - Complete feature documentation
- [USAGE_GUIDE.md](./USAGE_GUIDE.md) - General usage guide
- [API_REFERENCE.md](./API_REFERENCE.md) - API documentation
