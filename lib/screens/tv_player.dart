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

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _tuneIn();
  }

  Future<void> _tuneIn() async {
    try {
      // 1. Pergunta ao servidor o que está passando agora
      final tvData = await TvService().getLiveTv();
      final movieId = tvData['movie_id'];
      final offsetSeconds = tvData['offset_seconds'];

      print('📺 TV RECEBEU -> ID: ${tvData['movie_id']} | Pulo: ${tvData['offset_seconds']}s');
      print('📺 SINTONIZANDO TV: Filme ID $movieId | Pulando para o segundo $offsetSeconds');
      
      setState(() {
        _currentTitle = tvData['title'] ?? "TV Ao Vivo";
      });

      // 2. Prepara a URL do vídeo
      final token = await StorageService().getToken(); // Pegue o token como você já faz
      final videoUrl = 'http://10.0.2.2:4000/library/movies/$movieId/stream';

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: {'Authorization': 'Bearer $token'},
      );

      // 3. Inicializa o vídeo
      await _videoPlayerController!.initialize();

      // 4. O PULO DO GATO DA TV: Pula para o tempo exato que o servidor mandou!
      await _videoPlayerController!.seekTo(Duration(seconds: offsetSeconds));

      // 5. Configura o player da interface (escondemos os controles para dar mais cara de TV)
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        showControls: false, // Na TV, o usuário não pode pausar nem voltar!
      );

      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _currentTitle = "Erro ao sintonizar";
        _isLoading = false;
      });
      print(e);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
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
                    // O GestureDetector volta a abraçar tudo!
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _showOverlay = !_showOverlay;
                      });
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. O VÍDEO "AMORDAÇADO"
                        // O IgnorePointer impede o Chewie de roubar qualquer toque na tela
                        IgnorePointer(
                          child: Chewie(controller: _chewieController!),
                        ),

                        // 2. A CAMADA DE CONTROLES CUSTOMIZADA
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