import 'package:flutter/material.dart';
import 'package:streamer_app/services/storage_service.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import '../services/tv_service.dart';

class TvPlayerScreen extends StatefulWidget {
  const TvPlayerScreen({Key? key}) : super(key: key);

  @override
  State<TvPlayerScreen> createState() => _TvPlayerScreenState();
}

class _TvPlayerScreenState extends State<TvPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String _currentTitle = "Carregando sinal...";
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _tuneIn();
  }

  Future<void> _tuneIn() async {
    setState(() { 
      _isLoading = true; 
      _showOverlay = true; 
    });
    
    _videoPlayerController?.removeListener(_videoEndListener);
    
    try {
      final tvData = await TvService().getLiveTv();
      final movieId = tvData['movie_id'];
      final offsetSeconds = tvData['offset_seconds'];

      if (movieId == 0) {
        setState(() {
          _currentTitle = "Fora do ar";
          _isLoading = false;
        });
        return; 
      }

      setState(() {
        _currentTitle = tvData['title'] ?? "TV Ao Vivo";
      });

      final token = await StorageService().getToken(); 
      final ip = await StorageService().getServerIp(); 
      final videoUrl = 'http://$ip:4000/library/movies/$movieId/stream?token=$token';

      final oldVideoController = _videoPlayerController;
      final oldChewieController = _chewieController;

      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.seekTo(Duration(seconds: offsetSeconds));

      _videoPlayerController!.addListener(_videoEndListener);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        showControls: false, 
      );

      oldChewieController?.dispose();
      oldVideoController?.dispose();

      setState(() {
        _isLoading = false;
      });

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showOverlay = false;
          });
        }
      });
      
    } catch (e) {
      setState(() {
        _currentTitle = "Erro ao sintonizar";
        _isLoading = false;
      });
      print(e);
    }
  }

  void _videoEndListener() {
    if (_videoPlayerController == null || !_videoPlayerController!.value.isInitialized) {
      return;
    }

    final position = _videoPlayerController!.value.position;
    final duration = _videoPlayerController!.value.duration;

    if (position > Duration.zero && position >= (duration - const Duration(seconds: 1))) {
      _videoPlayerController!.removeListener(_videoEndListener);
      _tuneIn(); 
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_videoEndListener);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.deepPurpleAccent)
            : _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _showOverlay = !_showOverlay;
                      });
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        IgnorePointer(
                          child: Chewie(controller: _chewieController!),
                        ),

                        if (_showOverlay)
                          Positioned(
                            top: 0, left: 0, right: 0,
                            child: Container(
                              height: 110,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black, Colors.transparent],
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'AO VIVO', 
                                      style: TextStyle(
                                        color: Colors.white, 
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _currentTitle,
                                      style: const TextStyle(
                                        color: Colors.white, 
                                        fontSize: 22, 
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : const Text("Sem sinal", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}