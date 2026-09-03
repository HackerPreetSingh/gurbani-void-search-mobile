import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_download_notifier.dart';
import '../../settings/presentation/display_settings_notifier.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  int _expandedIndex = 0; // Default first feature open
  bool _isPunjabiLanguage = false; // Language toggle for walkthrough

  static const Map<String, Map<String, String>> _walkthroughEnglish = {
    "search": {
      "title": "1. Shabad Search & Custom Keyboard",
      "description":
          "Search instantly across Sri Guru Granth Sahib Ji, Dasam Bani, and Vaaran Bhai Gurdas Ji with zero internet required.\n\n"
          "• Gurmukhi First-Letter Search: Type the first letters of words in Gurmukhi (e.g. type 'ਸਸਗ' to find 'ਸੁਣਿਐ ਸਤੁ ਸੰਤੋਖੁ ਗਿਆਨੁ').\n"
          "• Phonetic English Search: Type first letters using English/Roman characters (e.g. type 'kejjb' to find 'ਕਿਨਕਾ ਏਕ ਜਿਸੁ ਜੀਅ ਬਸਾਵੈ').\n"
          "• Middle-of-Line Search: You don't have to start from the beginning! Enter continuous word initials starting from anywhere in a Tukk (e.g. 'sgepjc' will find 'ਚਰਨ ਸਰਨ ਗੁਰ ਏਕ ਪੈਂਡਾ ਜਾਇ ਚਲ').\n"
          "• In-App Custom Keyboard: Tap the keyboard icon in the top-right corner of the Search tab to open the keyboard menu and switch seamlessly between Punjabi (Gurmukhi) and English phonetic keyboard layouts.\n"
          "• Search History: Tap the clock icon next to the search bar to view your recent searches and reload them with a single tap.",
    },
    "reading": {
      "title": "2. Reading Shabads & Display Controls",
      "description":
          "Enjoy a peaceful, respectful, and customizable reading experience when viewing any Shabad.\n\n"
          "• Display Settings Menu: Tap the gear icon (⚙️) in the top-right bar while reading a Shabad to toggle Punjabi meanings, English meanings, English Transliteration, Hindi text, Vishrams (colored pauses), and Larivaar (continuous text).\n"
          "• Vishram Pauses: When enabled, main pauses are highlighted in Green and secondary pauses in Blue to guide proper Gurbani recitation.\n"
          "• Pinch-to-Zoom: Pinch anywhere on the reading screen with two fingers to instantly enlarge or reduce font size.\n"
          "• Shabad Navigation: Tap the left or right floating arrows at the bottom of the screen to jump directly to the previous or next Shabad in the original scripture.\n"
          "• Save to Folders: Tap the folder icon in the top-right bar to save the entire Shabad or the exact highlighted Tukk into your custom Prakaran folders.",
    },
    "prakaran": {
      "title": "3. Prakarans (Custom Shabad Folders)",
      "description":
          "Organize Gurbani Shabads for special events, programs, or daily contemplation.\n\n"
          "• Create Occasion Folders: Build personal folders (e.g. 'Anand Karaj', 'Morning Routine', 'Gurpurab Keertan', 'Sukhmani Sahib Tukks') and save Shabads into them.\n"
          "• Instant Access: Tap the folder icon on the top-left of the Search home screen to view all your folders.\n"
          "• Exact Tukk Highlighting: Tapping any saved entry inside a folder automatically opens the Shabad and scrolls straight to the exact Tukk you saved.",
    },
    "nitnem": {
      "title": "4. Nitnem & Banis (Daily Routine)",
      "description":
          "Read daily prayers in their exact liturgical sequence with custom routine ordering.\n\n"
          "• Drag & Drop Reordering: Hold and drag any Bani up or down in the Nitnem list to match your personal daily Maryada routine.\n"
          "• Sukhmani Sahib Ashtapadi Pagination: Sukhmani Sahib is split into 24 clean Ashtapadis with dark blue Salok styling and bottom page-turning arrows for effortless reading.\n"
          "• Full Customization: Enjoy Vishrams, Larivaar mode, Punjabi/English meanings, and 2-finger Pinch-to-Zoom across all Banis.",
    },
    "sggs": {
      "title": "5. Whole Sri Guru Granth Sahib Ji (1430 Angs)",
      "description":
          "Read the entire holy scripture Ang-by-Ang directly inside the app.\n\n"
          "• Convenient Access: Sri Guru Granth Sahib Ji is included directly in the Bani list (immediately after Aasa Ki Var).\n"
          "• Ang Turning Arrows: Use the bottom left and right floating arrows to turn Angs smoothly from Ang 1 to Ang 1430.\n"
          "• Direct Ang Jump: Tap the 'Ang X / 1430' button at the bottom to open a numeric keypad dialog, type any Ang number (e.g. 500), and jump there instantly.\n"
          "• Reading Options: Fully supports Pinch-to-Zoom, Larivaar script, Vishrams, and translations.",
    },
    "tracker": {
      "title": "6. Nitnem Tracker (Spiritual Progress)",
      "description":
          "Set, track, and manage your spiritual progress with detailed live analytics.\n\n"
          "• Goal Templates: Setup progress trackers for Mool Mantar Jaap, Waheguru Simran, Bani counts, or Sehaj Path.\n"
          "• Flexible Units: Log progress in Raw Units, Maalas (1 Maala = 108 units), or Angs.\n"
          "• Fixed or Infinite Duration: Set a specific deadline date or choose 'No End Date' for continuous daily tracking.\n"
          "• Past Date Logging: Forgot to record yesterday's progress? Select past dates in the calendar to back-log entries accurately.\n"
          "• Live Analytics & Trends: View progress bars, daily averages, required daily targets, and color-coded status badges (Ahead, On Track, Behind).\n"
          "• Goal Management: Tap any goal card for detailed history logs, or swipe left on a goal card to delete it.",
    },
  };

  static const Map<String, Map<String, String>> _walkthroughPunjabi = {
    "search": {
      "title": "੧. ਸ਼ਬਦ ਖੋਜ ਅਤੇ ਕਸਟਮ ਕੀਬੋਰਡ",
      "description":
          "ਸ੍ਰੀ ਗੁਰੂ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ, ਦਸਮ ਬਾਣੀ ਅਤੇ ਭਾਈ ਗੁਰਦਾਸ ਜੀ ਦੀਆਂ ਵਾਰਾਂ ਵਿੱਚ ਤੇਜ਼ੀ ਨਾਲ ਖੋਜ ਕਰੋ। ਪੰਜਾਬੀ ਦੇ ਪਹਿਲੇ ਅੱਖਰਾਂ (ਜਿਵੇਂ: 'ਸਸਗ' ਨਾਲ 'ਸੁਣਿਐ ਸਤੁ ਸੰਤੋਖੁ ਗਿਆਨੁ') ਜਾਂ ਅੰਗਰੇਜ਼ੀ ਫੋਨੇਟਿਕ ਅੱਖਰਾਂ (ਜਿਵੇਂ: 'kejjb' ਨਾਲ 'ਕਿਨਕਾ ਏਕ ਜਿਸੁ ਜੀਅ ਬਸਾਵੈ') ਨਾਲ ਖੋਜ ਕਰੋ। ਤੁਕ ਦੇ ਵਿਚਕਾਰਲੇ ਸ਼ਬਦਾਂ ਨਾਲ ਵੀ ਖੋਜ (ਜਿਵੇਂ: 'sgepjc' ਨਾਲ 'ਚਰਨ ਸਰਨ ਗੁਰ ਏਕ ਪੈਂਡਾ ਜਾਇ ਚਲ') ਕੀਤੀ ਜਾ ਸਕਦੀ ਹੈ। ਕੀਬੋਰਡ ਦਾ ਲੇਆਉਟ ਬਦਲਣ ਲਈ ਉੱਪਰ ਸੱਜੇ ਪਾਸੇ ਕੀਬੋਰਡ ਵਾਲਾ ਆਈਕਨ ਦਬਾਓ। ਪਹਿਲਾਂ ਕੀਤੀਆਂ ਖੋਜਾਂ ਵੇਖਣ ਲਈ ਘੜੀ ਵਾਲਾ ਆਈਕਨ ਦਬਾਓ।",
    },
    "reading": {
      "title": "੨. ਸ਼ਬਦ ਪੜ੍ਹਨਾ ਅਤੇ ਡਿਸਪਲੇਅ ਸੈਟਿੰਗਾਂ",
      "description":
          "ਸ਼ਬਦ ਪੜ੍ਹਦੇ ਸਮੇਂ ਉੱਪਰ ਸੱਜੇ ਪਾਸੇ ਗੀਅਰ (⚙️) ਆਈਕਨ ਦਬਾ ਕੇ ਪੰਜਾਬੀ/ਅੰਗਰੇਜ਼ੀ ਅਰਥ, ਉਚਾਰਨ (Transliteration), ਹਿੰਦੀ ਲਿਖਤ, ਵਿਸ਼ਰਾਮ (ਰੰਗਦਾਰ ਠਹਿਰਾਵ), ਅਤੇ ਲੜੀਵਾਰ ਨੂੰ ਚਾਲੂ ਜਾਂ ਬੰਦ ਕਰੋ। ਦੋ ਉਂਗਲਾਂ ਨਾਲ ਪਿੰਚ-ਟੂ-ਜ਼ੂਮ ਕਰਕੇ ਲਿਖਤ ਦਾ ਆਕਾਰ ਵਧਾਓ ਜਾਂ ਘਟਾਓ। ਹੇਠਾਂ ਖੱਬੇ/ਸੱਜੇ ਤੀਰਾਂ ਨਾਲ ਪਿਛਲੇ ਜਾਂ ਅਗਲੇ ਸ਼ਬਦ 'ਤੇ ਜਾਓ। ਫੋਲਡਰ ਆਈਕਨ ਦਬਾ ਕੇ ਪੂਰਾ ਸ਼ਬਦ ਜਾਂ ਕੋਈ ਖਾਸ ਤੁਕ ਸੰਭਾਲੋ।",
    },
    "prakaran": {
      "title": "੩. ਪ੍ਰਕਰਣ (ਕਸਟਮ ਸ਼ਬਦ ਫੋਲਡਰ)",
      "description":
          "ਆਪਣੇ ਕਸਟਮ ਫੋਲਡਰ (ਜਿਵੇਂ: ਆਨੰਦ ਕਾਰਜ, ਸਵੇਰ ਦੀ ਰੁਟੀਨ) ਬਣਾਓ ਅਤੇ ਵੱਖ-ਵੱਖ ਮੌਕਿਆਂ ਲਈ ਸ਼ਬਦਾਂ ਨੂੰ ਸੁਵਿਧਾਜਨਕ ਢੰਗ ਨਾਲ ਸੰਭਾਲੋ। Search ਟੈਬ ਵਿੱਚ ਉੱਪਰ ਖੱਬੇ ਪਾਸੇ ਵਾਲੇ ਆਈਕਨ ਤੋਂ ਸੰਭਾਲੇ ਹੋਏ ਫੋਲਡਰ ਖੋਲ੍ਹੋ। ਕਿਸੇ ਵੀ ਸੰਭਾਲੀ ਹੋਈ ਐਂਟਰੀ 'ਤੇ ਦਬਾਉਣ ਨਾਲ ਸਿੱਧਾ ਉਸੇ ਤੁਕ 'ਤੇ ਪਹੁੰਚ ਜਾਵੋਗੇ।",
    },
    "nitnem": {
      "title": "੪. ਨਿਤਨੇਮ ਅਤੇ ਬਾਣੀਆਂ",
      "description":
          "ਆਪਣੀ ਰੋਜ਼ਾਨਾ ਦੀ ਮਰਯਾਦਾ ਅਨੁਸਾਰ ਕਿਸੇ ਵੀ ਬਾਣੀ ਨੂੰ ਦਬਾ ਕੇ ਉੱਪਰ ਜਾਂ ਹੇਠਾਂ ਖਿਸਕਾ ਕੇ ਕ੍ਰਮ ਬਦਲੋ। ਸੁਖਮਨੀ ਸਾਹਿਬ ਨੂੰ ੨੪ ਅਸ਼ਟਪਦੀਆਂ ਵਿੱਚ ਵੰਡਿਆ ਗਿਆ ਹੈ, ਜਿਨ੍ਹਾਂ ਵਿੱਚ ਗੂੜ੍ਹੇ ਨੀਲੇ ਰੰਗ ਦੇ ਸਲੋਕ ਅਤੇ ਅੰਗ ਬਦਲਣ ਲਈ ਤੀਰ ਦਿੱਤੇ ਗਏ ਹਨ। ਲੜੀਵਾਰ, ਵਿਸ਼ਰਾਮ ਅਤੇ ਪਿੰਚ-ਟੂ-ਜ਼ੂਮ ਦੀ ਵੀ ਸਹੂਲਤ ਉਪਲਬਧ ਹੈ।",
    },
    "sggs": {
      "title": "੫. ਸੰਪੂਰਨ ਸ੍ਰੀ ਗੁਰੂ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ (੧੪੩੦ ਅੰਗ)",
      "description":
          "ਬਾਣੀਆਂ ਦੀ ਸੂਚੀ ਵਿੱਚ (ਆਸਾ ਕੀ ਵਾਰ ਤੋਂ ਬਾਅਦ) ਸੰਪੂਰਨ ਸ੍ਰੀ ਗੁਰੂ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ ਪੜ੍ਹੋ। ਹੇਠਾਂ ਦਿੱਤੇ ਤੀਰਾਂ ਨਾਲ ਅੰਗ ਬਦਲੋ ਜਾਂ 'Ang X / 1430' 'ਤੇ ਦਬਾ ਕੇ ਮਨਚਾਹਾ ਅੰਗ ਨੰਬਰ ਲਿਖੋ ਅਤੇ ਤੁਰੰਤ ਉਸ ਅੰਗ 'ਤੇ ਪਹੁੰਚੋ।",
    },
    "tracker": {
      "title": "੬. ਨਿਤਨੇਮ ਟਰੈਕਰ (ਆਤਮਿਕ ਤਰੱਕੀ)",
      "description":
          "ਮੂਲ ਮੰਤਰ, ਸਿਮਰਨ, ਬਾਣੀਆਂ ਦੀ ਗਿਣਤੀ ਜਾਂ ਸਹਿਜ ਪਾਠ ਲਈ ਆਪਣੇ ਟੀਚੇ ਬਣਾਓ। Raw Units, ਮਾਲਾ (੧੦੮ ਇਕਾਈਆਂ) ਅਤੇ ਅੰਗਾਂ ਦਾ ਸਮਰਥਨ ਹੈ। ਨਿਰਧਾਰਤ ਸਮਾਂ ਜਾਂ 'ਕੋਈ ਅੰਤਿਮ ਮਿਤੀ ਨਹੀਂ' ਚੁਣ ਸਕਦੇ ਹੋ। ਅੱਜ ਜਾਂ ਪਿਛਲੀਆਂ ਮਿਤੀਆਂ ਦੀ ਪ੍ਰਗਤੀ ਦਰਜ ਕਰੋ। ਲਾਈਵ ਪ੍ਰਗਤੀ ਪੱਟੀ, ਰੋਜ਼ਾਨਾ ਔਸਤ, ਉਮੀਦ ਕੀਤੀ ਪ੍ਰਗਤੀ ਅਤੇ ਰੰਗਾਂ ਰਾਹੀਂ ਸਥਿਤੀ (ਅੱਗੇ, ਸਹੀ ਰਾਹ 'ਤੇ, ਜਾਂ ਪਿੱਛੇ) ਵੇਖੋ। ਕਿਸੇ ਟੀਚੇ ਨੂੰ ਮਿਟਾਉਣ ਲਈ ਖੱਬੇ ਵੱਲ ਸਵਾਈਪ ਕਰੋ।",
    },
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isBold = ref.watch(boldTextSettingsProvider).value ?? false;
    final walkthroughData = _isPunjabiLanguage ? _walkthroughPunjabi : _walkthroughEnglish;
    final featureKeys = ["search", "reading", "prakaran", "nitnem", "sggs", "tracker"];

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // --- 1. TOP ACTION CONTROLS ---
              Card(
                color: Colors.teal.shade50.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.teal.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SwitchListTile(
                    secondary: const Icon(Icons.format_bold, size: 28, color: Colors.teal),
                    title: Text(
                      'Bold Text Mode (A-Z Bold)',
                      style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Make all text across the entire app bold for easier reading.',
                      style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
                    ),
                    value: isBold,
                    activeThumbColor: Colors.teal,
                    onChanged: (_) {
                      ref.read(boldTextSettingsProvider.notifier).toggleBoldText();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                color: Colors.teal.shade50.withValues(alpha: 0.3),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.teal.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_download_outlined, color: Colors.teal, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Offline Gurbani Database',
                              style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.w600),
                            ),
                            Text(
                              'Download or update the full offline database',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showDownloadDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text('Update', style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 20),

              // --- 2. INTERACTIVE FEATURE WALKTHROUGH ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _isPunjabiLanguage ? 'ਐਪ ਦੇ ਫੀਚਰਾਂ ਦੀ ਪੂਰੀ ਜਾਣਕਾਰੀ' : 'Interactive Feature Guide',
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.teal,
                        fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
                      ),
                    ),
                  ),
                  // Language Toggle Switch
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LangChip(
                          label: 'EN',
                          isSelected: !_isPunjabiLanguage,
                          onTap: () => setState(() => _isPunjabiLanguage = false),
                          isBold: isBold,
                        ),
                        _LangChip(
                          label: 'ਪੰਜਾਬੀ',
                          isSelected: _isPunjabiLanguage,
                          onTap: () => setState(() => _isPunjabiLanguage = true),
                          isBold: isBold,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _isPunjabiLanguage 
                    ? 'ਕਿਸੇ ਵੀ ਫੀਚਰ \'ਤੇ ਦਬਾਓ ਅਤੇ ਉਸ ਬਾਰੇ ਪੂਰੀ ਜਾਣਕਾਰੀ ਪੜ੍ਹੋ:'
                    : 'Tap on any feature below to expand and learn how to use it:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
              ),
              const SizedBox(height: 16),

              // Accordion List
              Column(
                children: List.generate(featureKeys.length, (index) {
                  final key = featureKeys[index];
                  final item = walkthroughData[key]!;
                  final isExpanded = _expandedIndex == index;
                  final IconData icon = _getFeatureIcon(index);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: isExpanded ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isExpanded ? Colors.teal : Colors.grey.shade300,
                        width: isExpanded ? 1.5 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _expandedIndex = isExpanded ? -1 : index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isExpanded ? Colors.teal : Colors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: isExpanded ? Colors.white : Colors.teal, size: 22),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    item['title']!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
                                      color: isExpanded ? Colors.teal.shade900 : Colors.black87,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: isExpanded ? Colors.teal : Colors.grey,
                                ),
                              ],
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                              Text(
                                item['description']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),

              // --- 3. MISSION, CREDITS & FOOTER AT BOTTOM ---
              Text(
                'About This App',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Gurbani Search is a labor of love, built to help the global Sangat connect with Gurbani through a high-performance, offline-first experience. Our mission is to provide reliable and respectful access to spiritual wisdom, regardless of internet connectivity.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 28),
              Text(
                'Special Thanks & Credits:',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This application would not be possible without the foundational research, data API, and open-source contributions provided by:',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 12),
              BulletPoint(text: 'The BaniDB Team for their robust Gurbani API.', isBold: isBold),
              BulletPoint(text: 'Akal Technologies for their pioneering research in Gurbani technology.', isBold: isBold),
              BulletPoint(text: 'The Khalis Foundation & STTM teams for their dedication to digital Gurbani preservation.', isBold: isBold),

              const SizedBox(height: 48),
              Center(
                child: Text(
                  'May this small tool be a companion on your spiritual journey.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFeatureIcon(int index) {
    switch (index) {
      case 0: return Icons.search;
      case 1: return Icons.menu_book;
      case 2: return Icons.folder_special;
      case 3: return Icons.auto_stories;
      case 4: return Icons.import_contacts;
      case 5: return Icons.track_changes;
      default: return Icons.help_outline;
    }
  }

  void _showDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Database Update', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                const _ManualDownloadView(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isBold;

  const _LangChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isBold,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.teal.shade900,
            fontWeight: isBold || isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ManualDownloadView extends ConsumerWidget {
  const _ManualDownloadView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(databaseDownloadProvider);
    final downloadNotifier = ref.read(databaseDownloadProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (downloadState.status == DownloadStatus.downloading) ...[
          const Icon(Icons.downloading, size: 48, color: Colors.teal),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: downloadState.progress),
          const SizedBox(height: 8),
          Text(
            downloadState.progress != null && downloadState.progress! >= 0
                ? 'Downloading: ${(downloadState.progress! * 100).toStringAsFixed(1)}%'
                : 'Starting download...',
          ),
        ] else if (downloadState.status == DownloadStatus.idle || downloadState.status == DownloadStatus.error) ...[
          const Icon(Icons.cloud_download, size: 48, color: Colors.teal),
          const SizedBox(height: 16),
          const Text(
            'Click below to refresh the offline Gurbani database files.',
            textAlign: TextAlign.center,
          ),
          if (downloadState.status == DownloadStatus.error)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Error: ${downloadState.errorMessage}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => downloadNotifier.downloadDatabase(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Start Download'),
          ),
        ] else if (downloadState.status == DownloadStatus.success) ...[
          const Icon(Icons.check_circle, size: 48, color: Colors.green),
          const SizedBox(height: 16),
          const Text('Database updated successfully!'),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ],
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;
  final bool isBold;

  const BulletPoint({super.key, required this.text, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
