import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const HuangguoVIPApp());
}

class HuangguoVIPApp extends StatelessWidget {
  const HuangguoVIPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '黄果短剧 VIP版',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> _dramas = [];
  bool _loading = true;
  int _currentPage = 1;
  final int _totalPages = 144;
  String _filterStatus = 'all';
  String _filterSort = 'hot';
  bool _isVIP = true;

  final List<String> _apiBases = [
    'https://ctb09.ir95e08v.cc',
  ];

  @override
  void initState() {
    super.initState();
    _loadVIPStatus();
    _loadDramas();
  }

  Future<void> _loadVIPStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isVIP = prefs.getBool('isVIP') ?? true;
    });
  }

  Future<void> _loadDramas() async {
    setState(() => _loading = true);

    for (final apiBase in _apiBases) {
      try {
        final params = <String, String>{
          'page': _currentPage.toString(),
          if (_filterSort == 'hot') 'sort': 'hot',
          if (_filterSort == 'new') 'sort': 'new',
          if (_filterStatus == 'completed') 'is_finished': '1',
          if (_filterStatus == 'unfinished') 'is_finished': '0',
        };

        final uri = Uri.parse('$apiBase/api/videos').replace(queryParameters: params);
        final response = await http.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 1 && data['data'] != null) {
            final items = data['data']['items'] as List<dynamic>?;
            if (items != null) {
              setState(() {
                _dramas.clear();
                for (final item in items) {
                  _dramas.add({
                    'id': item['id'],
                    'title': item['title'] ?? '',
                    'cover': item['cover'] ?? '',
                    'score': (item['score'] ?? 0).toDouble(),
                    'episodes': item['episode_count'] ?? 1,
                    'isFinished': item['is_finished'] == true || item['is_finished'] == 1,
                    'tags': item['tags'] ?? [],
                    'desc': item['description'] ?? '',
                  });
                }
                _loading = false;
              });
              return;
            }
          }
        }
      } catch (e) {
        print('API error: $e');
        continue;
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('黄果短剧'),
            if (_isVIP)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'VIP',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 3 / 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              padding: const EdgeInsets.all(8),
              itemCount: _dramas.length + (_currentPage < _totalPages ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _dramas.length) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentPage++;
                        });
                        _loadDramas();
                      },
                      child: const Text('加载更多'),
                    ),
                  );
                }
                final drama = _dramas[index];
                return DramaCard(
                  drama: drama,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPage(dramaId: drama['id']),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('筛选条件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('状态'),
            Row(
              children: [
                FilterChip(
                  label: const Text('全部'),
                  selected: _filterStatus == 'all',
                  onSelected: (selected) {
                    setState(() => _filterStatus = 'all');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('已完结'),
                  selected: _filterStatus == 'completed',
                  onSelected: (selected) {
                    setState(() => _filterStatus = 'completed');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('连载中'),
                  selected: _filterStatus == 'unfinished',
                  onSelected: (selected) {
                    setState(() => _filterStatus = 'unfinished');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('排序'),
            Row(
              children: [
                FilterChip(
                  label: const Text('热门'),
                  selected: _filterSort == 'hot',
                  onSelected: (selected) {
                    setState(() => _filterSort = 'hot');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('最新'),
                  selected: _filterSort == 'new',
                  onSelected: (selected) {
                    setState(() => _filterSort = 'new');
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _currentPage = 1);
              _loadDramas();
              Navigator.pop(context);
            },
            child: const Text('应用'),
          ),
        ],
      ),
    );
  }
}

class DramaCard extends StatelessWidget {
  final Map<String, dynamic> drama;
  final VoidCallback onTap;

  const DramaCard({super.key, required this.drama, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                drama['cover'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(child: Icon(Icons.error)),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drama['title'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          drama['score'].toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        drama['isFinished'] ? '全${drama['episodes']}集' : '更新至${drama['episodes']}集',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
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

class DetailPage extends StatefulWidget {
  final int dramaId;

  const DetailPage({super.key, required this.dramaId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Map<String, dynamic>? _drama;
  List<int> _episodes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);

    try {
      final response = await http.get(
        Uri.parse('https://ctb09.ir95e08v.cc/video/${widget.dramaId}/'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final html = response.body;
        final match = RegExp(r'<script[^>]*id="videoInitialData"[^>]*>(.*?)</script>')
            .firstMatch(html);
        if (match != null) {
          final jsonStr = match.group(1)!;
          final data = json.decode(jsonStr);
          final tracking = data['tracking'] as Map<String, dynamic>?;
          final totalEp = tracking?['total_episode'] ?? 1;
          final epPlaySrcs = data['epPlaySrcs'] as Map<String, dynamic>?;
          final availableEps = epPlaySrcs?.keys.length ?? 0;
          final isFinished = availableEps >= totalEp || data['is_finished'] == true;

          setState(() {
            _drama = {
              'id': widget.dramaId,
              'title': data['title'] ?? '',
              'cover': data['posterSrc'] ?? '',
              'desc': data['description'] ?? '',
              'tags': data['tags'] ?? [],
              'totalEpisodes': totalEp,
              'availableEpisodes': availableEps,
              'isFinished': isFinished,
              'epPlaySrcs': epPlaySrcs ?? {},
              'score': data['score'] ?? 0,
            };
            _episodes = (epPlaySrcs?.keys ?? [])
                .map((e) => int.parse(e.toString()))
                .toList()
              ..sort();
            _loading = false;
          });
        }
      }
    } catch (e) {
      print('Detail error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_drama?['title'] ?? '加载中...'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drama == null
              ? const Center(child: Text('加载失败'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(_drama!['cover']),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _drama!['title'],
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  _drama!['isFinished'] ? '已完结' : '连载中',
                                  style: const TextStyle(color: Colors.amber),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  _drama!['isFinished']
                                      ? '全${_drama!['totalEpisodes']}集'
                                      : '更新至${_drama!['availableEpisodes']}集',
                                ),
                                const SizedBox(width: 16),
                                Text('${_drama!['score']}分'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (_drama!['tags'] as List<dynamic>)
                                  .map((tag) => Chip(
                                        label: Text(tag.toString()),
                                        backgroundColor: Colors.amber.withOpacity(0.2),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                            Text(_drama!['desc']),
                            const SizedBox(height: 24),
                            const Text(
                              '剧集列表',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _episodes
                                  .map((ep) => ElevatedButton(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PlayerPage(
                                              dramaId: widget.dramaId,
                                              episode: ep,
                                              epPlaySrcs: _drama!['epPlaySrcs'],
                                              dramaTitle: _drama!['title'],
                                            ),
                                          ),
                                        ),
                                        child: Text('第$ep集'),
                                      ))
                                  .toList(),
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

class PlayerPage extends StatefulWidget {
  final int dramaId;
  final int episode;
  final Map<String, dynamic> epPlaySrcs;
  final String dramaTitle;

  const PlayerPage({super.key, required this.dramaId, required this.episode, required this.epPlaySrcs, required this.dramaTitle});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _errorMessage;
  double _speed = 1;
  Timer? _timer;
  int _attempt = 0;

  List<int> get _episodes => widget.epPlaySrcs.keys
      .map((key) => int.tryParse(key.toString()))
      .whereType<int>()
      .toList()
    ..sort();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => unawaited(_saveProgress()));
  }

  Uri? _videoUri() {
    final source = widget.epPlaySrcs[widget.episode.toString()];
    if (source is! String || source.trim().isEmpty) return null;
    final parsed = Uri.tryParse(source.trim());
    if (parsed == null) return null;
    final uri = parsed.hasScheme ? parsed : Uri.parse('https://ctb09.ir95e08v.cc').resolveUri(parsed);
    return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty ? uri : null;
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;
    final attempt = ++_attempt;
    setState(() { _loading = true; _errorMessage = null; });
    final old = _controller;
    _controller = null;
    await old?.dispose();
    final uri = _videoUri();
    if (uri == null) {
      if (mounted && attempt == _attempt) setState(() { _loading = false; _errorMessage = '暂时没有可播放的视频地址'; });
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri, httpHeaders: const {
      'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
    });
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || attempt != _attempt) { await controller.dispose(); return; }
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble('progress_${widget.dramaId}_${widget.episode}');
      if (saved != null && saved > 0) {
        final target = Duration(seconds: saved.floor());
        final duration = controller.value.duration;
        await controller.seekTo(duration > Duration.zero && target > duration ? duration : target);
      }
      await controller.play();
      if (mounted && attempt == _attempt) setState(() => _loading = false);
    } catch (error) {
      debugPrint('Player initialization failed: $error');
      await controller.dispose();
      if (mounted && attempt == _attempt) setState(() {
        _controller = null;
        _loading = false;
        _errorMessage = '视频加载失败，请检查网络后重试';
      });
    }
  }

  Future<void> _saveProgress() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final seconds = controller.value.position.inSeconds.toDouble();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('progress_${widget.dramaId}_${widget.episode}', seconds);
      await prefs.setInt('last_drama_id', widget.dramaId);
      await prefs.setInt('last_episode', widget.episode);
    } catch (error) { debugPrint('Unable to save playback progress: $error'); }
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_saveProgress());
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _seek(Duration change) async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final next = c.value.position + change;
    final end = c.value.duration;
    await c.seekTo(next < Duration.zero ? Duration.zero : (end > Duration.zero && next > end ? end : next));
  }

  Future<void> _toggle() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) { await c.pause(); } else { await c.play(); }
    if (mounted) setState(() {});
  }

  void _openEpisode(int episode) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => PlayerPage(
      dramaId: widget.dramaId,
      episode: episode,
      epPlaySrcs: widget.epPlaySrcs,
      dramaTitle: widget.dramaTitle,
    )));
  }

  String _time(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours, m = d.inMinutes.remainder(60), s = d.inSeconds.remainder(60);
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.dramaTitle} · 第 ${widget.episode} 集')),
    body: ColoredBox(color: Colors.black, child: Column(children: [
      Expanded(child: Center(child: _loading
        ? const CircularProgressIndicator()
        : _errorMessage != null
          ? _PlayerError(message: _errorMessage!, onRetry: _initializePlayer)
          : _buildVideo())),
      if (!_loading && _errorMessage == null) _buildControls(),
    ])),
  );

  Widget _buildVideo() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return _PlayerError(message: '播放器尚未准备好', onRetry: _initializePlayer);
    return ValueListenableBuilder<VideoPlayerValue>(valueListenable: c, builder: (context, value, child) {
      if (value.hasError) return _PlayerError(message: '播放中断，请检查视频地址或网络后重试', onRetry: _initializePlayer);
      final ratio = value.aspectRatio;
      return AspectRatio(aspectRatio: ratio.isFinite && ratio > 0 ? ratio : 16 / 9, child: VideoPlayer(c));
    });
  }

  Widget _buildControls() {
    final c = _controller!;
    final episodes = _episodes;
    final index = episodes.indexOf(widget.episode);
    return SafeArea(top: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        VideoProgressIndicator(c, allowScrubbing: true, padding: const EdgeInsets.symmetric(vertical: 8), colors: VideoProgressColors(playedColor: Colors.amber, bufferedColor: Colors.white38, backgroundColor: Colors.white24)),
        ValueListenableBuilder<VideoPlayerValue>(valueListenable: c, builder: (context, value, child) => Row(children: [
          Text('${_time(value.position)} / ${_time(value.duration)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const Spacer(),
          IconButton(tooltip: '上一集', onPressed: index > 0 ? () => _openEpisode(episodes[index - 1]) : null, icon: const Icon(Icons.skip_previous)),
          IconButton(tooltip: '下一集', onPressed: index >= 0 && index < episodes.length - 1 ? () => _openEpisode(episodes[index + 1]) : null, icon: const Icon(Icons.skip_next)),
        ])),
        ValueListenableBuilder<VideoPlayerValue>(valueListenable: c, builder: (context, value, child) => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          IconButton(tooltip: '后退 10 秒', onPressed: () => _seek(const Duration(seconds: -10)), icon: const Icon(Icons.replay_10)),
          IconButton.filled(tooltip: value.isPlaying ? '暂停' : '播放', onPressed: _toggle, icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow)),
          IconButton(tooltip: '前进 10 秒', onPressed: () => _seek(const Duration(seconds: 10)), icon: const Icon(Icons.forward_10)),
          PopupMenuButton<double>(tooltip: '播放速度', initialValue: _speed, onSelected: (speed) async {
            await c.setPlaybackSpeed(speed);
            if (mounted) setState(() => _speed = speed);
          }, itemBuilder: (_) => [for (final speed in [0.75, 1.0, 1.25, 1.5, 2.0]) PopupMenuItem(value: speed, child: Text('${speed}×'))], child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${_speed}×'))),
        ])),
      ]),
    ));
  }
}

class _PlayerError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _PlayerError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: Colors.white70, size: 40),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('重试')),
    ]),
  );
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDramaId = prefs.getInt('last_drama_id');
    final lastEpisode = prefs.getInt('last_episode');

    if (lastDramaId != null && lastEpisode != null) {
      setState(() {
        _history = [
          {
            'dramaId': lastDramaId,
            'episode': lastEpisode,
          }
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('观看历史'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('last_drama_id');
              await prefs.remove('last_episode');
              setState(() => _history.clear());
            },
          ),
        ],
      ),
      body: _history.isEmpty
          ? const Center(child: Text('暂无观看历史'))
          : ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return ListTile(
                  title: Text('短剧 ID: ${item['dramaId']}'),
                  subtitle: Text('第${item['episode']}集'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPage(dramaId: item['dramaId']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
