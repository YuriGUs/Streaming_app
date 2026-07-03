import 'package:flutter/material.dart';
import '../models/movie.dart';
import 'player.dart';

class EpisodesScreen extends StatelessWidget {
  final String showTitle;
  final List<Movie> episodes;
  final String token;
  final String ip; // NOVO: A tela agora exige o IP para carregar as imagens!

  const EpisodesScreen({
    Key? key,
    required this.showTitle,
    required this.episodes,
    required this.token,
    required this.ip, // NOVO
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ordena os episódios por nome para garantir que o Ep01 venha antes do Ep02
    episodes.sort((a, b) => a.title.compareTo(b.title));

    return Scaffold(
      appBar: AppBar(
        title: Text(showTitle),
        backgroundColor: Colors.black87,
      ),
      backgroundColor: Colors.grey[900],
      body: ListView.builder(
        itemCount: episodes.length,
        itemBuilder: (context, index) {
          final ep = episodes[index];
          return ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: ep.thumbnailPath != null
                ? Image.network(
                    // 👇 FIX: Agora usa a variável do IP dinâmico 👇
                    'http://$ip:4000/library/movies/${ep.id}/thumbnail',
                    headers: {'Authorization': 'Bearer $token'},
                    width: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.movie, color: Colors.white24),
                  )
                : const Icon(Icons.movie, color: Colors.white24, size: 50),
            title: Text(ep.title, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              'Duração: ${(ep.duration / 60).floor()} min',
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.play_circle_fill, color: Colors.deepPurpleAccent, size: 36),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    movieId: ep.id,
                    title: ep.title,
                    token: token,
                    // Nota: O PlayerScreen já busca o IP sozinho lá dentro, 
                    // então não precisamos passar ele aqui de novo!
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}