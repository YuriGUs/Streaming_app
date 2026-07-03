import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart'; // NOVO IMPORT

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
  ChewieController? _chewieController; // NOVO: O controlador da interface bonita
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    
    final videoUrl = Uri.parse(
        'http://10.0.2.2:4000/library/movies/${widget.movieId}/stream?token=${widget.token}');

    _videoPlayerController = VideoPlayerController.networkUrl(videoUrl)
      ..initialize().then((_) {
        // Quando o vídeo carregar, configuramos a interface do Chewie
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: true,
          looping: false,
          allowFullScreen: true, // Habilita o botão de tela cheia
          allowPlaybackSpeedChanging: true, // Velocidade 1.5x, 2x etc
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(errorMessage, style: const TextStyle(color: Colors.white)),
            );
          },
        );
        
        setState(() {}); // Atualiza a tela
      }).catchError((error) {
        setState(() {
          _hasError = true;
        });
        print("Erro crítico no player: $error");
      });
  }

  @override
  void dispose() {
    // Agora precisamos destruir os DOIS controladores para não vazar memória
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
            // Se o Chewie estiver pronto, mostramos ele!
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