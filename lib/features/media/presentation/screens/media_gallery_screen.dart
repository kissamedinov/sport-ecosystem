import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';
import '../../data/models/media_item.dart';
import '../../data/repositories/media_repository.dart';
import 'upload_media_screen.dart';

class MediaGalleryScreen extends StatefulWidget {
  final String? clubId;
  final String? tournamentId;
  final String? userId;

  const MediaGalleryScreen({
    super.key,
    this.clubId,
    this.tournamentId,
    this.userId,
  });

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  late Future<List<MediaItem>> _mediaFuture;

  @override
  void initState() {
    super.initState();
    _refreshMedia();
  }

  void _refreshMedia() {
    final repo = context.read<MediaRepository>();
    if (widget.clubId != null) {
      _mediaFuture = repo.getClubMedia(widget.clubId!);
    } else if (widget.tournamentId != null) {
      _mediaFuture = repo.getTournamentMedia(widget.tournamentId!);
    } else {
      _mediaFuture = repo.getUserMedia(widget.userId ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('MEDIA GALLERY', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UploadMediaScreen(
                    clubId: widget.clubId,
                    tournamentId: widget.tournamentId,
                  ),
                ),
              );
              if (result == true) {
                setState(() {
                  _refreshMedia();
                });
              }
            },
            icon: Icon(Icons.add_a_photo, color: PremiumTheme.neonGreen),
          ),
        ],
      ),
      body: FutureBuilder<List<MediaItem>>(
        future: _mediaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: Colors.white10),
                  const SizedBox(height: 16),
                  const Text('No media found', style: TextStyle(color: Colors.white38)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => _viewMedia(item),
                child: Hero(
                  tag: item.id,
                  child: PremiumCard(
                    padding: EdgeInsets.zero,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: item.url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.white.withValues(alpha: 0.05)),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                        if (item.mediaType == 'VIDEO')
                          const Center(
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.play_arrow, color: Colors.white),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black87, Colors.transparent],
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              item.title ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _viewMedia(MediaItem item) {
    // Basic full screen view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: Center(
            child: Hero(
              tag: item.id,
              child: CachedNetworkImage(
                imageUrl: item.url,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
