import 'dart:math';
import 'db_helper.dart';

class SearchEngine {
  static final Random _random = Random();

  // 1. قوالب حوارية مرنة (عند إيجاد إجابة)
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

  // 2. قوالب حوارية مرنة (عند عدم إيجاد إجابة)
  static const List<String> _notFoundPatterns = [
    "بحثت في جميع الملفات المرفوعة ولم أجد أي معلومات تطابق سؤالك. هل يمكنك إعادة صياغة السؤال أو رفع ملف آخر؟",
    "أعتذر منك، لقد راجعت كل ملفاتك ولم أجد إشارة لهذا الموضوع. ربما تحتاج إلى رفع مستند يغطي هذه النقطة.",
    "لم أتمكن من العثور على إجابة لسؤالك في الملفات الحالية. جرب استخدام كلمات مفتاحية أخرى.",
    "المعلومات المتوفرة لدي في الملفات لا تجيب على هذا السؤال. هل تود سؤالي عن شيء آخر موجود في ملفاتك؟",
    "سؤالك خارج نطاق المعلومات الموجودة في ملفاتك. إذا أردت، يمكنك تفعيل البحث عبر الإنترنت لاحقاً."
  ];

  // 3. قوالب حوارية (إذا كان السؤال قصيراً جداً أو غير مفهوم)
  static const List<String> _vaguePatterns = [
    "سؤالك غير واضح بالنسبة لي. هل يمكنك كتابة المزيد من التفاصيل؟",
    "لم أفهم ما تقصده بالضبط. هل يمكنك صياغة السؤال بطريقة أوضح؟",
    "من فضلك اكتب سؤالاً يحتوي على كلمات مفتاحية أكثر حتى أتمكن من البحث في ملفاتك."
  ];

  // دالة إزالة التشكيل وتوحيد الحروف
  static String _normalize(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '') // إزالة التشكيل
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .toLowerCase();
  }

  // اختيار قالب عشوائي
  static String _pickRandom(List<String> list) {
    return list[_random.nextInt(list.length)];
  }

  // المحرك الأساسي للبحث والإجابة
  static Future<String> getAnswer(String userQuestion) async {
    final chunks = await DatabaseHelper.instance.getAllChunks();
    
    if (chunks.isEmpty) {
      return "لم تقم برفع أي ملفات بعد. اذهب إلى تبويب 'الملفات' وارفع ملف PDF أولاً، وسأقوم بقراءته والإجابة منه.";
    }

    final normalizedQuestion = _normalize(userQuestion);
    
    // تقسيم السؤال إلى كلمات
    final queryWords = normalizedQuestion
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2) // تجاهل الكلمات القصيرة
        .toList();

    if (queryWords.isEmpty) {
      return _pickRandom(_vaguePatterns);
    }

    Map<String, dynamic>? bestChunk;
    int highestScore = 0;

    // البحث في جميع المقاطع
    for (var chunk in chunks) {
      String chunkText = _normalize(chunk['text']);
      int currentScore = 0;

      for (String word in queryWords) {
        if (chunkText.contains(word)) {
          currentScore++;
        }
      }

      if (currentScore > highestScore) {
        highestScore = currentScore;
        bestChunk = chunk;
      }
    }

    // شرط ذكي: يجب أن يتطابق على الأقل كلمتين (أو كلمة واحدة إذا كان السؤال قصيراً)
    int minMatchRequired = queryWords.length > 3 ? 2 : 1;

    if (bestChunk != null && highestScore >= minMatchRequired) {
      String answerText = bestChunk['text'];
      
      // تنظيف النص من الفراغات الزائدة
      answerText = answerText.replaceAll(RegExp(r'\s+'), ' ').trim();

      // إذا كان المقطع طويلاً جداً، نأخذ جزءاً منه
      if (answerText.length > 500) {
        answerText = answerText.substring(0, 500) + '...';
      }

      // دمج القالب العشوائي مع النص
      String prefix = _pickRandom(_foundPatterns);
      return "$prefix$answerText";
      
    } else {
      // لم يجد تطابقاً كافياً
      return _pickRandom(_notFoundPatterns);
    }
  }
}