import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  final String filePath;
  final String title;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final source = widget.filePath.trim();
      if (source.isEmpty) {
        setState(() => _errorMessage = 'Video source is empty.');
        return;
      }

      // Accept:
      // - http/https URLs
      // - local file paths
      // - content:// URIs returned by Android shares / SAF
      if (source.startsWith('http://') || source.startsWith('https://')) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(source));
      } else if (source.startsWith('content://')) {
        _videoController = VideoPlayerController.contentUri(Uri.parse(source));
      } else {
        final file = File(source);
        if (!await file.exists()) {
          setState(() => _errorMessage = 'File not found:\n$source');
          return;
        }
        final len = await file.length();
        if (len == 0) {
          setState(() =>
              _errorMessage = 'File is empty (0 bytes). Download may have failed.');
          return;
        }
        _videoController = VideoPlayerController.file(file);
      }

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF7C3AED),
          handleColor: const Color(0xFF7C3AED),
          bufferedColor: const Color(0x557C3AED),
          backgroundColor: const Color(0xFF2A2A3E),
        ),
      );

      if (!mounted) return;
      setState(() => _isInitialized = true);
    } catch (e) {
      // Add more context if controller has errorDescription
      final controllerError = _videoController?.value.errorDescription;
      final details = controllerError == null ? '' : '\n\nDetails: $controllerError';
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load video: $e$details');
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : !_isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: Chewie(controller: _chewieController!),
                  ),
                ),
    );
  }
}
