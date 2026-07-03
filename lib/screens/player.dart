import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart'; 
// Ajuste o import abaixo se a sua pasta se chamar diferente, 
// mas o padrão que estávamos usando era o relativo:
import '../services/storage_service.dart';

class PlayerScreen extends StatefulWidget {
  final int movieId;
  final String title;
  final String token;

  const PlayerScreen({
    super.key,
    required this.movieId,
    required this.title,
    required this.token,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    
    // DESTRANCA AS ORIENTAÇÕES QUANDO O PLAYER ABRIR
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Chama a função assíncrona que carrega o vídeo
    _initializeVideo();
  }
    
  Future<void> _initializeVideo() async {
    try {
      // 1. Pega o IP e monta a URL de forma dinâmica
      final ip = await StorageService().getServerIp();
      final videoUrl = Uri.parse(
          'http://$ip:4000/library/movies/${widget.movieId}/stream?token=${widget.token}');

      // 2. Inicializa o controlador do player
      _videoPlayerController = VideoPlayerController.networkUrl(videoUrl)
        ..initialize().then((_) {
          // 3. Quando o vídeo carregar, configura a interface do Chewie
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            autoPlay: true,
            looping: false,

            // Configura as orientações do vídeo
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
          
          // 4. Atualiza a tela para mostrar o player de forma segura
          if (mounted) setState(() {}); 
        });
    } catch (error) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
      print("Erro crítico no player: $error");
    }
  }

  @override
  void dispose() {
    // TRANCA TUDO NA VERTICAL DE NOVO NA HORA DE IR EMBORA
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

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
            ? const Text(
                "Erro ao carregar o vídeo.",
                style: TextStyle(color: Colors.red),
              )
            : _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(
                    controller: _chewieController!,
                  )
                : const CircularProgressIndicator(
                    color: Colors.deepPurpleAccent,
                  ),
      ),
    );
  }
}