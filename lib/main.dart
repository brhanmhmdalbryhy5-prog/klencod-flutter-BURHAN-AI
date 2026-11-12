import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'core/db_helper.dart';
import 'core/search_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database; 
  runApp(const BurhanAIApp());
}

// --- الألوان والثيم ---
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
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: primaryLight,
          surface: surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textPrimary,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primaryLight,
          unselectedItemColor: textMuted,
        ),
      );
}

class BurhanAIApp extends StatelessWidget {
  const BurhanAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'برهان AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainScreen(),
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
    const ChatScreen(),
    const FilesScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('برهان AI | Burhan AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
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

// --- شاشة الدردشة (محدثة للبحث في الملفات) ---
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'text': 'مرحباً! أنا برهان AI. لقد جهزت ذاكرتي. ارفع ملفاً من تبويب "الملفات" ثم اسألني عنه.'}
  ];
  bool _isThinking = false;

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isThinking) return;
    
    String userQuestion = _controller.text;
    
    setState(() {
      _messages.add({'role': 'user', 'text': userQuestion});
      _controller.clear();
      _isThinking = true;
    });

    // محاكاة تفكير بسيط ثم جلب الإجابة من الملفات
    await Future.delayed(const Duration(milliseconds: 500));
    String answer = await SearchEngine.getAnswer(userQuestion);

    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': answer});
        _isThinking = false;
      });
    }
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
                return const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('برهان يبحث في ملفاتك...', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                );
              }
              
              final msg = _messages[index];
              final isUser = msg['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                  decoration: BoxDecoration(
                    gradient: isUser ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]) : null,
                    color: isUser ? null : AppTheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? Radius.zero : const Radius.circular(16),
                      bottomRight: isUser ? const Radius.circular(16) : Radius.zero,
                    ),
                    border: isUser ? null : Border.all(color: Colors.white12),
                  ),
                  child: Text(msg['text']!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.5)),
                ),
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
                    hintText: 'اكتب سؤالك هنا...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppTheme.primary,
                radius: 24,
                child: IconButton(
                  icon: _isThinking ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _isThinking ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- شاشة الملفات ---
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

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
        int chunkSize = 150; // تم تصغير حجم المقطع لدقة البحث
        
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ تم حفظ "$fileName" في الذاكرة!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                const Icon(Icons.folder_special, size: 48, color: AppTheme.primaryLight),
                const SizedBox(height: 12),
                const Text('ارفع ملف PDF لحفظه في الذاكرة', style: TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator(color: AppTheme.primaryLight)
                    : ElevatedButton.icon(
                        onPressed: _pickAndSaveFile,
                        icon: const Icon(Icons.add),
                        label: const Text('اختيار ملف وحفظه'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('الملفات المحفوظة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ),
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
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 36),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(file['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                  const SizedBox(height: 4),
                                  Text('${file['total_pages']} صفحة | جاهز للإجابة', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                                ],
                              ),
                            ),
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

// --- شاشة السجل ---
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('سجل المحادثات سيظهر هنا قريباً', style: TextStyle(color: AppTheme.textMuted, fontSize: 18)));
  }
}

// --- شاشة الإعدادات ---
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _onlineMode = false;

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
          subtitle: const Text('غير مفعل حالياً في هذه النسخة.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          value: _onlineMode,
          activeColor: AppTheme.primaryLight,
          onChanged: (val) => setState(() => _onlineMode = val),
        ),
        const Divider(color: Colors.white12),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Text('حول التطبيق', style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const ListTile(
          title: Text('برهان AI', style: TextStyle(color: AppTheme.textPrimary)),
          subtitle: Text('الإصدار 1.0.0 - محلي 100%', style: TextStyle(color: AppTheme.textMuted)),
          leading: Icon(Icons.smart_toy, color: AppTheme.primaryLight),
        ),
      ],
    );
  }
}