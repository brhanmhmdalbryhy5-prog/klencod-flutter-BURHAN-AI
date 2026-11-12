import 'db_helper.dart';

class SearchEngine {
  // دالة إزالة التشكيل وتوحيد الحروف لتسهيل البحث
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

  // المحرك الأساسي للبحث والإجابة
  static Future<String> getAnswer(String userQuestion) async {
    final chunks = await DatabaseHelper.instance.getAllChunks();
    
    if (chunks.isEmpty) {
      return "لم تقم برفع أي ملفات بعد. اذهب إلى تبويب 'الملفات' وارفع ملف PDF أولاً، وسأقوم بقراءته والإجابة منه.";
    }

    final normalizedQuestion = _normalize(userQuestion);
    
    // تقسيم السؤال إلى كلمات (تجاهل الكلمات القصيرة جداً مثل "من"، "في")
    final queryWords = normalizedQuestion
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();

    if (queryWords.isEmpty) {
      return "سؤالك غير واضح. هل يمكنك كتابة سؤال يحتوي على كلمات مفتاحية أكثر؟";
    }

    Map<String, dynamic>? bestChunk;
    int highestScore = 0;

    // البحث في جميع المقاطع
    for (var chunk in chunks) {
      String chunkText = _normalize(chunk['text']);
      int currentScore = 0;

      for (String word in queryWords) {
        // إذا كانت الكلمة موجودة في المقطع، نزيد النتيجة
        if (chunkText.contains(word)) {
          currentScore++;
        }
      }

      if (currentScore > highestScore) {
        highestScore = currentScore;
        bestChunk = chunk;
      }
    }

    // إذا وجدنا مقطعاً يحتوي على كلمات مطابقة
    if (bestChunk != null && highestScore > 0) {
      String answerText = bestChunk['text'];
      
      // إذا كان المقطع طويلاً جداً، نأخذ أول 600 حرف منه
      if (answerText.length > 600) {
        answerText = answerText.substring(0, 600) + '...';
      }

      // صياغة الرد بأسلوب حواري مرن (Pattern)
      return "بناءً على ما وجدته في ملفاتك، إليك الإجابة:\n\n$answerText";
    } else {
      // لم يجد أي كلمة مطابقة
      return "بحثت في جميع الملفات المرفوعة ولم أجد معلومات تتعلق بسؤالك. قد تحتاج إلى رفع ملف آخر يحتوي على هذه المعلومة.";
    }
  }
}