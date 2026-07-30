import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

// Виджет для фонового зацикленного видео
class LoopingVideoCover extends StatefulWidget {
  final String videoPath;
  const LoopingVideoCover({super.key, required this.videoPath});

  @override
  State<LoopingVideoCover> createState() => _LoopingVideoCoverState();
}

class _LoopingVideoCoverState extends State<LoopingVideoCover> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.videoPath.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
    } else if (widget.videoPath.startsWith('asset:')) {
      _controller = VideoPlayerController.asset(widget.videoPath.substring(6));
    } else {
      _controller = VideoPlayerController.file(File(widget.videoPath));
    }
    
    _controller.initialize().then((_) {
      _controller.setLooping(true);
      _controller.setVolume(0.0);
      _controller.play();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      );
    } else {
      return Container(color: Colors.black26);
    }
  }
}

// Флаг для переключения режима интерфейса:
// true  - режим "Киоск в ТЦ" (гигантские масштабированные элементы, крупные шрифты и отступы)
// false - режим "Разработка на ПК" (стандартные компактные мобильные размеры для удобного тестирования)
bool isKioskMode = true;

// Конфигурация API — KIE.AI
String aiApiProvider = 'Nano Banana Pro';
String aiApiKey = '';

// Списки элементов каталогов (глобальные, чтобы к ним был легкий доступ из любого экрана)
List<VipTemplate> photoTemplatesList = [];
List<VipTemplate> videoTemplatesList = [];
List<VipGame> gamesCatalogList = [];
List<VipTrend> trendsCatalogList = [];



// Пресеты градиентов для админки
final List<Map<String, dynamic>> _presets = [
  {
    'name': 'Золотой',
    'colors': [const Color(0xFFCF9E42), const Color(0xFF966C25)],
    'glow': const Color(0xFFCF9E42)
  },
  {
    'name': 'Киберпанк',
    'colors': [const Color(0xFF00E5FF), const Color(0xFFF72585)],
    'glow': const Color(0xFF00E5FF)
  },
  {
    'name': 'Фиолетовый',
    'colors': [const Color(0xFF9D4EDD), const Color(0xFF6C25FF)],
    'glow': const Color(0xFF9D4EDD)
  },
  {
    'name': 'Неон',
    'colors': [const Color(0xFF6C25FF), const Color(0xFF00E5FF)],
    'glow': const Color(0xFF6C25FF)
  },
  {
    'name': 'Малина',
    'colors': [const Color(0xFFF72585), const Color(0xFF7209B7)],
    'glow': const Color(0xFFF72585)
  },
  {
    'name': 'Серый',
    'colors': [const Color(0xFF2C2C2C), const Color(0xFF000000)],
    'glow': const Color(0xFF888888)
  },
];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trendum VIP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: LuxuryColors.bgDark,
        fontFamily: 'Roboto', // Используем стандартный, но настроем стили
      ),
      home: const MainScreen(),
    );
  }
}

class LuxuryColors {
  static const Color bgDark = Color(0xFF07060B);
  static const Color bgDarker = Color(0xFF0C0A15);
  
  static const Gradient goldGradient = LinearGradient(
    colors: [
      Color(0xFFCF9E42), // Роскошный золотой
      Color(0xFFF5DA8A), // Светлое золото
      Color(0xFFE9C369), // Среднее золото
      Color(0xFF966C25), // Темное золото
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient goldTextGradient = LinearGradient(
    colors: [
      Color(0xFFF5DA8A),
      Color(0xFFCF9E42),
      Color(0xFF966C25),
      Color(0xFFF5DA8A),
    ],
  );

  static const Gradient glassBorderGradient = LinearGradient(
    colors: [
      Color(0x40FFFFFF), // Полупрозрачный белый
      Color(0x08FFFFFF),
      Color(0x2BFFD700), // Полупрозрачный золотой для премиум-блеска
      Color(0x05FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient premiumCardGradient = LinearGradient(
    colors: [
      Color(0x18FFE89C), // Легкий золотой оттенок
      Color(0x03FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Градиентная рамка для эффекта стекла
class GradientBorderPainter extends CustomPainter {
  final double width;
  final double borderRadius;
  final Gradient gradient;

  GradientBorderPainter({
    required this.width,
    required this.borderRadius,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant GradientBorderPainter oldDelegate) {
    return oldDelegate.width != width ||
           oldDelegate.borderRadius != borderRadius ||
           oldDelegate.gradient != gradient;
  }
}

// Контейнер с эффектом глассморфизма
class GlassContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final double borderWidth;
  final Widget child;
  final Gradient? gradient;
  final Gradient? borderGradient;

  const GlassContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 24.0,
    this.blur = 20.0,
    this.borderWidth = 1.0,
    required this.child,
    this.gradient,
    this.borderGradient,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GradientBorderPainter(
        width: borderWidth,
        borderRadius: borderRadius,
        gradient: borderGradient ?? LuxuryColors.glassBorderGradient,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: gradient ?? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.04),
                  Colors.white.withValues(alpha: 0.01),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int _logoClickCount = 0;
  DateTime? _lastLogoClickTime;
  bool _showAdminPanel = false;
  late TextEditingController _apiKeyController;
  
  // Контроллер для анимации фоновых сфер
  late AnimationController _bgAnimationController;
  // Контроллер для анимации появления контента
  late AnimationController _contentAnimationController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: aiApiKey);
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _contentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentAnimationController.forward();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _contentAnimationController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }




  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Темный базовый градиентный фон
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  LuxuryColors.bgDark,
                  Color(0xFF0F0B1E),
                  LuxuryColors.bgDark,
                ],
              ),
            ),
          ),

          // 2. Анимированные фоновые светящиеся сферы (без тяжелого размытия всего экрана)
          AnimatedBuilder(
            animation: _bgAnimationController,
            builder: (context, child) {
              final double animVal = _bgAnimationController.value * 2 * math.pi;
              
              // Расчет траекторий сфер
              final double sphere1X = size.width * 0.1 + math.sin(animVal) * 80;
              final double sphere1Y = size.height * 0.2 + math.cos(animVal) * 80;

              final double sphere2X = size.width * 0.8 + math.cos(animVal + 2) * 120;
              final double sphere2Y = size.height * 0.7 + math.sin(animVal + 1) * 100;

              final double sphere3X = size.width * 0.3 + math.sin(animVal + 4) * 100;
              final double sphere3Y = size.height * 0.8 + math.cos(animVal + 3) * 70;

              return Stack(
                children: [
                  // Сфера 1 - Фиолетовая
                  Positioned(
                    left: sphere1X - 150,
                    top: sphere1Y - 150,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF6C25FF).withValues(alpha: 0.25),
                            const Color(0xFF6C25FF).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Сфера 2 - Золотая
                  Positioned(
                    left: sphere2X - 200,
                    top: sphere2Y - 200,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFCF9E42).withValues(alpha: 0.18),
                            const Color(0xFFCF9E42).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Сфера 3 - Бирюзовая/Синяя
                  Positioned(
                    left: sphere3X - 170,
                    top: sphere3Y - 170,
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF00E5FF).withValues(alpha: 0.12),
                            const Color(0xFF00E5FF).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 3. Основной контент и интерфейс
          SafeArea(
            bottom: false, // Отключаем автоотступ снизу в SafeArea, так как используем bottomNavigationBar
            child: Padding(
              padding: EdgeInsets.only(
                top: isKioskMode ? 24.0 : 12.0,
                left: isKioskMode ? 24.0 : 16.0,
                right: isKioskMode ? 24.0 : 16.0,
              ),
              child: Column(
                children: [
                  // Шапка для мобильных
                  _buildMobileHeader(context),
                  SizedBox(height: isKioskMode ? 48.0 : 8.0),
                  // Основной контент
                  Expanded(
                    child: _buildMainContent(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Логотип с золотым градиентным текстом
  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LuxuryColors.goldGradient.createShader(bounds),
          child: Icon(
            Icons.stacked_line_chart_rounded, // График с несколькими кривыми/линиями
            size: isKioskMode ? 90 : 24, // Сделали компактнее для ПК
            color: Colors.white,
          ),
        ),
        SizedBox(width: isKioskMode ? 32 : 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LuxuryColors.goldTextGradient.createShader(bounds),
              child: Text(
                'TRENDUM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isKioskMode ? 72 : 18, // Сделали компактнее для ПК
                  fontWeight: FontWeight.w900,
                  letterSpacing: isKioskMode ? 8.0 : 3.0,
                ),
              ),
            ),
            Text(
              'ИНТЕРАКТИВНЫЙ КИОСК',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: isKioskMode ? 22 : 8, // Сделали компактнее для ПК
                fontWeight: FontWeight.w700,
                letterSpacing: isKioskMode ? 4.0 : 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Мобильная шапка
  Widget _buildMobileHeader(BuildContext context) {
    return GlassContainer(
      borderRadius: isKioskMode ? 32 : 12, // Сделали компактнее для ПК
      child: Padding(
        padding: isKioskMode
            ? const EdgeInsets.symmetric(horizontal: 48, vertical: 56)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Сделали компактнее для ПК
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onLogoTap,
            child: _buildLogo(), // Выровнено по центру, аватар убран
          ),
        ),
      ),
    );
  }

  void _onLogoTap() {
    final now = DateTime.now();
    if (_lastLogoClickTime == null || now.difference(_lastLogoClickTime!) > const Duration(seconds: 3)) {
      _logoClickCount = 1;
    } else {
      _logoClickCount++;
    }
    _lastLogoClickTime = now;

    if (_logoClickCount >= 6) {
      _logoClickCount = 0;
      _showPinDialog();
    }
  }

  void _showPinDialog() {
    final TextEditingController pinCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F0B1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFCF9E42), width: 1.5),
          ),
          title: const Text(
            'Вход в админ-панель',
            style: TextStyle(color: Color(0xFFF5DA8A), fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Введите PIN-код для доступа:',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8.0),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  counterText: '',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFCF9E42)),
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                if (pinCtrl.text == '3944') {
                  Navigator.pop(context);
                  setState(() {
                    _showAdminPanel = true;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Неверный PIN-код!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Войти', style: TextStyle(color: Color(0xFFCF9E42), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Сборка основного контента с анимацией переключения
  Widget _buildMainContent(BuildContext context) {
    return FadeTransition(
      opacity: _contentAnimationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _contentAnimationController,
          curve: Curves.easeOutCubic,
        )),
        child: _getSelectedPage(),
      ),
    );
  }

  // Роутинг страниц на основе выбранного индекса
  Widget _getSelectedPage() {
    if (_showAdminPanel) {
      return _buildAdminPanelScreen();
    }
    switch (_selectedIndex) {
      case 0:
        return const VipTrendsPage();
      case 1:
        return const PremiumClubPage();
      case 2:
        return const VipAssetsPage();
      case 3:
        return const VipSettingsPage();
      default:
        return const VipTrendsPage();
    }
  }

  // ==========================================
  // АДМИНИСТРАТИВНАЯ ПАНЕЛЬ УПРАВЛЕНИЯ
  // ==========================================
  Widget _buildAdminPanelScreen() {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          // Шапка админки
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Панель Администратора',
                  style: TextStyle(
                    color: Color(0xFFF5DA8A),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.redAccent, width: 1.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() {
                      _showAdminPanel = false;
                    });
                  },
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: const Text('Выйти'),
                ),
              ],
            ),
          ),

          // Таб-бар
          const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFFCF9E42),
            labelColor: Color(0xFFF5DA8A),
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.settings), text: 'Настройки'),
              Tab(icon: Icon(Icons.camera_enhance), text: 'Шаблоны Фото'),
              Tab(icon: Icon(Icons.play_circle_filled), text: 'Шаблоны Видео'),
              Tab(icon: Icon(Icons.sports_esports), text: 'Игры'),
              Tab(icon: Icon(Icons.music_note), text: 'Тренды'),
            ],
          ),

          const SizedBox(height: 16),

          // Содержимое вкладок
          Expanded(
            child: TabBarView(
              children: [
                _buildAdminSettingsTab(),
                _buildAdminTemplatesTab(isPhoto: true),
                _buildAdminTemplatesTab(isPhoto: false),
                _buildAdminGamesTab(),
                _buildAdminTrendsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdminSectionTitle('Общие параметры киоска'),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Режим киоска (Крупный масштаб)', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Увеличивает все шрифты и отступы под экраны ТЦ', style: TextStyle(color: Colors.white60)),
            activeThumbColor: const Color(0xFFCF9E42),
            value: isKioskMode,
            onChanged: (val) {
              setState(() {
                isKioskMode = val;
              });
            },
          ),
          const Divider(color: Colors.white24, height: 32),
          _buildAdminSectionTitle('Настройки ИИ — KIE.AI'),
          const SizedBox(height: 16),

          // Карточка провайдера
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCF9E42).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFCF9E42), Color(0xFFF5DA8A)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KIE.AI', style: TextStyle(color: Color(0xFFF5DA8A), fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Nano Banana 2 (Фото) · Gemini Omni Video (Видео)', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ade80).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4ade80).withValues(alpha: 0.4)),
                  ),
                  child: const Text('Активен', style: TextStyle(color: Color(0xFF4ade80), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text('API Ключ KIE.AI:', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          const Text('Получить ключ: kie.ai → Dashboard → API Keys', style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'sk-xxxxxxxxxxxxxxxxxxxxxxxx',
              hintStyle: const TextStyle(color: Colors.white30),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFCF9E42)),
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFFCF9E42), size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.white38, size: 18),
                onPressed: () {},
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
            ),
            onChanged: (val) {
              aiApiKey = val;
              aiApiProvider = 'Nano Banana Pro';
            },
          ),

          const SizedBox(height: 12),
          // Инфо-блок
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6C25FF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6C25FF).withValues(alpha: 0.25)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF9D4EDD), size: 14),
                  SizedBox(width: 6),
                  Text('Использование токенов', style: TextStyle(color: Color(0xFF9D4EDD), fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
                SizedBox(height: 6),
                Text('📸 Фото (2K): ~\$0.06 ≈ 5 сом за генерацию', style: TextStyle(color: Colors.white54, fontSize: 11)),
                SizedBox(height: 2),
                Text('🎬 Видео 10с (1080P): ~\$0.63 ≈ 55 сом за генерацию', style: TextStyle(color: Colors.white54, fontSize: 11)),
                SizedBox(height: 2),
                Text('💡 Пополните баланс на KIE.AI для получения бонуса −10%', style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: Color(0xFFF5DA8A), fontSize: 18, fontWeight: FontWeight.bold),
    );
  }



  Widget _buildAdminTemplatesTab({required bool isPhoto}) {
    final List<VipTemplate> list = isPhoto ? photoTemplatesList : videoTemplatesList;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF9E42),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _showAddTemplateDialog(isPhoto),
            icon: const Icon(Icons.add),
            label: Text(isPhoto ? 'Добавить шаблон Фото' : 'Добавить шаблон Видео'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                color: Colors.white.withValues(alpha: 0.03),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white10),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: ListTile(
                  leading: (item.coverImageBytes != null || (item.coverImagePath != null && item.coverImagePath!.isNotEmpty))
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 36,
                            height: 48,
                            child: item.coverImageBytes != null
                                ? Image.memory(item.coverImageBytes!, fit: BoxFit.cover)
                                : item.coverImagePath!.endsWith('.mp4') || item.coverImagePath!.endsWith('.mov')
                                    ? LoopingVideoCover(videoPath: item.coverImagePath!)
                                    : item.coverImagePath!.startsWith('http')
                                        ? Image.network(
                                            item.coverImagePath!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image, color: Colors.white54),
                                          )
                                        : item.coverImagePath!.startsWith('asset:')
                                            ? Image.asset(
                                                item.coverImagePath!.substring(6),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(Icons.broken_image, color: Colors.white54),
                                              )
                                            : Image.file(
                                                File(item.coverImagePath!),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(Icons.broken_image, color: Colors.white54),
                                              ),
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: item.shimmerColor.withValues(alpha: 0.2),
                          child: Icon(item.icon, color: Colors.white),
                        ),
                  title: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Цвета: ', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          Container(width: 12, height: 12, color: item.gradientColors[0]),
                          const SizedBox(width: 4),
                          Container(width: 12, height: 12, color: item.gradientColors[1]),
                        ],
                      ),
                      if (item.coverImagePath != null && item.coverImagePath!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.image_outlined, color: Color(0xFFCF9E42), size: 12),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.coverImagePath!.split(RegExp(r'[/\\]')).last,
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Обложка не установлена',
                            style: TextStyle(color: Colors.white30, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        list.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminGamesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF9E42),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showAddGameDialog,
            icon: const Icon(Icons.add),
            label: const Text('Добавить игру'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: gamesCatalogList.length,
            itemBuilder: (context, index) {
              final game = gamesCatalogList[index];
              return Card(
                color: Colors.white.withValues(alpha: 0.03),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white10),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: game.glowColor.withValues(alpha: 0.2),
                    child: Icon(game.icon, color: Colors.white),
                  ),
                  title: Text(game.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    game.hasCameraMode ? 'Камера (Жесты) + Смартфон' : 'Только Смартфон',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        gamesCatalogList.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminTrendsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF9E42),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showAddTrendDialog,
            icon: const Icon(Icons.add),
            label: const Text('Добавить видео-тренд'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: trendsCatalogList.length,
            itemBuilder: (context, index) {
              final trend = trendsCatalogList[index];
              return Card(
                color: Colors.white.withValues(alpha: 0.03),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white10),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: trend.glowColor.withValues(alpha: 0.2),
                    child: Icon(trend.icon, color: Colors.white),
                  ),
                  title: Text(trend.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        trendsCatalogList.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddTemplateDialog(bool isPhoto) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController promptCtrl = TextEditingController();
    String? selectedCoverPath;      // для натива (Windows)
    Uint8List? selectedCoverBytes;  // для веба
    List<String> selectedPromptPaths = [];      // для натива
    List<Uint8List> selectedPromptBytes = [];   // для веба
    IconData selectedIcon = Icons.auto_awesome_rounded;
    int selectedPresetIdx = 0;
    bool isAiSelected = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F0B1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFCF9E42), width: 1.5),
              ),
              title: Text(
                isPhoto ? 'Новый шаблон Фото' : 'Новый шаблон Видео',
                style: const TextStyle(color: Color(0xFFF5DA8A), fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Название:', style: TextStyle(color: Colors.white70)),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Введите название',
                        hintStyle: TextStyle(color: Colors.white30),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCF9E42))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Обложка (9:16):', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['png', 'jpg', 'jpeg', 'mp4', 'mov'],
                          allowMultiple: false,
                          withData: true,
                        );
                        if (result != null) {
                          final file = result.files.single;
                          if (kIsWeb) {
                            if (file.bytes != null) {
                              setDialogState(() {
                                selectedCoverBytes = file.bytes;
                                selectedCoverPath = null;
                              });
                            }
                          } else {
                            if (file.path != null) {
                              setDialogState(() {
                                selectedCoverPath = file.path;
                                selectedCoverBytes = null;
                              });
                            }
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (selectedCoverBytes != null || selectedCoverPath != null)
                                ? const Color(0xFFCF9E42)
                                : Colors.white24,
                            width: 1.5,
                          ),
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (selectedCoverBytes != null || selectedCoverPath != null)
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  selectedCoverBytes != null
                                      ? Image.memory(selectedCoverBytes!, fit: BoxFit.cover)
                                      : (selectedCoverPath!.endsWith('.mp4') || selectedCoverPath!.endsWith('.mov'))
                                          ? LoopingVideoCover(videoPath: selectedCoverPath!)
                                          : Image.file(File(selectedCoverPath!), fit: BoxFit.cover),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () => setDialogState(() {
                                        selectedCoverBytes = null;
                                        selectedCoverPath = null;
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      color: Colors.black54,
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.edit, color: Color(0xFFF5DA8A), size: 14),
                                          SizedBox(width: 6),
                                          Text('Изменить', style: TextStyle(color: Color(0xFFF5DA8A), fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, color: Color(0xFFCF9E42), size: 36),
                                  SizedBox(height: 8),
                                  Text('Нажмите, чтобы загрузить', style: TextStyle(color: Colors.white54, fontSize: 13)),
                                  SizedBox(height: 4),
                                  Text('Формат 9:16 (PNG, JPG, MP4)', style: TextStyle(color: Colors.white30, fontSize: 11)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Иконка:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icons.flash_on_rounded,
                        Icons.workspace_premium_rounded,
                        Icons.camera_roll_rounded,
                        Icons.zoom_in_rounded,
                        Icons.auto_awesome_rounded,
                        Icons.face_rounded,
                      ].map((icon) {
                        final bool isSel = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSel ? const Color(0xFFCF9E42).withValues(alpha: 0.2) : Colors.transparent,
                              border: Border.all(color: isSel ? const Color(0xFFCF9E42) : Colors.white24),
                            ),
                            child: Icon(icon, color: isSel ? const Color(0xFFF5DA8A) : Colors.white, size: 22),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Градиент:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_presets.length, (index) {
                        final preset = _presets[index];
                        final bool isSel = selectedPresetIdx == index;
                        return ChoiceChip(
                          label: Text(preset['name'], style: TextStyle(color: isSel ? Colors.black : Colors.white)),
                          selected: isSel,
                          selectedColor: const Color(0xFFCF9E42),
                          backgroundColor: Colors.white12,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() => selectedPresetIdx = index);
                            }
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(isPhoto ? 'Генерация ИИ (Нано Банана)' : 'Генерация ИИ (Gemini Omni Video)', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      subtitle: Text(isPhoto ? 'Гость будет сфотографирован с ИИ-эффектом' : 'Видео гостя будет обработано нейросетью', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                      value: isAiSelected,
                      activeThumbColor: const Color(0xFFCF9E42),
                      onChanged: (val) => setDialogState(() => isAiSelected = val),
                    ),
                    if (isAiSelected) ...[
                      const SizedBox(height: 12),
                      const Text('Промпт для ИИ:', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: promptCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: isPhoto 
                              ? 'Например: Гость рядом с клоуном Пеннивайзом...'
                              : 'Например: Гость танцует в стиле киберпанк, неоновые шлейфы...',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCF9E42))),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.auto_awesome_rounded, color: Color(0xFF9D4EDD), size: 14),
                        const SizedBox(width: 6),
                        const Text('Референс-фото для ИИ', style: TextStyle(color: Color(0xFF9D4EDD), fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('До 3 фото', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      const Text(
                        'ИИ будет ориентироваться на эти образцы при генерации',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      // Три ячейки для референс-фото
                      Row(
                        children: List.generate(3, (slotIndex) {
                          final int count = kIsWeb ? selectedPromptBytes.length : selectedPromptPaths.length;
                          final bool hasImage = slotIndex < count;
                          final bool canAdd = count == slotIndex;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: slotIndex < 2 ? 8.0 : 0),
                              child: GestureDetector(
                                onTap: () async {
                                  if (hasImage) return;
                                  if (!canAdd) return;
                                  final result = await FilePicker.platform.pickFiles(
                                    type: FileType.image,
                                    allowMultiple: false,
                                    withData: true,
                                  );
                                  if (result != null) {
                                    final file = result.files.single;
                                    if (kIsWeb && file.bytes != null) {
                                      setDialogState(() => selectedPromptBytes.add(file.bytes!));
                                    } else if (!kIsWeb && file.path != null) {
                                      setDialogState(() => selectedPromptPaths.add(file.path!));
                                    }
                                  }
                                },
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: hasImage
                                            ? const Color(0xFF6C25FF)
                                            : canAdd
                                                ? Colors.white24
                                                : Colors.white10,
                                        width: 1.5,
                                      ),
                                      color: Colors.white.withValues(alpha: hasImage ? 0.0 : 0.03),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: hasImage
                                        ? Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              kIsWeb
                                                  ? Image.memory(selectedPromptBytes[slotIndex], fit: BoxFit.cover)
                                                  : Image.file(File(selectedPromptPaths[slotIndex]), fit: BoxFit.cover),
                                              Positioned(
                                                top: 4, right: 4,
                                                child: GestureDetector(
                                                  onTap: () => setDialogState(() {
                                                    if (kIsWeb) {
                                                      selectedPromptBytes.removeAt(slotIndex);
                                                    } else {
                                                      selectedPromptPaths.removeAt(slotIndex);
                                                    }
                                                  }),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(3),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.black54,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.close, color: Colors.white, size: 12),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 0, left: 0, right: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                                  color: Colors.black54,
                                                  child: Text(
                                                    'Фото ${slotIndex + 1}',
                                                    style: const TextStyle(color: Color(0xFF9D4EDD), fontSize: 10),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate_outlined,
                                                color: canAdd ? const Color(0xFF9D4EDD) : Colors.white12,
                                                size: 22,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${slotIndex + 1}',
                                                style: TextStyle(
                                                  color: canAdd ? Colors.white38 : Colors.white12,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty) return;
                    final preset = _presets[selectedPresetIdx];
                    setState(() {
                      final newTemplate = VipTemplate(
                        name: nameCtrl.text,
                        gradientColors: preset['colors'] as List<Color>,
                        icon: selectedIcon,
                        shimmerColor: preset['glow'] as Color,
                        isAi: isAiSelected,
                        prompt: isAiSelected ? promptCtrl.text : null,
                        promptImagePaths: (!kIsWeb && isAiSelected && selectedPromptPaths.isNotEmpty) ? List.from(selectedPromptPaths) : null,
                        promptImageBytes: (kIsWeb && isAiSelected && selectedPromptBytes.isNotEmpty) ? List.from(selectedPromptBytes) : null,
                        resultImagePath: isAiSelected ? 'pennywise_ai_result.png' : null,
                        coverImagePath: !kIsWeb ? selectedCoverPath : null,
                        coverImageBytes: kIsWeb ? selectedCoverBytes : null,
                      );
                      if (isPhoto) {
                        photoTemplatesList.add(newTemplate);
                      } else {
                        videoTemplatesList.add(newTemplate);
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Добавить', style: TextStyle(color: Color(0xFFCF9E42), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddGameDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    IconData selectedIcon = Icons.sports_esports_rounded;
    int selectedPresetIdx = 0;
    bool hasCamera = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F0B1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFCF9E42), width: 1.5),
              ),
              title: const Text('Новая игра', style: TextStyle(color: Color(0xFFF5DA8A), fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Название:', style: TextStyle(color: Colors.white70)),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Введите название',
                        hintStyle: TextStyle(color: Colors.white30),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCF9E42))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Иконка:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icons.sports_esports_rounded,
                        Icons.accessibility_new_rounded,
                        Icons.screen_rotation_rounded,
                        Icons.mic_rounded,
                        Icons.videocam_rounded,
                      ].map((icon) {
                        final bool isSel = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSel ? const Color(0xFFCF9E42).withValues(alpha: 0.2) : Colors.transparent,
                              border: Border.all(color: isSel ? const Color(0xFFCF9E42) : Colors.white24),
                            ),
                            child: Icon(icon, color: isSel ? const Color(0xFFF5DA8A) : Colors.white, size: 22),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Градиент:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_presets.length, (index) {
                        final preset = _presets[index];
                        final bool isSel = selectedPresetIdx == index;
                        return ChoiceChip(
                          label: Text(preset['name'], style: TextStyle(color: isSel ? Colors.black : Colors.white)),
                          selected: isSel,
                          selectedColor: const Color(0xFFCF9E42),
                          backgroundColor: Colors.white12,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() => selectedPresetIdx = index);
                            }
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Поддержка камеры', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      subtitle: const Text('Если включено, будет доступно управление жестами', style: TextStyle(color: Colors.white30, fontSize: 11)),
                      value: hasCamera,
                      activeThumbColor: const Color(0xFFCF9E42),
                      onChanged: (val) => setDialogState(() => hasCamera = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty) return;
                    final preset = _presets[selectedPresetIdx];
                    setState(() {
                      gamesCatalogList.add(VipGame(
                        name: nameCtrl.text,
                        icon: selectedIcon,
                        gradientColors: preset['colors'] as List<Color>,
                        glowColor: preset['glow'] as Color,
                        hasCameraMode: hasCamera,
                      ));
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Добавить', style: TextStyle(color: Color(0xFFCF9E42), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddTrendDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    IconData selectedIcon = Icons.music_note_rounded;
    int selectedPresetIdx = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F0B1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFCF9E42), width: 1.5),
              ),
              title: const Text('Новый видео-тренд', style: TextStyle(color: Color(0xFFF5DA8A), fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Название:', style: TextStyle(color: Colors.white70)),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Введите название',
                        hintStyle: TextStyle(color: Colors.white30),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCF9E42))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Иконка:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icons.music_note_rounded,
                        Icons.waves_rounded,
                        Icons.auto_awesome_rounded,
                        Icons.smart_toy_rounded,
                        Icons.favorite_rounded,
                      ].map((icon) {
                        final bool isSel = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSel ? const Color(0xFFCF9E42).withValues(alpha: 0.2) : Colors.transparent,
                              border: Border.all(color: isSel ? const Color(0xFFCF9E42) : Colors.white24),
                            ),
                            child: Icon(icon, color: isSel ? const Color(0xFFF5DA8A) : Colors.white, size: 22),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Градиент:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_presets.length, (index) {
                        final preset = _presets[index];
                        final bool isSel = selectedPresetIdx == index;
                        return ChoiceChip(
                          label: Text(preset['name'], style: TextStyle(color: isSel ? Colors.black : Colors.white)),
                          selected: isSel,
                          selectedColor: const Color(0xFFCF9E42),
                          backgroundColor: Colors.white12,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() => selectedPresetIdx = index);
                            }
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty) return;
                    final preset = _presets[selectedPresetIdx];
                    setState(() {
                      trendsCatalogList.add(VipTrend(
                        name: nameCtrl.text,
                        icon: selectedIcon,
                        gradientColors: preset['colors'] as List<Color>,
                        glowColor: preset['glow'] as Color,
                      ));
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Добавить', style: TextStyle(color: Color(0xFFCF9E42), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

enum TrendsPageState {
  categories,
  photoTemplates,
  videoTemplates,
  shooting,
  processing,
  result,
  gamesCatalog,
  gameConnect,
  gamePlay,
  trendsCatalog,
  trendPreview,
}

class VipTrendsPage extends StatefulWidget {
  const VipTrendsPage({super.key});

  @override
  State<VipTrendsPage> createState() => _VipTrendsPageState();
}

class _VipTrendsPageState extends State<VipTrendsPage> with TickerProviderStateMixin {
  late AnimationController _borderAnimationController;
  
  // Переменные состояния интерактива
  TrendsPageState _pageState = TrendsPageState.categories;
  String _selectedCategory = ''; // 'фото', 'видео', 'игры', 'тренды'
  String _selectedItemName = ''; // Выбранный шаблон / игра / тренд
  VipTemplate? _selectedTemplate; // Выбранный объект шаблона
  String _gameControlType = ''; // 'camera' (жесты) или 'phone' (смартфон)
  int _timerDuration = 3; // Таймер отсчета: 3, 5, 8, 10 секунд
  
  // Симуляции
  double _processingProgress = 0.0;
  String _processingStepText = '';
  String? _generatedImageUrl;
  bool _isAiGenerating = false;
  bool _phoneConnected = false;
  int _countdownValue = 0;
  bool _isRecording = false;
  double _recordingProgress = 0.0;
  
  // Игровая симуляция (Gesture Runner)
  int _gameScore = 0;
  double _playerX = 0.0; // Позиция игрока от -1.0 до 1.0
  List<double> _obstacleY = [0.0, 0.5]; // Y-координаты препятствий (от 0.0 до 1.0)
  List<double> _obstacleX = [-0.3, 0.4]; // X-координаты препятствий
  Timer? _gameTimer;
  Timer? _countdownTimer;
  Timer? _recordingTimer;
  Timer? _processingTimer;
  Timer? _connectTimer;

  @override
  void initState() {
    super.initState();
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _borderAnimationController.dispose();
    _cancelAllTimers();
    super.dispose();
  }

  void _cancelAllTimers() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _processingTimer?.cancel();
    _connectTimer?.cancel();
  }

  // Переход к выбору категорий
  void _resetToCategories() {
    _cancelAllTimers();
    setState(() {
      _pageState = TrendsPageState.categories;
      _selectedCategory = '';
      _selectedItemName = '';
      _gameControlType = '';
      _processingProgress = 0.0;
      _phoneConnected = false;
      _isRecording = false;
      _gameScore = 0;
    });
  }



  // Запуск таймера обратного отсчета перед съемкой
  void _startCountdown() {
    _cancelAllTimers();
    setState(() {
      _countdownValue = _timerDuration;
      _isRecording = false;
    });
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownValue > 1) {
        setState(() {
          _countdownValue--;
        });
      } else {
        timer.cancel();
        setState(() {
          _countdownValue = 0;
          _isRecording = true;
          _recordingProgress = 0.0;
        });
        _startRecording();
      }
    });
  }

  // Запуск записи видео (для трендов/видео)
  void _startRecording() {
    const int durationMs = 4000; // 4 секунды симуляции записи
    const int stepMs = 50;
    int elapsed = 0;
    
    _recordingTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      if (!mounted) return;
      elapsed += stepMs;
      setState(() {
        _recordingProgress = elapsed / durationMs;
      });
      
      if (elapsed >= durationMs) {
        timer.cancel();
        setState(() {
          _isRecording = false;
          _pageState = TrendsPageState.processing;
        });
        _startProcessing();
      }
    });
  }

  Future<String?> _generateAiImage(String prompt, {bool isVideo = false}) async {
    if (aiApiKey.isEmpty && aiApiProvider != 'Custom') {
      debugPrint('[AI Banana] API key is empty. Using simulated fallback.');
      return null;
    }

    try {
      if (aiApiProvider == 'Google AI Studio') {
        debugPrint('[AI Banana] Sending request to Google AI Studio...');
        final response = await http.post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict?key=$aiApiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'instances': [{'prompt': prompt}],
            'parameters': {'sampleCount': 1, 'aspectRatio': '1:1'}
          }),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final String? base64Str = data['predictions']?[0]?['bytesBase64Encoded'];
          if (base64Str != null) {
            final String mimeType = data['predictions']?[0]?['mimeType'] ?? 'image/jpeg';
            return 'data:$mimeType;base64,$base64Str';
          }
        }
      } else if (aiApiProvider == 'Nano Banana Pro') {
        final String modelName = isVideo ? 'gemini-omni-video' : 'nano-banana-2';
        debugPrint('[AI Banana] Sending task request to Kie.ai (model: $modelName)...');
        final Map<String, dynamic> inputPayload = {
          'prompt': prompt,
        };
        if (isVideo) {
          inputPayload['resolution'] = '1080P';
          inputPayload['duration'] = '10s';
        }
        final response = await http.post(
          Uri.parse('https://api.kie.ai/api/v1/jobs/createTask'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $aiApiKey',
          },
          body: jsonEncode({
            'model': modelName,
            'input': inputPayload,
          }),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final String? taskId = data['data']?['taskId'];
          if (taskId != null) {
            for (int i = 0; i < 8; i++) {
              await Future.delayed(const Duration(milliseconds: 1500));
              debugPrint('[AI Banana] Polling Nano Banana Pro task status (attempt ${i + 1})...');
              final checkRes = await http.get(
                Uri.parse('https://api.kie.ai/api/v1/jobs/recordInfo?taskId=$taskId'),
                headers: {
                  'Authorization': 'Bearer $aiApiKey',
                },
              );
              if (checkRes.statusCode == 200) {
                final checkData = jsonDecode(checkRes.body);
                final String status = checkData['data']?['status'] ?? '';
                if (status == 'success') {
                  dynamic outputField = checkData['data']?['output'];
                  String? imageUrl = checkData['data']?['result'] ?? checkData['data']?['imgUrl'];
                  if (imageUrl == null && outputField != null) {
                    if (outputField is List && outputField.isNotEmpty) {
                      imageUrl = outputField.first.toString();
                    } else {
                      imageUrl = outputField.toString();
                    }
                  }
                  debugPrint('[AI Banana] Nano Banana Pro success: $imageUrl');
                  return imageUrl;
                } else if (status == 'fail' || status == 'failed') {
                  debugPrint('[AI Banana] Nano Banana Pro task failed');
                  break;
                }
              }
            }
          } else {
            debugPrint('[AI Banana] Nano Banana Pro response empty taskId: ${response.body}');
          }
        } else {
          debugPrint('[AI Banana] Nano Banana Pro failed with code: ${response.statusCode}, body: ${response.body}');
        }
      } else if (aiApiProvider == 'OpenAI') {
        debugPrint('[AI Banana] Sending request to OpenAI DALL-E...');
        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/images/generations'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $aiApiKey',
          },
          body: jsonEncode({
            'prompt': prompt,
            'n': 1,
            'size': '1024x1024',
            'model': 'dall-e-3',
          }),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final String? imageUrl = data['data']?[0]?['url'];
          debugPrint('[AI Banana] OpenAI response success: $imageUrl');
          return imageUrl;
        } else {
          debugPrint('[AI Banana] OpenAI failed with code: ${response.statusCode}, body: ${response.body}');
        }
      } else if (aiApiProvider == 'Replicate') {
        debugPrint('[AI Banana] Sending request to Replicate...');
        final response = await http.post(
          Uri.parse('https://api.replicate.com/v1/predictions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $aiApiKey',
          },
          body: jsonEncode({
            'version': 'ac732df83db7ddd8f555f2b24b85aa497efd8c76375592d60b540232f6b0b207',
            'input': {'prompt': prompt}
          }),
        );
        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final String? getUrl = data['urls']?['get'];
          if (getUrl != null) {
            for (int i = 0; i < 8; i++) {
              await Future.delayed(const Duration(seconds: 1));
              debugPrint('[AI Banana] Polling Replicate (attempt ${i + 1})...');
              final checkRes = await http.get(
                Uri.parse(getUrl),
                headers: {'Authorization': 'Token $aiApiKey'},
              );
              final checkData = jsonDecode(checkRes.body);
              final String status = checkData['status'] ?? '';
              if (status == 'succeeded') {
                final String? imageUrl = checkData['output']?[0];
                debugPrint('[AI Banana] Replicate generated URL: $imageUrl');
                return imageUrl;
              } else if (status == 'failed' || status == 'canceled') {
                debugPrint('[AI Banana] Replicate generation status: $status');
                break;
              }
            }
          }
        } else {
          debugPrint('[AI Banana] Replicate prediction creation failed: ${response.statusCode}, body: ${response.body}');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[AI Banana] Exception during API generation: $e');
      debugPrint('$stackTrace');
    }
    return null;
  }

  // Запуск рендеринга/обработки кадра
  void _startProcessing() {
    _cancelAllTimers();
    final bool isAi = _selectedTemplate?.isAi ?? false;
    final bool isVideo = _selectedCategory == 'видео' || _selectedCategory == 'тренды';
    setState(() {
      _processingProgress = 0.0;
      _generatedImageUrl = null;
      _isAiGenerating = isAi;
      _processingStepText = isAi 
          ? (isVideo ? 'Инициализация Gemini Omni Video...' : 'Инициализация ИИ Нано Банана...') 
          : 'Цветокоррекция и кадрирование...';
    });

    if (isAi && _selectedTemplate?.prompt != null) {
      _generateAiImage(_selectedTemplate!.prompt!, isVideo: isVideo).then((url) {
        if (mounted) {
          setState(() {
            _generatedImageUrl = url;
            _isAiGenerating = false;
          });
        }
      });
    }

    const int durationMs = 4000;
    const int stepMs = 60;
    int elapsed = 0;

    _processingTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      if (!mounted) return;
      elapsed += stepMs;
      
      setState(() {
        double targetProgress = elapsed / durationMs;
        
        if (isAi && targetProgress >= 0.95 && _isAiGenerating) {
          _processingProgress = 0.95;
          _processingStepText = isVideo 
              ? 'Gemini Omni Video: финальный рендеринг кадров...' 
              : 'ИИ Нано Банана: дорисовываем детали...';
          if (elapsed > 15000) {
            _isAiGenerating = false;
          } else {
            elapsed -= stepMs; // Останавливаем прогресс на 95%
          }
        } else {
          _processingProgress = targetProgress.clamp(0.0, 1.0);
          if (isAi) {
            if (_processingProgress < 0.25) {
              _processingStepText = isVideo ? 'Подготовка видео-кадров...' : 'Инициализация ИИ Нано Банана...';
            } else if (_processingProgress < 0.55) {
              _processingStepText = isVideo ? 'Анализ движения и лиц...' : 'Анализ структуры лица гостя...';
            } else if (_processingProgress < 0.85) {
              _processingStepText = isVideo ? 'Генерация видеопотока 1080P...' : 'Нейросетевой рендеринг по промпту...';
            } else {
              _processingStepText = isVideo ? 'Сборка готового ИИ видео...' : 'Генерация финального фото ИИ...';
            }
          } else {
            if (_processingProgress < 0.35) {
              _processingStepText = 'Цветокоррекция и кадрирование...';
            } else if (_processingProgress < 0.75) {
              _processingStepText = 'Рендеринг визуальных эффектов...';
            } else {
              _processingStepText = 'Финальный экспорт и создание QR-кода...';
            }
          }
        }
      });

      if (elapsed >= durationMs) {
        timer.cancel();
        setState(() {
          _pageState = TrendsPageState.result;
        });
      }
    });
  }

  // Запуск игрового цикла симуляции
  void _startGameLoop() {
    _cancelAllTimers();
    setState(() {
      _gameScore = 0;
      _playerX = 0.0;
      _obstacleY = [0.0, 0.5];
      _obstacleX = [-0.3, 0.4];
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        _gameScore += 2;
        // Движение препятствий вниз
        for (int i = 0; i < _obstacleY.length; i++) {
          _obstacleY[i] += 0.02;
          if (_obstacleY[i] >= 1.0) {
            _obstacleY[i] = 0.0;
            // Случайная позиция по горизонтали
            _obstacleX[i] = (math.Random().nextDouble() * 1.6) - 0.8;
          }
          
          // Проверка столкновений
          if (_obstacleY[i] >= 0.8 && _obstacleY[i] <= 0.9) {
            double diff = (_playerX - _obstacleX[i]).abs();
            if (diff < 0.25) {
              // Столкновение! Сбрасываем очки немного и сдвигаем препятствие
              _gameScore = (_gameScore - 200).clamp(0, 999999);
              _obstacleY[i] = 0.0;
            }
          }
        }
      });
    });
  }

  // Общий метод для заголовка шагов
  Widget _buildStepHeader(String title, VoidCallback onBack) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: isKioskMode ? 36 : 24),
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => LuxuryColors.goldGradient.createShader(bounds),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isKioskMode ? 28 : 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_pageState) {
      case TrendsPageState.categories:
        return _buildCategoriesScreen();
      case TrendsPageState.photoTemplates:
      case TrendsPageState.videoTemplates:
        return _buildTemplatesScreen();
      case TrendsPageState.shooting:
        return _buildShootingScreen();
      case TrendsPageState.processing:
        return _buildProcessingScreen();
      case TrendsPageState.result:
        return _buildResultScreen();
      case TrendsPageState.gamesCatalog:
        return _buildGamesCatalogScreen();
      case TrendsPageState.gameConnect:
        return _buildGameConnectScreen();
      case TrendsPageState.gamePlay:
        return _buildGamePlayScreen();
      case TrendsPageState.trendsCatalog:
        return _buildTrendsCatalogScreen();
      case TrendsPageState.trendPreview:
        return _buildTrendPreviewScreen();
    }
  }

  // ЭКРАН 1: Выбор категорий — премиальная сетка без текстов
  Widget _buildCategoriesScreen() {
    final List<_CategoryDef> categories = [
      _CategoryDef(
        label: 'Фото',
        icon: Icons.camera_enhance_rounded,
        phaseOffset: 0.0,
        gradientColors: [const Color(0xFFCF9E42), const Color(0xFF966C25)],
        glowColor: const Color(0xFFCF9E42),
        onTap: () => setState(() {
          _selectedCategory = 'фото';
          _pageState = TrendsPageState.photoTemplates;
        }),
      ),
      _CategoryDef(
        label: 'Видео',
        icon: Icons.play_circle_filled_rounded,
        phaseOffset: 0.25,
        gradientColors: [const Color(0xFF9D4EDD), const Color(0xFF6C25FF)],
        glowColor: const Color(0xFF9D4EDD),
        onTap: () => setState(() {
          _selectedCategory = 'видео';
          _pageState = TrendsPageState.videoTemplates;
        }),
      ),
      _CategoryDef(
        label: 'Игры',
        icon: Icons.sports_esports_rounded,
        phaseOffset: 0.5,
        gradientColors: [const Color(0xFF00E5FF), const Color(0xFF0077B6)],
        glowColor: const Color(0xFF00E5FF),
        onTap: () => setState(() {
          _selectedCategory = 'игры';
          _pageState = TrendsPageState.gamesCatalog;
        }),
      ),
      _CategoryDef(
        label: 'Тренды',
        icon: Icons.music_note_rounded,
        phaseOffset: 0.75,
        gradientColors: [const Color(0xFFF72585), const Color(0xFF7209B7)],
        glowColor: const Color(0xFFF72585),
        onTap: () => setState(() {
          _selectedCategory = 'тренды';
          _pageState = TrendsPageState.trendsCatalog;
        }),
      ),
    ];

    return GridView.count(
      physics: const BouncingScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: isKioskMode ? 24 : 12,
      crossAxisSpacing: isKioskMode ? 24 : 12,
      children: categories
          .map((cat) => _buildCategoryCard(cat))
          .toList(),
    );
  }

  Widget _buildCategoryCard(_CategoryDef cat) {
    return _PremiumCategoryCard(
      cat: cat,
      borderAnimationController: _borderAnimationController,
    );
  }
  // ЭКРАН 2: Выбор шаблонов (Фото / Видео)
  Widget _buildTemplatesScreen() {
    final bool isPhoto = _selectedCategory == 'фото';
    final List<VipTemplate> templates = isPhoto ? photoTemplatesList : videoTemplatesList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(isPhoto ? 'Шаблоны Фото' : 'Шаблоны Видео', _resetToCategories),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final int cols = constraints.maxWidth > 500 ? 3 : 2;
              return GridView.count(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(12),
                crossAxisCount: cols,
                mainAxisSpacing: isKioskMode ? 20 : 12,
                crossAxisSpacing: isKioskMode ? 20 : 12,
                childAspectRatio: 9 / 16,
                children: templates.map((tmpl) => _PremiumTemplateCard(
                  template: tmpl,
                  onTap: () => setState(() {
                    _selectedItemName = tmpl.name;
                    _selectedTemplate = tmpl;
                    _pageState = TrendsPageState.shooting;
                  }),
                )).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // ЭКРАН 6: Каталог Игр
  Widget _buildGamesCatalogScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Каталог VIP Игр', _resetToCategories),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final int cols = constraints.maxWidth > 500 ? 3 : 2;
              return GridView.count(
                physics: const BouncingScrollPhysics(),
                crossAxisCount: cols,
                mainAxisSpacing: isKioskMode ? 20 : 10,
                crossAxisSpacing: isKioskMode ? 20 : 10,
                children: gamesCatalogList.map((game) => _PremiumGameCard(
                  game: game,
                  onCameraMode: () {
                    setState(() {
                      _selectedItemName = game.name;
                      _gameControlType = 'camera';
                      _pageState = TrendsPageState.gamePlay;
                    });
                    _startGameLoop();
                  },
                  onPhoneMode: () {
                    setState(() {
                      _selectedItemName = game.name;
                      _gameControlType = 'phone';
                      _pageState = TrendsPageState.gameConnect;
                    });
                    _startConnectionSimulation();
                  },
                )).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // ЭКРАН 9: Каталог Трендов
  Widget _buildTrendsCatalogScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Выбор видео-тренда', _resetToCategories),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final int cols = constraints.maxWidth > 500 ? 3 : 2;
              return GridView.count(
                physics: const BouncingScrollPhysics(),
                crossAxisCount: cols,
                mainAxisSpacing: isKioskMode ? 20 : 10,
                crossAxisSpacing: isKioskMode ? 20 : 10,
                children: trendsCatalogList.map((trend) => _PremiumTrendCard(
                  trend: trend,
                  onTap: () => setState(() {
                    _selectedItemName = trend.name;
                    _pageState = TrendsPageState.trendPreview;
                  }),
                )).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // Эмуляция подключения телефона
  void _startConnectionSimulation() {
    _cancelAllTimers();
    setState(() {
      _phoneConnected = false;
    });
    _connectTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _phoneConnected = true;
        });
      }
    });
  }



  // ЭКРАН 3: Видоискатель / Камера
  Widget _buildShootingScreen() {
    final bool isTrends = _selectedCategory == 'тренды';
    final bool isVideo = _selectedCategory == 'видео' || isTrends;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          isTrends ? 'Запись тренда' : 'Камера киоска',
          () {
            setState(() {
              _pageState = isTrends 
                  ? TrendsPageState.trendsCatalog
                  : (_selectedCategory == 'фото' 
                      ? TrendsPageState.photoTemplates
                      : TrendsPageState.videoTemplates);
            });
          },
        ),
        
        Expanded(
          child: GlassContainer(
            borderGradient: LinearGradient(
              colors: [
                _isRecording ? Colors.red.withValues(alpha: 0.5) : const Color(0xFF00E5FF).withValues(alpha: 0.4),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            child: Stack(
              children: [
                // Симуляция видоискателя камеры (Анимированный фон с силуэтом)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF1E1035),
                          LuxuryColors.bgDark,
                        ],
                        radius: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: 0.15,
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: isKioskMode ? 280 : 150,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Наложенный шаблонный контур/фильтр
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isRecording ? Colors.red.withValues(alpha: 0.3) : const Color(0xFFCF9E42).withValues(alpha: 0.2),
                          width: isKioskMode ? 16 : 8,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Разметка камеры
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Text(
                              _selectedItemName,
                              style: TextStyle(
                                color: const Color(0xFFCF9E42),
                                fontSize: isKioskMode ? 18 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_isRecording)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'REC',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isKioskMode ? 18 : 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Гигантский таймер обратного отсчета
                if (_countdownValue > 0)
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '$_countdownValue',
                        style: TextStyle(
                          color: const Color(0xFFF5DA8A),
                          fontSize: isKioskMode ? 160 : 100,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(color: Color(0xFFCF9E42), blurRadius: 30),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Прогресс записи видео (сверху видоискателя)
                if (_isRecording)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: _recordingProgress,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                      minHeight: 4,
                    ),
                  ),

                // Секция управления снизу видоискателя
                Positioned(
                  bottom: isKioskMode ? 32 : 16,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // Настраиваемый таймер (только для трендов и до начала съёмки)
                      if (isTrends && _countdownValue == 0 && !_isRecording)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [3, 5, 8, 10].map((sec) {
                              final bool isSel = _timerDuration == sec;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _timerDuration = sec;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isKioskMode ? 12 : 6,
                                      horizontal: isKioskMode ? 20 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSel ? const Color(0xFFCF9E42) : Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSel ? const Color(0xFFF5DA8A) : Colors.white.withValues(alpha: 0.2),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      '$secс',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isKioskMode ? 16 : 12,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      // Кнопка пуска камеры
                      if (_countdownValue == 0 && !_isRecording)
                        GestureDetector(
                          onTap: () {
                            if (isTrends) {
                              _startCountdown();
                            } else if (isVideo) {
                              setState(() {
                                _isRecording = true;
                                _recordingProgress = 0.0;
                              });
                              _startRecording();
                            } else {
                              // Симуляция фото-вспышки
                              _startProcessing();
                            }
                          },
                          child: Container(
                            width: isKioskMode ? 96 : 64,
                            height: isKioskMode ? 96 : 64,
                            decoration: BoxDecoration(
                              color: isVideo ? Colors.red : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: isKioskMode ? 6.0 : 4.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isVideo ? Colors.red.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              isVideo ? Icons.fiber_manual_record : Icons.camera_alt_rounded,
                              color: isVideo ? Colors.red : Colors.black,
                              size: isKioskMode ? 44 : 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ЭКРАН 4: Лоадер обработки
  Widget _buildProcessingScreen() {
    return Center(
      child: GlassContainer(
        width: isKioskMode ? 480 : 320,
        child: Padding(
          padding: EdgeInsets.all(isKioskMode ? 48.0 : 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Стильный круговой индикатор
              SizedBox(
                width: isKioskMode ? 120 : 80,
                height: isKioskMode ? 120 : 80,
                child: CircularProgressIndicator(
                  value: _processingProgress,
                  strokeWidth: isKioskMode ? 8.0 : 4.0,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCF9E42)),
                ),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => LuxuryColors.goldTextGradient.createShader(bounds),
                child: Text(
                  '${(_processingProgress * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isKioskMode ? 32 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _processingStepText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isKioskMode ? 18 : 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Автоматический монтаж готового кадра...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: isKioskMode ? 14 : 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ЭКРАН 5: Результат с QR-кодом
  Widget _buildResultScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildStepHeader('Готовый результат', _resetToCategories),
        
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Большой результат 9 на 16
              Center(
                child: SizedBox(
                  height: isKioskMode ? 1300 : 680,
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: GlassContainer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildFinalResultView(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Название шаблона под картинкой
              Center(
                child: Text(
                  _selectedItemName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isKioskMode ? 24 : 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Обработка успешно завершена',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: isKioskMode ? 16 : 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Кюар-код
              Center(
                child: GlassContainer(
                  width: isKioskMode ? 400 : 260,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildQrCode(isKioskMode ? 180.0 : 120.0),
                        const SizedBox(height: 12),
                        Text(
                          'Сканируйте QR-код',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isKioskMode ? 18 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'чтобы сохранить контент на смартфон',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: isKioskMode ? 14 : 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Кнопка Готово
              Center(
                child: SizedBox(
                  width: isKioskMode ? 320 : 200,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCF9E42),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: isKioskMode ? 20 : 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 10,
                    ),
                    onPressed: _resetToCategories,
                    child: const Text(
                      'Готово',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinalResultView() {
    final bool isVideo = _selectedCategory == 'видео' || _selectedCategory == 'тренды';
    final String? resUrl = _generatedImageUrl ?? _selectedTemplate?.resultImagePath;

    if (isVideo) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1F1035),
              Color(0xFF0F081D),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_selectedTemplate?.coverImageBytes != null || _selectedTemplate?.coverImagePath != null)
              Opacity(
                opacity: 0.25,
                child: _selectedTemplate!.coverImageBytes != null
                    ? Image.memory(_selectedTemplate!.coverImageBytes!, fit: BoxFit.cover)
                    : _selectedTemplate!.coverImagePath!.endsWith('.mp4') || _selectedTemplate!.coverImagePath!.endsWith('.mov')
                        ? LoopingVideoCover(videoPath: _selectedTemplate!.coverImagePath!)
                        : _selectedTemplate!.coverImagePath!.startsWith('http')
                            ? Image.network(_selectedTemplate!.coverImagePath!, fit: BoxFit.cover)
                            : _selectedTemplate!.coverImagePath!.startsWith('asset:')
                                ? Image.asset(_selectedTemplate!.coverImagePath!.substring(6), fit: BoxFit.cover)
                                : Image.file(File(_selectedTemplate!.coverImagePath!), fit: BoxFit.cover),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: isKioskMode ? 100 : 70,
                    height: isKioskMode ? 100 : 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFCF9E42).withValues(alpha: 0.1),
                      border: Border.all(color: const Color(0xFFCF9E42), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFCF9E42).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: const Color(0xFFF5DA8A),
                      size: isKioskMode ? 60 : 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam_rounded, color: Color(0xFFCF9E42), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '1080P Full HD Video',
                          style: TextStyle(color: Colors.white, fontSize: isKioskMode ? 14 : 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.95), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Видео готово к загрузке',
                      style: TextStyle(color: const Color(0xFFF5DA8A), fontSize: isKioskMode ? 16 : 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedTemplate?.prompt != null
                          ? 'Промпт: "${_selectedTemplate!.prompt}"'
                          : 'Обработанный видео-эффект: ${_selectedTemplate?.name}',
                      style: TextStyle(color: Colors.white70, fontSize: isKioskMode ? 14 : 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (resUrl != null) {
      if (resUrl.startsWith('http') || resUrl.startsWith('data:')) {
        return Image.network(
          resUrl,
          fit: BoxFit.cover,
          errorBuilder: (ctx, e, st) => _buildPhotoFallback(),
        );
      } else if (resUrl.startsWith('asset:')) {
        return Image.asset(
          resUrl.substring(6),
          fit: BoxFit.cover,
          errorBuilder: (ctx, e, st) => _buildPhotoFallback(),
        );
      } else {
        return Image.file(
          File(resUrl),
          fit: BoxFit.cover,
          errorBuilder: (ctx, e, st) => _buildPhotoFallback(),
        );
      }
    }

    return _buildPhotoFallback();
  }

  Widget _buildPhotoFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFCF9E42), size: 48),
            const SizedBox(height: 12),
            Text(
              'Фото сгенерировано ИИ Нано Банана по промпту:\n"${_selectedTemplate?.prompt ?? ''}"',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCode(double size) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: QrPainter(),
      ),
    );
  }



  // ЭКРАН 7: Подключение смартфона
  Widget _buildGameConnectScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Подключение контроллера', _resetToCategories),
        Expanded(
          child: Center(
            child: GlassContainer(
              width: isKioskMode ? 440 : 300,
              child: Padding(
                padding: EdgeInsets.all(isKioskMode ? 40.0 : 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQrCode(isKioskMode ? 220.0 : 140.0),
                    const SizedBox(height: 24),
                    Text(
                      'Подключение смартфона',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isKioskMode ? 24 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Отсканируйте код, чтобы использовать телефон в качестве геймпада.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: isKioskMode ? 15 : 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _phoneConnected ? Colors.green.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _phoneConnected ? Colors.green.withValues(alpha: 0.5) : Colors.blue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _phoneConnected ? Icons.check_circle_outline_rounded : Icons.sync_rounded,
                            color: _phoneConnected ? Colors.green : Colors.blue,
                            size: isKioskMode ? 28 : 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _phoneConnected ? 'Устройство подключено!' : 'Ожидание подключения...',
                            style: TextStyle(
                              color: _phoneConnected ? Colors.green : Colors.blue,
                              fontSize: isKioskMode ? 16 : 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_phoneConnected) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCF9E42),
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: isKioskMode ? 18 : 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            setState(() {
                              _pageState = TrendsPageState.gamePlay;
                            });
                            _startGameLoop();
                          },
                          child: Text(
                            'Начать игру',
                            style: TextStyle(fontSize: isKioskMode ? 18 : 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ЭКРАН 8: Игровой симулятор (Мини-игра)
  Widget _buildGamePlayScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedItemName,
                style: TextStyle(
                  color: const Color(0xFFCF9E42),
                  fontSize: isKioskMode ? 28 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Счет: $_gameScore',
                style: TextStyle(
                  color: const Color(0xFFF5DA8A),
                  fontSize: isKioskMode ? 28 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Stack(
                children: [
                  // Сетка/Линии горизонта
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: GridPaper(
                        color: const Color(0xFF00E5FF),
                        divisions: 1,
                        subdivisions: 1,
                        interval: isKioskMode ? 100 : 50,
                      ),
                    ),
                  ),

                  // Отрисовка препятствий
                  ...List.generate(_obstacleY.length, (index) {
                    return Positioned(
                      left: (size) {
                        double width = size.maxWidth;
                        double center = width / 2;
                        return center + (_obstacleX[index] * center) - (isKioskMode ? 25 : 15);
                      }(context as BoxConstraints), // Ограничитель размеров получим из LayoutBuilder
                      top: (size) {
                        return _obstacleY[index] * (size.maxHeight - 120);
                      }(context as BoxConstraints),
                      child: Container(
                        width: isKioskMode ? 50 : 30,
                        height: isKioskMode ? 50 : 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9D4EDD),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9D4EDD).withValues(alpha: 0.6),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: isKioskMode ? 32 : 18),
                      ),
                    );
                  }),

                  // Отрисовка игрока (Шарик на рельсах)
                  Positioned(
                    bottom: 80,
                    left: (size) {
                      double width = size.maxWidth;
                      double center = width / 2;
                      return center + (_playerX * center) - (isKioskMode ? 30 : 18);
                    }(context as BoxConstraints),
                    child: Container(
                      width: isKioskMode ? 60 : 36,
                      height: isKioskMode ? 60 : 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Icon(
                        _gameControlType == 'camera' ? Icons.accessibility_new_rounded : Icons.phone_android_rounded,
                        color: Colors.black,
                        size: isKioskMode ? 32 : 20,
                      ),
                    ),
                  ),

                  // Ограничитель для получения размеров (LayoutBuilder враппер поверх всего стека)
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Обновляем позицию игрока кнопками на экране
                        return Stack(
                          children: [
                            // Информационная панель контроллера
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _gameControlType == 'camera' ? 'Управление: Жесты (Камера)' : 'Управление: Смартфон (Акселерометр)',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: isKioskMode ? 14 : 11,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Сенсорные кнопки по бокам для ручного управления на ПК
                            Positioned(
                              bottom: 16,
                              left: 16,
                              child: _buildGameButton(
                                Icons.arrow_back_ios_new_rounded,
                                () {
                                  setState(() {
                                    _playerX = (_playerX - 0.2).clamp(-0.8, 0.8);
                                  });
                                },
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: _buildGameButton(
                                Icons.arrow_forward_ios_rounded,
                                () {
                                  setState(() {
                                    _playerX = (_playerX + 0.2).clamp(-0.8, 0.8);
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: isKioskMode ? 260 : 160,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9D4EDD),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isKioskMode ? 18 : 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _resetToCategories,
              child: Text(
                'Завершить игру',
                style: TextStyle(fontSize: isKioskMode ? 18 : 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isKioskMode ? 72 : 48,
        height: isKioskMode ? 72 : 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFCF9E42).withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: const Color(0xFFF5DA8A), size: isKioskMode ? 32 : 20),
      ),
    );
  }



  // ЭКРАН 10: Демонстрация тренда
  Widget _buildTrendPreviewScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Демонстрация', _resetToCategories),
        
        Expanded(
          child: GlassContainer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Симуляция проигрывания вертикального видео
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F0B1E), Color(0xFF1E1035), Color(0xFF0C0A15)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_note_rounded,
                              color: const Color(0xFFCF9E42).withValues(alpha: 0.3),
                              size: isKioskMode ? 120 : 72,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Воспроизведение демо-ролика',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: isKioskMode ? 18 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // TikTok-like оверлей (профиль звука, лайки)
                  Positioned(
                    right: 16,
                    bottom: 120,
                    child: Column(
                      children: [
                        _buildSocialIcon(Icons.favorite_rounded, '3.2K'),
                        const SizedBox(height: 16),
                        _buildSocialIcon(Icons.comment_rounded, '124'),
                        const SizedBox(height: 16),
                        _buildSocialIcon(Icons.share_rounded, '64'),
                      ],
                    ),
                  ),

                  Positioned(
                    left: 16,
                    bottom: 16,
                    right: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@trendum_kiosk',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isKioskMode ? 18 : 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Повторите этот зажигательный танец и заберите готовый клип по QR-коду!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: isKioskMode ? 16 : 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.music_note_rounded, color: const Color(0xFFF5DA8A), size: isKioskMode ? 20 : 14),
                            const SizedBox(width: 6),
                            Text(
                              'Оригинальный звук - $_selectedItemName',
                              style: TextStyle(
                                color: const Color(0xFFF5DA8A),
                                fontSize: isKioskMode ? 15 : 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: isKioskMode ? 320 : 200,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCF9E42),
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: isKioskMode ? 18 : 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
              onPressed: () {
                setState(() {
                  _pageState = TrendsPageState.shooting;
                });
              },
              child: Text(
                'Повторить тренд (Далее)',
                style: TextStyle(fontSize: isKioskMode ? 18 : 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: isKioskMode ? 56 : 36,
          height: isKioskMode ? 56 : 36,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: Colors.white, size: isKioskMode ? 28 : 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: isKioskMode ? 14 : 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Кастомный рисовальщик для структуры QR-кода
class QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final double markerSize = size.width * 0.25;
    
    // Рисуем 3 угловых маркера (поисковые структуры)
    _drawMarker(canvas, Offset.zero, markerSize, paint);
    _drawMarker(canvas, Offset(size.width - markerSize, 0), markerSize, paint);
    _drawMarker(canvas, Offset(0, size.height - markerSize), markerSize, paint);

    // Рисуем псевдослучайные пиксели (фиксированный seed для постоянства узора)
    final math.Random random = math.Random(1337);
    final double pixelSize = size.width / 16;
    
    for (int y = 0; y < 16; y++) {
      for (int x = 0; x < 16; x++) {
        // Пропускаем зоны маркеров (левый верхний, правый верхний, левый нижний)
        if ((x < 5 && y < 5) || (x > 10 && y < 5) || (x < 5 && y > 10)) {
          continue;
        }
        if (random.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(x * pixelSize, y * pixelSize, pixelSize, pixelSize),
            paint,
          );
        }
      }
    }
  }

  void _drawMarker(Canvas canvas, Offset offset, double size, Paint paint) {
    // Внешняя рамка
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(offset.dx, offset.dy, size, size), const Radius.circular(4)),
      paint,
    );
    
    // Белая прослойка
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final double inner1 = size * 0.72;
    final double diff1 = (size - inner1) / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(offset.dx + diff1, offset.dy + diff1, inner1, inner1), const Radius.circular(2)),
      whitePaint,
    );
    
    // Внутренний квадрат
    final double inner2 = size * 0.44;
    final double diff2 = (size - inner2) / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(offset.dx + diff2, offset.dy + diff2, inner2, inner2), const Radius.circular(2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Кастомный художник для анимированной неоновой границы
class NeonBorderPainter extends CustomPainter {
  final double animationValue;
  final double phaseOffset; // Смещение фазы
  final double borderRadius;
  final double borderWidth;
  final bool isSelected;

  NeonBorderPainter({
    required this.animationValue,
    required this.phaseOffset,
    required this.borderRadius,
    required this.borderWidth,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final double angle = (animationValue + phaseOffset) * 2 * math.pi;

    // 1. Четкая тонкая неоновая линия границы (как на скрине 2)
    final paint = Paint()
      ..strokeWidth = isKioskMode ? 2.5 : 1.5 // Настраивается под киоск/ПК
      ..style = PaintingStyle.stroke;

    final neonShader = SweepGradient(
      colors: const [
        Color(0xFF00E5FF), // Бирюзовый
        Color(0xFF9D4EDD), // Фиолетовый
        Color(0xFFCF9E42), // Золотой
        Color(0xFF00E5FF), // Бирюзовый (чтобы замкнуть градиент)
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
      transform: GradientRotation(angle),
    ).createShader(rect);

    paint.shader = neonShader;

    // 2. Легкое, аккуратное неоновое свечение (glow) вокруг четкой линии
    final glowPaint = Paint()
      ..strokeWidth = isKioskMode ? 5.5 : 3.5 // Настраивается под киоск/ПК
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isKioskMode ? 6.0 : 4.0); // Динамический радиус размытия

    glowPaint.shader = SweepGradient(
      colors: [
        const Color(0xFF00E5FF).withValues(alpha: 0.4), 
        const Color(0xFF9D4EDD).withValues(alpha: 0.4), 
        const Color(0xFFCF9E42).withValues(alpha: 0.4), 
        const Color(0xFF00E5FF).withValues(alpha: 0.4),
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
      transform: GradientRotation(angle),
    ).createShader(rect);

    // Рисуем сначала свечение, а поверх него — четкую неоновую линию
    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant NeonBorderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.phaseOffset != phaseOffset ||
           oldDelegate.borderRadius != borderRadius ||
           oldDelegate.borderWidth != borderWidth ||
           oldDelegate.isSelected != isSelected;
  }
}

// ==========================================
// 2. СТРАНИЦА: Премиум Клуб
// ==========================================
class PremiumClubPage extends StatelessWidget {
  const PremiumClubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        const Text(
          'Ваши VIP Привилегии',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Эксклюзивные предложения, доступные только членам Exclusive Club',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        
        // Список VIP карточек
        _buildClubCard(
          context,
          'Персональный Консьерж',
          'AI-помощник бизнес-класса, решающий любые повседневные задачи 24/7.',
          Icons.support_agent_rounded,
          'АКТИВИРОВАНО',
        ),
        const SizedBox(height: 16),
        _buildClubCard(
          context,
          'Закрытые Инвестиции',
          'Доступ к ранним сделкам, венчурным фондам и премиальным инвестиционным пулам.',
          Icons.account_balance_rounded,
          'ДОСТУПНО',
        ),
        const SizedBox(height: 16),
        _buildClubCard(
          context,
          'Аналитический Отдел VIP',
          'Ежедневная выжимка от ведущих аналитиков и инсайды с фондовых рынков.',
          Icons.analytics_rounded,
          'ПОДКЛЮЧЕНО',
        ),
      ],
    );
  }

  Widget _buildClubCard(BuildContext context, String title, String description, IconData icon, String status) {
    return GlassContainer(
      borderGradient: LinearGradient(
        colors: [
          const Color(0xFFCF9E42).withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Иконка
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFCF9E42).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCF9E42).withValues(alpha: 0.3)),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFF5DA8A),
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: status == 'ДОСТУПНО' ? const Color(0xFF00E5FF) : const Color(0xFFF5DA8A),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. СТРАНИЦА: Активы VIP
// ==========================================
class VipAssetsPage extends StatelessWidget {
  const VipAssetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        const Text(
          'Ваш Премиальный Баланс',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Активы под управлением и история начислений дивидендов',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),

        // Карточка баланса
        _buildBalanceCard(),
        const SizedBox(height: 24),

        // Распределение портфеля
        const Text(
          'Распределение портфеля',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildAssetProgress('Драгоценные металлы', 0.45, '45%', const Color(0xFFCF9E42)),
        const SizedBox(height: 12),
        _buildAssetProgress('Венчурные активы', 0.30, '30%', const Color(0xFF6C25FF)),
        const SizedBox(height: 12),
        _buildAssetProgress('Недвижимость VIP', 0.25, '25%', const Color(0xFF00E5FF)),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return GlassContainer(
      gradient: LinearGradient(
        colors: [
          const Color(0xFFCF9E42).withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.02),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderGradient: const LinearGradient(
        colors: [
          Color(0xFFCF9E42),
          Color(0x11FFFFFF),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'ОБЩАЯ СТОИМОСТЬ ПОРТФЕЛЯ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (bounds) => LuxuryColors.goldTextGradient.createShader(bounds),
              child: const Text(
                '\$14,248,500.00',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.arrow_upward_rounded,
                  color: Color(0xFF00E5FF),
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text(
                  '+\$345,120 (2.48%) за сегодня',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetProgress(String label, double value, String percent, Color color) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  percent,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                color: color,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. СТРАНИЦА: Настройки VIP
// ==========================================
class VipSettingsPage extends StatefulWidget {
  const VipSettingsPage({super.key});

  @override
  State<VipSettingsPage> createState() => _VipSettingsPageState();
}

class _VipSettingsPageState extends State<VipSettingsPage> {
  bool _twoFactor = true;
  bool _biometrics = false;
  bool _darkGoldStyle = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        const Text(
          'Настройки Безопасности & Стиля',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Управление конфиденциальностью и персонализацией VIP-аккаунта',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),

        // Настройки дизайна
        const Text(
          'Персонализация',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSwitchSetting(
          'Темный Золотой Стиль (Luxury)',
          'Активирует премиальное оформление с использованием золотых градиентов.',
          _darkGoldStyle,
          (val) => setState(() => _darkGoldStyle = val),
        ),

        const SizedBox(height: 24),

        // Настройки безопасности
        const Text(
          'Конфиденциальность и защита',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSwitchSetting(
          'Двухфакторная авторизация (2FA)',
          'Дополнительный уровень защиты при подтверждении VIP операций.',
          _twoFactor,
          (val) => setState(() => _twoFactor = val),
        ),
        const SizedBox(height: 12),
        _buildSwitchSetting(
          'Биометрическая защита (Face ID / Touch ID)',
          'Быстрый и безопасный вход в VIP-кабинет.',
          _biometrics,
          (val) => setState(() => _biometrics = val),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(String title, String description, bool value, ValueChanged<bool> onChanged) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFFF5DA8A),
              activeTrackColor: const Color(0xFFCF9E42).withValues(alpha: 0.4),
              inactiveThumbColor: Colors.white.withValues(alpha: 0.6),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// МОДЕЛИ ДАННЫХ для каталогов
// ==========================================

class _CategoryDef {
  final String label;
  final IconData icon;
  final double phaseOffset;
  final List<Color> gradientColors;
  final Color glowColor;
  final VoidCallback onTap;

  const _CategoryDef({
    required this.label,
    required this.icon,
    required this.phaseOffset,
    required this.gradientColors,
    required this.glowColor,
    required this.onTap,
  });
}





// ==========================================
// ПРЕМИАЛЬНАЯ КАРТОЧКА КАТЕГОРИИ (без текста)
// ==========================================
class _PremiumCategoryCard extends StatefulWidget {
  final _CategoryDef cat;
  final AnimationController borderAnimationController;

  const _PremiumCategoryCard({
    required this.cat,
    required this.borderAnimationController,
  });

  @override
  State<_PremiumCategoryCard> createState() => _PremiumCategoryCardState();
}

class _PremiumCategoryCardState extends State<_PremiumCategoryCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _shimmerController;
  bool _hovered = false;

  // Рандомные параметры анимации — задаются один раз при создании карточки
  late final bool _shimmerReversed;  // направление: вперёд или назад
  late final int _shimmerMode;       // 0=sweep, 1=pulse, 2=double-sweep

  @override
  void initState() {
    super.initState();
    final rng = math.Random();

    // Случайные параметры анимации
    _shimmerReversed = rng.nextBool();
    _shimmerMode     = rng.nextInt(3); // 0, 1 или 2

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Рандомная длительность 3000–6000 мс — каждая карточка в своём темпе
    final int shimmerMs = 3000 + rng.nextInt(3001);
    _shimmerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: shimmerMs),
    );
    // ВАЖНО: сначала устанавливаем начальную фазу, ПОТОМ repeat()
    // Порядок обратный — .value= вызывает stop(), поэтому repeat() должен быть последним
    _shimmerController.value = rng.nextDouble();
    _shimmerController.repeat(); // ← запускаем ПОСЛЕ установки value
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) {
          _scaleController.reverse();
          widget.cat.onTap();
        },
        onTapCancel: () => _scaleController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedBuilder(
            animation: widget.borderAnimationController,
            builder: (context, child) {
              return CustomPaint(
                painter: NeonBorderPainter(
                  animationValue: widget.borderAnimationController.value,
                  phaseOffset: widget.cat.phaseOffset,
                  borderRadius: isKioskMode ? 36.0 : 20.0,
                  borderWidth: 2.0,
                  isSelected: true,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isKioskMode ? 36.0 : 20.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(isKioskMode ? 36.0 : 20.0),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.cat.gradientColors[0].withValues(alpha: _hovered ? 0.22 : 0.12),
                            widget.cat.gradientColors[1].withValues(alpha: _hovered ? 0.12 : 0.04),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Круглый радиальный ореол иконки (увеличенный)
                          Container(
                            width: isKioskMode ? 160 : 90,
                            height: isKioskMode ? 160 : 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  widget.cat.glowColor.withValues(alpha: 0.40),
                                  widget.cat.glowColor.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                widget.cat.icon,
                                color: Colors.white,
                                size: isKioskMode ? 80 : 46,
                                shadows: [
                                  Shadow(
                                    color: widget.cat.glowColor,
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isKioskMode ? 20 : 10),
                          // Декоративная линия-разделитель
                          Container(
                            width: isKioskMode ? 56 : 36,
                            height: 2,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1),
                              gradient: LinearGradient(
                                colors: [
                                  widget.cat.glowColor.withValues(alpha: 0.0),
                                  widget.cat.glowColor,
                                  widget.cat.glowColor.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isKioskMode ? 14 : 8),
                          // Название — анимированный шейдер через TextStyle.foreground
                          // (надёжнее ShaderMask на всех платформах)
                          AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              final double t = _shimmerReversed
                                  ? 1.0 - _shimmerController.value
                                  : _shimmerController.value;
                              final glow = widget.cat.glowColor;

                              // Фиксированная ширина: достаточно для любого короткого текста
                              final double textH = isKioskMode ? 30.0 : 18.0;
                              final double W = isKioskMode ? 480.0 : 280.0;
                              final double offset = -W + W * 2 * t;

                              final Paint shimmerPaint = Paint();

                              if (_shimmerMode == 1) {
                                // РЕЖИМ 1: пульсация яркости
                                final double pulse =
                                    math.sin(t * math.pi * 2) * 0.5 + 0.5;
                                shimmerPaint.shader = LinearGradient(
                                  colors: [
                                    glow.withValues(alpha: 0.4 + pulse * 0.4),
                                    Colors.white.withValues(alpha: 0.6 + pulse * 0.4),
                                    const Color(0xFFFFF5CC)
                                        .withValues(alpha: 0.6 + pulse * 0.4),
                                    Colors.white.withValues(alpha: 0.6 + pulse * 0.4),
                                    glow.withValues(alpha: 0.4 + pulse * 0.4),
                                  ],
                                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                                ).createShader(
                                  Rect.fromLTWH(offset * 0.6, 0, W, textH),
                                );
                              } else if (_shimmerMode == 2) {
                                // РЕЖИМ 2: два скользящих блика
                                shimmerPaint.shader = LinearGradient(
                                  colors: [
                                    glow.withValues(alpha: 0.5),
                                    glow,
                                    Colors.white,
                                    const Color(0xFFFFF5CC),
                                    Colors.white,
                                    glow,
                                    Colors.white,
                                    glow,
                                    glow.withValues(alpha: 0.5),
                                  ],
                                  stops: const [
                                    0.0, 0.08, 0.15, 0.22, 0.3,
                                    0.5, 0.65, 0.8, 1.0,
                                  ],
                                ).createShader(
                                  Rect.fromLTWH(offset, 0, W, textH),
                                );
                              } else {
                                // РЕЖИМ 0: одиночный чистый блик
                                shimmerPaint.shader = LinearGradient(
                                  colors: [
                                    glow.withValues(alpha: 0.45),
                                    glow,
                                    Colors.white,
                                    const Color(0xFFFFF5CC),
                                    Colors.white,
                                    glow,
                                    glow.withValues(alpha: 0.45),
                                  ],
                                  stops: const [
                                    0.0, 0.2, 0.35, 0.5, 0.65, 0.8, 1.0,
                                  ],
                                ).createShader(
                                  Rect.fromLTWH(offset, 0, W, textH),
                                );
                              }

                              return Text(
                                widget.cat.label.toUpperCase(),
                                style: TextStyle(
                                  foreground: shimmerPaint,
                                  fontSize: isKioskMode ? 22 : 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: isKioskMode ? 4.0 : 2.5,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
}
}

class VipTemplate {
  String name;
  List<Color> gradientColors;
  IconData icon;
  Color shimmerColor;
  bool isAi;
  String? prompt;
  List<String>? promptImagePaths;    // Пути до 3 референс-фото (натив)
  List<Uint8List>? promptImageBytes; // Байты до 3 референс-фото (веб)
  String? resultImagePath;
  String? coverImagePath;  // Путь к обложке (натив)
  Uint8List? coverImageBytes; // Байты обложки (веб)

  VipTemplate({
    required this.name,
    required this.gradientColors,
    required this.icon,
    required this.shimmerColor,
    this.isAi = false,
    this.prompt,
    this.promptImagePaths,
    this.promptImageBytes,
    this.resultImagePath,
    this.coverImagePath,
    this.coverImageBytes,
  });
}

class VipGame {
  String name;
  IconData icon;
  List<Color> gradientColors;
  Color glowColor;
  bool hasCameraMode;

  VipGame({
    required this.name,
    required this.icon,
    required this.gradientColors,
    required this.glowColor,
    required this.hasCameraMode,
  });
}

class VipTrend {
  String name;
  List<Color> gradientColors;
  IconData icon;
  Color glowColor;

  VipTrend({
    required this.name,
    required this.gradientColors,
    required this.icon,
    required this.glowColor,
  });
}

class _PremiumTemplateCard extends StatefulWidget {
  final VipTemplate template;
  final VoidCallback onTap;

  const _PremiumTemplateCard({required this.template, required this.onTap});

  @override
  State<_PremiumTemplateCard> createState() => _PremiumTemplateCardState();
}

class _PremiumTemplateCardState extends State<_PremiumTemplateCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildCoverImage(VipTemplate template) {
    final Widget fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: template.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
    // Веб: используем байты
    if (template.coverImageBytes != null) {
      return Image.memory(template.coverImageBytes!, fit: BoxFit.cover, errorBuilder: (ctx, e, st) => fallback);
    }
    // Натив: используем путь
    final String? path = template.coverImagePath;
    if (path == null || path.isEmpty) return fallback;
    if (path.endsWith('.mp4') || path.endsWith('.mov')) {
      return LoopingVideoCover(videoPath: path);
    } else if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (ctx, e, st) => fallback);
    } else if (path.startsWith('asset:')) {
      return Image.asset(path.substring(6), fit: BoxFit.cover, errorBuilder: (ctx, e, st) => fallback);
    } else {
      return Image.file(File(path), fit: BoxFit.cover, errorBuilder: (ctx, e, st) => fallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCover = widget.template.coverImageBytes != null ||
        (widget.template.coverImagePath != null && widget.template.coverImagePath!.isNotEmpty);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isKioskMode ? 28 : 18),
              boxShadow: [
                BoxShadow(
                  color: widget.template.shimmerColor.withValues(alpha: _hovered ? 0.4 : 0.15),
                  blurRadius: _hovered ? 20 : 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isKioskMode ? 28 : 18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Задний фон (обложка или градиент)
                  if (hasCover)
                    _buildCoverImage(widget.template)
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.template.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: isKioskMode ? 80 : 52,
                          height: isKioskMode ? 80 : 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.25),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                          ),
                          child: Icon(widget.template.icon, color: Colors.white, size: isKioskMode ? 40 : 26),
                        ),
                      ),
                    ),
                  
                  // Затемняющий градиент снизу для лучшей читаемости текста
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Название шаблона
                  Positioned(
                    bottom: isKioskMode ? 20 : 12,
                    left: 8,
                    right: 8,
                    child: Text(
                      widget.template.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isKioskMode ? 18 : 12,
                        fontWeight: FontWeight.bold,
                        shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumGameCard extends StatefulWidget {
  final VipGame game;
  final VoidCallback onCameraMode;
  final VoidCallback onPhoneMode;

  const _PremiumGameCard({required this.game, required this.onCameraMode, required this.onPhoneMode});

  @override
  State<_PremiumGameCard> createState() => _PremiumGameCardState();
}

class _PremiumGameCardState extends State<_PremiumGameCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isKioskMode ? 28 : 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isKioskMode ? 28 : 18),
            gradient: LinearGradient(
              colors: [
                widget.game.gradientColors[0].withValues(alpha: 0.18),
                widget.game.gradientColors[1].withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: widget.game.glowColor.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isKioskMode ? 80 : 52,
                height: isKioskMode ? 80 : 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.2),
                ),
                child: Icon(widget.game.icon, color: Colors.white, size: isKioskMode ? 40 : 26),
              ),
              const SizedBox(height: 8),
              Text(
                widget.game.name,
                style: TextStyle(color: Colors.white, fontSize: isKioskMode ? 18 : 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.game.hasCameraMode) ...[
                    GestureDetector(
                      onTap: widget.onCameraMode,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
                        child: Icon(Icons.videocam_rounded, color: const Color(0xFF00E5FF), size: isKioskMode ? 24 : 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  GestureDetector(
                    onTap: widget.onPhoneMode,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
                      child: Icon(Icons.phone_android_rounded, color: const Color(0xFFCF9E42), size: isKioskMode ? 24 : 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumTrendCard extends StatefulWidget {
  final VipTrend trend;
  final VoidCallback onTap;

  const _PremiumTrendCard({required this.trend, required this.onTap});

  @override
  State<_PremiumTrendCard> createState() => _PremiumTrendCardState();
}

class _PremiumTrendCardState extends State<_PremiumTrendCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isKioskMode ? 28 : 18),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isKioskMode ? 28 : 18),
                gradient: LinearGradient(
                  colors: [
                    widget.trend.gradientColors[0].withValues(alpha: _hovered ? 0.25 : 0.12),
                    widget.trend.gradientColors[1].withValues(alpha: _hovered ? 0.15 : 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: widget.trend.glowColor.withValues(alpha: 0.25), width: 1.5),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: isKioskMode ? 80 : 52,
                      height: isKioskMode ? 80 : 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                      child: Icon(widget.trend.icon, color: Colors.white, size: isKioskMode ? 40 : 26),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Text(
                      widget.trend.name,
                      style: TextStyle(color: Colors.white, fontSize: isKioskMode ? 18 : 12, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
