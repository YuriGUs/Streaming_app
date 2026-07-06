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
  bool _isMuted = false;
  bool _isTransitioning = false; // NOVO: Impede que o app surte e pule dois vídeos

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
    setState(() { _isLoading = true; });
    
    // Desliga o espião antigo para evitar conflitos de memória
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

      // Guarda os players antigos para destruí-los depois, mantendo a tela preta lisa
      final oldVideoController = _videoPlayerController;
      final oldChewieController = _chewieController;

      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.seekTo(Duration(seconds: offsetSeconds));

      // 🌟 O NOVO ESPIÃO DA TV: Fica monitorando quando o programa vai acabar
      _videoPlayerController!.addListener(_videoEndListener);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        showControls: false, 
      );

      // Limpa os reprodutores antigos
      oldChewieController?.dispose();
      oldVideoController?.dispose();

      setState(() {
        _isLoading = false;
        _isTransitioning = false;
      });
      
    } catch (e) {
      setState(() {
        _currentTitle = "Erro ao sintonizar";
        _isLoading = false;
      });
      print(e);
    }
  }

  // 🌟 AÇÃO AO FIM DO VÍDEO
  void _videoEndListener() {
    if (_videoPlayerController == null || !_videoPlayerController!.value.isInitialized || _isTransitioning) {
      return;
    }

    final position = _videoPlayerController!.value.position;
    final duration = _videoPlayerController!.value.duration;

    // Se faltar 1 segundo para acabar...
    if (position > Duration.zero && position >= (duration - const Duration(seconds: 1))) {
      _isTransitioning = true; 
      _videoPlayerController!.removeListener(_videoEndListener);
      
      // Sintoniza a TV novamente em segundo plano!
      _tuneIn(); 
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
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

                        if (_showOverlay) ...[
                          Positioned(
                            top: 0, left: 0, right: 0,
                            child: Container(
                              height: 100,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black87, Colors.transparent],
                                ),
                              ),
                              child: SafeArea(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          _currentTitle,
                                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      margin: const EdgeInsets.only(top: 8, right: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('AO VIVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          Positioned(
                            bottom: 40, right: 20,
                            child: FloatingActionButton(
                              backgroundColor: Colors.deepPurpleAccent.withValues(alpha: 0.8),
                              onPressed: () {
                                setState(() {
                                  _isMuted = !_isMuted;
                                  _videoPlayerController!.setVolume(_isMuted ? 0.0 : 1.0);
                                });
                              },
                              child: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const Text("Sem sinal", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}