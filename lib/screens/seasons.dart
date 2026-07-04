import 'package:flutter/material.dart';
import '../models/movie.dart';
import 'episodes.dart';

class SeasonsScreen extends StatelessWidget {
  final String showTitle;
  final List<Movie> episodes;
  final String token;
  final String ip; // NOVO: Variável para receber o IP

  const SeasonsScreen({
    Key? key,
    required this.showTitle,
    required this.episodes,
    required this.token,
    required this.ip, // NOVO: Exige o IP no construtor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Agrupa os episódios pelo número da temporada
    final Map<int, List<Movie>> seasonsMap = {};
    for (var ep in episodes) {
      if (!seasonsMap.containsKey(ep.season)) {
        seasonsMap[ep.season] = [];
      }
      seasonsMap[ep.season]!.add(ep);
    }

    // Ordena as temporadas numericamente (1, 2, 3...)
    final seasonNumbers = seasonsMap.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(showTitle),
        backgroundColor: Colors.black87,
      ),
      backgroundColor: Colors.grey[900],
      body: ListView.builder(
        itemCount: seasonNumbers.length,
        itemBuilder: (context, index) {
          final sNum = seasonNumbers[index];
          final seasonEps = seasonsMap[sNum]!;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            title: Text(
              'Temporada $sNum',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${seasonEps.length} episódios',
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24),
            onTap: () {
              // Navega para a tela de episódios, enviando SÓ os episódios dessa temporada específica
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EpisodesScreen(
                    showTitle: '$showTitle - Temporada $sNum',
                    episodes: seasonEps,
                    token: token,
                    ip: ip, // NOVO: Repassa o IP para a tela de episódios!
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