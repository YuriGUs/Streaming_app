import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';
import '../services/storage_service.dart';
import 'player.dart';
import 'login.dart';
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _loadData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const TvPlayerScreen()),
        );
      }
    });
  }

  void _loadData() {
    _initFuture = Future.wait([
      MovieService().getMovies(),
      StorageService().getToken(),
      StorageService().getServerIp(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black87,
          toolbarHeight: 80, 
          // Botão Sair adaptado para Controle Remoto
          leading: Center(
            child: TvHeaderButton(
              icon: Icons.logout,
              color: Colors.redAccent,
              onPressed: () async {
                await StorageService().deleteToken();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              },
            ),
          ),
          title: const Text(
            'Biblioteca', 
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)
          ),
          centerTitle: true,
          // Botão de TV Ao Vivo adaptado para Controle Remoto
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: TvHeaderButton(
                  icon: Icons.live_tv,
                  color: Colors.deepPurpleAccent,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const TvPlayerScreen()),
                    );
                  },
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              color: Colors.black45,
              child: const TabBar(
                indicatorColor: Colors.deepPurpleAccent,
                indicatorWeight: 4,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Filmes'),
                  Tab(text: 'Séries'),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.grey[950],
        body: FutureBuilder<List<dynamic>>(
          future: _initFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent));
            } else if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('Nenhum dado encontrado.', style: TextStyle(color: Colors.white)));
            }

            final movies = snapshot.data![0] as List<Movie>;
            final token = snapshot.data![1] as String?; 
            final ip = snapshot.data![2] as String;   

            if (movies.isEmpty) {
              return const Center(
                child: Text('Nenhum vídeo na biblioteca.', style: TextStyle(color: Colors.white, fontSize: 18)),
              );
            }

            final filmes = movies.where((m) => m.category == 'filme').toList();
            final series = movies.where((m) => m.category == 'serie').toList();

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
                _buildFilmesGrid(filmes, token, ip),
                _buildSeriesGrid(groupedSeries, token, ip),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilmesGrid(List<Movie> filmes, String? token, String ip) {
    if (filmes.isEmpty) {
      return const Center(child: Text('Nenhum filme encontrado.', style: TextStyle(color: Colors.white54, fontSize: 18)));
    }
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(32), 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6, 
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.7, 
      ),
      itemCount: filmes.length,
      itemBuilder: (context, index) {
        final movie = filmes[index];
        return TvFocusCard(
          title: movie.title,
          thumbnailPath: movie.thumbnailPath,
          token: token,
          ip: ip, 
          onTap: () {
             Navigator.of(context).push(
               MaterialPageRoute(
                 builder: (context) => PlayerScreen(
                   movieId: movie.id.toInt(),
                   title: movie.title,
                   token: token!,
                 ),
               ),
             );
          },
        );
      },
    );
  }

  Widget _buildSeriesGrid(Map<String, List<Movie>> groupedSeries, String? token, String ip) {
    if (groupedSeries.isEmpty) {
      return const Center(child: Text('Nenhuma série encontrada.', style: TextStyle(color: Colors.white54, fontSize: 18)));
    }
    final seriesNames = groupedSeries.keys.toList()..sort();

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(32), 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6, 
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.7,
      ),
      itemCount: seriesNames.length,
      itemBuilder: (context, index) {
        final showName = seriesNames[index];
        final episodes = groupedSeries[showName]!;
        final firstEpisode = episodes.first;

        return TvFocusCard(
          title: showName, 
          thumbnailPath: firstEpisode.thumbnailPath,
          token: token,
          ip: ip,
          isSerie: true,
          episodeCount: episodes.length,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SeasonsScreen( 
                  showTitle: showName,
                  episodes: episodes,
                  token: token!,
                  ip: ip,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Botão customizado para o Topo da TV que acende ao focar
class TvHeaderButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const TvHeaderButton({Key? key, required this.icon, required this.color, required this.onPressed}) : super(key: key);

  @override
  State<TvHeaderButton> createState() => _TvHeaderButtonState();
}

class _TvHeaderButtonState extends State<TvHeaderButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focus) => setState(() => _isFocused = focus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isFocused ? widget.color.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _isFocused ? widget.color : Colors.transparent, width: 2),
        ),
        child: Icon(widget.icon, color: _isFocused ? Colors.white : widget.color, size: 32),
      ),
    );
  }
}

class TvFocusCard extends StatefulWidget {
  final String title;
  final String? thumbnailPath;
  final String? token;
  final String ip;
  final bool isSerie;
  final int episodeCount;
  final VoidCallback onTap;

  const TvFocusCard({
    Key? key,
    required this.title,
    this.thumbnailPath,
    this.token,
    required this.ip,
    this.isSerie = false,
    this.episodeCount = 0,
    required this.onTap,
  }) : super(key: key);

  @override
  State<TvFocusCard> createState() => _TvFocusCardState();
}

class _TvFocusCardState extends State<TvFocusCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focus) => setState(() => _isFocused = focus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isFocused ? 1.06 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _isFocused ? Colors.white : Colors.transparent, width: 3),
          boxShadow: _isFocused
              ? [BoxShadow(color: Colors.deepPurpleAccent.withOpacity(0.6), blurRadius: 16, spreadRadius: 2)]
              : [],
        ),
          child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            onTap: widget.onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.thumbnailPath != null && widget.token != null)
                  Image.network(
                    'http://${widget.ip}:4000/library/movies/${widget.thumbnailPath!.split('/').last.split('.').first}/thumbnail',
                    headers: {'Authorization': 'Bearer ${widget.token}'},
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 40)),
                  )
                else
                  const Center(child: Icon(Icons.movie, size: 40, color: Colors.white24)),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black, Colors.transparent],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (widget.isSerie)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.deepPurpleAccent, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        '${widget.episodeCount} EPs',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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