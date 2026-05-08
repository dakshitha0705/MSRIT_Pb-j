import 'package:battery_barter/widgets/character_painter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// ── Avatar Screen ──────────────────────────────────
class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});
  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen>
    with SingleTickerProviderStateMixin {
  // Selected items per category
  String _animal = 'panda';
  String? _top;
  String? _bottom;
  String? _outfit; // full outfit overrides top+bottom
  String? _shoesVal;
  String? _hat;
  String? _glasses;
  String? _extra;

  int _catIndex = 0;
  late TabController _tabCtrl;
  bool _saving = false;

  static const _categories = [
    'Animal',
    'Outfit',
    'Top',
    'Bottom',
    'Shoes',
    'Hat',
    'Glasses',
    'Extra',
  ];

  // ── Item definitions ──────────────────────────────
  static const _animals = [
    _Item('panda', 'Panda', '🐼'),
    _Item('fox', 'Fox', '🦊'),
    _Item('cat', 'Cat', '🐱'),
    _Item('bear', 'Bear', '🐻'),
    _Item('bunny', 'Bunny', '🐰'),
    _Item('koala', 'Koala', '🐨'),
    _Item('tiger', 'Tiger', '🐯'),
    _Item('wolf', 'Wolf', '🐺'),
  ];
  static const _outfits = [
    _Item('school', 'School', '🎒'),
    _Item('superhero', 'Hero', '🦸'),
    _Item('tuxedo', 'Tuxedo', '🤵'),
    _Item('spacesuit', 'Astronaut', '👨‍🚀'),
    _Item('ninja', 'Ninja', '🥷'),
    _Item('chef', 'Chef', '👨‍🍳'),
    _Item('doctor', 'Doctor', '👨‍⚕️'),
    _Item('royal', 'Royal', '🤴'),
  ];
  static const _tops = [
    _Item('tshirt', 'T-Shirt', '👕'),
    _Item('hoodie', 'Hoodie', '🧥'),
    _Item('jacket', 'Jacket', '🥼'),
    _Item('suit', 'Blazer', '👔'),
    _Item('dress', 'Dress', '👗'),
    _Item('sweater', 'Sweater', '🧶'),
    _Item('tank', 'Tank Top', '🩱'),
    _Item('polo', 'Polo', '👚'),
  ];
  static const _bottoms = [
    _Item('jeans', 'Jeans', '👖'),
    _Item('shorts', 'Shorts', '🩳'),
    _Item('skirt', 'Skirt', '🩱'),
    _Item('sweats', 'Sweats', '🩲'),
    _Item('trousers', 'Trousers', '👖'),
    _Item('leggings', 'Leggings', '🩲'),
  ];
  static const _shoes = [
    _Item('sneakers', 'Sneakers', '👟'),
    _Item('boots', 'Boots', '👢'),
    _Item('heels', 'Heels', '👠'),
    _Item('sandals', 'Sandals', '🩴'),
    _Item('loafers', 'Loafers', '🥿'),
    _Item('cleats', 'Cleats', '⛸️'),
  ];
  static const _hats = [
    _Item('cap', 'Cap', '🧢'),
    _Item('tophat', 'Top Hat', '🎩'),
    _Item('crown', 'Crown', '👑'),
    _Item('graduation', 'Grad Cap', '🎓'),
    _Item('cowboy', 'Cowboy', '🤠'),
    _Item('santa', 'Santa', '🎅'),
    _Item('beret', 'Beret', '🪖'),
    _Item('party', 'Party', '🎉'),
  ];
  static const _glassesList = [
    _Item('sunglasses', 'Shades', '🕶️'),
    _Item('glasses', 'Glasses', '👓'),
    _Item('goggles', 'Goggles', '🥽'),
    _Item('monocle', 'Monocle', '🧐'),
  ];
  static const _extras = [
    _Item('bow', 'Bow', '🎀'),
    _Item('necklace', 'Chain', '📿'),
    _Item('watch', 'Watch', '⌚'),
    _Item('bag', 'Bag', '👜'),
    _Item('backpack', 'Backpack', '🎒'),
    _Item('umbrella', 'Umbrella', '☂️'),
    _Item('wings', 'Wings', '🪽'),
    _Item('cape', 'Cape', '🦸'),
  ];

  List<_Item> get _currentItems {
    switch (_catIndex) {
      case 0:
        return _animals;
      case 1:
        return _outfits;
      case 2:
        return _tops;
      case 3:
        return _bottoms;
      case 4:
        return _shoes;
      case 5:
        return _hats;
      case 6:
        return _glassesList;
      case 7:
        return _extras;
      default:
        return [];
    }
  }

  String? _selectedForCat(int cat) {
    switch (cat) {
      case 0:
        return _animal;
      case 1:
        return _outfit;
      case 2:
        return _top;
      case 3:
        return _bottom;
      case 4:
        return _shoesVal;

      case 5:
        return _hat;
      case 6:
        return _glasses;
      case 7:
        return _extra;
      default:
        return null;
    }
  }

  void _selectItem(String key) {
    setState(() {
      switch (_catIndex) {
        case 0:
          _animal = key;
          break;
        case 1:
          _outfit = _outfit == key ? null : key;
          break;
        case 2:
          _top = _top == key ? null : key;
          break;
        case 3:
          _bottom = _bottom == key ? null : key;
          break;
        case 4:
          _shoesVal = _shoesVal == key ? null : key;
          break;
        case 5:
          _hat = _hat == key ? null : key;
          break;
        case 6:
          _glasses = _glasses == key ? null : key;
          break;
        case 7:
          _extra = _extra == key ? null : key;
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _categories.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() => _catIndex = _tabCtrl.index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSaved());
  }

  void _loadSaved() {
    final user = context.read<FirestoreService>().currentUser;
    if (user == null) return;
    final key = user.avatar;
    final parts = key.split('|');
    setState(() {
      _animal = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : 'panda';
      _outfit = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
      _top = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
      _bottom = parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null;
      _shoesVal = parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null;
      _hat = parts.length > 5 && parts[5].isNotEmpty ? parts[5] : null;
      _glasses = parts.length > 6 && parts[6].isNotEmpty ? parts[6] : null;
      _extra = parts.length > 7 && parts[7].isNotEmpty ? parts[7] : null;
    });
  }

  String get _avatarKey =>
      '$_animal|${_outfit ?? ''}|${_top ?? ''}|${_bottom ?? ''}|${_shoesVal ?? ''}|${_hat ?? ''}|${_glasses ?? ''}|${_extra ?? ''}';

  Future<void> _save() async {
    setState(() => _saving = true);
    final uid = context.read<AuthService>().uid;
    await context
        .read<FirestoreService>()
        .updateUserFields(uid, {'avatar': _avatarKey});
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar saved!'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.arrow_back_ios_rounded,
                          size: 16,
                          color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('My Avatar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      )),
                  const Spacer(),
                  // Save button
                  GestureDetector(
                    onTap: _saving ? null : _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              )),
                    ),
                  ),
                ],
              ),
            ),

            // ── Character preview ──────────────────────
            Container(
              height: size.height * 0.38,
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        colors: [Color(0xFF1E3A5F), Color(0xFF0D1B3E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)
                    : const LinearGradient(
                        colors: [Color(0xFFDBEAFE), Color(0xFFE0E7FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFF2563EB).withOpacity(0.12),
                ),
              ),
              child: Stack(
                children: [
                  // Floor reflection
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(24)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            (isDark ? Colors.white : const Color(0xFF2563EB))
                                .withOpacity(0.06),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Character
                  Center(
                    child: CustomPaint(
                      size: Size(size.width * 0.45, size.height * 0.33),
                      painter: CharacterPainter(
                        animal: _animal,
                        outfit: _outfit,
                        top: _outfit != null ? null : _top,
                        bottom: _outfit != null ? null : _bottom,
                        shoes: _shoesVal,
                        hat: _hat,
                        glasses: _glasses,
                        extra: _extra,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Category tabs ──────────────────────────
            Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final sel = i == _catIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _catIndex = i);
                      _tabCtrl.animateTo(i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF2563EB)
                            : (isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_categories[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel
                                ? Colors.white
                                : (isDark
                                    ? Colors.white.withOpacity(0.55)
                                    : Colors.black.withOpacity(0.55)),
                          )),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // ── Item grid ──────────────────────────────
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: _currentItems.length,
                itemBuilder: (_, i) {
                  final item = _currentItems[i];
                  final selKey = _selectedForCat(_catIndex);
                  final selected = selKey == item.key;
                  return GestureDetector(
                    onTap: () => _selectItem(item.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: selected
                            ? const Color(0xFF2563EB).withOpacity(0.12)
                            : (isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.white),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF2563EB)
                              : (isDark
                                  ? Colors.white.withOpacity(0.07)
                                  : Colors.black.withOpacity(0.07)),
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                    color: const Color(0xFF2563EB)
                                        .withOpacity(0.18),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.emoji,
                              style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 4),
                          Text(item.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? const Color(0xFF2563EB)
                                    : (isDark
                                        ? Colors.white.withOpacity(0.6)
                                        : Colors.black.withOpacity(0.5)),
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item model ─────────────────────────────────────
class _Item {
  final String key, label, emoji;
  const _Item(this.key, this.label, this.emoji);
}

// ── Character Painter ──────────────────────────────
