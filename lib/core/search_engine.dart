import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';

class SearchEngine {
  static final Random _random = Random();

  static const List<String> _foundPatterns = [
    "بناءً على ما وجدته في مستنداتك:\n\n",
    "لقد راجعت ملفاتك، وإليك ما يتعلق بسؤالك:\n\n",
    "بحسب النص الموجود في ملفاتك:\n\n",
    "وجدت هذه المعلومة في مستنداتك:\n\n",
    "إليك ما ورد في ملفك بخصوص هذا الموضوع:\n\n",
  ];

  static const List<String> _notFoundPatterns = [
    "بحثت في جميع الملفات المرفوعة ولم أجد أي معلومات تطابق سؤالك.",
    "أعتذر منك، لقد راجعت كل ملفاتك ولم أجد إشارة لهذا الموضوع.",
    "لم أتمكن من العثور على إجابة لسؤالك في الملفات الحالية.",
  ];

  static String _normalize(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F]'), '').replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه').replaceAll('ى', 'ي').toLowerCase();
  }

  static String _pickRandom(List<String> list) => list[_random.nextInt(list.length)];

  static double _calculateSimilarity(String s1, String s2) {
    List<String> words1 = s1.split(' ');
    List<String> words2 = s2.split(' ');
    int matches = 0;
    for (var w in words1) {
      if (words2.contains(w)) matches++;
    }
    return words1.isEmpty ? 0 : matches / words1.length;
  }

  static Future<String?> _searchWikipedia(String query) async {
    try {
      String url = "https://ar.wikipedia.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(query)}&format=json&utf8=1&srlimit=1";
      var response = await http.get(Uri.parse(url), headers: {"User-Agent": "BurhanAI/1.0"}).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var searchResults = data['query']['search'];
        if (searchResults != null && searchResults.isNotEmpty) {
          String snippet = searchResults[0]['snippet'];
          snippet = snippet.replaceAll(RegExp(r'<[^>]*>'), '');
          return snippet;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String> getAnswer(String userQuestion) async {
    final normalizedQuestion = _normalize(userQuestion);
    
    final learnedQAs = await DatabaseHelper.instance.getAllLearnedQA();
    for (var qa in learnedQAs) {
      if (_calculateSimilarity(normalizedQuestion, _normalize(qa['question'])) > 0.6) {
        return qa['answer'];
      }
    }

    final chunks = await DatabaseHelper.instance.getAllChunks();
    final queryWords = normalizedQuestion.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
    
    if (queryWords.isEmpty) return "سؤالك غير واضح.";

    Map<String, dynamic>? bestChunk;
    int highestScore = 0;

    for (var chunk in chunks) {
      String chunkText = _normalize(chunk['text']);
      int currentScore = 0;
      for (String word in queryWords) {
        if (chunkText.contains(word)) currentScore++;
      }
      if (currentScore > highestScore) {
        highestScore = currentScore;
        bestChunk = chunk;
      }
    }

    int minMatch = queryWords.length > 3 ? 2 : 1;

    if (bestChunk != null && highestScore >= minMatch) {
      String answerText = bestChunk['text'].replaceAll(RegExp(r'\s+'), ' ').trim();
      if (answerText.length > 500) answerText = answerText.substring(0, 500) + '...';
      return "${_pickRandom(_foundPatterns)}$answerText";
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isOnline = prefs.getBool('online_mode') ?? false;

    if (isOnline) {
      String? wikiAnswer = await _searchWikipedia(userQuestion);
      if (wikiAnswer != null && wikiAnswer.isNotEmpty) {
        return "لم أجد الإجابة في ملفاتك، لكني بحثت في الإنترنت (ويكيبيديا) ووجدت التالي:\n\n🌐 $wikiAnswer\n\n(ملاحظة: هذه المعلومة من الإنترنت وليست من ملفاتك).";
      } else {
        return "لم أجد الإجابة في ملفاتك، وحاولت البحث في الإنترنت لكني لم أجد نتيجة واضحة.";
      }
    }

    return "${_pickRandom(_notFoundPatterns)} (تلميح: يمكنك تفعيل 'الوضع المتصل' من الإعدادات للبحث في الإنترنت).";
  }
}