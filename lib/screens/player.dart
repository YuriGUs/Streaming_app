import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart'; 
import '../services/storage_service.dart';
import '../models/movie.dart'; 

class PlayerScreen extends StatefulWidget {
  final int movieId;
  final String title;
  final String token;
  
  final List<Movie>? playlist; 
  final int currentIndex;

  const PlayerScreen({
    super.key,
    required this.movieId,
    required this.title,
    required this.token,
    this.playlist,
    this.currentIndex = 0,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;
  bool _isTransitioning = false;

  bool _showNextVideoMsg = false;
  String _nextVideoTitle = "";

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    _initializeVideo();
  }
    
  Future<void> _initializeVideo() async {
    try {
      final ip = await StorageService().getServerIp();
      final videoUrl = Uri.parse(
          'http://$ip:4000/library/movies/${widget.movieId}/stream?token=${widget.token}');

      _videoPlayerController = VideoPlayerController.networkUrl(videoUrl)
        ..initialize().then((_) {
          
          _videoPlayerController.addListener(_videoEndListener);

          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            autoPlay: true,
            looping: false,
            deviceOrientationsOnEnterFullScreen: [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
            deviceOrientationsAfterFullScreen: [
              DeviceOrientation.portraitUp,
            ],
            allowFullScreen: true, 
            allowPlaybackSpeedChanging: true, 
            errorBuilder: (context, errorMessage) {
              return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white)));
            },
          );
          
          if (mounted) setState(() {}); 
        });
    } catch (error) {
      if (mounted) {
        setState(() { _hasError = true; });
      }
      print("Erro crítico no player: $error");
    }
  }

  void _videoEndListener() {
    if (!_videoPlayerController.value.isInitialized || _isTransitioning) {
      return;
    }

    final position = _videoPlayerController.value.position;
    final duration = _videoPlayerController.value.duration;

    if (position > Duration.zero && position >= (duration - const Duration(seconds: 1))) {
      _isTransitioning = true; 
      _videoPlayerController.removeListener(_videoEndListener);
      _playNextVideo();
    }
  }

  void _playNextVideo() {
    if (widget.playlist != null && widget.currentIndex < widget.playlist!.length - 1) {
      final nextVideo = widget.playlist![widget.currentIndex + 1];

      setState(() {
        _showNextVideoMsg = true;
        _nextVideoTitle = nextVideo.title;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PlayerScreen(
                movieId: nextVideo.id.toInt(),
                title: nextVideo.title,
                token: widget.token,
                playlist: widget.playlist, 
                currentIndex: widget.currentIndex + 1, 
              ),
            ),
          );
        }
      });
      
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
           Navigator.of(context).pop(); 
        }
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _videoPlayerController.removeListener(_videoEndListener);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: _hasError
            ? const Text("Erro ao carregar o vídeo.", style: TextStyle(color: Colors.red))
            : _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Chewie(controller: _chewieController!),
                      
                      if (_showNextVideoMsg)
                        Positioned(
                          top: 24, 
                          left: 0,   // 🌟 AMARRA NA ESQUERDA
                          right: 0,  // 🌟 AMARRA NA DIREITA
                          child: Center( // 🌟 SEGURA TUDO BEM NO MEIO
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, value, child) {
                                return Opacity(opacity: value, child: child);
                              },
                              child: Container(
                                width: 320, 
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white24, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.deepPurpleAccent,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Próximo: $_nextVideoTitle',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1, 
                                        overflow: TextOverflow.ellipsis, 
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : const CircularProgressIndicator(color: Colors.deepPurpleAccent),
      ),
    );
  }
}