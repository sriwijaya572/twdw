import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DownloadScreen extends StatefulWidget {
  final String cookies;

  const DownloadScreen({super.key, required this.cookies});

  @override
  _DownloadScreenState createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  List<String> mediaUrls = [];
  int downloadedCount = 0;

  @override
  void initState() {
    super.initState();
    // Mulai ambil media setelah halaman terbuka
    _startScraping();
  }

  Future<void> _startScraping() async {
    // Contoh: Ambil media dari timeline
    final response = await http.get(
      Uri.parse('https://twitter.com/home'),
      headers: {
        'Cookie': widget.cookies,
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      },
    );

    if (response.statusCode == 200) {
      final document = parse(response.body);
      final images = document.querySelectorAll('img');

      // Filter URL gambar dari Twitter
      for (final img in images) {
        final src = img.attributes['src'];
        if (src != null && src.contains('pbs.twimg.com')) {
          setState(() {
            mediaUrls.add(src);
          });
        }
      }

      // Mulai unduh
      _downloadMedia();
    }
  }

  Future<void> _downloadMedia() async {
    for (final url in mediaUrls) {
      try {
        // Unduh gambar
        final response = await http.get(Uri.parse(url));
        final directory = await getApplicationDocumentsDirectory();
        final fileName = url.split('/').last;
        final file = File('${directory.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          downloadedCount++;
        });

        // Jeda 1 detik per file
        await Future.delayed(Duration(seconds: 1));
      } catch (e) {
        print('Gagal mengunduh: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Unduh Media')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Total Media: ${mediaUrls.length}'),
            Text('Terunduh: $downloadedCount'),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}