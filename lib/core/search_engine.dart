import 'dart:math';
import 'db_helper.dart';

class SearchEngine {
  static final Random _random = Random();

  static const List<String> _foundPatterns = [
    "بناءً على ما وجدته في مستنداتك، الإجابة هي:\n\n",
    "لقد بحثت في ملفاتك، وإليك ما يتعلق بسؤالك:\n\n",
    "بحسب النص الموجود في ملفاتك:\n\n",
    "وجدت هذه المعلومة في مستنداتك:\n\n",
    "إليك ما ورد في ملفك بخصوص هذا الموضوع:\n\n",
    "من خلال تحليلي لمحتوى الملف، إليك الإجابة:\n\n",
    "المعلومة التي تبحث عنها موجودة في ملفك وتقول:\n\n",
    "بعد مراجعة البيانات المتاحة لدي، وجدت التالي:\n\n"
  ];

  static const List<String> _notFoundPatterns = [
    "بحثت في جميع الملفات المرفوعة ولم أجد أي معلومات تطابق سؤالك. هل يمكنك إعادة صياغة السؤال أو رفع ملف آخر؟",
    "أعتذر منك، لقد راجعت كل ملفاتك ولم أجد إشارة لهذا الموضوع. ربما تحتاج إلى رفع مستند يغطي هذه النقطة.",
    "لم أتمكن من العثور على إجابة لسؤالك في الملفات الحالية. جرب استخدام كلمات مفتاحية أخرى.",
    "المعلومات المتوفرة لدي في الملفات لا تجيب على هذا السؤال. هل تود سؤالي عن شيء آخر موجود في ملفاتك؟",
    "سؤالك خارج نطاق المعلومات الموجودة في ملفاتك. إذا أردت، يمكنك تفعيل البحث عبر الإنترنت لاحقاً."
  ];

  static const List<String> _vaguePatterns = [
    "سؤالك غير واضح بالنسبة لي. هل يمكنك كتابة المزيد من التفاصيل؟",
    "لم أفهم ما تقصده بالضبط. هل يمكنك صياغة السؤال بطريقة أوضح؟",
    "من فضلك اكتب سؤالاً يحتوي على كلمات مفتاحية أكثر حتى أتمكن من البحث في ملفاتك."
  ];

  static String _normalize(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '') 
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .toLowerCase();
  }

  static String _pickRandom(List<String> list) {
    return list[_random.nextInt(list.length)];
  }

  static Future<String> getAnswer(String userQuestion) async {
    final chunks = await DatabaseHelper.instance.getAllChunks();
    
    if (chunks.isEmpty) {
      return "لم تقم برفع أي ملفات بعد. اذهب إلى تبويب 'الملفات' وارفع ملف PDF أولاً، وسأقوم بقراءته والإجابة منه.";
    }

    final normalizedQuestion = _normalize(userQuestion);
    final queryWords = normalizedQuestion
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();

    if (queryWords.isEmpty) return _pickRandom(_vaguePatterns);

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

    int minMatchRequired = queryWords.length > 3 ? 2 : 1;

    if (bestChunk != null && highestScore >= minMatchRequired) {
      String answerText = bestChunk['text'];
      answerText = answerText.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (answerText.length > 500) {
        answerText = answerText.substring(0, 500) + '...';
      }

      String prefix = _pickRandom(_foundPatterns);
      return "$prefix$answerText";
      
    } else {
      return _pickRandom(_notFoundPatterns);
    }
  }
}