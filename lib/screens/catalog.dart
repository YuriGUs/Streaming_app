import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';   // Seu serviço de filmes
import '../services/storage_service.dart'; // Seu serviço de token
import 'player.dart';                       // Sua tela do player
import 'episodes.dart';                     // A nova tela de episódios
import 'seasons.dart';
import 'tv_player.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late Future<List<dynamic>> _initFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _initFuture = Future.wait([
      MovieService().getMovies(),
      StorageService().getToken(),
    ]);
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadData();
    });
    await _initFuture;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Streaming'),
          backgroundColor: Colors.black87,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.live_tv, color: Colors.deepPurpleAccent, size: 28),
                tooltip: 'Assistir TV Ao Vivo',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TvPlayerScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.deepPurpleAccent,
            tabs: [
              Tab(icon: Icon(Icons.movie), text: 'Filmes'),
              Tab(icon: Icon(Icons.tv), text: 'Séries'),
            ],
          ),
        ),
        backgroundColor: Colors.grey[950],
        body: FutureBuilder<List<dynamic>>(
          future: _initFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('Nenhum dado encontrado.', style: TextStyle(color: Colors.white)));
            }

            final movies = snapshot.data![0] as List<Movie>;
            final token = snapshot.data![1] as String?;

            if (movies.isEmpty) {
              return const Center(child: Text('Nenhum vídeo na biblioteca.', style: TextStyle(color: Colors.white)));
            }

            // Separa os dados por categoria
            final filmes = movies.where((m) => m.category == 'filme').toList();
            final series = movies.where((m) => m.category == 'serie').toList();

            // Agrupa os episódios das séries por pasta pai
            final Map<String, List<Movie>> groupedSeries = {};
            for (var ep in series) {
              final showName = ep.showTitle ?? 'Série Desconhecida';
              if (!groupedSeries.containsKey(showName)) {
                groupedSeries[showName] = [];
              }
              groupedSeries[showName]!.add(ep);
            }

            return TabBarView(
              children: [
                // Aba de Filmes
                _buildFilmesGrid(filmes, token),

                // Aba de Séries
                _buildSeriesGrid(groupedSeries, token),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- MÉTODOS AUXILIARES (FICAM ABAIXO DO MÉTODO BUILD, MAS DENTRO DA CLASSE STATE) ---

  Widget _buildFilmesGrid(List<Movie> filmes, String? token) {
    if (filmes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.deepPurpleAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            alignment: Alignment.center,
            child: const Text('Nenhum filme encontrado.', style: TextStyle(color: Colors.white54)),
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Colors.deepPurpleAccent,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(), 
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: filmes.length,
        itemBuilder: (context, index) {
          final movie = filmes[index];
          return _buildCard(
            title: movie.title,
            thumbnailPath: movie.thumbnailPath,
            token: token,
            onTap: () {
               Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PlayerScreen(
                      movieId: movie.id,
                      title: movie.title,
                      token: token!,
                    ),
                  ),
                );
            },
          );
        },
      ),
    );
  }

  Widget _buildSeriesGrid(Map<String, List<Movie>> groupedSeries, String? token) {
    if (groupedSeries.isEmpty) {
      // ... (mantenha o RefreshIndicator de lista vazia que já estava aqui)
      return RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.deepPurpleAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            alignment: Alignment.center,
            child: const Text('Nenhuma série encontrada.', style: TextStyle(color: Colors.white54)),
          ),
        ),
      );
    }
    
    // 1. Pegamos os nomes
    final seriesNames = groupedSeries.keys.toList();

    // 2. A MÁGICA DA ORDENAÇÃO NUMÉRICA:
    seriesNames.sort((a, b) {
      // Usamos Regex (Expressão Regular) para caçar os números no texto
      final regExp = RegExp(r'\d+');
      final matchA = regExp.firstMatch(a);
      final matchB = regExp.firstMatch(b);

      if (matchA != null && matchB != null) {
        // Se achou número nas duas strings, converte para inteiro e compara
        final numA = int.parse(matchA.group(0)!);
        final numB = int.parse(matchB.group(0)!);
        
        if (numA != numB) {
          return numA.compareTo(numB); // Agora o 2 vem antes do 10!
        }
      }
      
      // Se não tiver números (ex: "Breaking Bad" vs "Arcane"), vai na ordem alfabética
      return a.compareTo(b);
    });

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Colors.deepPurpleAccent,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: seriesNames.length,
        itemBuilder: (context, index) {
          final showName = seriesNames[index];
          final episodes = groupedSeries[showName]!;
          final firstEpisode = episodes.first;

          return _buildCard(
            title: showName, 
            thumbnailPath: firstEpisode.thumbnailPath,
            token: token,
            isSerie: true,
            episodeCount: episodes.length,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SeasonsScreen( // AGORA CHAMA A TELA DE TEMPORADAS
                    showTitle: showName,
                    episodes: episodes,
                    token: token!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String title,
    String? thumbnailPath,
    String? token,
    bool isSerie = false,
    int episodeCount = 0,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.grey[900]),
            if (thumbnailPath != null && token != null)
              Image.network(
                'http://10.0.2.2:4000/library/movies/${thumbnailPath.split('/').last.split('.').first}/thumbnail',
                headers: {'Authorization': 'Bearer $token'},
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 50)),
              )
            else
              const Center(child: Icon(Icons.movie, size: 50, color: Colors.white24)),
            
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            if (isSerie)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$episodeCount EPs',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}