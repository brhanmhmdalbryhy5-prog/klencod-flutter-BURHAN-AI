import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BurhanAIApp());
}

// --- الألوان المتدرجة (تم نقلها من الكود الخاص بك) ---
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

// --- الشاشة الرئيسية التي تدير التنقل ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // قائمة الشاشات
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
        title: const Text(
          'برهان AI | Burhan AI',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'برهان AI',
                applicationVersion: '1.0.0',
                applicationLegalese: 'مساعد ذكاء اصطناعي محلي يعمل بدون إنترنت.',
              );
            },
          )
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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

// --- 1. شاشة الدردشة ---
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'text': 'مرحباً! أنا برهان AI. ارفع ملفاً من تبويب "الملفات" ثم اسألني عنه.'}
  ];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': _controller.text});
      _controller.clear();
      // رد وهمي للتجربة
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _messages.add({'role': 'assistant', 'text': 'هذا رد تجريبي. لقد استلمت رسالتك وسأجيبك من الملفات قريباً.'});
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)])
                        : null,
                    color: isUser ? null : AppTheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? Radius.zero : const Radius.circular(16),
                      bottomRight: isUser ? const Radius.circular(16) : Radius.zero,
                    ),
                    border: isUser ? null : Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    msg['text']!,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.5),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
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
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- 2. شاشة الملفات ---
class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

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
                const Icon(Icons.cloud_upload_outlined, size: 48, color: AppTheme.primaryLight),
                const SizedBox(height: 12),
                const Text('ارفع ملف PDF أو DOCX أو TXT', style: TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text('الحد الأقصى 300 صفحة للملف', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // هنا سنضع كود اختيار الملف لاحقاً
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('سيتم تفعيل اختيار الملفات في الخطوة القادمة!')),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('اختيار ملف'),
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
            child: Text('ملفاتك:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _buildFileCard('كتاب_الفيزياء.pdf', '280 صفحة | جاهز', isReady: true),
                _buildFileCard('ملاحظات_الاجتماع.pdf', '45 صفحة | 60% قيد الفهرسة', isReady: false),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFileCard(String name, String details, {required bool isReady}) {
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
          Icon(Icons.picture_as_pdf, color: isReady ? Colors.redAccent : Colors.orange, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(details, style: TextStyle(color: isReady ? Colors.greenAccent : Colors.orange, fontSize: 12)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted), onPressed: () {}),
        ],
      ),
    );
  }
}

// --- 3. شاشة السجل ---
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('سجل المحادثات سيظهر هنا', style: TextStyle(color: AppTheme.textMuted, fontSize: 18)),
    );
  }
}

// --- 4. شاشة الإعدادات ---
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
        _buildSectionTitle('إعدادات البحث'),
        SwitchListTile(
          title: const Text('الوضع المتصل (البحث في الإنترنت)', style: TextStyle(color: AppTheme.textPrimary)),
          subtitle: const Text('يستخدم ويكيبيديا لتوضيح ما ليس في ملفاتك.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          value: _onlineMode,
          activeColor: AppTheme.primaryLight,
          onChanged: (val) {
            setState(() { _onlineMode = val; });
          },
        ),
        const Divider(color: Colors.white12),
        _buildSectionTitle('إعدادات الملفات'),
        ListTile(
          title: const Text('الحد الأقصى للصفحات', style: TextStyle(color: AppTheme.textPrimary)),
          subtitle: const Text('300 صفحة لكل ملف', style: TextStyle(color: AppTheme.textMuted)),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          onTap: () {},
        ),
        const Divider(color: Colors.white12),
        _buildSectionTitle('حول التطبيق'),
        const ListTile(
          title: Text('برهان AI', style: TextStyle(color: AppTheme.textPrimary)),
          subtitle: Text('الإصدار 1.0.0 - محلي 100%', style: TextStyle(color: AppTheme.textMuted)),
          leading: Icon(Icons.smart_toy, color: AppTheme.primaryLight),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Text(title, style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}