# Quick Reference: Full Quran Navigation

## 🚀 Quick Start

### Import the Package
```dart
import 'package:flutter_quran_tajwid/flutter_quran_tajwid.dart';
```

### Initialize
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QuranJsonService().initialize();
  runApp(const MyApp());
}
```

### Use the Screen
```dart
// Start at page 1 (Al-Fatiha)
home: const RecitationScreen(),

// Or start at specific page
home: const RecitationScreen(initialPageNumber: 50),

// Or start at specific Surah
final quranService = QuranJsonService();
final page = quranService.getPageForSurah(2); // Al-Baqarah
home: RecitationScreen(initialPageNumber: page!),
```

## 📍 Navigation Methods

### Method 1: Use Arrow Buttons
Click the ◀ or ▶ buttons to go to previous/next page

### Method 2: Direct Page Input
1. Click the page number field
2. Type a page number (1-604)
3. Press Enter

### Method 3: Surah Dropdown
1. Click "Go to Surah..." dropdown
2. Select a Surah from the list
3. Automatically jumps to that Surah's first page

### Method 4: Programmatic Navigation
```dart
// In your widget that has access to RecitationScreen state
_changePage(pageNumber);
```

## 🔍 Surah List Reference

### First 10 Surahs
| # | Name | Arabic | Page |
|---|------|--------|------|
| 1 | Al-Fatiha | الفاتحة | 1 |
| 2 | Al-Baqarah | البقرة | 2 |
| 3 | Al-Imran | آل عمران | 50 |
| 4 | An-Nisa | النساء | 77 |
| 5 | Al-Ma'idah | المائدة | 106 |
| 6 | Al-An'am | الأنعام | 128 |
| 7 | Al-A'raf | الأعراف | 151 |
| 8 | Al-Anfal | الأنفال | 177 |
| 9 | At-Taubah | التوبة | 187 |
| 10 | Yunus | يونس | 208 |

### Middle Surahs
| # | Name | Page |
|---|------|------|
| 55 | Ar-Rahman | 417 |
| 56 | Al-Waqi'ah | 423 |
| 67 | Al-Mulk | 474 |

### Last Surahs
| # | Name | Arabic | Page |
|---|------|--------|------|
| 110 | An-Nasr | النصر | 601 |
| 111 | Al-Lahab | المسد | 602 |
| 112 | Al-Ikhlas | الإخلاص | 603 |
| 113 | Al-Falaq | الفلق | 604 |
| 114 | An-Nas | الناس | 604 |

**Complete list in dropdown** - Automatically loaded when you open the Surah selector

## 🎯 Common Tasks

### Task: Start at Al-Baqarah (Surah 2)
```dart
home: const RecitationScreen(initialPageNumber: 2),
```

### Task: Allow user to start from any page
```dart
home: const RecitationScreen(), // Starts at page 1
// User can navigate using PageNavigation widget
```

### Task: Get page number for a Surah
```dart
final quranService = QuranJsonService();
await quranService.initialize();
final pageForYasin = quranService.getPageForSurah(36); // 415
```

### Task: Get all Surahs with pages
```dart
final quranService = QuranJsonService();
await quranService.initialize();
final allSurahs = quranService.getAllSurahs();
// Returns: [
//   {'number': 1, 'name': 'Al-Fatiha', 'pageNumber': 1},
//   {'number': 2, 'name': 'Al-Baqarah', 'pageNumber': 2},
//   ...
// ]
```

## ⚙️ Configuration

### Change Starting Page
Edit your main.dart:
```dart
// Change from:
home: const RecitationScreen(initialPageNumber: 1),
// To:
home: const RecitationScreen(initialPageNumber: 150),
```

### Customize Navigation Widget
Edit `lib/widgets/page_navigation.dart`:
- Change colors, styling, layout
- Add custom buttons or functionality
- Adjust responsive behavior

### Change Page Display Format
Edit `lib/screens/recitation_screen.dart`:
- Modify line grouping
- Change font sizes
- Customize highlighting colors

## 📊 Pages Overview

| Category | Pages | Details |
|----------|-------|---------|
| Total Pages | 604 | Complete Quran |
| Lines per Page | 15 | Traditional format |
| Surahs | 114 | All chapters |
| Verses | ~6,236 | Total verses |
| Words | ~77,000+ | Approximate |
| First Page | 1 | Al-Fatiha |
| Last Page | 604 | An-Nas |

## 🛠️ Troubleshooting

| Issue | Solution |
|-------|----------|
| Page doesn't load | Check page number is 1-604 |
| Surah not in dropdown | Initialize QuranJsonService first |
| Navigation buttons disabled | On pages 1 (prev) or 604 (next) |
| Page transitions slow | Clear app cache, restart |
| Highlighting not working | Ensure recitation is started |
| Surah dropdown empty | Call `quranService.initialize()` first |

## 💡 Tips & Tricks

### Tip 1: Quick Page Jump
Don't use the dropdown for browsing pages - use direct input instead. It's faster for jumping to specific pages.

### Tip 2: Bookmark Your Page
Screenshot or note the page number. You can jump back to it anytime using the input field.

### Tip 3: Learn by Surah
Use the Surah dropdown to systematically practice each Surah from beginning to end.

### Tip 4: Track Progress
Count completed pages out of 604. Each page ≈ 2-3 minutes of recitation.

### Tip 5: Page Context
Look at the Surah name (changes per page) to understand which Surah content you're viewing.

## 📚 Class References

### RecitationScreen
```dart
class RecitationScreen extends ConsumerStatefulWidget {
  final int initialPageNumber; // Default: 1
  const RecitationScreen({
    super.key,
    this.initialPageNumber = 1,
  });
}
```

### PageNavigation
```dart
class PageNavigation extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  
  const PageNavigation({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });
}
```

### QuranJsonService Methods
```dart
Future<void> initialize()              // Load JSON data
QuranPage? getPage(int pageNumber)     // Get specific page
int getTotalPages()                    // Get total pages (604)
QuranChapter? getSurah(int surahNumber) // Get surah chapter
int? getPageForSurah(int surahNumber)  // Find page for surah
List<Map> getAllSurahs()               // Get all 114 surahs
```

## 🎨 UI Components

### Page Navigation Bar
```
[◀] [Page Input] [of 604] [▶]
[Go to Surah: Dropdown]
```

### Status Banner
```
Status: Ready to recite Page 100
```

### Line Display
```
بسم الله الرحمن الرحيم ٱلحمد لله رب الع
almonds الرحمن الرحيم إياك نعبد وإياك نست
```

## 🔗 Related Files

| File | Purpose |
|------|---------|
| `lib/widgets/page_navigation.dart` | Navigation UI |
| `lib/screens/recitation_screen.dart` | Main screen |
| `lib/services/quran_json_service.dart` | Data service |
| `lib/utils/quran_text.json` | Quran data |
| `FULL_QURAN_NAVIGATION.md` | Full documentation |
| `MIGRATION_GUIDE.md` | Migration help |

## 📞 Support

- Check [FULL_QURAN_NAVIGATION.md](./FULL_QURAN_NAVIGATION.md) for details
- See [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md) for updates
- Review [NAVIGATION_VISUAL_GUIDE.md](./NAVIGATION_VISUAL_GUIDE.md) for visual overview

---

**Last Updated**: 2025-12-23  
**Version**: 1.0.0+1  
**Status**: ✅ Production Ready
