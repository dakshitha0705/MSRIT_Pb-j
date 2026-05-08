import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/music_player_service.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});
  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final _music = MusicPlayerService.instance;
  final _searchCtrl = TextEditingController();
  List<dynamic> _results = [];
  bool _searching = false;

  final _trending = [
    'Arijit Singh',
    'AP Dhillon',
    'Taylor Swift',
    'Bollywood 2024',
    'Punjabi hits',
    'The Weeknd',
    'KK songs',
    'Atif Aslam',
    'A.R. Rahman',
  ];

  @override
  void initState() {
    super.initState();
    _music.addListener(_onMusicChange);
    if (_music.queue.isEmpty)
      _search('Bollywood top hits');
    else
      setState(() => _results = _music.queue);
  }

  @override
  void dispose() {
    _music.removeListener(_onMusicChange);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onMusicChange() {
    if (mounted) setState(() {});
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _results = [];
    });
    try {
      final url = Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}'
          '&media=music&entity=song&limit=25&country=IN');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final songs = (data['results'] as List? ?? [])
            .where((s) => (s['previewUrl'] as String? ?? '').isNotEmpty)
            .map((s) => MusicSong.fromItunes(s as Map))
            .toList();
        await _music.setQueue(songs);
        setState(() {
          _results = songs;
          _searching = false;
        });
      } else {
        setState(() => _searching = false);
      }
    } catch (e) {
      setState(() => _searching = false);
      _snack('Connection error');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2)));

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
      '${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF1F5F9),
      body: SafeArea(
          child: Column(children: [
        // Header
        Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
            child: Row(children: [
              IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  onPressed: () => Navigator.pop(context)),
              Expanded(
                  child: Text('AmpUp Music',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.5))),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.3))),
                  child: const Text('30s Preview',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1)))),
            ])),

        // Search
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Container(
                decoration: BoxDecoration(
                    color:
                        isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.08))),
                child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    onSubmitted: _search,
                    decoration: InputDecoration(
                        hintText: 'Search any song or artist...',
                        hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white.withOpacity(0.3)
                                : Colors.black.withOpacity(0.3)),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: isDark
                                ? Colors.white.withOpacity(0.4)
                                : Colors.black.withOpacity(0.4)),
                        suffixIcon: _searching
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: const Color(0xFF6366F1))))
                            : _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.4)
                                            : Colors.black.withOpacity(0.4)),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      _search('Bollywood top hits');
                                    })
                                : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 4))))),

        // Now playing
        if (_music.current != null) ...[
          _buildNowPlaying(isDark),
          const SizedBox(height: 8),
        ],

        // Trending chips
        if (_results.isEmpty && !_searching)
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _trending
                      .map((t) => GestureDetector(
                          onTap: () {
                            _searchCtrl.text = t;
                            _search(t);
                          },
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF6366F1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFF6366F1)
                                          .withOpacity(0.3))),
                              child: Text(t,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6366F1),
                                      fontWeight: FontWeight.w600)))))
                      .toList())),

        Expanded(child: _buildList(isDark)),
      ])),
    );
  }

  Widget _buildNowPlaying(bool isDark) {
    final song = _music.current!;
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6366F1).withOpacity(isDark ? 0.3 : 0.15),
                  const Color(0xFF818CF8).withOpacity(isDark ? 0.2 : 0.1)
                ]),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: const Color(0xFF6366F1).withOpacity(0.3))),
        child: Column(children: [
          Row(children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: song.imageUrl.isNotEmpty
                    ? Image.network(song.imageUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(52))
                    : _placeholder(52)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A))),
                  Text(song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.45))),
                ])),
            IconButton(
                icon: Icon(Icons.skip_previous_rounded,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    size: 22),
                onPressed: _music.playPrev),
            GestureDetector(
                onTap: _music.togglePlay,
                child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF818CF8)])),
                    child: _music.loading
                        ? const Center(
                            child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)))
                        : Icon(
                            _music.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24))),
            IconButton(
                icon: Icon(Icons.skip_next_rounded,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    size: 22),
                onPressed: _music.playNext),
          ]),
          const SizedBox(height: 8),
          SliderTheme(
              data: SliderThemeData(
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 10),
                  trackHeight: 2.5,
                  thumbColor: const Color(0xFF6366F1),
                  activeTrackColor: const Color(0xFF6366F1),
                  inactiveTrackColor: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                  overlayColor: const Color(0xFF6366F1).withOpacity(0.2)),
              child: Slider(
                  value: _music.duration.inSeconds > 0
                      ? _music.position.inSeconds
                          .toDouble()
                          .clamp(0, _music.duration.inSeconds.toDouble())
                      : 0,
                  max: _music.duration.inSeconds > 0
                      ? _music.duration.inSeconds.toDouble()
                      : 1,
                  onChanged: (v) => _music.seek(Duration(seconds: v.toInt())))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(_music.position),
                        style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? Colors.white.withOpacity(0.4)
                                : Colors.black.withOpacity(0.4))),
                    Text('30s preview',
                        style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? Colors.white.withOpacity(0.3)
                                : Colors.black.withOpacity(0.3))),
                    Text(_fmt(_music.duration),
                        style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? Colors.white.withOpacity(0.4)
                                : Colors.black.withOpacity(0.4))),
                  ])),
        ]));
  }

  Widget _buildList(bool isDark) {
    if (_searching)
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    if (_results.isEmpty)
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.music_note_rounded,
            size: 48,
            color: isDark
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.15)),
        const SizedBox(height: 12),
        Text('Search for any song or artist',
            style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.3))),
      ]));

    return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _results.length,
        itemBuilder: (_, i) {
          final song = _results[i] as MusicSong;
          final isCurrent = _music.current?.id == song.id;
          return GestureDetector(
              onTap: () => _music.playSong(song, i),
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF6366F1)
                              .withOpacity(isDark ? 0.15 : 0.08)
                          : (isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isCurrent
                              ? const Color(0xFF6366F1).withOpacity(0.4)
                              : (isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.06)),
                          width: isCurrent ? 1.5 : 1)),
                  child: Row(children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: song.imageUrl.isNotEmpty
                            ? Image.network(song.imageUrl,
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholder(46))
                            : _placeholder(46)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent
                                      ? const Color(0xFF6366F1)
                                      : (isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A)))),
                          Text('${song.artist} • ${song.album}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.4)
                                      : Colors.black.withOpacity(0.4))),
                        ])),
                    const SizedBox(width: 8),
                    if (isCurrent && _music.playing)
                      const Icon(Icons.equalizer_rounded,
                          color: Color(0xFF6366F1), size: 16)
                    else
                      Text(song.durationFmt,
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white.withOpacity(0.35)
                                  : Colors.black.withOpacity(0.35))),
                  ])));
        });
  }

  Widget _placeholder(double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF818CF8)])),
      child: Icon(Icons.music_note_rounded,
          color: Colors.white, size: size * 0.45));
}
