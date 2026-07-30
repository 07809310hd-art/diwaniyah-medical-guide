// lib/main.dart
// نسخة احترافية عصرية _- تسجيل مستخدم آمن بالاسم الثلاثي المدقق ورقم الهاتف العراقي
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

void tapFeedback() {
  HapticFeedback.lightImpact();
  SystemSound.play(SystemSoundType.click);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://guutspmwwjfakjohcgrm.supabase.co',
    anonKey: 'sb_publishable_yGfJ4UkufW6L-lV4VKpwOg_envW3xfm',
  );

  runApp(const DiwaniyahMedicalApp());
}

// ==================== بيانات المستخدم الحالي ====================
class CurrentUser {
  static String? name;
  static String? phone;
  static String? city;

  static bool get isRegistered => name != null && phone != null && city != null;

  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    name = prefs.getString('user_name');
    phone = prefs.getString('user_phone');
    city = prefs.getString('user_city');
  }

  static Future<void> save(String newName, String newPhone, String newCity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newName);
    await prefs.setString('user_phone', newPhone);
    await prefs.setString('user_city', newCity);
    name = newName;
    phone = newPhone;
    city = newCity;
  }
}

// ==================== الألوان ====================
class AppColors {
  static const Color primary = Color(0xFF0EA5E9);
  static const Color primaryDark = Color(0xFF0369A1);
  static const Color secondary = Color(0xFF1E3A8A);
  static const Color accent = Color(0xFF14B8A6);
  static const Color background = Color(0xFFF4F8FB);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color success = Color(0xFF16A34A);
  static const Color whatsapp = Color(0xFF25D366);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF1E3A8A)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14B8A6), Color(0xFF0EA5E9)],
  );
}

class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  FadeSlidePageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

void pushAnimated(BuildContext context, Widget page) {
  Navigator.push(context, FadeSlidePageRoute(page: page));
}

// ==================== النماذج ====================
class Doctor {
  final int id;
  final String fullName;
  final String specialty;
  final String clinicName;
  final String address;
  final String phoneNumber;
  final String whatsappNumber;
  final String workingHours;
  final String bio;
  final double? latitude;
  final double? longitude;

  Doctor({
    required this.id,
    required this.fullName,
    required this.specialty,
    required this.clinicName,
    required this.address,
    required this.phoneNumber,
    required this.whatsappNumber,
    required this.workingHours,
    required this.bio,
    this.latitude,
    this.longitude,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'] ?? 0,
      fullName: map['full_name']?.toString() ?? 'بدون اسم',
      specialty: map['specialty']?.toString() ?? 'عام',
      clinicName: map['clinic_name']?.toString() ?? 'عيادة عامة',
      address: map['address']?.toString() ?? 'الديوانية',
      phoneNumber: map['phone_number']?.toString() ?? '07800000000',
      whatsappNumber: map['whatsapp_number']?.toString() ?? '9647800000000',
      workingHours: map['working_hours']?.toString() ?? 'غير محدد',
      bio: map['bio']?.toString() ?? 'لا توجد نبذة',
      latitude: map['latitude'] == null ? null : (map['latitude'] as num).toDouble(),
      longitude: map['longitude'] == null ? null : (map['longitude'] as num).toDouble(),
    );
  }
}

class MedicalPost {
  final int id;
  final String mediaType;
  final String mediaUrl;
  final String title;
  final String? providerName;
  final String? category;

  MedicalPost({
    required this.id,
    required this.mediaType,
    required this.mediaUrl,
    required this.title,
    this.providerName,
    this.category,
  });

  bool get isVideo => mediaType.toLowerCase() == 'video';

  factory MedicalPost.fromMap(Map<String, dynamic> map) {
    return MedicalPost(
      id: map['id'] ?? 0,
      mediaType: map['media_type']?.toString() ?? 'image',
      mediaUrl: map['media_url']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      providerName: map['provider_name']?.toString(),
      category: map['category']?.toString(),
    );
  }
}

class DiwaniyahMedicalApp extends StatelessWidget {
  const DiwaniyahMedicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دليل الأطباء في الديوانية',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          tertiary: AppColors.accent,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Cairo',
        splashFactory: InkRipple.splashFactory,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AppEntryGate(),
    );
  }
}

class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    await CurrentUser.loadFromPrefs();
    if (!mounted) return;
    setState(() => _isChecking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return CurrentUser.isRegistered ? const MainNavigationScreen() : const OnboardingScreen();
  }
}

// ==================== شاشة تسجيل البيانات الآمنة (الاسم الثلاثي) ====================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();

    // التحقق من أن الحقول ليست فارغة
    if (name.isEmpty || phone.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة جميع الحقول بدقة')),
      );
      return;
    }

    // التحقق من إدخال الاسم الثلاثي على الأقل (3 كلمات)
    final nameParts = name.split(RegExp(r'\s+'));
    if (nameParts.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الاسم الثلاثي الحقيقي (الاسم، اسم الاب، اسم الجد)')),
      );
      return;
    }

    // التحقق من رقم الهاتف العراقي (11 رقم ويبدأ بـ 07)
    if (!RegExp(r'^07[0-9]{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الهاتف غير صحيح، يجب أن يتكون من 11 رقماً ويبدأ بـ 07')),
      );
      return;
    }

    tapFeedback();
    setState(() => _isSaving = true);
    await CurrentUser.save(name, phone, city);

    try {
      await Supabase.instance.client.from('app_users').insert({
        'full_name': name,
        'phone_number': phone,
        'city': city,
      });
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Container(
                height: 90,
                width: 90,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 20),
              const Text(
                'التسجيل الآمن في دليل أطباء الديوانية',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
              const SizedBox(height: 8),
              const Text(
                'يرجى إدخال اسمك الثلاثي الحقيقي ورقم هاتفك للمتابعة بأمان والتفاعل بشكل موثوق',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
              ),
              const SizedBox(height: 28),
              _OnboardingField(
                controller: _nameController,
                icon: Icons.person_rounded,
                hint: 'الاسم الثلاثي (مثال: محمد قاسم حسين)',
              ),
              const SizedBox(height: 14),
              _OnboardingField(
                controller: _phoneController,
                icon: Icons.phone_rounded,
                hint: 'رقم الهاتف (مثال: 07817499784)',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _OnboardingField(
                controller: _cityController,
                icon: Icons.location_city_rounded,
                hint: 'مكان السكن (مثال: الديوانية - حي الحسين)',
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: _ActionButton(
                  label: _isSaving ? 'جارِ التحقق والحفظ...' : 'دخول آمن',
                  icon: Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  onTap: _isSaving ? () {} : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType keyboardType;

  const _OnboardingField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.secondary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// ==================== شاشة التنقل الرئيسية ====================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = const [
    HomeScreen(),
    AllDoctorsScreen(),
    ReelsScreen(),
    MessagesScreen(),
    SettingsScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = const [
    {'icon': Icons.home_rounded, 'label': 'الرئيسية'},
    {'icon': Icons.medical_services_rounded, 'label': 'الأطباء'},
    {'icon': Icons.video_collection_rounded, 'label': 'نبض الديوانية'},
    {'icon': Icons.chat_bubble_rounded, 'label': 'المراسلة'},
    {'icon': Icons.settings_rounded, 'label': 'الإعدادات'},
  ];

  void _onTabTapped(int index) {
    tapFeedback();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const PageScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(_navItems.length, (index) {
                  final bool selected = _currentIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabTapped(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: EdgeInsets.symmetric(
                          horizontal: selected ? 8 : 4,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: selected ? AppColors.heroGradient : null,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _navItems[index]['icon'],
                              color: selected ? Colors.white : AppColors.textMuted,
                              size: 22,
                            ),
                            if (selected)
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(start: 5),
                                  child: Text(
                                    _navItems[index]['label'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== الشاشة الرئيسية ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  List<Doctor> allDoctors = [];
  bool isLoading = true;
  late final AnimationController _listController;

  final List<Map<String, dynamic>> categories = const [
    {'name': 'طبيب باطنية', 'icon': Icons.medical_services_rounded},
    {'name': 'طب القلب', 'icon': Icons.favorite_rounded},
    {'name': 'طبيب أسنان', 'icon': Icons.mood_rounded},
    {'name': 'طبيبة أطفال', 'icon': Icons.child_care_rounded},
    {'name': 'طب عيون', 'icon': Icons.remove_red_eye_rounded},
    {'name': 'نسائية وتوليد', 'icon': Icons.pregnant_woman_rounded},
    {'name': 'عظام ومفاصل', 'icon': Icons.accessibility_new_rounded},
    {'name': 'أمراض جلدية', 'icon': Icons.face_retouching_natural_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fetchDoctors();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    try {
      final response = await supabase.from('doctors').select();
      final List<Doctor> loadedDoctors =
          (response as List).map((doc) => Doctor.fromMap(doc)).toList();

      if (!mounted) return;
      setState(() {
        allDoctors = loadedDoctors;
        isLoading = false;
      });
      _listController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -30,
                      child: _decorativeCircle(140, Colors.white.withOpacity(0.08)),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: _decorativeCircle(100, Colors.white.withOpacity(0.06)),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 70),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'دليل أطباء الديوانية',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'رعايتك الصحية على بُعد ضغطة زر',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _SearchBar(allDoctors: allDoctors),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'التخصصات الطبية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cat = categories[index];
                  return _CategoryTile(
                    name: cat['name'],
                    icon: cat['icon'],
                    index: index,
                    onTap: () => pushAnimated(
                      context,
                      CategoryDoctorsScreen(
                        categoryName: cat['name'],
                        allDoctors: allDoctors,
                      ),
                    ),
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text(
                'أبرز الأطباء المضافين',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
          if (isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const _ShimmerDoctorCard(),
                childCount: 3,
              ),
            )
          else if (allDoctors.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'لا يوجد أطباء مضافون بعد',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final doc = allDoctors[index];
                  final animation = CurvedAnimation(
                    parent: _listController,
                    curve: Interval(
                      (index / (allDoctors.length > 5 ? 5 : allDoctors.length)) * 0.5,
                      1.0,
                      curve: Curves.easeOutCubic,
                    ),
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: DoctorCard(doctor: doc),
                    ),
                  );
                },
                childCount: allDoctors.length > 5 ? 5 : allDoctors.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _decorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final List<Doctor> allDoctors;
  const _SearchBar({required this.allDoctors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        onSubmitted: (value) {
          pushAnimated(
            context,
            SearchResultScreen(searchQuery: value, allDoctors: allDoctors),
          );
        },
        decoration: InputDecoration(
          hintText: 'ابحث عن اسم الطبيب أو الاختصاص...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final String name;
  final IconData icon;
  final int index;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.name,
    required this.icon,
    required this.index,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  double _scale = 1.0;

  static const List<List<Color>> _palette = [
    [Color(0xFF0EA5E9), Color(0xFF0369A1)],
    [Color(0xFF14B8A6), Color(0xFF0F766E)],
    [Color(0xFF6366F1), Color(0xFF4338CA)],
    [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    [Color(0xFF06B6D4), Color(0xFF0E7490)],
    [Color(0xFFEC4899), Color(0xFFBE185D)],
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    [Color(0xFF22C55E), Color(0xFF15803D)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _palette[widget.index % _palette.length];
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
        tapFeedback();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Column(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: colors[1].withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerDoctorCard extends StatefulWidget {
  const _ShimmerDoctorCard();

  @override
  State<_ShimmerDoctorCard> createState() => _ShimmerDoctorCardState();
}

class _ShimmerDoctorCardState extends State<_ShimmerDoctorCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF1F5F9),
                Color(0xFFE2E8F0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  const DoctorCard({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            tapFeedback();
            pushAnimated(context, DoctorDetailScreen(doctor: doctor));
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'doctor-avatar-${doctor.id}-${doctor.fullName}',
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: const BoxDecoration(
                      gradient: AppColors.accentGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          doctor.specialty,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              doctor.clinicName,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryDoctorsScreen extends StatelessWidget {
  final String categoryName;
  final List<Doctor> allDoctors;

  const CategoryDoctorsScreen({super.key, required this.categoryName, required this.allDoctors});

  @override
  Widget build(BuildContext context) {
    final filtered = allDoctors
        .where((d) => d.specialty.contains(categoryName) || categoryName.contains(d.specialty))
        .toList();

    return Scaffold(
      appBar: _gradientAppBar(categoryName),
      body: filtered.isEmpty
          ? _emptyState('لا توجد أطباء مسجلين في هذا التخصص حالياً')
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (context, index) => DoctorCard(doctor: filtered[index]),
            ),
    );
  }
}

class SearchResultScreen extends StatelessWidget {
  final String searchQuery;
  final List<Doctor> allDoctors;

  const SearchResultScreen({super.key, required this.searchQuery, required this.allDoctors});

  @override
  Widget build(BuildContext context) {
    final results = allDoctors
        .where((d) =>
            d.fullName.contains(searchQuery) ||
            d.specialty.contains(searchQuery) ||
            d.clinicName.contains(searchQuery))
        .toList();

    return Scaffold(
      appBar: _gradientAppBar('نتائج البحث: "$searchQuery"'),
      body: results.isEmpty
          ? _emptyState('عذراً، لم نجد نتائج مطابقة لبحثك')
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: results.length,
              itemBuilder: (context, index) => DoctorCard(doctor: results[index]),
            ),
    );
  }
}

class AllDoctorsScreen extends StatelessWidget {
  const AllDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _gradientAppBar('قائمة الأطباء الكاملة'),
      body: FutureBuilder(
        future: Supabase.instance.client.from('doctors').select(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: 5,
              itemBuilder: (context, index) => const _ShimmerDoctorCard(),
            );
          }
          final docs = (snapshot.data as List).map((d) => Doctor.fromMap(d)).toList();
          if (docs.isEmpty) {
            return _emptyState('لا يوجد أطباء مضافون بعد');
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) => DoctorCard(doctor: docs[index]),
          );
        },
      ),
    );
  }
}

// ==================== شاشة "نبض الديوانية" (عشوائي + لا نهائي) ====================
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final supabase = Supabase.instance.client;
  final PageController _pageController = PageController();
  final Map<int, VideoPlayerController> _controllers = {};
  List<MedicalPost> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await supabase
          .from('medical_reels')
          .select();
      
      var posts = (response as List).map((e) => MedicalPost.fromMap(e)).toList();
      posts.shuffle(Random());

      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
      _syncControllers(0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _syncControllers(int centerIndex) {
    if (_posts.isEmpty) return;
    final int len = _posts.length;
    final int prevIndex = (centerIndex - 1 + len) % len;
    final int nextIndex = (centerIndex + 1) % len;

    final wanted = <int>{centerIndex, prevIndex, nextIndex};

    final toRemove = _controllers.keys.where((k) => !wanted.contains(k)).toList();
    for (final k in toRemove) {
      _controllers[k]?.dispose();
      _controllers.remove(k);
    }

    for (final i in wanted) {
      if (_controllers.containsKey(i)) continue;
      final post = _posts[i];
      if (!post.isVideo) continue;
      final uri = Uri.tryParse(post.mediaUrl);
      if (uri == null) continue;
      final controller = VideoPlayerController.networkUrl(uri);
      _controllers[i] = controller;
      controller.setLooping(true);
      controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        if (i == _currentPage) controller.play();
      }).catchError((_) {});
    }
  }

  void _onPageChanged(int index) {
    _controllers[_currentPage]?.pause();
    setState(() => _currentPage = index);
    _controllers[index]?.play();
    _syncControllers(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _hasError
              ? Center(
                  child: Text(
                    'تعذر تحميل المحتوى، تحقق من الاتصال بالإنترنت',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد عروض أو مقاطع مضافة حالياً',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: null, 
                      onPageChanged: (index) {
                        final actualIndex = index % _posts.length;
                        _onPageChanged(actualIndex);
                      },
                      itemBuilder: (context, index) {
                        final actualIndex = index % _posts.length;
                        return _ReelItem(
                          key: ValueKey('${_posts[actualIndex].id}_$index'),
                          post: _posts[actualIndex],
                          controller: _controllers[actualIndex],
                          isActive: actualIndex == _currentPage,
                        );
                      },
                    ),
    );
  }
}

class _ReelItem extends StatefulWidget {
  final MedicalPost post;
  final VideoPlayerController? controller;
  final bool isActive;

  const _ReelItem({super.key, required this.post, required this.controller, required this.isActive});

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem> {
  bool _showPauseIcon = false;
  bool _isLiked = false;
  int _likesCount = 0;
  int _commentsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didUpdateWidget(covariant _ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive && oldWidget.isActive && _showPauseIcon) {
      _showPauseIcon = false;
    }
  }

  Future<void> _loadStats() async {
    try {
      final likesResponse = await Supabase.instance.client
          .from('reel_likes')
          .select()
          .eq('reel_id', widget.post.id);
      final likesList = likesResponse as List;

      final commentsResponse = await Supabase.instance.client
          .from('reel_comments')
          .select()
          .eq('reel_id', widget.post.id);
      final commentsList = commentsResponse as List;

      if (!mounted) return;
      setState(() {
        _likesCount = likesList.length;
        _isLiked = CurrentUser.phone != null &&
            likesList.any((l) => l['user_phone'] == CurrentUser.phone);
        _commentsCount = commentsList.length;
      });
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    final phone = CurrentUser.phone;
    if (phone == null) return;
    tapFeedback();
    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !wasLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
    try {
      if (wasLiked) {
        await Supabase.instance.client
            .from('reel_likes')
            .delete()
            .eq('reel_id', widget.post.id)
            .eq('user_phone', phone);
      } else {
        await Supabase.instance.client.from('reel_likes').insert({
          'reel_id': widget.post.id,
          'user_phone': phone,
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLiked = wasLiked;
        _likesCount += wasLiked ? 1 : -1;
      });
    }
  }

  void _openComments() {
    tapFeedback();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(
        reelId: widget.post.id,
        onCommentAdded: () {
          if (mounted) setState(() => _commentsCount++);
        },
      ),
    );
  }

  Future<void> _share() async {
    tapFeedback();
    final text = Uri.encodeComponent('${widget.post.title}\n${widget.post.mediaUrl}');
    final url = Uri.parse('https://wa.me/?text=$text');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('تعذر فتح المشاركة');
    }
  }

  void _togglePlayPause() {
    final controller = widget.controller;
    if (controller == null || !controller.value.isInitialized) return;
    tapFeedback();
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        _showPauseIcon = true;
      } else {
        controller.play();
        _showPauseIcon = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final controller = widget.controller;
    final isReady = controller != null && controller.value.isInitialized;

    return GestureDetector(
      onTap: post.isVideo ? _togglePlayPause : null,
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (post.isVideo)
              isReady
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator(color: Colors.white))
            else
              Image.network(
                post.mediaUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
                errorBuilder: (context, error, stack) => const Center(
                  child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                ),
              ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 90, 110),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (post.providerName != null && post.providerName!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              post.providerName!,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (post.category != null && post.category!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.4)),
                            ),
                            child: Text(
                              post.category!,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.title,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              left: 12,
              right: null,
              bottom: 130,
              child: Column(
                children: [
                  _ReelActionButton(
                    icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    iconColor: _isLiked ? const Color(0xFFEF4444) : Colors.white,
                    label: _likesCount > 0 ? '$_likesCount' : 'إعجاب',
                    onTap: _toggleLike,
                  ),
                  const SizedBox(height: 20),
                  _ReelActionButton(
                    icon: Icons.mode_comment_rounded,
                    iconColor: Colors.white,
                    label: _commentsCount > 0 ? '$_commentsCount' : 'تعليق',
                    onTap: _openComments,
                  ),
                  const SizedBox(height: 20),
                  _ReelActionButton(
                    icon: Icons.share_rounded,
                    iconColor: Colors.white,
                    label: 'مشاركة',
                    onTap: _share,
                  ),
                ],
              ),
            ),

            if (_showPauseIcon)
              const Center(
                child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 70),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReelActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ReelActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final int reelId;
  final VoidCallback onCommentAdded;

  const _CommentsSheet({required this.reelId, required this.onCommentAdded});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _textController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final response = await Supabase.instance.client
          .from('reel_comments')
          .select()
          .eq('reel_id', widget.reelId)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _comments = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _textController.text.trim();
    final name = CurrentUser.name;
    if (text.isEmpty || name == null || _isSending) return;
    tapFeedback();
    setState(() => _isSending = true);
    try {
      await Supabase.instance.client.from('reel_comments').insert({
        'reel_id': widget.reelId,
        'user_name': name,
        'comment_text': text,
      });
      _textController.clear();
      widget.onCommentAdded();
      await _loadComments();
    } catch (e) {
      debugPrint('تعذر إرسال التعليق: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'التعليقات',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _comments.isEmpty
                      ? const Center(
                          child: Text('كن أول من يعلّق', style: TextStyle(color: AppColors.textMuted)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final c = _comments[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Color(0xFFE0F2FE),
                                    child: Icon(Icons.person, size: 18, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c['user_name']?.toString() ?? 'مستخدم',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          c['comment_text']?.toString() ?? '',
                                          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'اكتب تعليقك...',
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendComment,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.send_rounded, color: AppColors.primary),
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

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  Future<void> _openUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('تعذر فتح الرابط');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _gradientAppBar('المراسلة والخدمات'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppColors.secondary.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 8)),
              ],
            ),
            child: const Column(
              children: [
                Icon(Icons.support_agent_rounded, size: 46, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'قسم المراسلة والاستفسارات الطبية',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 6),
                Text(
                  'قريباً يمكنك التواصل المباشر مع عيادات الديوانية',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'تواصل مع فريق التطبيق',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.chat_rounded,
            iconColor: AppColors.whatsapp,
            title: 'مراسلة مطوّر البرنامج',
            subtitle: 'تواصل مباشر عبر واتساب لأي استفسار أو دعم فني',
            trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
            onTap: () => _openUrl('https://wa.me/9647817499784'),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('تعذر فتح الرابط');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _gradientAppBar('إعدادات التطبيق'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SettingsCard(
            icon: Icons.info_outline_rounded,
            title: 'عن التطبيق',
            subtitle: 'دليل أطباء الديوانية السحابي - النسخة العصرية',
          ),
          const SizedBox(height: 10),
          const _SettingsCard(
            icon: Icons.notifications_outlined,
            title: 'الإشعارات',
            subtitle: 'تفعيل إشعارات العيادات والأطباء الجدد',
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'حساب المطوّر',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.camera_alt_rounded,
            iconColor: const Color(0xFFE1306C),
            title: 'انستقرام المطوّر',
            subtitle: '@bd4bd4',
            trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
            onTap: () => _openUrl('https://instagram.com/bd4bd4'),
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            icon: Icons.chat_rounded,
            iconColor: AppColors.whatsapp,
            title: 'واتساب المطوّر',
            subtitle: '07817499784',
            trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
            onTap: () => _openUrl('https://wa.me/9647817499784'),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap == null
            ? null
            : () {
                tapFeedback();
                onTap!();
              },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: AppColors.secondary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor ?? AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class DoctorDetailScreen extends StatelessWidget {
  final Doctor doctor;
  const DoctorDetailScreen({super.key, required this.doctor});

  Future<void> _openUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('تعذر فتح الرابط');
    }
  }

  Future<void> _openGoogleMap() async {
    final String googleMapsUrl = doctor.hasLocation
        ? 'https://www.google.com/maps/search/?api=1&query=${doctor.latitude},${doctor.longitude}'
        : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${doctor.clinicName} ${doctor.address}')}';

    final Uri url = Uri.parse(googleMapsUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('تعذر فتح الخريطة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Hero(
                          tag: 'doctor-avatar-${doctor.id}-${doctor.fullName}',
                          child: Container(
                            height: 84,
                            width: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.accentGradient,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 6)),
                              ],
                            ),
                            child: const Icon(Icons.person_rounded, size: 46, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          doctor.fullName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            doctor.specialty,
                            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _AnimatedInfoCard(delayMs: 0, icon: Icons.local_hospital_rounded, title: 'العيادة', subtitle: doctor.clinicName),
                  _AnimatedInfoCard(
                    delayMs: 60,
                    icon: Icons.location_on_rounded,
                    title: 'العنوان (اضغط لعرض الموقع على الخريطة)',
                    subtitle: doctor.address,
                    onTap: _openGoogleMap,
                  ),
                  _AnimatedInfoCard(delayMs: 120, icon: Icons.access_time_rounded, title: 'أوقات الدوام', subtitle: doctor.workingHours),
                  _AnimatedInfoCard(delayMs: 180, icon: Icons.description_rounded, title: 'نبذة عن الطبيب', subtitle: doctor.bio),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'اتصال',
                          icon: Icons.phone_rounded,
                          color: AppColors.success,
                          onTap: () => _openUrl('tel:${doctor.phoneNumber}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: 'واتساب',
                          icon: Icons.chat_rounded,
                          color: AppColors.whatsapp,
                          onTap: () => _openUrl('https://wa.me/${doctor.whatsappNumber}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _ActionButton(
                      label: 'عرض موقع العيادة على خرائط جوجل',
                      icon: Icons.map_rounded,
                      color: AppColors.primaryDark,
                      onTap: _openGoogleMap,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedInfoCard extends StatelessWidget {
  final int delayMs;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _AnimatedInfoCard({
    required this.delayMs,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AppColors.secondary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.chevron_left_rounded, color: AppColors.primary, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

PreferredSizeWidget _gradientAppBar(String title) {
  return AppBar(
    title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.heroGradient)),
    elevation: 0,
    centerTitle: true,
    iconTheme: const IconThemeData(color: Colors.white),
  );
}

Widget _emptyState(String message, {IconData icon = Icons.search_off_rounded}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: AppColors.primary.withOpacity(0.4)),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    ),
  );
}