import 'package:hive_flutter/hive_flutter.dart';
import '../models/surah.dart';

class QuranCache {
  static const String _boxName = 'quran_cache';
  late Box<dynamic> _box;

  Future<void> initialize() async {
    // Initialize Hive if not already done
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  Future<void> cacheSurah(Surah surah) async {
    await _box.put(surah.number, {
      'number': surah.number,
      'name': surah.name,
      'englishName': surah.englishName,
      'numberOfAyahs': surah.numberOfAyahs,
      'text': surah.text,
    });
  }

  Surah? getSurah(int number) {
    final data = _box.get(number);
    if (data == null) return null;
    return Surah(
      number: data['number'],
      name: data['name'],
      englishName: data['englishName'],
      numberOfAyahs: data['numberOfAyahs'],
      text: data['text'],
    );
  }

  Future<void> clear() async {
    await _box.clear();
  }

  bool isCached(int number) {
    return _box.containsKey(number);
  }

  int get cachedCount => _box.length;
}

class QuranService {
  static final QuranCache _cache = QuranCache();

  // Full Quran data - All 114 Surahs with selected ayahs
  static final Map<int, Map<String, dynamic>> _quranData = {
    1: {
      'name': 'الفاتحة',
      'englishName': 'Al-Fatiha',
      'numberOfAyahs': 7,
      'text':
          'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ . ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ . ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ . مَٰلِكِ يَوۡمِ ٱلدِّينِ ٤'
    },
    2: {
      'name': 'البقرة',
      'englishName': 'Al-Baqarah',
      'numberOfAyahs': 286,
      'text':
          'الم ١ ذَٰلِكَ ٱلۡكِتَٰبُ لَا رَيۡبَ ۛ فِيهِ ۛ هُدًى لِّلۡمُتَّقِينَ ٢ ٱلَّذِينَ يُؤۡمِنُونَ بِٱلۡغَيۡبِ وَيُقِيمُونَ ٱلصَّلَوٰةَ ٣'
    },
    3: {
      'name': 'آل عمران',
      'englishName': 'Ali-Imran',
      'numberOfAyahs': 200,
      'text':
          'الم ١ ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡحَيُّ ٱلۡقَيُّومُ ٢ نَزَّلَ عَلَيۡكَ ٱلۡكِتَٰبَ ٣'
    },
    4: {
      'name': 'النساء',
      'englishName': 'An-Nisa',
      'numberOfAyahs': 176,
      'text':
          'يَٰٓأَيُّهَا ٱلنَّاسُ ٱتَّقُواْ رَبَّكُمُ ٱلَّذِي خَلَقَكُم مِّن نَّفۡسٍ وَٰحِدَةٍ ١'
    },
    5: {
      'name': 'المائدة',
      'englishName': 'Al-Ma-idah',
      'numberOfAyahs': 120,
      'text':
          'يَٰٓأَيُّهَا ٱلَّذِينَ آمَنُوٓاْ أَوۡفُواْ بِٱلۡعُقُودِ ١'
    },
    6: {
      'name': 'الأنعام',
      'englishName': 'Al-An-am',
      'numberOfAyahs': 165,
      'text':
          'ٱلۡحَمۡدُ لِلَّهِ ٱلَّذِي خَلَقَ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَ ١'
    },
    7: {
      'name': 'الأعراف',
      'englishName': 'Al-A-raf',
      'numberOfAyahs': 206,
      'text':
          'المص ١ كِتَٰبٌ أُنزِلَ إِلَيۡكَ فَلَا يَكُن فِي صَدۡرِكَ حَرَجٌ ٢'
    },
    8: {
      'name': 'الأنفال',
      'englishName': 'Al-Anfal',
      'numberOfAyahs': 75,
      'text':
          'يَسۡـَٔلُونَكَ عَنِ ٱلۡأَنفَالِ ۖ قُلِ ٱلۡأَنفَالُ لِلَّهِ وَٱلرَّسُولِ ١'
    },
    9: {
      'name': 'التوبة',
      'englishName': 'At-Taubah',
      'numberOfAyahs': 129,
      'text':
          'بَرَآءَةٌ مِّنَ ٱللَّهِ وَرَسُولِهِۦ إِلَى ٱلَّذِينَ عَٰهَدتُّم ١'
    },
    10: {
      'name': 'يونس',
      'englishName': 'Yunus',
      'numberOfAyahs': 109,
      'text':
          'الر ۚ تِلۡكَ آيَٰتُ ٱلۡكِتَٰبِ ٱلۡحَكِيمِ ١'
    },
    11: {
      'name': 'هود',
      'englishName': 'Hud',
      'numberOfAyahs': 123,
      'text': 'الر ۚ كِتَٰبٌ أُحۡكِمَتۡ آيَٰتُهُ ١'
    },
    12: {
      'name': 'يوسف',
      'englishName': 'Yusuf',
      'numberOfAyahs': 111,
      'text': 'الر ۚ تِلۡكَ آيَٰتُ ٱلۡكِتَٰبِ ٱلۡمُبِينِ ١'
    },
    13: {
      'name': 'الرعد',
      'englishName': 'Ar-Ra-d',
      'numberOfAyahs': 43,
      'text': 'الم ۖ تِلۡكَ آيَٰتُ ٱلۡكِتَٰبِ ١'
    },
    14: {
      'name': 'إبراهيم',
      'englishName': 'Ibrahim',
      'numberOfAyahs': 52,
      'text': 'الر ۚ كِتَٰبٌ أَنزَلۡنَٰهُ إِلَيۡكَ ١'
    },
    15: {
      'name': 'الحجر',
      'englishName': 'Al-Hijr',
      'numberOfAyahs': 99,
      'text': 'الر ۚ تِلۡكَ آيَٰتُ ٱلۡكِتَٰبِ وَقُرۡآنٍ مُّبِينٍ ١'
    },
    16: {
      'name': 'النحل',
      'englishName': 'An-Nahl',
      'numberOfAyahs': 128,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    17: {
      'name': 'الإسراء',
      'englishName': 'Al-Isra',
      'numberOfAyahs': 111,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    18: {
      'name': 'الكهف',
      'englishName': 'Al-Kahf',
      'numberOfAyahs': 110,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    19: {
      'name': 'مريم',
      'englishName': 'Maryam',
      'numberOfAyahs': 98,
      'text': 'كهيعص ١'
    },
    20: {
      'name': 'طه',
      'englishName': 'Ta-Ha',
      'numberOfAyahs': 135,
      'text': 'طه ١'
    },
    21: {
      'name': 'الأنبياء',
      'englishName': 'Al-Anbiya',
      'numberOfAyahs': 112,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    22: {
      'name': 'الحج',
      'englishName': 'Al-Hajj',
      'numberOfAyahs': 78,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    23: {
      'name': 'المؤمنون',
      'englishName': 'Al-Mu-minun',
      'numberOfAyahs': 118,
      'text': 'قَدۡ أَفۡلَحَ ٱلۡمُؤۡمِنُونَ ١'
    },
    24: {
      'name': 'النور',
      'englishName': 'An-Nur',
      'numberOfAyahs': 64,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    25: {
      'name': 'الفرقان',
      'englishName': 'Al-Furqan',
      'numberOfAyahs': 77,
      'text': 'تَبَارَكَ ٱلَّذِي نَزَّلَ ٱلۡفُرۡقَانَ ١'
    },
    26: {
      'name': 'الشعراء',
      'englishName': 'Ash-Shuara',
      'numberOfAyahs': 227,
      'text': 'طس ۖ تِلۡكَ آيَٰتُ ٱلۡقُرۡآنِ وَكِتَابٍ مُّبِينٍ ١'
    },
    27: {
      'name': 'النمل',
      'englishName': 'An-Naml',
      'numberOfAyahs': 93,
      'text': 'طس ۚ تِلۡكَ آيَٰتُ ٱلۡقُرۡآنِ وَكِتَابٍ مُّبِينٍ ١'
    },
    28: {
      'name': 'القصص',
      'englishName': 'Al-Qasas',
      'numberOfAyahs': 88,
      'text': 'طس ۖ تِلۡكَ آيَٰتُ ٱلۡكِتَٰبِ ٱلۡمُبِينِ ١'
    },
    29: {
      'name': 'العنكبوت',
      'englishName': 'Al-Ankabut',
      'numberOfAyahs': 69,
      'text': 'الم ١'
    },
    30: {
      'name': 'الروم',
      'englishName': 'Ar-Rum',
      'numberOfAyahs': 60,
      'text': 'الم ١'
    },
    31: {
      'name': 'لقمان',
      'englishName': 'Luqman',
      'numberOfAyahs': 34,
      'text': 'الم ١'
    },
    32: {
      'name': 'السجدة',
      'englishName': 'As-Sajdah',
      'numberOfAyahs': 30,
      'text': 'الم ١'
    },
    33: {
      'name': 'الأحزاب',
      'englishName': 'Al-Ahzab',
      'numberOfAyahs': 73,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    34: {
      'name': 'سبأ',
      'englishName': 'Saba',
      'numberOfAyahs': 54,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    35: {
      'name': 'فاطر',
      'englishName': 'Fatir',
      'numberOfAyahs': 45,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    36: {
      'name': 'يس',
      'englishName': 'Ya-Sin',
      'numberOfAyahs': 83,
      'text': 'ياس ١'
    },
    37: {
      'name': 'الصافات',
      'englishName': 'As-Safat',
      'numberOfAyahs': 182,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    38: {
      'name': 'ص',
      'englishName': 'Sad',
      'numberOfAyahs': 88,
      'text': 'ص ۚ وَٱلۡقُرۡآنِ ذِي ٱلذِّكۡرِ ١'
    },
    39: {
      'name': 'الزمر',
      'englishName': 'Az-Zumar',
      'numberOfAyahs': 75,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    40: {
      'name': 'غافر',
      'englishName': 'Ghafir',
      'numberOfAyahs': 85,
      'text': 'حم ١'
    },
    41: {
      'name': 'فصلت',
      'englishName': 'Fussilat',
      'numberOfAyahs': 54,
      'text': 'حم ١'
    },
    42: {
      'name': 'الشورى',
      'englishName': 'Ash-Shura',
      'numberOfAyahs': 53,
      'text': 'حم ۞ عسق ١'
    },
    43: {
      'name': 'الزخرف',
      'englishName': 'Az-Zukhruf',
      'numberOfAyahs': 89,
      'text': 'حم ١'
    },
    44: {
      'name': 'الدخان',
      'englishName': 'Ad-Dukhan',
      'numberOfAyahs': 59,
      'text': 'حم ١'
    },
    45: {
      'name': 'الجاثية',
      'englishName': 'Al-Jathiyah',
      'numberOfAyahs': 37,
      'text': 'حم ١'
    },
    46: {
      'name': 'الأحقاف',
      'englishName': 'Al-Ahqaf',
      'numberOfAyahs': 35,
      'text': 'حم ١'
    },
    47: {
      'name': 'محمد',
      'englishName': 'Muhammad',
      'numberOfAyahs': 38,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    48: {
      'name': 'الفتح',
      'englishName': 'Al-Fath',
      'numberOfAyahs': 29,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    49: {
      'name': 'الحجرات',
      'englishName': 'Al-Hujurat',
      'numberOfAyahs': 18,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    50: {
      'name': 'ق',
      'englishName': 'Qaf',
      'numberOfAyahs': 45,
      'text': 'ق ۚ وَٱلۡقُرۡآنِ ٱلۡمَجِيدِ ١'
    },
    51: {
      'name': 'الذاريات',
      'englishName': 'Adh-Dhariyat',
      'numberOfAyahs': 60,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    52: {
      'name': 'الطور',
      'englishName': 'At-Tur',
      'numberOfAyahs': 49,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    53: {
      'name': 'النجم',
      'englishName': 'An-Najm',
      'numberOfAyahs': 62,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    54: {
      'name': 'القمر',
      'englishName': 'Al-Qamar',
      'numberOfAyahs': 55,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    55: {
      'name': 'الرحمن',
      'englishName': 'Ar-Rahman',
      'numberOfAyahs': 78,
      'text': 'الرَّحۡمَٰنُ ١'
    },
    56: {
      'name': 'الواقعة',
      'englishName': 'Al-Waqiah',
      'numberOfAyahs': 96,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    57: {
      'name': 'الحديد',
      'englishName': 'Al-Hadid',
      'numberOfAyahs': 29,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    58: {
      'name': 'المجادلة',
      'englishName': 'Al-Mujadilah',
      'numberOfAyahs': 22,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    59: {
      'name': 'الحشر',
      'englishName': 'Al-Hashr',
      'numberOfAyahs': 24,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    60: {
      'name': 'الممتحنة',
      'englishName': 'Al-Mumtahanah',
      'numberOfAyahs': 13,
      'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'
    },
    61: {
      'name': 'الصف',
      'englishName': 'As-Saff',
      'numberOfAyahs': 14,
      'text': 'يُسَبِّحُ لِلَّهِ مَا فِي ٱلسَّمَٰوَٰتِ ١'
    },
    62: {
      'name': 'الجمعة',
      'englishName': 'Al-Jumuah',
      'numberOfAyahs': 11,
      'text': 'يُسَبِّحُ لِلَّهِ مَا فِي ٱلسَّمَٰوَٰتِ ١'
    },
    63: {
      'name': 'المنافقون',
      'englishName': 'Al-Munafiqun',
      'numberOfAyahs': 11,
      'text': 'إِذَا جَآءَكَ ٱلۡمُنَٰفِقُونَ ١'
    },
    64: {
      'name': 'التغابن',
      'englishName': 'At-Taghabun',
      'numberOfAyahs': 18,
      'text': 'يُسَبِّحُ لِلَّهِ مَا فِي ٱلسَّمَٰوَٰتِ ١'
    },
    65: {
      'name': 'الطلاق',
      'englishName': 'At-Talaq',
      'numberOfAyahs': 12,
      'text': 'يَٰٓأَيُّهَا ٱلنَّبِيُّ إِذَا طَلَّقۡتُمُ ٱلنِّسَآءَ ١'
    },
    66: {
      'name': 'التحريم',
      'englishName': 'At-Tahrim',
      'numberOfAyahs': 12,
      'text': 'يَٰٓأَيُّهَا ٱلنَّبِيُّ لِمَ تُحَرِّمُ ١'
    },
    67: {
      'name': 'الملك',
      'englishName': 'Al-Mulk',
      'numberOfAyahs': 30,
      'text': 'تَبَارَكَ ٱلَّذِي بِيَدِهِ ٱلۡمُلۡكُ ١'
    },
    68: {
      'name': 'القلم',
      'englishName': 'Al-Qalam',
      'numberOfAyahs': 52,
      'text': 'ن ۚ وَٱلۡقَلَمِ وَمَا يَسۡطُرُونَ ١'
    },
    69: {
      'name': 'الحاقة',
      'englishName': 'Al-Haqqah',
      'numberOfAyahs': 52,
      'text': 'ٱلۡحَآقَّةُ ١'
    },
    70: {
      'name': 'المعارج',
      'englishName': 'Al-Maarij',
      'numberOfAyahs': 44,
      'text': 'سَأَلَ سَآئِلٌ بِعَذَابٍ وَاقِعٍ ١'
    },
    71: {
      'name': 'نوح',
      'englishName': 'Nuh',
      'numberOfAyahs': 28,
      'text': 'إِنَّا أَرۡسَلۡنَا نُوحًا إِلَىٰ قَوۡمِهِۦ ١'
    },
    72: {
      'name': 'الجن',
      'englishName': 'Al-Jinn',
      'numberOfAyahs': 28,
      'text': 'قُل أُوحِيَ إِلَيَّ ١'
    },
    73: {
      'name': 'المزمل',
      'englishName': 'Al-Muzzammil',
      'numberOfAyahs': 20,
      'text': 'يَٰٓأَيُّهَا ٱلۡمُزَّمِّلُ ١'
    },
    74: {
      'name': 'المدثر',
      'englishName': 'Al-Muddaththir',
      'numberOfAyahs': 56,
      'text': 'يَٰٓأَيُّهَا ٱلۡمُدَّثِّرُ ١'
    },
    75: {
      'name': 'القيامة',
      'englishName': 'Al-Qiyamah',
      'numberOfAyahs': 40,
      'text': 'لَآ أُقۡسِمُ بِيَوۡمِ ٱلۡقِيَٰمَةِ ١'
    },
    76: {
      'name': 'الإنسان',
      'englishName': 'Al-Insan',
      'numberOfAyahs': 31,
      'text': 'هَلۡ أَتَىٰ عَلَى ٱلۡإِنسَانِ حِينٌ مِّنَ ٱلدَّهۡرِ ١'
    },
    77: {
      'name': 'المرسلات',
      'englishName': 'Al-Mursalat',
      'numberOfAyahs': 50,
      'text': 'وَٱلۡمُرۡسَلَٰتِ عُرۡفًا ١'
    },
    78: {
      'name': 'النبأ',
      'englishName': 'An-Naba',
      'numberOfAyahs': 40,
      'text': 'عَمَّ يَتَسَآءَلُونَ ١'
    },
    79: {
      'name': 'الناشعات',
      'englishName': 'An-Naziat',
      'numberOfAyahs': 46,
      'text': 'وَٱلنَّٰشِعَٰتِ غَرۡقًا ١'
    },
    80: {
      'name': 'عبس',
      'englishName': 'Abasa',
      'numberOfAyahs': 42,
      'text': 'عَبَسَ وَتَوَلَّىٰ ١'
    },
    81: {
      'name': 'التكوير',
      'englishName': 'At-Takwir',
      'numberOfAyahs': 29,
      'text': 'إِذَا ٱلشَّمۡسُ كُوِّرَتۡ ١'
    },
    82: {
      'name': 'الانفطار',
      'englishName': 'Al-Infitar',
      'numberOfAyahs': 19,
      'text': 'إِذَا ٱلسَّمَآءُ ٱنفَطَرَتۡ ١'
    },
    83: {
      'name': 'المطففين',
      'englishName': 'Al-Mutaffifin',
      'numberOfAyahs': 36,
      'text': 'وَيۡلٌ لِّلۡمُطَفِّفِينَ ١'
    },
    84: {
      'name': 'الانشقاق',
      'englishName': 'Al-Inshiqaq',
      'numberOfAyahs': 25,
      'text': 'إِذَا ٱلسَّمَآءُ ٱنشَقَّتۡ ١'
    },
    85: {
      'name': 'البروج',
      'englishName': 'Al-Buruj',
      'numberOfAyahs': 22,
      'text': 'وَٱلسَّمَآءِ ذَاتِ ٱلۡبُرُوجِ ١'
    },
    86: {
      'name': 'الطارق',
      'englishName': 'At-Tariq',
      'numberOfAyahs': 17,
      'text': 'وَٱلسَّمَآءِ وَٱلطَّٰرِقِ ١'
    },
    87: {
      'name': 'الأعلى',
      'englishName': 'Al-Ala',
      'numberOfAyahs': 19,
      'text': 'سَبِّحِ ٱسۡمَ رَبِّكَ ٱلۡأَعۡلَى ١'
    },
    88: {
      'name': 'الغاشية',
      'englishName': 'Al-Ghashiyah',
      'numberOfAyahs': 26,
      'text': 'هَلۡ أَتَاكَ حَدِيثُ ٱلۡغَاشِيَةِ ١'
    },
    89: {
      'name': 'الفجر',
      'englishName': 'Al-Fajr',
      'numberOfAyahs': 30,
      'text': 'وَٱلۡفَجۡرِ ١'
    },
    90: {
      'name': 'البلد',
      'englishName': 'Al-Balad',
      'numberOfAyahs': 20,
      'text': 'لَآ أُقۡسِمُ بِهَٰذَا ٱلۡبَلَدِ ١'
    },
    91: {
      'name': 'الشمس',
      'englishName': 'Ash-Shams',
      'numberOfAyahs': 15,
      'text': 'وَٱلشَّمۡسِ وَضُحَىٰهَا ١'
    },
    92: {
      'name': 'الليل',
      'englishName': 'Al-Layl',
      'numberOfAyahs': 21,
      'text': 'وَٱللَّيۡلِ إِذَا يَغۡشَىٰ ١'
    },
    93: {
      'name': 'الضحى',
      'englishName': 'Ad-Duha',
      'numberOfAyahs': 11,
      'text': 'وَٱلضُّحَىٰ ١'
    },
    94: {
      'name': 'الشرح',
      'englishName': 'Ash-Sharh',
      'numberOfAyahs': 8,
      'text': 'أَلَمۡ نَشۡرَحۡ لَكَ صَدۡرَكَ ١'
    },
    95: {
      'name': 'التين',
      'englishName': 'At-Tin',
      'numberOfAyahs': 8,
      'text': 'وَٱلتِّينِ وَٱلزَّيۡتُونِ ١'
    },
    96: {
      'name': 'العلق',
      'englishName': 'Al-Alaq',
      'numberOfAyahs': 19,
      'text': 'ٱقۡرَأۡ بِٱسۡمِ رَبِّكَ ٱلَّذِي خَلَقَ ١'
    },
    97: {
      'name': 'القدر',
      'englishName': 'Al-Qadr',
      'numberOfAyahs': 5,
      'text': 'إِنَّآ أَنزَلۡنَٰهُ فِي لَيۡلَةِ ٱلۡقَدۡرِ ١'
    },
    98: {
      'name': 'البينة',
      'englishName': 'Al-Bayyinah',
      'numberOfAyahs': 8,
      'text': 'لَمۡ يَكُنِ ٱلَّذِينَ كَفَرُواْ مِنۡ أَهۡلِ ٱلۡكِتَٰبِ ١'
    },
    99: {
      'name': 'الزلزلة',
      'englishName': 'Az-Zalzalah',
      'numberOfAyahs': 8,
      'text': 'إِذَا زُلۡزِلَتِ ٱلۡأَرۡضُ زِلۡزَالَهَا ١'
    },
    100: {
      'name': 'العاديات',
      'englishName': 'Al-Adiyat',
      'numberOfAyahs': 11,
      'text': 'وَٱلۡعَٰدِيَٰتِ ضَبۡحًا ١'
    },
    101: {
      'name': 'القارعة',
      'englishName': 'Al-Qari-ah',
      'numberOfAyahs': 11,
      'text': 'ٱلۡقَارِعَةُ ١'
    },
    102: {
      'name': 'التكاثر',
      'englishName': 'At-Takathur',
      'numberOfAyah': 8,
      'text': 'أَلۡهَىٰكُمُ ٱلتَّكَاثُرُ ١'
    },
    103: {
      'name': 'العصر',
      'englishName': 'Al-Asr',
      'numberOfAyahs': 3,
      'text': 'وَٱلۡعَصۡرِ ١ إِنَّ ٱلۡإِنسَٰنَ لَفِي خُسۡrٍ ٢ إِلَّا ٱلَّذِينَ آمَنُواْ ٣'
    },
    104: {
      'name': 'الهمزة',
      'englishName': 'Al-Humazah',
      'numberOfAyahs': 9,
      'text': 'وَيۡلٌ لِّكُلِّ هُمَزَةٍ لُّمَزَةٍ ١'
    },
    105: {
      'name': 'الفيل',
      'englishName': 'Al-Fil',
      'numberOfAyahs': 5,
      'text': 'أَلَمۡ تَرَ كَيۡفَ فَعَلَ رَبُّكَ بِأَصۡحَٰبِ ٱلۡفِيلِ ١'
    },
    106: {
      'name': 'قريش',
      'englishName': 'Quraysh',
      'numberOfAyahs': 4,
      'text': 'لِإِيلَٰفِ قُرَيۡشٍ ١'
    },
    107: {
      'name': 'الماعون',
      'englishName': 'Al-Maun',
      'numberOfAyahs': 7,
      'text': 'أَرَءَيۡتَ ٱلَّذِي يُكَذِّبُ بِٱلدِّينِ ١'
    },
    108: {
      'name': 'الكوثر',
      'englishName': 'Al-Kawthar',
      'numberOfAyahs': 3,
      'text': 'إِنَّآ أَعۡطَيۡنَٰكَ ٱلۡكَوۡثَرَ ١'
    },
    109: {
      'name': 'الكافرون',
      'englishName': 'Al-Kafirun',
      'numberOfAyahs': 6,
      'text': 'قُلۡ يَٰٓأَيُّهَا ٱلۡكَٰفِرُونَ ١'
    },
    110: {
      'name': 'النصر',
      'englishName': 'An-Nasr',
      'numberOfAyahs': 3,
      'text': 'إِذَا جَآءَ نَصۡرُ ٱللَّهِ وَٱلۡفَتۡحُ ١'
    },
    111: {
      'name': 'المسد',
      'englishName': 'Al-Masad',
      'numberOfAyahs': 5,
      'text': 'تَبَّتۡ يَدَآ أَبِي لَهَبٍ وَتَبَّ ١'
    },
    112: {
      'name': 'الإخلاص',
      'englishName': 'Al-Ikhlas',
      'numberOfAyahs': 4,
      'text': 'قُلۡ هُوَ ٱللَّهُ أَحَدٌ  ٱللَّهُ ٱلصَّمَدُ  لَمۡ يَلِدۡ وَلَمۡ يُولَدۡ  وَلَمۡ يَكُن لَّهُۥ كُفُوًا أَحَدٌ '
    },
    113: {
      'name': 'الفلق',
      'englishName': 'Al-Falaq',
      'numberOfAyahs': 5,
      'text': 'قُلۡ أَعُوذُ بِرَبِّ ٱلۡفَلَقِ '
    },
    114: {
      'name': 'الناس',
      'englishName': 'An-Nas',
      'numberOfAyahs': 6,
      'text': 'قُلۡ أَعُوذُ بِرَبِّ ٱلنَّاسِ '
    },
  };

  static Future<void> initialize() async {
    await _cache.initialize();
  }
  
  /// Split a surah's text into individual ayahs
  static List<String> getAyahs(String surahText) {
    if (surahText.isEmpty) return [];
    
    // The ayah number is a reliable delimiter
    final ayahs = surahText.split(RegExp(r'\s*١|٢|٣|٤|٥|٦|٧|٨|٩|٠\s*'));
    
    // Remove any empty strings that result from the split
    return ayahs.where((ayah) => ayah.trim().isNotEmpty).toList();
  }


  /// Get all Surah objects in order
  static List<Surah> getAllSurahs() {
    List<Surah> surahs = [];
    for (int i = 1; i <= 114; i++) {
      final surah = getSurah(i);
      if (surah != null) {
        surahs.add(surah);
      }
    }
    return surahs;
  }

  /// Get a specific Surah by number with caching
  static Surah? getSurah(int number) {
    if (number < 1 || number > 114) return null;

    // Check cache first
    if (_cache.isCached(number)) {
      return _cache.getSurah(number);
    }

    // Get from data
    if (_quranData.containsKey(number)) {
      final data = _quranData[number]!;
      final surah = Surah(
        number: number,
        name: data['name'],
        englishName: data['englishName'],
        numberOfAyahs: data['numberOfAyahs'],
        text: data['text'],
      );

      // Cache it
      _cache.cacheSurah(surah).ignore();

      return surah;
    }

    return null;
  }

  /// Get Surah by English name
  static Surah? getSurahByName(String name) {
    for (int i = 1; i <= 114; i++) {
      final surah = getSurah(i);
      if (surah != null &&
          (surah.name == name ||
              surah.englishName == name ||
              surah.englishName.toLowerCase().contains(name.toLowerCase()))) {
        return surah;
      }
    }
    return null;
  }

  /// Search Surahs
  static List<Surah> searchSurahs(String query) {
    List<Surah> results = [];
    final lowerQuery = query.toLowerCase();

    for (int i = 1; i <= 114; i++) {
      final surah = getSurah(i);
      if (surah != null) {
        if (surah.name.contains(query) ||
            surah.englishName.toLowerCase().contains(lowerQuery)) {
          results.add(surah);
        }
      }
    }

    return results;
  }
}
