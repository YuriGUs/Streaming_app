import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/movie.dart';
import 'player.dart';

class EpisodesScreen extends StatelessWidget {
  final String showTitle;
  final List<Movie> episodes;
  final String token;
  final String ip;

  const EpisodesScreen({
    super.key,
    required this.showTitle,
    required this.episodes,
    required this.token,
    required this.ip,
  });

  @override
  Widget build(BuildContext context) {
    // Ordena os episódios para garantir a cronologia correta (Ep01, Ep02...)
    episodes.sort((a, b) => a.title.compareTo(b.title));

    return Scaffold(
      appBar: AppBar(
        title: Text(showTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black87,
        toolbarHeight: 70,
      ),
      backgroundColor: Colors.grey[950],
      // 📺 MUDANÇA PARA TV: GridView deitado (16:9) no lugar de vertical espremido
      body: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 📺 4 episódios horizontais por linha
          crossAxisSpacing: 24,
          mainAxisSpacing: 32,
          childAspectRatio: 1.4, // Proporção perfeita para miniatura de vídeo + texto embaixo
        ),
        itemCount: episodes.length,
        itemBuilder: (context, index) {
          final ep = episodes[index];
          return TvEpisodeCard(
            ep: ep,
            index: index,
            playlist: episodes,
            token: token,
            ip: ip,
          );
        },
      ),
    );
  }
}

// 📺 Componente focado em reproduzir episódios com controle remoto
class TvEpisodeCard extends StatefulWidget {
  final Movie ep;
  final int index;
  final List<Movie> playlist;
  final String token;
  final String ip;

  const TvEpisodeCard({
    super.key,
    required this.ep,
    required this.index,
    required this.playlist,
    required this.token,
    required this.ip,
  });

  @override
  State<TvEpisodeCard> createState() => _TvEpisodeCardState();
}

class _TvEpisodeCardState extends State<TvEpisodeCard> {
  bool _isFocused = false;

  void _playVideo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerScreen(
          movieId: widget.ep.id.toInt(),
          title: widget.ep.title,
          token: widget.token,
          playlist: widget.playlist,   
          currentIndex: widget.index,  
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focus) => setState(() => _isFocused = focus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
          _playVideo();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isFocused ? 1.05 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _isFocused ? Colors.white : Colors.transparent, width: 3),
          boxShadow: _isFocused
              ? [BoxShadow(color: Colors.deepPurpleAccent.withValues(alpha: 0.5), blurRadius: 16, spreadRadius: 1)]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GestureDetector(
            onTap: _playVideo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Miniatura do episódio
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.grey[900]),
                      widget.ep.thumbnailPath != null
                          ? Image.network(
                              'http://${widget.ip}:4000/library/movies/${widget.ep.id}/thumbnail',
                              headers: {'Authorization': 'Bearer ${widget.token}'},
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.movie, color: Colors.white24, size: 40),
                            )
                          : const Icon(Icons.movie, color: Colors.white24, size: 40),
                      
                      // Ícone de Play centralizado discreto
                      if (_isFocused)
                        Container(
                          color: Colors.black38,
                          child: const Center(
                            child: Icon(Icons.play_circle_fill, color: Colors.deepPurpleAccent, size: 48),
                          ),
                        ),
                      
                      // Tarja de Duração discreta no canto do vídeo
                      Positioned(
                        bottom: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            '${(widget.ep.duration / 60).floor()}m',
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Textos descritivos abaixo do vídeo
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.grey[900],
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Center(
                      child: Text(
                        widget.ep.title,
                        style: TextStyle(
                          color: _isFocused ? Colors.deepPurpleAccent : Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 14
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}