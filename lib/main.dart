import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/db_helper.dart';
import 'core/search_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database; 
  runApp(const BurhanAIApp());
}

class AppTheme {
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF7C3AED);
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(primary: primary, secondary: primaryLight, surface: surface),
        appBarTheme: const AppBarTheme(backgroundColor: surface, foregroundColor: textPrimary, elevation: 0),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface, selectedItemColor: primaryLight, unselectedItemColor: textMuted,
        ),
      );
}

class BurhanAIApp extends StatelessWidget {
  const BurhanAIApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'برهان AI', debugShowCheckedModeBanner: false, theme: AppTheme.dark, home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const ChatScreen(), const FilesScreen(), const HistoryScreen(), const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('برهان AI | Burhan AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), centerTitle: true),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'الدردشة'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: 'الملفات'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'السجل'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isThinking = false;
  int _currentSessionId = -1;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    int sessionId = await DatabaseHelper.instance.createSession('محادثة ${DateTime.now().day}/${DateTime.now().month}');
    setState(() {
      _currentSessionId = sessionId;
      _messages.add({'role': 'assistant', 'text': 'مرحباً! أنا برهان AI. جاهز للإجابة من ملفاتك. (يمكنك تصحيح أي إجابة لتعليمي)', 'id': 0});
    });
  }

  Future<void> _sendMessage({String? customText, bool isCorrection = false}) async {
    String userQuestion = customText ?? _controller.text;
    if (userQuestion.trim().isEmpty || _isThinking) return;

    if (!isCorrection) {
      setState(() {
        _messages.add({'role': 'user', 'text': userQuestion, 'id': _messages.length});
        _controller.clear();
        _isThinking = true;
      });
      await DatabaseHelper.instance.addMessage(_currentSessionId, 'user', userQuestion);
    } else {
      setState(() {
        _messages.add({'role': 'user', 'text': 'الإجابة الصحيحة هي: $userQuestion', 'id': _messages.length});
        _isThinking = true;
      });
      await DatabaseHelper.instance.addLearnedQA(
        _messages[_messages.length - 2]['text'],
        userQuestion
      );
      await DatabaseHelper.instance.addMessage(_currentSessionId, 'assistant', 'شكراً! لقد تعلمت هذه المعلومة.');
    }

    await Future.delayed(const Duration(milliseconds: 600));
    
    String answer = isCorrection 
        ? "شكراً لك! لقد حفظت هذه الإجابة في ذاكرتي الدائمة، وسأستخدمها في المرات القادمة."
        : await SearchEngine.getAnswer(userQuestion);

    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': answer, 'id': _messages.length});
        _isThinking = false;
      });
      await DatabaseHelper.instance.addMessage(_currentSessionId, 'assistant', answer);
    }
  }

  void _showCorrectionDialog() {
    final TextEditingController correctionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('✍️ تصحيح الإجابة', style: TextStyle(color: AppTheme.primaryLight)),
        content: TextField(
          controller: correctionController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'اكتب الإجابة الصحيحة هنا...',
            hintStyle: TextStyle(color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.background,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              Navigator.pop(context);
              if (correctionController.text.isNotEmpty) {
                _sendMessage(customText: correctionController.text, isCorrection: true);
              }
            },
            child: const Text('حفظ وتعلم'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isThinking ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isThinking) {
                return const Align(alignment: Alignment.centerRight, child: Padding(padding: EdgeInsets.all(16), child: Text('برهان يبحث...', style: TextStyle(color: AppTheme.textMuted))));
              }
              
              final msg = _messages[index];
              final isUser = msg['role'] == 'user';
              return Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      decoration: BoxDecoration(
                        gradient: isUser ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]) : null,
                        color: isUser ? null : AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: isUser ? null : Border.all(color: Colors.white12),
                      ),
                      child: Text(msg['text'], style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.5)),
                    ),
                  ),
                  if (!isUser && index > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 8),
                      child: InkWell(
                        onTap: _showCorrectionDialog,
                        child: const Text('✍️ تصحيح الإجابة', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: AppTheme.surface, border: Border(top: BorderSide(color: Colors.white12))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'اكتب سؤالك هنا...', hintStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true, fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppTheme.primary, radius: 24,
                child: IconButton(
                  icon: _isThinking ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _isThinking ? null : () => _sendMessage(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});
  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _savedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadSavedFiles(); 
  }

  Future<void> _loadSavedFiles() async {
    final files = await DatabaseHelper.instance.getAllFiles();
    if (mounted) setState(() => _savedFiles = files);
  }

  Future<void> _pickAndSaveFile() async {
    setState(() => _isLoading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        
        final bytes = await file.readAsBytes();
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        String fullText = PdfTextExtractor(document).extractText();
        int pageCount = document.pages.count;
        document.dispose();

        List<String> words = fullText.split(RegExp(r'\s+'));
        List<String> chunks = [];
        int chunkSize = 150; 
        
        for (int i = 0; i < words.length; i += chunkSize) {
          int end = (i + chunkSize < words.length) ? i + chunkSize : words.length;
          chunks.add(words.sublist(i, end).join(' '));
        }

        String fileHash = fileName + pageCount.toString();
        int fileId = await DatabaseHelper.instance.addFile(fileName, fileHash, pageCount);
        for (int i = 0; i < chunks.length; i++) {
          await DatabaseHelper.instance.addChunk(fileId, i, chunks[i]);
        }

        await _loadSavedFiles();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ تم حفظ "$fileName"!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _generateQuiz(int fileId) async {
    final chunk = await DatabaseHelper.instance.getRandomChunk(fileId);
    if (chunk == null) return;

    List<String> words = chunk['text'].split(' ');
    if (words.length < 6) return;

    String questionPart = words.take(4).join(' ');
    String answerPart = words.skip(4).take(15).join(' ') + '...';

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        bool showAnswer = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: const Text('🎓 اختبرني', style: TextStyle(color: AppTheme.primaryLight)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('أكمل الجملة من الملف:', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                  const SizedBox(height: 12),
                  Text('"$questionPart ........."', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  if (showAnswer) ...[
                    const Text('الإجابة:', style: TextStyle(color: Colors.greenAccent, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('"$answerPart"', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                  ]
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق', style: TextStyle(color: AppTheme.textMuted))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () => setStateDialog(() => showAnswer = true),
                  child: const Text('أظهر الإجابة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
            child: Column(
              children: [
                const Icon(Icons.folder_special, size: 48, color: AppTheme.primaryLight),
                const SizedBox(height: 12),
                const Text('ارفع ملف PDF لحفظه', style: TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator(color: AppTheme.primaryLight)
                    : ElevatedButton.icon(
                        onPressed: _pickAndSaveFile,
                        icon: const Icon(Icons.add), label: const Text('اختيار ملف'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Align(alignment: Alignment.centerRight, child: Text('الملفات المحفوظة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary))),
          const SizedBox(height: 12),
          Expanded(
            child: _savedFiles.isEmpty
                ? const Center(child: Text('لا توجد ملفات محفوظة بعد.', style: TextStyle(color: AppTheme.textMuted)))
                : ListView.builder(
                    itemCount: _savedFiles.length,
                    itemBuilder: (context, index) {
                      final file = _savedFiles[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 36),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(file['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                  Text('${file['total_pages']} صفحة', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(icon: const Icon(Icons.quiz, color: AppTheme.primaryLight), onPressed: () => _generateQuiz(file['id'])),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await DatabaseHelper.instance.getAllSessions();
    if (mounted) setState(() => _sessions = sessions);
  }

  @override
  Widget build(BuildContext context) {
    return _sessions.isEmpty
        ? const Center(child: Text('لا يوجد سجل محادثات بعد.', style: TextStyle(color: AppTheme.textMuted)))
        : ListView.builder(
            itemCount: _sessions.length,
            itemBuilder: (context, index) {
              final session = _sessions[index];
              return ListTile(
                leading: const Icon(Icons.chat, color: AppTheme.primaryLight),
                title: Text(session['title'] ?? 'محادثة', style: const TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text(session['created_at'].toString().substring(0, 16), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              );
            },
          );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _onlineMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _onlineMode = prefs.getBool('online_mode') ?? false;
    });
  }

  Future<void> _toggleOnlineMode(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('online_mode', value);
    setState(() => _onlineMode = value);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Text('إعدادات البحث', style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        SwitchListTile(
          title: const Text('الوضع المتصل (البحث في الإنترنت)', style: TextStyle(color: AppTheme.textPrimary)),
          subtitle: const Text('يبحث في ويكيبيديا عند عدم وجود الإجابة في ملفاتك.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          value: _onlineMode,
          activeColor: AppTheme.primaryLight,
          onChanged: _toggleOnlineMode,
        ),
        const Divider(color: Colors.white12),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Text('حول التطبيق', style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const ListTile(
          title: Text('برهان AI', style: TextStyle(color: AppTheme.textPrimary)),
          subtitle: Text('الإصدار 1.1.0 - يدعم الوضع المتصل', style: TextStyle(color: AppTheme.textMuted)),
          leading: Icon(Icons.smart_toy, color: AppTheme.primaryLight),
        ),
      ],
    );
  }
}