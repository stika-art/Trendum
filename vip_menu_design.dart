import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

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
  
  // Контроллер для анимации фоновых сфер
  late AnimationController _bgAnimationController;
  // Контроллер для анимации появления контента
  late AnimationController _contentAnimationController;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  void _onMenuSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    _contentAnimationController.reset();
    _contentAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 900;

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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Сайдбар меню для десктопа
                        _buildSidebar(context),
                        const SizedBox(width: 24),
                        // Основной контент
                        Expanded(
                          child: _buildMainContent(context),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        // Шапка для мобильных
                        _buildMobileHeader(context),
                        const SizedBox(height: 16),
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

  // Виджет сайдбара
  Widget _buildSidebar(BuildContext context) {
    return GlassContainer(
      width: 280,
      height: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Логотип Trendum VIP
            _buildLogo(),
            const SizedBox(height: 48),
            
            // Элементы меню
            Expanded(
              child: Column(
                children: [
                  _buildMenuItem(0, Icons.insert_chart_outlined, 'VIP Тренды'),
                  const SizedBox(height: 16),
                  _buildMenuItem(1, Icons.stars_rounded, 'Премиум Клуб'),
                  const SizedBox(height: 16),
                  _buildMenuItem(2, Icons.account_balance_wallet_outlined, 'Активы VIP'),
                  const SizedBox(height: 16),
                  _buildMenuItem(3, Icons.tune_rounded, 'Настройки VIP'),
                ],
              ),
            ),

            // Профиль пользователя внизу
            _buildUserProfileCard(),
          ],
        ),
      ),
    );
  }

  // Логотип с золотым градиентным текстом
  Widget _buildLogo() {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LuxuryColors.goldGradient.createShader(bounds),
          child: const Icon(
            Icons.query_stats_rounded,
            size: 32,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LuxuryColors.goldTextGradient.createShader(bounds),
              child: const Text(
                'TRENDUM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.0,
                ),
              ),
            ),
            Text(
              'EXCLUSIVE CLUB',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Элемент меню для сайдбара
  Widget _buildMenuItem(int index, IconData icon, String title) {
    final bool isSelected = _selectedIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onMenuSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      const Color(0xFFCF9E42).withValues(alpha: 0.15),
                      const Color(0xFFCF9E42).withValues(alpha: 0.02),
                    ],
                  )
                : null,
            border: isSelected
                ? Border.all(
                    color: const Color(0xFFCF9E42).withValues(alpha: 0.3),
                    width: 1.0,
                  )
                : Border.all(
                    color: Colors.transparent,
                    width: 1.0,
                  ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFFF5DA8A) : Colors.white.withValues(alpha: 0.5),
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Профиль пользователя внизу меню
  Widget _buildUserProfileCard() {
    return GlassContainer(
      borderRadius: 16,
      borderGradient: LinearGradient(
        colors: [
          const Color(0xFFCF9E42).withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Аватар с золотой обводкой
            Container(
              padding: const EdgeInsets.all(2.0),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LuxuryColors.goldGradient,
              ),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: LuxuryColors.bgDark,
                child: Icon(Icons.person_outline_rounded, color: Color(0xFFF5DA8A)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Александр В.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LuxuryColors.goldGradient,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'VIP MEMBER',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
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

  // Мобильная шапка
  Widget _buildMobileHeader(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLogo(),
            // Mini профиль
            Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LuxuryColors.goldGradient,
              ),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: LuxuryColors.bgDark,
                child: Icon(Icons.person_outline_rounded, color: Color(0xFFF5DA8A), size: 18),
              ),
            ),
          ],
        ),
      ),
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
}

// ==========================================
// 1. СТРАНИЦА: VIP Тренды (Интерактивный график)
// ==========================================
class VipTrendsPage extends StatefulWidget {
  const VipTrendsPage({super.key});

  @override
  State<VipTrendsPage> createState() => _VipTrendsPageState();
}

class _VipTrendsPageState extends State<VipTrendsPage> with SingleTickerProviderStateMixin {
  late AnimationController _graphController;
  final List<double> _points = [0.2, 0.45, 0.3, 0.75, 0.6, 0.9, 0.95];

  @override
  void initState() {
    super.initState();
    _graphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _graphController.forward();
  }

  @override
  void dispose() {
    _graphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // Приветственный премиум баннер
        _buildWelcomeBanner(),
        const SizedBox(height: 24),
        
        // Интерактивный VIP график трендов
        _buildChartCard(),
        const SizedBox(height: 24),

        // Сетка второстепенных показателей
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return Row(
                children: [
                  Expanded(child: _buildStatCard('Индекс Влияния', '98.4%', '+1.2% за день', Icons.insights_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Объем Капитала', '14.2M \$', '+4.5% за неделю', Icons.monetization_on_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Уровень Доступа', 'ALPHA VIP', 'Максимальный', Icons.vpn_key_outlined)),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildStatCard('Индекс Влияния', '98.4%', '+1.2% за день', Icons.insights_rounded),
                  const SizedBox(height: 12),
                  _buildStatCard('Объем Капитала', '14.2M \$', '+4.5% за неделю', Icons.monetization_on_outlined),
                  const SizedBox(height: 12),
                  _buildStatCard('Уровень Доступа', 'ALPHA VIP', 'Максимальный', Icons.vpn_key_outlined),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    return GlassContainer(
      gradient: LinearGradient(
        colors: [
          const Color(0xFFCF9E42).withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.01),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Добро пожаловать в Trendum VIP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ваш персональный аналитический терминал готов к работе. Все системы функционируют в режиме максимальной точности.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Золотой премиум значок
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LuxuryColors.goldGradient,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFCF9E42).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 36,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Интерактивный Индекс Трендов',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Обновляется в реальном времени с использованием AI',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                // Кнопки переключения таймфрейма
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: ['D', 'W', 'M', 'Y'].map((t) {
                      final bool isSelected = t == 'W';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFCF9E42).withValues(alpha: 0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected ? Border.all(color: const Color(0xFFCF9E42).withValues(alpha: 0.4)) : null,
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFFF5DA8A) : Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
            const SizedBox(height: 32),
            // Отрисовка графика
            SizedBox(
              height: 220,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _graphController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: TrendGraphPainter(_points, _graphController.value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  icon,
                  color: const Color(0xFFCF9E42).withValues(alpha: 0.6),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Кастомный художник для красивого графика
class TrendGraphPainter extends CustomPainter {
  final List<double> points;
  final double animationValue;

  TrendGraphPainter(this.points, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paintLine = Paint()
      ..shader = LuxuryColors.goldGradient.createShader(Offset.zero & size)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFCF9E42).withValues(alpha: 0.2),
          const Color(0xFFCF9E42).withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final double stepX = size.width / (points.length - 1);
    
    List<Offset> offsets = [];
    for (int i = 0; i < points.length; i++) {
      double x = i * stepX;
      double y = size.height - (points[i] * size.height * animationValue);
      offsets.add(Offset(x, y));
    }

    path.moveTo(offsets[0].dx, offsets[0].dy);
    fillPath.moveTo(offsets[0].dx, size.height);
    fillPath.lineTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p1 = offsets[i];
      final p2 = offsets[i + 1];
      final controlPoint1 = Offset(p1.dx + stepX / 2, p1.dy);
      final controlPoint2 = Offset(p2.dx - stepX / 2, p2.dy);
      
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p2.dx, p2.dy);
      fillPath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p2.dx, p2.dy);
    }

    fillPath.lineTo(offsets.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // Рисуем светящиеся точки на пиках
    final paintDot = Paint()
      ..color = const Color(0xFFF5DA8A)
      ..style = PaintingStyle.fill;
    final paintDotShadow = Paint()
      ..color = const Color(0xFFCF9E42).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
      ..style = PaintingStyle.fill;

    for (var offset in offsets) {
      canvas.drawCircle(offset, 6.0, paintDotShadow);
      canvas.drawCircle(offset, 3.5, paintDot);
    }
  }

  @override
  bool shouldRepaint(covariant TrendGraphPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.points != points;
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
