import 'dart:io';
import 'package:flutter/material.dart';
import 'post.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final TextEditingController commentController = TextEditingController();

  final List<String> comments = [];

  bool isLiked = false;

  void likePost() {
    setState(() {
      isLiked = !isLiked;
    });
  }

  void addComment() {
    final String comment = commentController.text.trim();

    if (comment.isEmpty) {
      return;
    }

    setState(() {
      comments.add(comment);
    });

    commentController.clear();
  }

  Future<File?> _resolveOrCacheImageFile(String rawPathOrUrl) async {
    String path = rawPathOrUrl.trim();
    if (path.startsWith('file://')) {
      final uri = Uri.tryParse(path);
      if (uri != null) {
        path = uri.toFilePath();
      }
    }

    final localFile = File(path);
    if (localFile.existsSync()) {
      return localFile;
    }

    final uri = Uri.tryParse(rawPathOrUrl);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      try {
        final cacheDir = Directory(
          '${Directory.systemTemp.path}${Platform.pathSeparator}social_media_images',
        );
        if (!cacheDir.existsSync()) {
          cacheDir.createSync(recursive: true);
        }

        final filename =
            'post_img_${rawPathOrUrl.hashCode.abs().toRadixString(16)}.jpg';
        final cachedFile =
            File('${cacheDir.path}${Platform.pathSeparator}$filename');

        if (cachedFile.existsSync() && cachedFile.lengthSync() > 0) {
          return cachedFile;
        }

        final request = await HttpClient().getUrl(uri);
        final response = await request.close();
        if (response.statusCode == 200) {
          final bytes = await response.fold<List<int>>(
            <int>[],
            (List<int> previous, List<int> element) =>
                previous..addAll(element),
          );
          await cachedFile.writeAsBytes(bytes);
          return cachedFile;
        }
      } catch (e) {
        debugPrint('Error caching network image: $e');
      }
    }

    return null;
  }

  Future<void> openInWindowsFileExplorer() async {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening in Windows File Explorer...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final raw = widget.post.imageUrl.trim();
    final file = await _resolveOrCacheImageFile(raw);

    if (file != null && file.existsSync()) {
      try {
        await Process.start(
          'explorer.exe',
          ['/select,${file.absolute.path}'],
          mode: ProcessStartMode.detached,
        );
      } catch (e) {
        debugPrint('Failed to launch explorer: $e');
      }
    } else {
      final folder = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}social_media_images',
      );
      if (!folder.existsSync()) {
        folder.createSync(recursive: true);
      }
      try {
        await Process.start(
          'explorer.exe',
          [folder.absolute.path],
          mode: ProcessStartMode.detached,
        );
      } catch (e) {
        debugPrint('Failed to launch explorer: $e');
      }
    }
  }

  Widget _buildImage() {
    final raw = widget.post.imageUrl.trim();
    String path = raw;
    if (path.startsWith('file://')) {
      final uri = Uri.tryParse(path);
      if (uri != null) {
        path = uri.toFilePath();
      }
    }

    final localFile = File(path);
    if (localFile.existsSync()) {
      return Image.file(
        localFile,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildBrokenImagePlaceholder(),
      );
    }

    return Image.network(
      raw,
      width: double.infinity,
      height: 220,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _buildBrokenImagePlaceholder(),
    );
  }

  Widget _buildBrokenImagePlaceholder() {
    return const SizedBox(
      height: 220,
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: 70,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.post.username.trim();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(
                username.isEmpty ? '?' : username[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              username,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text('Student Feed'),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              widget.post.caption,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          GestureDetector(
            onTap: openInWindowsFileExplorer,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Tooltip(
                message: 'Click to open in Windows File Explorer',
                child: Stack(
                  children: [
                    _buildImage(),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_open,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Open in Explorer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: likePost,
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : null,
                ),
                label: Text(isLiked ? 'Liked' : 'Like'),
              ),
              Text('${comments.length} Comments'),
            ],
          ),
          for (final String comment in comments)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                4,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(comment),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: addComment,
                  icon: const Icon(Icons.send),
                  color: Colors.green,
                  tooltip: 'Send comment',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
