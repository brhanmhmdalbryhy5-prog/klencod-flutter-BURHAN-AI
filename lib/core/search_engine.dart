import 'dart:convert';
import 'package:http/http.dart' as http;
import 'db_helper.dart';

class SearchEngine {
  // المفتاح الخاص بك مشفر
  static const String _encodedKey = "QVEuQWI4Uk42S21ja2ZZM3hpaDFlS1hnUkdVZzl0Y2VUckR0UU13MXhGUHh5dWEtTTJxQmc=";
  
  static Future<String> _askGemini(String question, String fileContext) async {
    try {
      final String apiKey = utf8.decode(base64.decode(_encodedKey));

      String prompt = fileContext.isEmpty 
          ? "أجب على السؤال التالي باللغة العربية بأسلوب حواري مرن ومختصر:\n\n$question"
          : """
أنت مساعد ذكي اسمك "برهان AI". 
أجب على سؤال المستخدم بناءً على النص المرفق من ملفه.
إذا لم تكن الإجابة موجودة في النص، قل بوضوح: "لم أجد هذه المعلومة في الملف المرفق".
لا تخترع معلومات من خارج النص. أجب باللغة العربية بأسلوب حواري مرن ومختصر.

النص من الملف:
$fileContext

سؤال المستخدم:
$question
""";

      // تم التحديث إلى نموذج gemini-2.5-flash الأحدث والمستقر
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'close', 
        },
        body: jsonEncode({
          "contents": [
            {"parts": [{"text": prompt}]}
          ]
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return "حدث خطأ من الخادم (كود ${response.statusCode}):\n${response.body}";
      }
    } catch (e) {
      return "تعذر الاتصال بالإنترنت (انتهت المهلة).\nتأكد من قوة إشارة الشبكة لديك.\n\nتفاصيل: $e";
    }
  }

  static Future<String> getAnswer(String userQuestion) async {
    final chunks = await DatabaseHelper.instance.getAllChunks();
    String fileContext = "";

    if (chunks.isNotEmpty) {
      final queryWords = userQuestion.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
      
      chunks.sort((a, b) {
        int scoreA = queryWords.where((w) => a['text'].toString().toLowerCase().contains(w)).length;
        int scoreB = queryWords.where((w) => b['text'].toString().toLowerCase().contains(w)).length;
        return scoreB.compareTo(scoreA);
      });

      if (queryWords.isNotEmpty) {
         fileContext = chunks.take(3).map((c) => c['text']).join('\n---\n');
      }
    }

    return await _askGemini(userQuestion, fileContext);
  }
}