import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MusicSong {
  final String id, title, artist, album, imageUrl, previewUrl;
  final int durationMs;
  const MusicSong(
      {required this.id,
      required this.title,
      required this.artist,
      required this.album,
      required this.imageUrl,
      required this.previewUrl,
      required this.durationMs});

  factory MusicSong.fromItunes(Map m) => MusicSong(
        id: m['trackId']?.toString() ?? '',
        title: m['trackName'] as String? ?? '',
        artist: m['artistName'] as String? ?? 'Unknown',
        album: m['collectionName'] as String? ?? '',
        imageUrl: (m['artworkUrl100'] as String? ?? '')
            .replaceAll('100x100bb', '300x300bb'),
        previewUrl: m['previewUrl'] as String? ?? '',
        durationMs: m['trackTimeMillis'] as int? ?? 30000,
      );

  String get durationFmt {
    final s = durationMs ~/ 1000;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

class MusicPlayerService extends ChangeNotifier {
  static final MusicPlayerService _instance = MusicPlayerService._internal();
  factory MusicPlayerService() => _instance;
  static MusicPlayerService get instance => _instance;
  MusicPlayerService._internal() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
  List<MusicSong> _queue = [];
  MusicSong? _current;
  bool _playing = false;
  bool _loading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _currentIdx = 0;

  MusicSong? get current => _current;
  bool get playing => _playing;
  bool get loading => _loading;
  Duration get position => _position;
  Duration get duration => _duration;
  List<MusicSong> get queue => _queue;

  void _init() {
    _player.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });
    _player.durationStream.listen((d) {
      if (d != null) {
        _duration = d;
        notifyListeners();
      }
    });
    _player.playerStateStream.listen((s) {
      _playing = s.playing;
      notifyListeners();
      if (s.processingState == ProcessingState.completed) playNext();
    });
  }

  Future<void> setQueue(List<MusicSong> songs) async {
    _queue = songs;
    notifyListeners();
  }

  Future<void> playSong(MusicSong song, int index) async {
    _loading = true;
    _current = song;
    _currentIdx = index;
    notifyListeners();
    try {
      await _player.stop();
      await _player.setUrl(song.previewUrl);
      await _player.play();
    } catch (e) {
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        await _player.setUrl(song.previewUrl);
        await _player.play();
      } catch (_) {}
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlay() async {
    if (_playing) {
      await _player.pause();
    } else {
      if (_current == null && _queue.isNotEmpty) {
        await playSong(_queue[0], 0);
      } else {
        await _player.play();
      }
    }
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;
    final next = (_currentIdx + 1) % _queue.length;
    await playSong(_queue[next], next);
  }

  Future<void> playPrev() async {
    if (_queue.isEmpty) return;
    final prev = (_currentIdx - 1 + _queue.length) % _queue.length;
    await playSong(_queue[prev], prev);
  }

  void seek(Duration pos) => _player.seek(pos);
}
