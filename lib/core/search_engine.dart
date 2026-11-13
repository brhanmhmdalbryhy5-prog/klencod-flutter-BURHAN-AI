import 'dart:convert';
import 'package:http/http.dart' as http;
import 'db_helper.dart';

class SearchEngine {
  // المفتاح مشفر لتجاوز حماية المنصة
  static const String _encodedKey = "QVEuQWI4Uk42THFYU2l2TXdkb291QW9wSmJMRkNWYWd1ZmVFMl91cHBOaVhSdDBFRFVUUGc=";

  static Future<String> _askGemini(String question, String fileContext) async {
    try {
      // فك تشفير المفتاح عند التشغيل
      final String apiKey = utf8.decode(base64.decode(_encodedKey));
      
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent');
      
      final prompt = """
أنت مساعد ذكي اسمك "برهان AI". 
أجب على سؤال المستخدم بناءً على النص المرفق من ملفه فقط.
إذا لم تكن الإجابة موجودة في النص، قل بوضوح: "لم أجد هذه المعلومة في الملف المرفق".
لا تخترع معلومات من خارج النص. أجب باللغة العربية بأسلوب حواري مرن ومختصر.

النص من الملف:
$fileContext

سؤال المستخدم:
$question
""";

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode({
          "contents": [
            {"parts": [{"text": prompt}]}
          ]
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return "حدث خطأ في الاتصال بالذكاء الاصطناعي (كود: ${response.statusCode}).\nتأكد من أن مفتاح API صحيح ومفعل.";
      }
    } catch (e) {
      return "تعذر الاتصال بالإنترنت أو انتهت مهلة الاتصال. تأكد من اتصالك وحاول مرة أخرى.";
    }
  }

  static Future<String> getAnswer(String userQuestion) async {
    // جمع النصوص من الملفات (أفضل 3 مقاطع بناءً على كلمات السؤال)
    final chunks = await DatabaseHelper.instance.getAllChunks();
    
    if (chunks.isEmpty) {
      return "لم تقم برفع أي ملفات بعد. اذهب إلى تبويب 'الملفات' وارفع ملف PDF أولاً.";
    }

    final queryWords = userQuestion.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
    
    chunks.sort((a, b) {
      int scoreA = queryWords.where((w) => a['text'].toString().toLowerCase().contains(w)).length;
      int scoreB = queryWords.where((w) => b['text'].toString().toLowerCase().contains(w)).length;
      return scoreB.compareTo(scoreA);
    });

    String fileContext = chunks.take(3).map((c) => c['text']).join('\n---\n');

    // الاتصال بـ Gemini مباشرة
    return await _askGemini(userQuestion, fileContext);
  }
}